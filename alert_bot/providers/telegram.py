from __future__ import annotations

import html
from typing import Any

import httpx

from ..config import BotConfig
from ..models import BotSettings, DeliveryResult, FallAlertRequest, Recipient


def format_event_title(event_type: str, simulated: bool = False) -> str:
    prefix = "[TEST] " if (simulated or event_type == "test") else ""
    mapping = {
        "fall_impact": "PHÁT HIỆN TÉ NGÃ VA CHẠM MẠNH",
        "slow_fall": "PHÁT HIỆN NGÃ CHẬM / BẤT ĐỘNG TRÊN SÀN",
        "manual_sos": "KÍCH HOẠT NÚT CẤP CỨU SOS KHẨN CẤP",
        "test": "KIỂM TRA HỆ THỐNG CẢNH BÁO NGÃ",
    }
    return f"{prefix}{mapping.get(event_type, 'CẢNH BÁO TÉ NGÃ KHẨN CẤP')}"


def build_telegram_html(
    alert_id: str,
    req: FallAlertRequest,
    settings: BotSettings,
) -> str:
    title = html.escape(format_event_title(req.event_type, req.simulated))
    person = html.escape(req.person_name or settings.person_name or "Người cần chăm sóc")
    room = html.escape(req.room_name or "Phòng đang giám sát")

    lines = [
        f"🚨 <b>{title}</b>",
        f"👤 Người được giám sát: <b>{person}</b>",
        f"📍 Vị trí: <b>{room}</b>",
    ]
    if req.velocity_mm_s > 0 or req.motion_peak > 0 or req.target_dist_cm > 0:
        lines.append("──────────────────")
        if req.velocity_mm_s > 0:
            lines.append(f"• Tốc độ rơi ToF: <b>{req.velocity_mm_s:.0f} mm/s</b>")
        if req.motion_peak > 0:
            lines.append(f"• Động năng Radar: <b>{req.motion_peak}/100</b>")
        if req.target_dist_cm > 0:
            lines.append(f"• Cự ly Radar: <b>{req.target_dist_cm} cm</b>")
        if req.tof_height_mm > 0:
            lines.append(f"• Chiều cao đo được: <b>{req.tof_height_mm} mm</b>")

    if settings.home_address:
        lines.append(f"🏠 Địa chỉ: <code>{html.escape(settings.home_address)}</code>")
    if settings.door_code:
        lines.append(f"🔑 Mã cửa / Hộp khóa: <code>{html.escape(settings.door_code)}</code>")
    if req.note:
        lines.append(f"📝 Ghi chú: <i>{html.escape(req.note)}</i>")

    lines.append("")
    lines.append(f"🆔 Mã sự cố: <code>{html.escape(alert_id)}</code>")
    lines.append(
        f"⚠️ <b>Vui lòng kiểm tra ngay hoặc gọi cấp cứu {html.escape(settings.emergency_number)}!</b>"
    )
    return "\n".join(lines)


def build_alert_keyboard(alert_id: str, emergency_number: str = "115") -> dict[str, Any]:
    return {
        "inline_keyboard": [
            [
                {
                    "text": "✅ Tôi đang tới / Đã xác nhận",
                    "callback_data": f"ack:{alert_id}",
                }
            ],
            [
                {
                    "text": "🟢 An toàn / Báo động giả",
                    "callback_data": f"resolve_ok:{alert_id}",
                },
                {
                    "text": f"🚑 Đã gọi {emergency_number}",
                    "callback_data": f"resolve_help:{alert_id}",
                },
            ],
        ]
    }


class TelegramProvider:
    def __init__(self, config: BotConfig, client: httpx.AsyncClient | None = None) -> None:
        self._config = config
        self._client = client

    @property
    def configured(self) -> bool:
        return self._config.has_telegram

    def _url(self, method: str) -> str:
        return f"https://api.telegram.org/bot{self._config.telegram_bot_token}/{method}"

    async def _post(self, method: str, payload: dict[str, Any], timeout: float = 10.0) -> dict[str, Any]:
        if self._client is not None:
            resp = await self._client.post(self._url(method), json=payload, timeout=timeout)
            return resp.json()
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(self._url(method), json=payload)
            return resp.json()

    async def get_me(self) -> dict[str, Any]:
        if not self.configured:
            return {"ok": False, "description": "TELEGRAM_BOT_TOKEN not configured"}
        try:
            return await self._post("getMe", {}, timeout=8.0)
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def set_webhook(self, url: str, secret_token: str = "") -> dict[str, Any]:
        if not self.configured:
            return {"ok": False, "description": "TELEGRAM_BOT_TOKEN not configured"}
        payload: dict[str, Any] = {
            "url": url,
            "allowed_updates": ["message", "callback_query"],
        }
        if secret_token:
            payload["secret_token"] = secret_token
        try:
            return await self._post("setWebhook", payload, timeout=10.0)
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def delete_webhook(self) -> dict[str, Any]:
        if not self.configured:
            return {"ok": False}
        try:
            return await self._post("deleteWebhook", {}, timeout=8.0)
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def get_updates(self, offset: int | None = None, timeout: int = 25) -> list[dict[str, Any]]:
        if not self.configured:
            return []
        payload: dict[str, Any] = {
            "timeout": timeout,
            "allowed_updates": ["message", "callback_query"],
        }
        if offset is not None:
            payload["offset"] = offset
        data = await self._post("getUpdates", payload, timeout=float(timeout + 8))
        if data.get("ok") and isinstance(data.get("result"), list):
            return data["result"]
        return []

    async def send_text(
        self,
        chat_id: str,
        text: str,
        reply_markup: dict[str, Any] | None = None,
        parse_mode: str = "HTML",
    ) -> dict[str, Any]:
        if not self.configured:
            return {"ok": False, "description": "TELEGRAM_BOT_TOKEN not configured"}
        payload: dict[str, Any] = {
            "chat_id": str(chat_id).strip(),
            "text": text,
            "parse_mode": parse_mode,
        }
        if reply_markup is not None:
            payload["reply_markup"] = reply_markup
        try:
            return await self._post("sendMessage", payload, timeout=10.0)
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def answer_callback(self, callback_query_id: str, text: str = "") -> dict[str, Any]:
        if not self.configured:
            return {"ok": False}
        try:
            return await self._post(
                "answerCallbackQuery",
                {"callback_query_id": callback_query_id, "text": text, "show_alert": False},
                timeout=8.0,
            )
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def edit_message_reply_markup(
        self, chat_id: str, message_id: int, reply_markup: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        if not self.configured:
            return {"ok": False}
        payload: dict[str, Any] = {
            "chat_id": str(chat_id),
            "message_id": message_id,
            "reply_markup": reply_markup or {"inline_keyboard": []},
        }
        try:
            return await self._post("editMessageReplyMarkup", payload, timeout=8.0)
        except Exception as exc:
            return {"ok": False, "description": str(exc)}

    async def send_fall_alert(
        self,
        alert_id: str,
        recipient: Recipient,
        req: FallAlertRequest,
        settings: BotSettings,
    ) -> DeliveryResult:
        target = recipient.telegram_chat_id.strip()
        if not self.configured:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="telegram",
                provider="telegram_bot",
                target=target,
                ok=False,
                detail="TELEGRAM_BOT_TOKEN chưa được cấu hình",
            )
        if not target:
            return DeliveryResult(
                recipient_id=recipient.id,
                recipient_name=recipient.name,
                channel="telegram",
                provider="telegram_bot",
                target="",
                ok=False,
                detail="Người nhận chưa có Telegram Chat ID",
            )

        text = build_telegram_html(alert_id, req, settings)
        kb = build_alert_keyboard(alert_id, settings.emergency_number)
        data = await self.send_text(chat_id=target, text=text, reply_markup=kb)
        ok = bool(data.get("ok"))
        msg_id = data.get("result", {}).get("message_id") if ok else None
        return DeliveryResult(
            recipient_id=recipient.id,
            recipient_name=recipient.name,
            channel="telegram",
            provider="telegram_bot",
            target=target,
            ok=ok,
            detail="OK" if ok else str(data.get("description", "Telegram send failed")),
            message_id=msg_id,
        )
