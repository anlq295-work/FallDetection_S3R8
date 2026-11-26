from __future__ import annotations

import asyncio
import html
import logging
import time
from typing import Any

import httpx

from .config import BotConfig
from .models import AiTrainingSample, AlertRecord, BotSettings, DeliveryResult, FallAlertRequest, Recipient
from .providers import CallProvider, SmsProvider, TelegramProvider
from .storage import SettingsStore, normalize_telegram_username

logger = logging.getLogger("alert_bot.dispatcher")


class AlertDispatcher:
    """Orchestrates simultaneous & sequential multi-channel fall alerts."""

    def __init__(
        self,
        config: BotConfig,
        store: SettingsStore,
        telegram: TelegramProvider | None = None,
        sms: SmsProvider | None = None,
        call: CallProvider | None = None,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self.config = config
        self.store = store
        self.telegram = telegram or TelegramProvider(config, client=http_client)
        self.sms = sms or SmsProvider(config, client=http_client)
        self.call = call or CallProvider(config, client=http_client)
        self._http_client = http_client
        self._escalation_tasks: dict[str, asyncio.Task[Any]] = {}
        self._last_alert_ts_by_key: dict[str, float] = {}

    def _resolve_target_recipients(
        self, req: FallAlertRequest, settings: BotSettings
    ) -> list[Recipient]:
        if not req.use_fallback_only:
            recipients = [r for r in settings.recipients if r.enabled]
            if req.target_recipient_ids:
                wanted = {rid.strip() for rid in req.target_recipient_ids if rid.strip()}
                filtered = [r for r in recipients if r.id in wanted or r.telegram_chat_id in wanted]
                return filtered
            if recipients:
                return recipients

        # Fallback if settings.json has no recipients yet, e.g. ESP32 sent its NVS contacts
        fallback: list[Recipient] = []
        max_len = max(
            len(req.fallback_chat_ids),
            len(req.fallback_phones),
            len(req.fallback_telegram_users),
            0,
        )
        for i in range(max_len):
            cid = req.fallback_chat_ids[i].strip() if i < len(req.fallback_chat_ids) else ""
            phone = req.fallback_phones[i].strip() if i < len(req.fallback_phones) else ""
            tuser = (
                normalize_telegram_username(req.fallback_telegram_users[i])
                if i < len(req.fallback_telegram_users)
                else ""
            )
            if cid or phone or tuser:
                fallback.append(
                    Recipient(
                        id=f"fallback_{i + 1}",
                        name=f"Liên hệ #{i + 1}",
                        phone=phone,
                        telegram_chat_id=cid,
                        telegram_username=tuser,
                        enabled=True,
                    )
                )
        if req.target_recipient_ids:
            wanted = {rid.strip() for rid in req.target_recipient_ids if rid.strip()}
            return [r for r in fallback if r.id in wanted or r.telegram_chat_id in wanted]
        return fallback

    async def _dispatch_to_recipient(
        self,
        alert_id: str,
        recipient: Recipient,
        req: FallAlertRequest,
        settings: BotSettings,
    ) -> list[DeliveryResult]:
        tasks: list[asyncio.Future[Any] | Any] = []

        if req.channels_override is not None:
            want_tg = "telegram" in req.channels_override
            want_sms = "sms" in req.channels_override
            want_call = "call" in req.channels_override
        else:
            want_tg = settings.channels.telegram and recipient.notify_telegram
            want_sms = settings.channels.sms and recipient.notify_sms
            want_call = settings.channels.call and recipient.notify_call

        if want_tg:
            if recipient.telegram_chat_id:
                tasks.append(self.telegram.send_fall_alert(alert_id, recipient, req, settings))
            elif req.channels_override is not None:
                tasks.append(
                    asyncio.sleep(
                        0,
                        result=DeliveryResult(
                            recipient_id=recipient.id,
                            recipient_name=recipient.name,
                            channel="telegram",
                            provider="telegram_bot",
                            target="",
                            ok=False,
                            detail="Chưa có Telegram Chat ID — hãy mở @hearth_care_bot trên Telegram và bấm /start để đăng ký!",
                        ),
                    )
                )

        if want_sms:
            tasks.append(self.sms.send_fall_sms(recipient, req, settings))

        if want_call:
            if recipient.telegram_username or recipient.phone:
                tasks.append(self.call.place_fall_calls(recipient, req, settings))
            elif req.channels_override is not None:
                tasks.append(
                    asyncio.sleep(
                        0,
                        result=DeliveryResult(
                            recipient_id=recipient.id,
                            recipient_name=recipient.name,
                            channel="call",
                            provider="none",
                            target="",
                            ok=False,
                            detail="Người nhận chưa có SĐT (Twilio Voice) hoặc @username (CallMeBot)",
                        ),
                    )
                )

        if not tasks:
            return []

        raw_results = await asyncio.gather(*tasks, return_exceptions=True)
        flat: list[DeliveryResult] = []
        for item in raw_results:
            if isinstance(item, DeliveryResult):
                flat.append(item)
            elif isinstance(item, list):
                flat.extend(x for x in item if isinstance(x, DeliveryResult))
            elif isinstance(item, Exception):
                logger.exception("Dispatch channel exception for %s: %s", recipient.name, item)
        return flat

    async def trigger_fall_alert(self, req: FallAlertRequest) -> tuple[AlertRecord, bool]:
        """Triggers alert dispatch. Returns (AlertRecord, deduplicated)."""
        settings = self.store.get_settings()
        dedup_key = f"{req.device_id or req.room_name}:{req.event_type}"
        now = time.monotonic()

        # Skip cooldown for test or manual SOS so explicit user triggers always fire immediately
        if req.event_type not in ("test", "manual_sos") and not req.simulated:
            last_ts = self._last_alert_ts_by_key.get(dedup_key, 0.0)
            if self.config.alert_cooldown_sec > 0 and (now - last_ts) < self.config.alert_cooldown_sec:
                existing = self.store.get_latest_active_alert()
                if existing is not None:
                    return existing, True
        self._last_alert_ts_by_key[dedup_key] = now

        if req.device_ip and req.device_ip != "0.0.0.0" and settings.esp32_lan_ip != req.device_ip:
            settings.esp32_lan_ip = req.device_ip
            self.store.update_settings(settings)

        recipients = self._resolve_target_recipients(req, settings)
        alert_id = self.store.generate_alert_id()
        person_name = req.person_name or settings.person_name or "Người cần chăm sóc"

        record = AlertRecord(
            alert_id=alert_id,
            event_type=req.event_type,
            room_name=req.room_name,
            person_name=person_name,
            simulated=req.simulated or req.event_type == "test",
            device_id=req.device_id,
            device_ip=req.device_ip or settings.esp32_lan_ip,
            ai_features=list(req.ai_features),
            ai_diagnostics=dict(req.ai_diagnostics),
        )
        self.store.create_alert(record)

        if not recipients:
            logger.warning("Alert %s triggered with 0 enabled recipients!", alert_id)
            return record, False

        if settings.dispatch_mode == "simultaneous" or len(recipients) == 1:
            batch = await asyncio.gather(
                *(self._dispatch_to_recipient(alert_id, r, req, settings) for r in recipients)
            )
            for r, res_list in zip(recipients, batch):
                record.notified_recipient_ids.append(r.id)
                record.deliveries.extend(res_list)
            self.store.update_alert(record)
        else:
            # Sequential escalation: notify recipient #1 immediately, escalate remaining in background
            first = recipients[0]
            first_results = await self._dispatch_to_recipient(alert_id, first, req, settings)
            record.notified_recipient_ids.append(first.id)
            record.deliveries.extend(first_results)
            self.store.update_alert(record)

            remaining = recipients[1:]
            if remaining:
                delay_sec = max(1, settings.escalation_minutes) * 60
                task = asyncio.create_task(
                    self._run_sequential_escalation(alert_id, remaining, req, delay_sec)
                )
                self._escalation_tasks[alert_id] = task

        return self.store.get_alert(alert_id) or record, False

    async def _run_sequential_escalation(
        self,
        alert_id: str,
        remaining: list[Recipient],
        req: FallAlertRequest,
        delay_sec: float,
    ) -> None:
        try:
            for recipient in remaining:
                await asyncio.sleep(delay_sec)
                current = self.store.get_alert(alert_id)
                if not current or current.status != "active":
                    logger.info("Escalation stopped for %s (status=%s)", alert_id, current.status if current else "none")
                    return
                settings = self.store.get_settings()
                logger.info("Escalating alert %s to next recipient: %s", alert_id, recipient.name)
                results = await self._dispatch_to_recipient(alert_id, recipient, req, settings)
                current.notified_recipient_ids.append(recipient.id)
                current.deliveries.extend(results)
                self.store.update_alert(current)
        except asyncio.CancelledError:
            logger.info("Escalation task cancelled for alert %s", alert_id)
        finally:
            self._escalation_tasks.pop(alert_id, None)

    def _cancel_escalation(self, alert_id: str) -> None:
        task = self._escalation_tasks.pop(alert_id, None)
        if task and not task.done():
            task.cancel()

    async def acknowledge_alert(self, alert_id: str, by: str) -> AlertRecord | None:
        self._cancel_escalation(alert_id)
        rec = self.store.mark_acknowledged(alert_id, by)
        if not rec:
            return None
        await self._broadcast_telegram_update(
            rec,
            f"✅ <b>ĐÃ XÁC NHẬN SỰ CỐ</b> (<code>{html.escape(alert_id)}</code>)\n"
            f"👤 <b>{html.escape(by)}</b> đã nhận thông báo và đang tới kiểm tra <b>{html.escape(rec.person_name)}</b> tại <b>{html.escape(rec.room_name)}</b>.",
        )
        return rec

    async def resolve_alert(
        self,
        alert_id: str,
        by: str,
        outcome: str = "person_ok",
        note: str = "",
        false_alarm_reason: str = "",
    ) -> AlertRecord | None:
        self._cancel_escalation(alert_id)
        rec = self.store.mark_resolved(alert_id, by, outcome)
        if not rec:
            return None

        # Human-in-the-Loop Edge AI: lưu nhãn thực tế kèm 12 đặc trưng cảm biến để tự huấn luyện lại
        ai_saved_msg = ""
        if not rec.simulated and len(rec.ai_features) == 12:
            if outcome == "needed_help":
                label = "FALL"
                is_false_alarm = False
            else:
                is_false_alarm = True
                reason_norm = (false_alarm_reason or "").strip().lower()
                if reason_norm in ("guestorpet", "normalroutine"):
                    label = "STAND"
                else:
                    label = "SIT"
            self.store.add_ai_sample(
                AiTrainingSample(
                    label=label,  # type: ignore[arg-type]
                    features=list(rec.ai_features),
                    source="user_feedback",
                    alert_id=rec.alert_id,
                    outcome=outcome,
                    reason=false_alarm_reason,
                    note=note,
                    is_false_alarm=is_false_alarm,
                    device_id=rec.device_id,
                    room_name=rec.room_name,
                )
            )
            ai_saved_msg = f"\n🧠 Đã lưu mẫu học Edge AI (nhãn: <code>{label}</code>)"

        outcome_map = {
            "person_ok": "🟢 Người thân an toàn",
            "needed_help": "🚑 Đã gọi cấp cứu / hỗ trợ y tế",
            "false_alarm": "⚪ Báo động giả",
        }
        outcome_label = outcome_map.get(outcome, outcome)
        extra_note = f"\n📝 Ghi chú: <i>{html.escape(note)}</i>" if note.strip() else ""
        await self._broadcast_telegram_update(
            rec,
            f"🏁 <b>ĐÃ ĐÓNG CẢNH BÁO</b> (<code>{html.escape(alert_id)}</code>)\n"
            f"• Kết quả: <b>{outcome_label}</b>\n"
            f"• Xử lý bởi: <b>{html.escape(by)}</b>{extra_note}{ai_saved_msg}",
            clear_buttons=True,
        )

        # Best-effort: tell ESP32-S3 on LAN to cancel local siren/LED and adapt threshold
        target_ip = rec.device_ip or self.store.get_settings().esp32_lan_ip
        if target_ip and target_ip != "0.0.0.0":
            await self._notify_esp32_cancel_alarm(target_ip)
            if not rec.simulated:
                fb_outcome = "true_fall" if outcome == "needed_help" else "false_alarm"
                await self._notify_esp32_ai_feedback(target_ip, fb_outcome)

        return rec

    async def _broadcast_telegram_update(
        self, rec: AlertRecord, text: str, clear_buttons: bool = False
    ) -> None:
        if not self.telegram.configured:
            return
        notified_chats: set[str] = set()
        for d in rec.deliveries:
            if d.channel == "telegram" and d.ok and d.target:
                if clear_buttons and d.message_id is not None:
                    await self.telegram.edit_message_reply_markup(d.target, d.message_id)
                notified_chats.add(d.target)

        # Also include any currently enabled Telegram recipients
        for r in self.store.enabled_recipients():
            if r.telegram_chat_id:
                notified_chats.add(r.telegram_chat_id)

        await asyncio.gather(
            *(self.telegram.send_text(chat_id, text) for chat_id in notified_chats),
            return_exceptions=True,
        )

    async def _notify_esp32_cancel_alarm(self, ip: str) -> None:
        url = f"http://{ip}/api/command"
        try:
            if self._http_client is not None:
                await self._http_client.post(url, json={"cmd": "CANCEL_ALARM"}, timeout=3.0)
            else:
                async with httpx.AsyncClient(timeout=3.0) as client:
                    await client.post(url, json={"cmd": "CANCEL_ALARM"})
        except Exception as exc:
            logger.debug("Could not send CANCEL_ALARM to ESP32 (%s): %s", ip, exc)

    async def _notify_esp32_ai_feedback(self, ip: str, outcome: str) -> None:
        url = f"http://{ip}/api/ai/feedback"
        try:
            if self._http_client is not None:
                await self._http_client.post(url, json={"outcome": outcome}, timeout=3.0)
            else:
                async with httpx.AsyncClient(timeout=3.0) as client:
                    await client.post(url, json={"outcome": outcome})
        except Exception as exc:
            logger.debug("Could not send AI feedback to ESP32 (%s): %s", ip, exc)

    async def shutdown(self) -> None:
        for alert_id in list(self._escalation_tasks.keys()):
            self._cancel_escalation(alert_id)
