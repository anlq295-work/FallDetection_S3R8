from __future__ import annotations

import csv
import io
import logging
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse, PlainTextResponse

from .config import BotConfig
from .dispatcher import AlertDispatcher
from .models import (
    AcknowledgeRequest,
    AiTrainingSample,
    BotSettings,
    FallAlertRequest,
    OtpSendRequest,
    OtpVerifyRequest,
    Recipient,
    ResolveRequest,
)
from .providers.email_otp import EmailOtpService
from .storage import SettingsStore
from .telegram_poller import TelegramBotPoller

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("alert_bot.server")


def create_app(
    config: BotConfig | None = None,
    store: SettingsStore | None = None,
    dispatcher: AlertDispatcher | None = None,
    otp_service: EmailOtpService | None = None,
    enable_poller: bool | None = None,
) -> FastAPI:
    cfg = config or BotConfig.from_env()
    st = store or SettingsStore(cfg.data_file)
    st.seed_defaults_if_empty(
        chat_ids=cfg.telegram_default_chat_ids,
        callmebot_users=cfg.callmebot_default_users,
        esp32_lan_ip=cfg.esp32_lan_ip,
    )
    disp = dispatcher or AlertDispatcher(cfg, st)
    otp = otp_service or EmailOtpService(cfg, client=disp._http_client)
    poller = TelegramBotPoller(disp.telegram, st, disp)
    should_poll = cfg.telegram_polling_enabled if enable_poller is None else enable_poller

    @asynccontextmanager
    async def lifespan(_app: FastAPI):
        if cfg.has_telegram and cfg.telegram_webhook_base_url:
            wh_url = f"{cfg.telegram_webhook_base_url}/api/telegram/webhook"
            res = await disp.telegram.set_webhook(wh_url, secret_token=cfg.telegram_webhook_secret)
            if res.get("ok"):
                logger.info("Telegram webhook mode configured (%s): ok=True", wh_url)
            else:
                logger.error("Telegram setWebhook failed (%s): %s", wh_url, res)
        elif should_poll:
            if cfg.has_telegram:
                await disp.telegram.delete_webhook()
            poller.start()
        yield
        await poller.stop()
        await disp.shutdown()

    app = FastAPI(
        title="FallDetection_S3R8 Multi-Channel Alert Bot",
        version="1.0.0",
        description="Telegram Bot + Voice Call (Twilio/CallMeBot) + Email OTP (Twilio Verify/SendGrid) service for Hearth / ESP32-S3",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    def verify_api_key(
        x_api_key: str | None = Header(default=None, alias="X-API-Key"),
        authorization: str | None = Header(default=None),
    ) -> None:
        if not cfg.api_key:
            return
        token = x_api_key or ""
        if not token and authorization and authorization.lower().startswith("bearer "):
            token = authorization[7:].strip()
        if token != cfg.api_key:
            raise HTTPException(status_code=401, detail="Invalid or missing API key")

    static_dir = Path(__file__).resolve().parent / "static"

    @app.get("/favicon.ico", include_in_schema=False)
    async def favicon_ico():
        ico = static_dir / "favicon.ico"
        if ico.exists():
            return FileResponse(ico, media_type="image/x-icon")
        raise HTTPException(status_code=404, detail="Not found")

    @app.get("/app-icon.png", include_in_schema=False)
    async def app_icon_png():
        png = static_dir / "app-icon-192.png"
        if png.exists():
            return FileResponse(png, media_type="image/png")
        raise HTTPException(status_code=404, detail="Not found")

    @app.get("/", response_class=HTMLResponse)
    async def index() -> str:
        settings = st.get_settings()
        ai_sum = st.ai_dataset_summary()
        providers = cfg.active_providers()
        prov_html = "".join(
            f"<li><code>{k}</code>: <b>{'ACTIVE' if v else 'not configured'}</b></li>"
            for k, v in providers.items()
        )
        return (
            "<!doctype html><html><head><meta charset='utf-8'>"
            "<link rel='icon' href='/favicon.ico' type='image/x-icon'>"
            "<title>Hearth Fall Alert Bot</title>"
            "<style>body{font-family:system-ui,sans-serif;max-width:760px;margin:32px auto;padding:0 16px;background:#0d1117;color:#e6edf3}"
            ".hdr{display:flex;align-items:center;gap:14px;margin-bottom:18px}"
            ".hdr img{width:52px;height:52px;border-radius:12px}"
            ".card{background:#161b22;border:1px solid #30363d;border-radius:12px;padding:18px;margin-bottom:16px}"
            ".row{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}"
            "button{background:#238636;color:#fff;border:none;padding:10px 14px;border-radius:8px;cursor:pointer;font-weight:700;font-size:14px}"
            "button.sec{background:#1f6feb}button.warn{background:#d29922;color:#0d1117}button.crit{background:#da3633}"
            "input{background:#0d1117;color:#e6edf3;border:1px solid #30363d;border-radius:8px;padding:9px 12px;font-size:14px}"
            "pre{background:#0d1117;border:1px solid #30363d;border-radius:8px;padding:12px;overflow:auto;font-size:12.5px;max-height:260px}"
            "code{background:#21262d;padding:2px 6px;border-radius:4px}a{color:#58a6ff}</style></head>"
            "<body><div class='hdr'><img src='/app-icon.png' alt='Hearth'><h1>Hearth Fall Alert Bot</h1></div>"
            "<div class='card'><h3>Trạng thái</h3>"
            f"<p>Chế độ gửi: <b>{settings.dispatch_mode}</b> · Người nhận đang bật: <b>{len(st.enabled_recipients())}</b></p>"
            f"<ul>{prov_html}</ul></div>"
            "<div class='card'><h3>🧪 Gửi thử nhanh (Test từng kênh)</h3>"
            "<p style='color:#8b949e;margin-top:0'>Tùy chọn nhập nhanh SĐT/Chat ID nếu chưa có trong danh bạ (hoặc để trống để gửi tới toàn bộ người đã cài đặt):</p>"
            "<div class='row'>"
            "<input id='tPhone' placeholder='SĐT (VD: 0912345678)' />"
            "<input id='tChat' placeholder='Telegram Chat ID' />"
            "<input id='tUser' placeholder='@username (CallMeBot)' />"
            "</div>"
            "<div class='row'>"
            "<button class='sec' onclick=\"runTest(['telegram'])\">💬 Test Telegram</button>"
            "<button class='warn' onclick=\"runTest(['call'])\">📞 Test Gọi điện</button>"
            "<button class='crit' onclick=\"runTest(['telegram','call'])\">🚨 Test Tất cả</button>"
            "</div>"
            "<h4 style='margin:16px 0 8px'>📧 Test Email OTP (Twilio Verify)</h4>"
            "<div class='row'>"
            "<input id='otpEmail' placeholder='Email nhận mã OTP' style='min-width:220px' />"
            "<button class='sec' onclick='sendOtp()'>Gửi mã OTP</button>"
            "<input id='otpCode' placeholder='Mã 6 số' style='width:110px' />"
            "<button onclick='verifyOtp()'>Xác thực OTP</button>"
            "</div>"
            "<pre id='out'>Nhấn nút bất kỳ để kiểm tra kết quả trả về...</pre></div>"
            "<div class='card'><h3>REST API</h3><ul>"
            "<li><a href='/docs'>Swagger UI (/docs)</a></li>"
            "<li><code>GET /health</code> — Kiểm tra trạng thái bot & nhà cung cấp</li>"
            "<li><code>GET / PUT /api/settings</code> — Đọc / đồng bộ danh sách người nhận & kênh gửi</li>"
            "<li><code>POST /api/alerts/fall</code> — Nhận sự kiện ngã từ ESP32-S3 hoặc Hearth App</li>"
            "<li><code>POST /api/alerts/test</code> — Gửi thử cảnh báo (hỗ trợ <code>channels_override</code>: telegram / call)</li>"
            "<li><code>POST /api/auth/otp/send</code> &amp; <code>/api/auth/otp/verify</code> — Gửi &amp; xác thực mã OTP Email đăng nhập App</li>"
            "<li><code>GET /api/ai/dataset</code> &amp; <a href='/api/ai/dataset.csv'><code>GET /api/ai/dataset.csv</code></a> — Tải bộ dữ liệu Edge AI (Human-in-the-Loop)</li>"
            "</ul></div>"
            "<div class='card'><h3>🧠 Dữ liệu tự học Edge AI (Human-in-the-Loop)</h3>"
            f"<p>Tổng mẫu đã thu: <b>{ai_sum['total']}</b> (FALL: <b>{ai_sum['FALL']}</b> | SIT: <b>{ai_sum['SIT']}</b> | "
            f"LIE: <b>{ai_sum['LIE']}</b> | STAND: <b>{ai_sum['STAND']}</b> | Báo động giả: <b>{ai_sum['false_alarms']}</b>)</p>"
            "<p><a href='/api/ai/dataset.csv'>⬇️ Tải dataset CSV</a> · "
            "Huấn luyện lại: <code>python scripts/train_edge_ai.py --pull-url &lt;URL_RENDER&gt;</code></p></div>"
            "<script>"
            "const out=document.getElementById('out');"
            "async function runTest(chs){out.textContent='Đang gửi test '+chs.join(', ')+'...';"
            "const p=document.getElementById('tPhone').value.trim();"
            "const c=document.getElementById('tChat').value.trim();"
            "const u=document.getElementById('tUser').value.trim();"
            "const hasManual=Boolean(p||c||u);"
            "const body={event_type:'test',room_name:'Web Test Dashboard',simulated:true,channels_override:chs,"
            "use_fallback_only:hasManual,"
            "fallback_phones:p?[p]:[],fallback_chat_ids:c?[c]:[],fallback_telegram_users:u?[u]:[]};"
            "const r=await fetch('/api/alerts/test',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});"
            "out.textContent=JSON.stringify(await r.json(),null,2);}"
            "async function sendOtp(){const e=document.getElementById('otpEmail').value.trim();"
            "out.textContent='Đang gửi OTP tới '+e+'...';"
            "const r=await fetch('/api/auth/otp/send',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:e,language:'vi'})});"
            "out.textContent=JSON.stringify(await r.json(),null,2);}"
            "async function verifyOtp(){const e=document.getElementById('otpEmail').value.trim();const code=document.getElementById('otpCode').value.trim();"
            "out.textContent='Đang xác thực OTP...';"
            "const r=await fetch('/api/auth/otp/verify',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:e,code:code})});"
            "out.textContent=JSON.stringify(await r.json(),null,2);}"
            "</script></body></html>"
        )

    @app.get("/health")
    async def health() -> dict[str, Any]:
        settings = st.get_settings()
        tg_mode = (
            "webhook"
            if (cfg.has_telegram and cfg.telegram_webhook_base_url)
            else ("polling" if (cfg.has_telegram and should_poll) else "disabled")
        )
        return {
            "status": "ok",
            "telegram_mode": tg_mode,
            "providers": cfg.active_providers(),
            "dispatch_mode": settings.dispatch_mode,
            "channels": settings.channels.model_dump(),
            "recipient_count": len(settings.recipients),
            "enabled_recipient_count": len(st.enabled_recipients()),
            "active_alert_id": (st.get_latest_active_alert().alert_id if st.get_latest_active_alert() else None),
            "ai_dataset": st.ai_dataset_summary(),
        }

    @app.get("/api/settings", dependencies=[Depends(verify_api_key)])
    async def get_settings() -> BotSettings:
        return st.get_settings()

    @app.put("/api/settings", dependencies=[Depends(verify_api_key)])
    async def put_settings(payload: BotSettings) -> BotSettings:
        return st.update_settings(payload)

    @app.post("/api/recipients", dependencies=[Depends(verify_api_key)])
    async def upsert_recipient(recipient: Recipient) -> Recipient:
        return st.upsert_recipient(recipient)

    @app.delete("/api/recipients/{recipient_id}", dependencies=[Depends(verify_api_key)])
    async def delete_recipient(recipient_id: str) -> dict[str, Any]:
        removed = st.remove_recipient(recipient_id)
        if not removed:
            raise HTTPException(status_code=404, detail="Recipient not found")
        return {"deleted": True, "id": recipient_id}

    @app.post("/api/alerts/fall", dependencies=[Depends(verify_api_key)])
    async def trigger_fall(req: FallAlertRequest) -> dict[str, Any]:
        record, deduplicated = await disp.trigger_fall_alert(req)
        ok_count = sum(1 for d in record.deliveries if d.ok)
        return {
            "ok": ok_count > 0 or deduplicated,
            "deduplicated": deduplicated,
            "delivered_count": ok_count,
            "attempted_count": len(record.deliveries),
            "alert": record.model_dump(),
        }

    @app.post("/api/alerts/test", dependencies=[Depends(verify_api_key)])
    async def trigger_test(req: FallAlertRequest | None = None) -> dict[str, Any]:
        payload = req or FallAlertRequest(
            event_type="test",
            room_name="Kiểm tra hệ thống",
            simulated=True,
            note="Tin nhắn/cuộc gọi thử nghiệm từ cấu hình Hearth",
        )
        payload.event_type = "test"
        payload.simulated = True
        record, _ = await disp.trigger_fall_alert(payload)
        ok_count = sum(1 for d in record.deliveries if d.ok)
        return {
            "ok": ok_count > 0,
            "delivered_count": ok_count,
            "attempted_count": len(record.deliveries),
            "alert": record.model_dump(),
        }

    @app.get("/api/alerts", dependencies=[Depends(verify_api_key)])
    async def list_alerts() -> dict[str, Any]:
        return {"alerts": [a.model_dump() for a in st.list_recent_alerts()]}

    @app.post("/api/alerts/{alert_id}/ack", dependencies=[Depends(verify_api_key)])
    async def ack_alert(alert_id: str, body: AcknowledgeRequest) -> dict[str, Any]:
        rec = await disp.acknowledge_alert(alert_id, by=body.by)
        if not rec:
            raise HTTPException(status_code=404, detail="Alert not found")
        return {"ok": True, "alert": rec.model_dump()}

    @app.post("/api/alerts/{alert_id}/resolve", dependencies=[Depends(verify_api_key)])
    async def resolve_alert(alert_id: str, body: ResolveRequest) -> dict[str, Any]:
        rec = await disp.resolve_alert(
            alert_id,
            by=body.by,
            outcome=body.outcome,
            note=body.note,
            false_alarm_reason=body.false_alarm_reason,
        )
        if not rec:
            raise HTTPException(status_code=404, detail="Alert not found")
        return {"ok": True, "alert": rec.model_dump()}

    # --- Edge AI Human-in-the-Loop Dataset Endpoints ---
    @app.post("/api/ai/samples", dependencies=[Depends(verify_api_key)])
    async def add_ai_sample(sample: AiTrainingSample) -> dict[str, Any]:
        if len(sample.features) != 12:
            raise HTTPException(status_code=400, detail="features must contain exactly 12 floats")
        stored = st.add_ai_sample(sample)
        return {"ok": True, "sample": stored.model_dump(), "summary": st.ai_dataset_summary()}

    @app.get("/api/ai/dataset", dependencies=[Depends(verify_api_key)])
    async def get_ai_dataset() -> dict[str, Any]:
        return {
            "summary": st.ai_dataset_summary(),
            "samples": [s.model_dump() for s in st.list_ai_samples()],
        }

    @app.get("/api/ai/dataset.csv", response_class=PlainTextResponse, dependencies=[Depends(verify_api_key)])
    async def download_ai_dataset_csv() -> str:
        feature_cols = [
            "max_motion", "max_static", "tof_high", "tof_mid", "tof_low",
            "drop_rate", "radar_dist", "max_drop_rate", "post_motion_mean",
            "post_static_mean", "radar_gate_spread", "height_drop_delta",
        ]
        buf = io.StringIO()
        writer = csv.writer(buf)
        writer.writerow(["timestamp", "label", "note", "weight", "is_false_alarm", *feature_cols])
        for s in st.list_ai_samples():
            if len(s.features) != 12:
                continue
            w = "3.5" if s.is_false_alarm else "3.0"
            note = s.reason or s.note or s.source
            writer.writerow([
                s.created_at, s.label, note, w, str(s.is_false_alarm).lower(),
                *[f"{v:.4f}" for v in s.features],
            ])
        return buf.getvalue()

    @app.post("/api/telegram/webhook", include_in_schema=False)
    async def telegram_webhook(
        update: dict[str, Any],
        x_telegram_bot_api_secret_token: str | None = Header(
            default=None, alias="X-Telegram-Bot-Api-Secret-Token"
        ),
    ) -> dict[str, Any]:
        if cfg.telegram_webhook_secret and x_telegram_bot_api_secret_token != cfg.telegram_webhook_secret:
            raise HTTPException(status_code=401, detail="Invalid Telegram webhook secret")
        await poller.handle_update(update)
        return {"ok": True}

    @app.post("/api/auth/otp/send", dependencies=[Depends(verify_api_key)])
    async def send_email_otp(body: OtpSendRequest) -> dict[str, Any]:
        res = await otp.send_otp(
            email=body.email,
            phone=body.phone,
            carer_name=body.carer_name,
            language=body.language,
        )
        return {
            "ok": res.ok,
            "provider": res.provider,
            "expires_in_sec": res.expires_in_sec,
            "detail": res.detail,
        }

    @app.post("/api/auth/otp/verify", dependencies=[Depends(verify_api_key)])
    async def verify_email_otp(body: OtpVerifyRequest) -> dict[str, Any]:
        res = await otp.verify_otp(email=body.email, code=body.code, phone=body.phone)
        return {
            "ok": res.ok,
            "provider": res.provider,
            "detail": res.detail,
        }

    # Expose internals on app.state for programmatic inspection/testing
    app.state.config = cfg
    app.state.store = st
    app.state.dispatcher = disp
    app.state.otp_service = otp
    app.state.poller = poller
    return app


app = create_app()
