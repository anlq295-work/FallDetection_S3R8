from __future__ import annotations

import asyncio
import html
import logging
from typing import Any

from .dispatcher import AlertDispatcher
from .models import FallAlertRequest
from .providers.telegram import TelegramProvider
from .storage import SettingsStore

logger = logging.getLogger("alert_bot.telegram_poller")


class TelegramBotPoller:
    """Interactive Telegram Bot listener (/start, /register, /settings, /contacts, /test, buttons)."""

    def __init__(
        self,
        telegram: TelegramProvider,
        store: SettingsStore,
        dispatcher: AlertDispatcher,
    ) -> None:
        self.telegram = telegram
        self.store = store
        self.dispatcher = dispatcher
        self._task: asyncio.Task[Any] | None = None
        self._offset: int | None = None
        self._running = False

    def start(self) -> None:
        if not self.telegram.configured:
            logger.info("Telegram polling skipped: TELEGRAM_BOT_TOKEN not set.")
            return
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._poll_loop())
        logger.info("Telegram bot long-polling started.")

    async def stop(self) -> None:
        self._running = False
        if self._task and not self._task.done():
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        self._task = None

    async def _poll_loop(self) -> None:
        while self._running:
            try:
                updates = await self.telegram.get_updates(offset=self._offset, timeout=20)
                for upd in updates:
                    upd_id = upd.get("update_id")
                    if isinstance(upd_id, int):
                        self._offset = upd_id + 1
                    await self.handle_update(upd)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.warning("Telegram poll error: %s", exc)
                await asyncio.sleep(3.0)

    async def handle_update(self, update: dict[str, Any]) -> None:
        if "callback_query" in update:
            await self._handle_callback(update["callback_query"])
        elif "message" in update:
            await self._handle_message(update["message"])

    async def _handle_message(self, msg: dict[str, Any]) -> None:
        text = (msg.get("text") or "").strip()
        if not text:
            return
        chat = msg.get("chat") or {}
        chat_id = str(chat.get("id", "")).strip()
        if not chat_id:
            return

        sender = msg.get("from") or {}
        full_name = " ".join(
            part for part in [sender.get("first_name", ""), sender.get("last_name", "")] if part
        ).strip() or chat.get("title") or f"User {chat_id}"
        username = (sender.get("username") or "").strip()

        parts = text.split()
        cmd = parts[0].split("@")[0].lower()
        args = parts[1:]

        if cmd == "/start":
            u_hint = f"@{html.escape(username)}" if username else "<i>(chưa đặt @username)</i>"
            welcome = (
                "🛡️ <b>Bot Cảnh Báo Té Ngã Hearth (FallDetection_S3R8)</b>\n\n"
                f"• Chat ID của bạn: <code>{html.escape(chat_id)}</code>\n"
                f"• Username Telegram: {u_hint}\n\n"
                "Bấm nút bên dưới để đăng ký nhận thông báo khi cảm biến phát hiện té ngã, "
                "hoặc gõ:\n"
                "<code>/register Tên Của Bạn 0912345678</code>\n\n"
                "Gõ /help để xem tất cả lệnh cấu hình."
            )
            kb = {
                "inline_keyboard": [
                    [{"text": "🔔 Đăng ký nhận cảnh báo ngã", "callback_data": "reg:self"}],
                    [
                        {"text": "💬 Test Telegram", "callback_data": "test:telegram"},
                        {"text": "📞 Test Gọi", "callback_data": "test:call"},
                    ],
                    [{"text": "⚙️ Cài đặt kênh (Telegram / Call)", "callback_data": "cfg:open"}],
                ]
            }
            await self.telegram.send_text(chat_id, welcome, reply_markup=kb)

        elif cmd == "/help":
            help_text = (
                "📖 <b>Danh sách lệnh Bot Cảnh Báo Té Ngã</b>\n\n"
                "• <code>/start</code> — Xem Chat ID & đăng ký nhanh\n"
                "• <code>/register [Tên] [SĐT]</code> — Đăng ký / cập nhật tên & SĐT nhận cuộc gọi\n"
                "• <code>/unregister</code> — Hủy nhận cảnh báo cho tài khoản này\n"
                "• <code>/settings</code> — Bật/tắt kênh Telegram, Call & chế độ gửi\n"
                "• <code>/contacts</code> — Xem danh sách người đang được cài đặt nhận cảnh báo\n"
                "• <code>/setname Tên Người Thân</code> — Đặt tên người được giám sát\n"
                "• <code>/test</code> — Gửi thử toàn bộ kênh (Telegram + Call)\n"
                "• <code>/test_tg</code> · <code>/test_call</code> — Test riêng từng kênh\n"
                "• <code>/status</code> — Kiểm tra trạng thái hệ thống & sự cố đang mở"
            )
            await self.telegram.send_text(chat_id, help_text)

        elif cmd == "/register":
            phone = ""
            name_parts: list[str] = []
            for tok in args:
                digits = "".join(ch for ch in tok if ch.isdigit())
                if len(digits) >= 9 and not phone:
                    phone = tok
                else:
                    name_parts.append(tok)
            reg_name = " ".join(name_parts).strip() or full_name
            rec = self.store.register_telegram_user(
                chat_id=chat_id,
                name=reg_name,
                username=username,
                phone=phone,
            )
            call_note = (
                f"• Gọi Telegram miễn phí (CallMeBot): <code>{html.escape(rec.telegram_username)}</code>\n"
                if rec.telegram_username
                else "• Gọi Telegram miễn phí: <i>Hãy đặt @username Telegram để dùng CallMeBot</i>\n"
            )
            await self.telegram.send_text(
                chat_id,
                f"✅ <b>Đã đăng ký nhận cảnh báo té ngã!</b>\n"
                f"• Tên: <b>{html.escape(rec.name)}</b>\n"
                f"• Chat ID: <code>{html.escape(rec.telegram_chat_id)}</code>\n"
                f"• SĐT (Gọi điện): <code>{html.escape(rec.phone or 'Chưa nhập')}</code>\n"
                f"{call_note}",
            )

        elif cmd == "/unregister":
            removed = self.store.remove_recipient(chat_id)
            if removed:
                await self.telegram.send_text(chat_id, "🔕 Đã hủy đăng ký nhận cảnh báo cho bạn.")
            else:
                await self.telegram.send_text(chat_id, "Bạn hiện chưa có trong danh sách nhận cảnh báo.")

        elif cmd == "/contacts":
            settings = self.store.get_settings()
            if not settings.recipients:
                await self.telegram.send_text(
                    chat_id,
                    "📋 Chưa có ai trong danh sách nhận cảnh báo.\n"
                    "Dùng <code>/register Tên SĐT</code> hoặc thêm từ ứng dụng Hearth!",
                )
                return
            lines = ["📋 <b>Danh sách người nhận cảnh báo đã cài đặt:</b>\n"]
            for idx, r in enumerate(settings.recipients, start=1):
                state = "🟢" if r.enabled else "⚪"
                chs = []
                if r.notify_telegram and r.telegram_chat_id:
                    chs.append("TG")
                if r.notify_call and (r.telegram_username or r.phone):
                    chs.append("Call")
                ch_str = " · ".join(chs) if chs else "Chưa đủ thông tin kênh"
                lines.append(
                    f"{idx}. {state} <b>{html.escape(r.name)}</b> ({ch_str})\n"
                    f"   └ SĐT: <code>{html.escape(r.phone or '-')}</code> | "
                    f"TG: <code>{html.escape(r.telegram_chat_id or '-')}</code> | "
                    f"CallMeBot: <code>{html.escape(r.telegram_username or '-')}</code>"
                )
            await self.telegram.send_text(chat_id, "\n".join(lines))

        elif cmd == "/settings":
            await self._send_settings_panel(chat_id)

        elif cmd == "/setname":
            new_name = " ".join(args).strip()
            if not new_name:
                await self.telegram.send_text(chat_id, "Cú pháp: <code>/setname Bà Nội</code>")
                return
            settings = self.store.get_settings()
            settings.person_name = new_name
            self.store.update_settings(settings)
            await self.telegram.send_text(
                chat_id, f"✅ Đã cập nhật tên người được giám sát: <b>{html.escape(new_name)}</b>"
            )

        elif cmd in ("/test", "/test_tg", "/test_call"):
            ch_map = {
                "/test_tg": ["telegram"],
                "/test_call": ["call"],
            }
            await self._run_channel_test(chat_id, full_name, ch_map.get(cmd))

        elif cmd == "/status":
            settings = self.store.get_settings()
            active = self.store.get_latest_active_alert()
            providers = self.dispatcher.config.active_providers()
            prov_lines = "\n".join(
                f"• {k}: {'✅' if v else '⚪'}" for k, v in providers.items()
            )
            active_str = (
                f"🚨 Đang có cảnh báo chưa xác nhận: <code>{html.escape(active.alert_id)}</code> ({html.escape(active.room_name)})"
                if active
                else "🟢 Hiện không có cảnh báo khẩn cấp đang mở."
            )
            await self.telegram.send_text(
                chat_id,
                f"📊 <b>Trạng thái Hearth Alert Bot</b>\n\n"
                f"{active_str}\n"
                f"• Người nhận đang bật: <b>{len(self.store.enabled_recipients())}</b>\n"
                f"• Chế độ gửi: <b>{settings.dispatch_mode}</b>\n\n"
                f"<b>Nhà cung cấp đã kích hoạt:</b>\n{prov_lines}",
            )

    async def _send_settings_panel(self, chat_id: str) -> None:
        s = self.store.get_settings()
        mode_label = "📢 Đồng thời (tất cả cùng lúc)" if s.dispatch_mode == "simultaneous" else f"🔢 Tuần tự (mỗi {s.escalation_minutes} phút)"
        text = (
            "⚙️ <b>Cài đặt kênh thông báo té ngã</b>\n\n"
            f"• Chế độ gửi: <b>{mode_label}</b>\n"
            f"• Telegram: {'✅ Bật' if s.channels.telegram else '❌ Tắt'}\n"
            f"• Gọi điện (Call): {'✅ Bật' if s.channels.call else '❌ Tắt'}\n"
            f"• Số người nhận đang bật: <b>{len(self.store.enabled_recipients())}</b>"
        )
        kb = {
            "inline_keyboard": [
                [
                    {"text": f"Telegram: {'BẬT' if s.channels.telegram else 'TẮT'}", "callback_data": "cfg:toggle_tg"},
                    {"text": f"Call: {'BẬT' if s.channels.call else 'TẮT'}", "callback_data": "cfg:toggle_call"},
                ],
                [
                    {"text": f"Đổi chế độ ({s.dispatch_mode})", "callback_data": "cfg:toggle_mode"},
                ],
                [
                    {"text": "💬 Test TG", "callback_data": "test:telegram"},
                    {"text": "📞 Test Call", "callback_data": "test:call"},
                    {"text": "🚨 Test All", "callback_data": "test:all"},
                ],
            ]
        }
        await self.telegram.send_text(chat_id, text, reply_markup=kb)

    async def _run_channel_test(
        self, chat_id: str, requester: str, channels: list[str] | None
    ) -> None:
        label = ", ".join(channels).upper() if channels else "TẤT CẢ KÊNH"
        rec, _ = await self.dispatcher.trigger_fall_alert(
            FallAlertRequest(
                event_type="test",
                room_name="Kiểm tra từ Telegram",
                simulated=True,
                note=f"Test {label} bởi {requester}",
                channels_override=channels,  # type: ignore[arg-type]
            )
        )
        ok_count = sum(1 for d in rec.deliveries if d.ok)
        total = len(rec.deliveries)
        detail_lines = [
            f"• {'✅' if d.ok else '❌'} {html.escape(d.recipient_name)} [{d.channel.upper()}/{d.provider}]: {html.escape(d.detail)}"
            for d in rec.deliveries
        ]
        details = "\n".join(detail_lines) if detail_lines else "<i>Chưa có người nhận phù hợp. Hãy gõ /register Tên SĐT trước.</i>"
        await self.telegram.send_text(
            chat_id,
            f"🧪 <b>Kết quả Test {html.escape(label)}</b>: <b>{ok_count}/{total}</b> thành công\n\n{details}",
        )

    async def _handle_callback(self, cb: dict[str, Any]) -> None:
        cb_id = str(cb.get("id", ""))
        data = str(cb.get("data", ""))
        sender = cb.get("from") or {}
        by_name = " ".join(
            part for part in [sender.get("first_name", ""), sender.get("last_name", "")] if part
        ).strip() or sender.get("username") or "Người chăm sóc"
        username = (sender.get("username") or "").strip()
        msg = cb.get("message") or {}
        chat_id = str((msg.get("chat") or {}).get("id", "")).strip()

        if data.startswith("ack:"):
            alert_id = data.removeprefix("ack:")
            rec = await self.dispatcher.acknowledge_alert(alert_id, by=by_name)
            await self.telegram.answer_callback(
                cb_id, "✅ Đã xác nhận! Đã báo cho mọi người." if rec else "Không tìm thấy cảnh báo."
            )
        elif data.startswith("resolve_ok:"):
            alert_id = data.removeprefix("resolve_ok:")
            rec = await self.dispatcher.resolve_alert(alert_id, by=by_name, outcome="person_ok")
            await self.telegram.answer_callback(
                cb_id, "🟢 Đã đóng cảnh báo (An toàn)." if rec else "Không tìm thấy cảnh báo."
            )
        elif data.startswith("resolve_help:"):
            alert_id = data.removeprefix("resolve_help:")
            rec = await self.dispatcher.resolve_alert(alert_id, by=by_name, outcome="needed_help")
            await self.telegram.answer_callback(
                cb_id, "🚑 Đã ghi nhận gọi cấp cứu." if rec else "Không tìm thấy cảnh báo."
            )
        elif data == "reg:self" and chat_id:
            rec = self.store.register_telegram_user(chat_id=chat_id, name=by_name, username=username)
            await self.telegram.answer_callback(cb_id, "✅ Đã đăng ký nhận cảnh báo!")
            await self.telegram.send_text(
                chat_id,
                f"✅ <b>{html.escape(rec.name)}</b> đã được thêm vào danh sách nhận cảnh báo!\n"
                "Để nhận thêm SMS/Gọi điện, gõ: <code>/register Tên 0912345678</code>",
            )
        elif data == "cfg:open" and chat_id:
            await self.telegram.answer_callback(cb_id, "")
            await self._send_settings_panel(chat_id)
        elif data.startswith("cfg:toggle_") and chat_id:
            s = self.store.get_settings()
            if data == "cfg:toggle_tg":
                s.channels.telegram = not s.channels.telegram
            elif data == "cfg:toggle_sms":
                s.channels.sms = not s.channels.sms
            elif data == "cfg:toggle_call":
                s.channels.call = not s.channels.call
            elif data == "cfg:toggle_mode":
                s.dispatch_mode = "sequential" if s.dispatch_mode == "simultaneous" else "simultaneous"
            self.store.update_settings(s)
            await self.telegram.answer_callback(cb_id, "Đã cập nhật cài đặt!")
            await self._send_settings_panel(chat_id)
        elif data.startswith("test:") and chat_id:
            kind = data.removeprefix("test:")
            ch = None if kind == "all" else [kind]
            await self.telegram.answer_callback(cb_id, f"Đang chạy test {kind.upper()}...")
            await self._run_channel_test(chat_id, by_name, ch)
        else:
            await self.telegram.answer_callback(cb_id, "")
