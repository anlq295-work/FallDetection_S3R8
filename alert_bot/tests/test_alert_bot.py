from __future__ import annotations

import asyncio
from pathlib import Path

import httpx
import pytest
from fastapi.testclient import TestClient

from alert_bot.config import BotConfig
from alert_bot.dispatcher import AlertDispatcher
from alert_bot.models import BotSettings, ChannelToggles, FallAlertRequest, Recipient
from alert_bot.server import create_app
from alert_bot.storage import SettingsStore, normalize_phone, normalize_telegram_username
from alert_bot.telegram_poller import TelegramBotPoller


def _make_mock_transport(recorded_calls: list[dict[str, object]]) -> httpx.MockTransport:
    def handler(request: httpx.Request) -> httpx.Response:
        url = str(request.url)
        recorded_calls.append(
            {
                "method": request.method,
                "url": url,
                "body": request.content.decode("utf-8", errors="replace"),
            }
        )
        if "api.telegram.org" in url:
            if "sendMessage" in url:
                return httpx.Response(200, json={"ok": True, "result": {"message_id": 42}})
            return httpx.Response(200, json={"ok": True, "result": True})
        if "api.callmebot.com" in url:
            return httpx.Response(200, text="Call queued for @alice")
        if "api.speedsms.vn" in url:
            return httpx.Response(200, json={"status": "success", "code": "00"})
        if "api.twilio.com" in url:
            return httpx.Response(201, json={"sid": "SM_TEST_123"})
        if "api.stringee.com" in url:
            return httpx.Response(200, json={"r": 13, "message": "WAIT_TEXT_TO_SPEECH", "call_id": "call-vn-test-1"})
        if "verify.twilio.com" in url:
            body_txt = request.content.decode("utf-8", errors="replace")
            if "VerificationCheck" in url:
                approved = "Code=654321" in body_txt
                return httpx.Response(200, json={"status": "approved" if approved else "pending"})
            return httpx.Response(201, json={"sid": "VE_TEST_123", "status": "pending"})
        if "api.sendgrid.com" in url:
            return httpx.Response(202, text="")
        if "/api/command" in url:
            return httpx.Response(200, json={"status": "ok"})
        return httpx.Response(404, text="not found")

    return httpx.MockTransport(handler)


def test_normalization_helpers() -> None:
    assert normalize_phone("0912 345 678") == "+84912345678"
    assert normalize_phone("+84 912-345-678") == "+84912345678"
    assert normalize_phone("0084912345678") == "+84912345678"
    assert normalize_phone("123") == ""
    assert normalize_telegram_username("alice") == "@alice"
    assert normalize_telegram_username("@alice") == "@alice"
    assert normalize_telegram_username("https://t.me/alice") == "@alice"


@pytest.mark.asyncio
async def test_simultaneous_multi_channel_dispatch(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        callmebot_enabled=True,
        twilio_account_sid="AC123",
        twilio_auth_token="AUTH123",
        twilio_from_number="+15551234567",
        speedsms_access_token="SPEED_TOKEN",
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.update_settings(
        BotSettings(
            dispatch_mode="simultaneous",
            person_name="Bà Nội",
            home_address="123 Nguyễn Huệ",
            door_code="2580",
            channels=ChannelToggles(telegram=True, sms=True, call=True),
            recipients=[
                Recipient(
                    id="r1",
                    name="Con trai An",
                    phone="0912345678",
                    telegram_chat_id="1001",
                    telegram_username="@an_care",
                    notify_telegram=True,
                    notify_sms=True,
                    notify_call=True,
                ),
                Recipient(
                    id="r2",
                    name="Con gái Bình",
                    phone="+14155550199",
                    telegram_chat_id="1002",
                    telegram_username="",
                    notify_telegram=True,
                    notify_sms=True,
                    notify_call=True,
                ),
            ],
        )
    )

    dispatcher = AlertDispatcher(cfg, store, http_client=client)
    rec, dedup = await dispatcher.trigger_fall_alert(
        FallAlertRequest(
            event_type="fall_impact",
            room_name="Phòng tắm",
            velocity_mm_s=720.0,
            motion_peak=88,
            target_dist_cm=140,
            device_ip="192.168.1.88",
        )
    )

    assert not dedup
    assert set(rec.notified_recipient_ids) == {"r1", "r2"}
    assert all(d.ok for d in rec.deliveries)

    providers_hit = {(d.recipient_id, d.channel, d.provider) for d in rec.deliveries}
    # r1 (VN phone + Telegram + SMS + CallMeBot + Twilio Voice)
    assert ("r1", "telegram", "telegram_bot") in providers_hit
    assert ("r1", "sms", "speedsms") in providers_hit
    assert ("r1", "call", "callmebot_telegram") in providers_hit
    assert ("r1", "call", "twilio_voice") in providers_hit
    # r2 (Telegram + Twilio Voice)
    assert ("r2", "telegram", "telegram_bot") in providers_hit
    assert ("r2", "sms", "twilio_sms") in providers_hit
    assert ("r2", "call", "twilio_voice") in providers_hit

    # Resolving sends CANCEL_ALARM to ESP32 LAN IP
    resolved = await dispatcher.resolve_alert(rec.alert_id, by="Con trai An", outcome="person_ok")
    assert resolved is not None
    assert resolved.status == "resolved"
    assert any("192.168.1.88/api/command" in str(c["url"]) for c in calls)

    await dispatcher.shutdown()
    await client.aclose()


@pytest.mark.asyncio
async def test_sequential_escalation_stops_on_ack(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        callmebot_enabled=False,
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.update_settings(
        BotSettings(
            dispatch_mode="sequential",
            escalation_minutes=1,
            channels=ChannelToggles(telegram=True, sms=False, call=False),
            recipients=[
                Recipient(id="first", name="Người 1", telegram_chat_id="111"),
                Recipient(id="second", name="Người 2", telegram_chat_id="222"),
            ],
        )
    )

    dispatcher = AlertDispatcher(cfg, store, http_client=client)
    rec, _ = await dispatcher.trigger_fall_alert(
        FallAlertRequest(event_type="slow_fall", room_name="Phòng ngủ")
    )
    # Only first recipient notified immediately
    assert rec.notified_recipient_ids == ["first"]
    assert rec.alert_id in dispatcher._escalation_tasks

    # Acknowledge cancels pending escalation task
    acked = await dispatcher.acknowledge_alert(rec.alert_id, by="Người 1")
    assert acked is not None
    assert acked.status == "acknowledged"
    assert rec.alert_id not in dispatcher._escalation_tasks

    await asyncio.sleep(0.05)
    await dispatcher.shutdown()
    await client.aclose()


@pytest.mark.asyncio
async def test_targeted_test_does_not_broadcast_to_other_contacts(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    client = httpx.AsyncClient(transport=_make_mock_transport(calls))
    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.update_settings(BotSettings(recipients=[
        Recipient(id="first", name="First", telegram_chat_id="111"),
        Recipient(id="second", name="Second", telegram_chat_id="222"),
    ]))
    dispatcher = AlertDispatcher(cfg, store, http_client=client)

    missing, _ = await dispatcher.trigger_fall_alert(FallAlertRequest(
        event_type="test", room_name="Room", target_recipient_ids=["deleted"],
        channels_override=["telegram"],
    ))
    assert missing.notified_recipient_ids == []
    assert calls == []

    selected, _ = await dispatcher.trigger_fall_alert(FallAlertRequest(
        event_type="test", room_name="Room", target_recipient_ids=["second"],
        channels_override=["telegram"],
    ))
    assert selected.notified_recipient_ids == ["second"]
    assert len([c for c in calls if "sendMessage" in str(c["url"])]) == 1

    await dispatcher.shutdown()
    await client.aclose()


@pytest.mark.asyncio
async def test_telegram_commands_register_and_toggle(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
    )
    store = SettingsStore(cfg.data_file)
    dispatcher = AlertDispatcher(cfg, store, http_client=client)
    poller = TelegramBotPoller(dispatcher.telegram, store, dispatcher)

    # /register command adds recipient to settings
    await poller.handle_update(
        {
            "message": {
                "text": "/register Minh Anh 0987654321",
                "chat": {"id": 555666},
                "from": {"first_name": "Minh", "username": "minh_anh"},
            }
        }
    )
    recipients = store.enabled_recipients()
    assert len(recipients) == 1
    assert recipients[0].name == "Minh Anh"
    assert recipients[0].phone == "0987654321"
    assert recipients[0].telegram_chat_id == "555666"
    assert recipients[0].telegram_username == "@minh_anh"

    # Toggle mode callback switches simultaneous -> sequential
    await poller.handle_update(
        {
            "callback_query": {
                "id": "cb_1",
                "data": "cfg:toggle_mode",
                "from": {"first_name": "Minh"},
                "message": {"chat": {"id": 555666}},
            }
        }
    )
    assert store.get_settings().dispatch_mode == "sequential"

    await dispatcher.shutdown()
    await client.aclose()


def test_fastapi_endpoints_and_api_key(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        api_key="secret123",
        telegram_bot_token="123456:TEST_TOKEN",
        callmebot_enabled=True,
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        # /health is open
        h = tc.get("/health")
        assert h.status_code == 200
        assert h.json()["status"] == "ok"

        # Protected endpoint rejects missing key
        assert tc.get("/api/settings").status_code == 401

        headers = {"X-API-Key": "secret123"}
        # Sync settings from Hearth App
        put_resp = tc.put(
            "/api/settings",
            headers=headers,
            json={
                "dispatch_mode": "simultaneous",
                "escalation_minutes": 2,
                "channels": {"telegram": True, "sms": False, "call": True},
                "person_name": "Ông Ngoại",
                "recipients": [
                    {
                        "id": "c1",
                        "name": "Chú Hùng",
                        "phone": "0909123456",
                        "telegram_chat_id": "999001",
                        "telegram_username": "@chu_hung",
                        "enabled": True,
                    }
                ],
            },
        )
        assert put_resp.status_code == 200
        assert put_resp.json()["person_name"] == "Ông Ngoại"

        # Trigger fall alert webhook (as ESP32 or App would)
        fall_resp = tc.post(
            "/api/alerts/fall",
            headers=headers,
            json={
                "event_type": "fall_impact",
                "room_name": "Phòng khách",
                "velocity_mm_s": 690,
                "motion_peak": 82,
            },
        )
        assert fall_resp.status_code == 200
        body = fall_resp.json()
        assert body["ok"] is True
        assert body["delivered_count"] == 2  # Telegram + CallMeBot

        alert_id = body["alert"]["alert_id"]
        ack_resp = tc.post(
            f"/api/alerts/{alert_id}/ack",
            headers=headers,
            json={"by": "Chú Hùng"},
        )
        assert ack_resp.status_code == 200
        assert ack_resp.json()["alert"]["status"] == "acknowledged"


def test_email_otp_twilio_verify_endpoints(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        twilio_account_sid="AC_TEST",
        twilio_auth_token="AUTH_TEST",
        twilio_verify_service_sid="VA_TEST_SERVICE",
        otp_resend_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        r_send = tc.post(
            "/api/auth/otp/send",
            json={"email": "family@example.com", "carer_name": "An", "language": "vi"},
        )
        assert r_send.status_code == 200
        assert r_send.json()["ok"] is True
        assert r_send.json()["provider"] == "twilio_verify_email"

        r_bad = tc.post(
            "/api/auth/otp/verify",
            json={"email": "family@example.com", "code": "000000"},
        )
        assert r_bad.status_code == 200
        assert r_bad.json()["ok"] is False

        r_ok = tc.post(
            "/api/auth/otp/verify",
            json={"email": "family@example.com", "code": "654321"},
        )
        assert r_ok.status_code == 200
        assert r_ok.json()["ok"] is True


def test_email_otp_sendgrid_end_to_end(tmp_path: Path) -> None:
    import json as _json
    import re as _re

    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        sendgrid_api_key="SG.TEST_KEY",
        sendgrid_from_email="noreply@hearth.local",
        otp_resend_cooldown_sec=0,
        otp_max_attempts=3,
    )
    store = SettingsStore(cfg.data_file)
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        r_send = tc.post(
            "/api/auth/otp/send",
            json={"email": "caregiver@example.com", "carer_name": "Linh", "language": "vi"},
        )
        assert r_send.status_code == 200
        assert r_send.json()["ok"] is True
        assert r_send.json()["provider"] == "twilio_sendgrid_email"

        # Extract the 6-digit OTP from mocked SendGrid request payload
        sg_call = next(c for c in calls if "api.sendgrid.com" in str(c["url"]))
        sg_payload = _json.loads(str(sg_call["body"]))
        plain_body = sg_payload["content"][0]["value"]
        match = _re.search(r"\b(\d{6})\b", plain_body)
        assert match is not None
        real_code = match.group(1)

        # Wrong code fails
        wrong_code = "000000" if real_code != "000000" else "111111"
        r_wrong = tc.post(
            "/api/auth/otp/verify",
            json={"email": "caregiver@example.com", "code": wrong_code},
        )
        assert r_wrong.json()["ok"] is False

        # Correct code succeeds and consumes OTP
        r_good = tc.post(
            "/api/auth/otp/verify",
            json={"email": "caregiver@example.com", "code": real_code},
        )
        assert r_good.json()["ok"] is True

        # Replaying same OTP fails
        r_replay = tc.post(
            "/api/auth/otp/verify",
            json={"email": "caregiver@example.com", "code": real_code},
        )
        assert r_replay.json()["ok"] is False


def test_targeted_channel_and_recipient_test_buttons(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        twilio_account_sid="AC123",
        twilio_auth_token="AUTH123",
        twilio_from_number="+15551234567",
        callmebot_enabled=False,
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.update_settings(
        BotSettings(
            channels=ChannelToggles(telegram=True, sms=True, call=True),
            recipients=[
                Recipient(id="r1", name="Người 1", phone="0912345678", telegram_chat_id="1001"),
                Recipient(id="r2", name="Người 2", phone="0987654321", telegram_chat_id="1002"),
            ],
        )
    )
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        # Web dashboard renders test buttons (Telegram & Call, no SMS)
        home = tc.get("/")
        assert home.status_code == 200
        assert "Test Telegram" in home.text and "Test Gọi điện" in home.text
        assert "Test SMS" not in home.text

        # Test ONLY Telegram for ONLY recipient r2
        r_tg = tc.post(
            "/api/alerts/test",
            json={"channels_override": ["telegram"], "target_recipient_ids": ["r2"]},
        )
        assert r_tg.status_code == 200
        deliveries = r_tg.json()["alert"]["deliveries"]
        assert len(deliveries) == 1
        assert deliveries[0]["channel"] == "telegram"
        assert deliveries[0]["recipient_id"] == "r2"

        # Test ONLY Call verifies Twilio Google Vietnamese voice in TwiML
        calls.clear()
        r_call = tc.post(
            "/api/alerts/test",
            json={"channels_override": ["call"], "target_recipient_ids": ["r1"]},
        )
        assert r_call.status_code == 200
        call_deliveries = r_call.json()["alert"]["deliveries"]
        assert len(call_deliveries) == 1
        assert call_deliveries[0]["channel"] == "call"
        assert call_deliveries[0]["provider"] == "twilio_voice"
        twilio_call_req = next(c for c in calls if "Calls.json" in str(c["url"]))
        assert "Google.vi-VN-Standard-A" in str(twilio_call_req["body"])


def test_telegram_webhook_mode_for_render(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        telegram_webhook_base_url="https://hearth-alert-bot.onrender.com",
        telegram_webhook_secret="wh_secret_123",
    )
    store = SettingsStore(cfg.data_file)
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        # Startup registered setWebhook automatically
        assert any("setWebhook" in str(c["url"]) for c in calls)

        # Wrong secret rejected
        bad = tc.post(
            "/api/telegram/webhook",
            headers={"X-Telegram-Bot-Api-Secret-Token": "wrong"},
            json={"message": {"text": "/start", "chat": {"id": 777}}},
        )
        assert bad.status_code == 401

        # Valid webhook registers recipient
        ok = tc.post(
            "/api/telegram/webhook",
            headers={"X-Telegram-Bot-Api-Secret-Token": "wh_secret_123"},
            json={
                "message": {
                    "text": "/register An 0912345678",
                    "chat": {"id": 777888},
                    "from": {"first_name": "An", "username": "an_test"},
                }
            },
        )
        assert ok.status_code == 200
        assert any(r.telegram_chat_id == "777888" and r.phone == "0912345678" for r in store.enabled_recipients())


def test_render_base64_webhook_secret_sanitized(monkeypatch) -> None:
    import re
    monkeypatch.setenv("TELEGRAM_WEBHOOK_SECRET", "abc+def/ghi===")
    monkeypatch.setenv("RENDER_EXTERNAL_URL", "https://hearth-alert-bot.onrender.com/")
    cfg = BotConfig.from_env()
    assert cfg.telegram_webhook_base_url == "https://hearth-alert-bot.onrender.com"
    assert re.fullmatch(r"[A-Za-z0-9_-]{1,256}", cfg.telegram_webhook_secret)
    assert cfg.telegram_webhook_secret != "abc+def/ghi==="


def test_edge_ai_human_in_the_loop_dataset_pipeline(tmp_path: Path) -> None:
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        telegram_bot_token="123456:TEST_TOKEN",
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.register_telegram_user("555111", "An")
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    sample_features = [62.0, 44.0, 1100.0, 650.0, 580.0, 310.0, 145.0, 620.0, 26.0, 40.0, 3.0, 460.0]

    with TestClient(app) as tc:
        # 1. ESP32 sends a fall alert with 12 Edge AI features
        r_fall = tc.post(
            "/api/alerts/fall",
            json={
                "event_type": "fall_impact",
                "room_name": "Phòng khách",
                "velocity_mm_s": 620.0,
                "motion_peak": 62,
                "simulated": False,
                "ai_features": sample_features,
                "ai_diagnostics": {"model_version": "mlp12-test"},
            },
        )
        assert r_fall.status_code == 200
        alert_id = r_fall.json()["alert"]["alert_id"]

        # 2. Carer resolves alert as False Alarm (satDownQuickly) -> auto-labeled SIT
        r_res = tc.post(
            f"/api/alerts/{alert_id}/resolve",
            json={
                "by": "An",
                "outcome": "false_alarm",
                "false_alarm_reason": "satDownQuickly",
                "note": "Ngồi phịch xuống ghế",
            },
        )
        assert r_res.status_code == 200

        # 3. Direct CLI recorder uploads a verified FALL sample
        r_add = tc.post(
            "/api/ai/samples",
            json={
                "label": "FALL",
                "features": [88.0, 42.0, 2200.0, 1900.0, 240.0, 640.0, 160.0, 1400.0, 9.0, 38.0, 6.0, 1150.0],
                "source": "recorder_cli",
            },
        )
        assert r_add.status_code == 200

        # 4. Verify dataset JSON & CSV export for scripts/train_edge_ai.py
        r_ds = tc.get("/api/ai/dataset")
        assert r_ds.status_code == 200
        ds = r_ds.json()
        assert ds["summary"]["total"] == 2
        assert ds["summary"]["SIT"] == 1
        assert ds["summary"]["FALL"] == 1
        assert ds["summary"]["false_alarms"] == 1

        r_csv = tc.get("/api/ai/dataset.csv")
        assert r_csv.status_code == 200
        assert "max_motion" in r_csv.text
        assert "SIT,satDownQuickly,3.5,true" in r_csv.text
        assert "FALL,recorder_cli,3.0,false" in r_csv.text


def test_stringee_voice_priority_over_twilio(tmp_path: Path) -> None:
    import json as _json
    calls: list[dict[str, object]] = []
    mock_client = httpx.AsyncClient(transport=_make_mock_transport(calls))

    cfg = BotConfig(
        data_file=str(tmp_path / "settings.json"),
        stringee_api_key_sid="SK.0.TEST_SID",
        stringee_api_key_secret="TEST_SECRET_KEY",
        stringee_from_number="842473001234",
        twilio_account_sid="AC_TEST",
        twilio_auth_token="AUTH_TEST",
        twilio_from_number="+15017122661",
        alert_cooldown_sec=0,
    )
    store = SettingsStore(cfg.data_file)
    store.update_settings(
        BotSettings(
            person_name="Bà Nội",
            channels=ChannelToggles(telegram=False, sms=False, call=True),
            recipients=[Recipient(id="r1", name="An", phone="0912345678", notify_call=True)],
        )
    )
    dispatcher = AlertDispatcher(cfg, store, http_client=mock_client)
    app = create_app(config=cfg, store=store, dispatcher=dispatcher, enable_poller=False)

    with TestClient(app) as tc:
        health = tc.get("/health").json()
        assert health["providers"]["stringee_voice_call"] is True

        r = tc.post(
            "/api/alerts/fall",
            json={"event_type": "fall_impact", "room_name": "Phòng tắm", "simulated": False},
        )
        assert r.status_code == 200
        deliveries = r.json()["alert"]["deliveries"]
        assert len(deliveries) == 1
        assert deliveries[0]["provider"] == "stringee_voice"
        assert deliveries[0]["ok"] is True

        # Twilio must NOT be called when Stringee succeeded
        assert any("api.stringee.com/v1/call2/callout" in str(c["url"]) for c in calls)
        assert not any("api.twilio.com" in str(c["url"]) for c in calls)

        str_req = next(c for c in calls if "api.stringee.com" in str(c["url"]))
        body = _json.loads(str(str_req["body"]))
        assert body["from"]["number"] == "842473001234"
        assert body["to"][0]["number"] == "84912345678"
        assert body["actions"][0]["action"] == "talk"
        assert "Bà Nội" in body["actions"][0]["text"]
        assert "Phòng tắm" in body["actions"][0]["text"]
