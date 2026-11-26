from __future__ import annotations

import base64
import hashlib
import hmac
import html
import json
import time
from urllib.parse import urlencode

import httpx

from ..config import BotConfig
from ..models import BotSettings, DeliveryResult, FallAlertRequest, Recipient
from ..storage import normalize_phone, normalize_telegram_username


def _b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def build_stringee_rest_jwt(api_key_sid: str, api_key_secret: str, ttl_sec: int = 3600) -> str:
    """Generates a Stringee REST API HS256 JWT token without external PyJWT dependency."""
    now = int(time.time())
    header = _b64url(
        json.dumps(
            {"typ": "JWT", "alg": "HS256", "cty": "stringee-api;v=1"},
            separators=(",", ":"),
        ).encode("utf-8")
    )
    payload = _b64url(
        json.dumps(
            {
                "jti": f"{api_key_sid}-{now}",
                "iss": api_key_sid,
                "exp": now + ttl_sec,
                "rest_api": True,
            },
            separators=(",", ":"),
        ).encode("utf-8")
    )
    signing_input = f"{header}.{payload}".encode("ascii")
    sig = _b64url(hmac.new(api_key_secret.encode("utf-8"), signing_input, hashlib.sha256).digest())
    return f"{header}.{payload}.{sig}"


def build_voice_script(req: FallAlertRequest, settings: BotSettings) -> str:
    prefix = "Đây là cuộc gọi kiểm tra hệ thống. " if (req.simulated or req.event_type == "test") else ""
    person = req.person_name or settings.person_name or "người thân của bạn"
    room = req.room_name or "trong nhà"
    action = {
        "fall_impact": "có thể vừa bị té ngã",
        "slow_fall": "đang nằm bất động lâu trên sàn",
        "manual_sos": "vừa nhấn nút cấp cứu khẩn cấp",
        "test": "đang kiểm tra cảnh báo ngã",
    }.get(req.event_type, "có dấu hiệu bị té ngã")

    return (
        f"{prefix}Cảnh báo khẩn cấp từ hệ thống Hearth! "
        f"{person} {action} tại {room}. "
        f"Vui lòng kiểm tra ngay lập tức hoặc mở Telegram để xác nhận."
    )


class CallProvider:
    """Dispatches voice calls via CallMeBot (free Telegram voice call), Stringee Voice (VN direct TTS), or Twilio Voice."""

    def __init__(self, config: BotConfig, client: httpx.AsyncClient | None = None) -> None:
        self._config = config
        self._client = client

    async def place_fall_calls(
        self,
        recipient: Recipient,
        req: FallAlertRequest,
        settings: BotSettings,
    ) -> list[DeliveryResult]:
        results: list[DeliveryResult] = []
        spoken_text = build_voice_script(req, settings)

        # 1. Free Telegram Voice Call via CallMeBot (if recipient has @telegram_username)
        tg_user = normalize_telegram_username(recipient.telegram_username)
        if self._config.callmebot_enabled and tg_user:
            results.append(await self._call_callmebot(recipient, tg_user, spoken_text))

        # 2. Real Cellular Phone Call: Priority #1 Stringee (direct VN TTS, no English trial prompt),
        #    falling back to Twilio Programmable Voice if Stringee is unconfigured or fails.
        e164 = normalize_phone(recipient.phone, self._config.default_country_code)
        if e164:
            stringee_ok = False
            if self._config.has_stringee:
                str_res = await self._call_stringee_voice(recipient, e164, spoken_text)
                results.append(str_res)
                stringee_ok = str_res.ok

            if not stringee_ok and self._config.has_twilio:
                results.append(await self._call_twilio_voice(recipient, e164, spoken_text))

        if not results:
            reason = (
                "Cần điền @username Telegram (CallMeBot miễn phí) hoặc cấu hình Stringee/Twilio Voice + SĐT"
            )
            results.append(
                DeliveryResult(
                    recipient_id=recipient.id,
                    recipient_name=recipient.name,
                    channel="call",
                    provider="unconfigured",
                    target=tg_user or e164 or "",
                    ok=False,
                    detail=reason,
                )
            )
        return results

    async def _call_callmebot(
        self, recipient: Recipient, telegram_user: str, spoken_text: str
    ) -> DeliveryResult:
        # CallMeBot free Telegram phone call API:
        # User must activate once at https://api2.callmebot.com/txt/login.php (authorize @CallMeBot_txtbot)
        params = urlencode(
            {
                "user": telegram_user,
                "text": spoken_text,
                "lang": self._config.callmebot_lang,
                "rpt": str(self._config.callmebot_repeat),
            }
        )
        url = f"http://api.callmebot.com/start.php?{params}"
        try:
            if self._client is not None:
                resp = await self._client.get(url, timeout=15.0)
            else:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.get(url)
            body_lower = resp.text.lower()
            ok = resp.status_code == 200 and ("error" not in body_lower or "call" in body_lower)
            detail = "OK (CallMeBot Telegram ringing)" if ok else f"HTTP {resp.status_code}: {resp.text[:160]}"
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="callmebot_telegram",
                target=telegram_user,
                ok=ok,
                detail=detail,
            )
        except Exception as exc:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="callmebot_telegram",
                target=telegram_user,
                ok=False,
                detail=str(exc),
            )

    async def _call_stringee_voice(
        self, recipient: Recipient, e164: str, spoken_text: str
    ) -> DeliveryResult:
        url = "https://api.stringee.com/v1/call2/callout"
        from_num = normalize_phone(
            self._config.stringee_from_number, self._config.default_country_code
        ).lstrip("+") or self._config.stringee_from_number.lstrip("+")
        to_num = e164.lstrip("+")

        token = build_stringee_rest_jwt(
            self._config.stringee_api_key_sid,
            self._config.stringee_api_key_secret,
        )
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-STRINGEE-AUTH": token,
            "User-Agent": "HearthAlertBot/1.0",
        }
        payload = {
            "from": {
                "type": "external",
                "number": from_num,
                "alias": from_num,
            },
            "to": [
                {
                    "type": "external",
                    "number": to_num,
                    "alias": to_num,
                }
            ],
            "actions": [
                {
                    "action": "talk",
                    "text": spoken_text,
                    "voice": self._config.stringee_voice or "hn_female_thutrang_phrase_48k-hsmm",
                    "speed": self._config.stringee_speed,
                    "bargeIn": False,
                    "loop": max(1, self._config.stringee_repeat),
                }
            ],
        }
        try:
            if self._client is not None:
                resp = await self._client.post(url, json=payload, headers=headers, timeout=15.0)
            else:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.post(url, json=payload, headers=headers)

            data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
            r_code = data.get("r") if isinstance(data, dict) else None
            # Stringee Callout success codes: 0 (SUCCESS) or 13 (WAIT_TEXT_TO_SPEECH — generating TTS then ringing)
            ok = resp.status_code in (200, 201) and r_code in (0, 13)
            if ok:
                call_id = data.get("call_id", "")
                detail = f"OK (Stringee VN voice ringing: {call_id})"
            else:
                msg = data.get("message") if isinstance(data, dict) else resp.text[:160]
                detail = f"Stringee r={r_code} HTTP {resp.status_code}: {msg}"

            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="stringee_voice",
                target=e164,
                ok=ok,
                detail=detail,
            )
        except Exception as exc:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="stringee_voice",
                target=e164,
                ok=False,
                detail=str(exc),
            )

    async def _call_twilio_voice(
        self, recipient: Recipient, e164: str, spoken_text: str
    ) -> DeliveryResult:
        url = (
            f"https://api.twilio.com/2010-04-01/Accounts/"
            f"{self._config.twilio_account_sid}/Calls.json"
        )
        safe_text = html.escape(spoken_text)
        voice_attr = (
            f' voice="{html.escape(self._config.twilio_voice_name)}"'
            if self._config.twilio_voice_name
            else ""
        )
        twiml = (
            f'<?xml version="1.0" encoding="UTF-8"?>'
            f'<Response><Say language="{html.escape(self._config.twilio_voice_lang)}"{voice_attr} loop="3">'
            f"{safe_text}</Say></Response>"
        )
        form = {
            "To": e164,
            "From": self._config.twilio_from_number,
            "Twiml": twiml,
        }
        try:
            if self._client is not None:
                resp = await self._client.post(
                    url,
                    data=form,
                    auth=(self._config.twilio_account_sid, self._config.twilio_auth_token),
                    timeout=12.0,
                )
            else:
                async with httpx.AsyncClient(timeout=12.0) as client:
                    resp = await client.post(
                        url,
                        data=form,
                        auth=(self._config.twilio_account_sid, self._config.twilio_auth_token),
                    )
            ok = resp.status_code in (200, 201)
            detail = "OK (Twilio phone ringing)" if ok else f"HTTP {resp.status_code}: {resp.text[:160]}"
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="twilio_voice",
                target=e164,
                ok=ok,
                detail=detail,
            )
        except Exception as exc:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="call",
                provider="twilio_voice",
                target=e164,
                ok=False,
                detail=str(exc),
            )
