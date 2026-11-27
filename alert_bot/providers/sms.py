from __future__ import annotations

import unicodedata

import httpx

from ..config import BotConfig
from ..models import BotSettings, DeliveryResult, FallAlertRequest, Recipient
from ..storage import normalize_phone


def _to_ascii_sms(text: str) -> str:
    """Strips Vietnamese diacritics so SMS stays GSM-7 1-segment and passes SpeedSMS encoding checks."""
    text = text.replace("đ", "d").replace("Đ", "D")
    nfkd = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in nfkd if not unicodedata.combining(ch) and ord(ch) < 128)


def build_sms_text(req: FallAlertRequest, settings: BotSettings) -> str:
    prefix = "[TEST] " if (req.simulated or req.event_type == "test") else ""
    person = _to_ascii_sms(req.person_name or settings.person_name or "Nguoi than")
    room = _to_ascii_sms(req.room_name or "Phong giam sat")
    event_desc = {
        "fall_impact": "co the da bi TE NGA",
        "slow_fall": "nam bat dong lau tren san",
        "manual_sos": "da bam nut cap cuu SOS",
        "test": "kiem tra he thong canh bao nga",
    }.get(req.event_type, "canh bao te nga")

    extras: list[str] = []
    if req.location:
        latitude = req.location.get("latitude")
        longitude = req.location.get("longitude")
        if latitude is not None and longitude is not None:
            extras.append(f"GPS: https://maps.google.com/?q={latitude:.6f},{longitude:.6f}")
    if settings.home_address:
        extras.append(_to_ascii_sms(settings.home_address))
    if settings.door_code:
        extras.append(f"Ma cua: {_to_ascii_sms(settings.door_code)}")
    extra_str = f" ({' | '.join(extras)})" if extras else ""

    return (
        f"{prefix}KHAN CAP HEARTH: {person} {event_desc} tai {room}.{extra_str} "
        f"Vui long kiem tra hoac goi ngay!"
    )


class SmsProvider:
    """Dispatches SMS via SpeedSMS (Vietnam) and/or Twilio SMS."""

    def __init__(self, config: BotConfig, client: httpx.AsyncClient | None = None) -> None:
        self._config = config
        self._client = client

    @property
    def configured(self) -> bool:
        return self._config.has_speedsms or self._config.has_twilio

    async def send_fall_sms(
        self,
        recipient: Recipient,
        req: FallAlertRequest,
        settings: BotSettings,
    ) -> DeliveryResult:
        raw_phone = recipient.phone.strip()
        e164 = normalize_phone(raw_phone, self._config.default_country_code)
        if not e164:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="none",
                target=raw_phone,
                ok=False,
                detail="Số điện thoại không hợp lệ hoặc bị trống",
            )

        body = build_sms_text(req, settings)

        # Use SpeedSMS for Vietnam (+84) when configured; preserve SpeedSMS error if Twilio also fails
        speed_res: DeliveryResult | None = None
        if self._config.has_speedsms and (e164.startswith("+84") or not self._config.has_twilio):
            speed_res = await self._send_speedsms(recipient, raw_phone, e164, body)
            if speed_res.ok or not self._config.has_twilio:
                return speed_res

        if self._config.has_twilio:
            tw_res = await self._send_twilio_sms(recipient, e164, body)
            if tw_res.ok or speed_res is None:
                return tw_res
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="speedsms+twilio_sms",
                target=e164,
                ok=False,
                detail=f"SpeedSMS: {speed_res.detail} | Twilio: {tw_res.detail}",
            )

        return DeliveryResult(
            recipient_id=recipient.id,
            recipient_name=recipient.name,
            channel="sms",
            provider="unconfigured",
            target=e164,
            ok=False,
            detail="Chưa cấu hình SpeedSMS hoặc Twilio SMS trong .env",
        )

    async def _send_speedsms(
        self, recipient: Recipient, raw_phone: str, e164: str, content: str
    ) -> DeliveryResult:
        # SpeedSMS expects Vietnamese local format (09xxxxxxxx)
        vn_phone = ("0" + e164[3:]) if e164.startswith("+84") else raw_phone
        payload: dict[str, object] = {
            "to": [vn_phone],
            "content": content,
            "sms_type": self._config.speedsms_type,
            "sender": self._config.speedsms_sender,
        }

        try:
            if self._client is not None:
                resp = await self._client.post(
                    self._config.speedsms_url,
                    json=payload,
                    auth=(self._config.speedsms_access_token, "x"),
                    timeout=10.0,
                )
            else:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.post(
                        self._config.speedsms_url,
                        json=payload,
                        auth=(self._config.speedsms_access_token, "x"),
                    )

            data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
            ok = resp.status_code == 200 and (data.get("status") in (None, "success"))
            detail = "OK" if ok else f"HTTP {resp.status_code}: {data.get('message', resp.text[:160])}"
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="speedsms",
                target=vn_phone,
                ok=ok,
                detail=detail,
            )
        except Exception as exc:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="speedsms",
                target=vn_phone,
                ok=False,
                detail=str(exc),
            )

    async def _send_twilio_sms(self, recipient: Recipient, e164: str, content: str) -> DeliveryResult:
        url = (
            f"https://api.twilio.com/2010-04-01/Accounts/"
            f"{self._config.twilio_account_sid}/Messages.json"
        )
        form = {
            "To": e164,
            "From": self._config.twilio_from_number,
            "Body": content,
        }
        try:
            if self._client is not None:
                resp = await self._client.post(
                    url,
                    data=form,
                    auth=(self._config.twilio_account_sid, self._config.twilio_auth_token),
                    timeout=10.0,
                )
            else:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.post(
                        url,
                        data=form,
                        auth=(self._config.twilio_account_sid, self._config.twilio_auth_token),
                    )
            ok = resp.status_code in (200, 201)
            detail = "OK" if ok else f"HTTP {resp.status_code}: {resp.text[:160]}"
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="twilio_sms",
                target=e164,
                ok=ok,
                detail=detail,
            )
        except Exception as exc:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="sms",
                provider="twilio_sms",
                target=e164,
                ok=False,
                detail=str(exc),
            )
