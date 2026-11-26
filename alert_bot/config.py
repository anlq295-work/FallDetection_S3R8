from __future__ import annotations

import hashlib
import os
import re
from dataclasses import dataclass
from pathlib import Path
from dotenv import load_dotenv

# Load alert_bot/.env if present, then root .env
_BOT_DIR = Path(__file__).resolve().parent
load_dotenv(_BOT_DIR / ".env", override=False)
load_dotenv(_BOT_DIR.parent / ".env", override=False)


def _split_csv(value: str) -> list[str]:
    if not value:
        return []
    parts = value.replace(";", ",").split(",")
    return [p.strip() for p in parts if p.strip()]


@dataclass
class BotConfig:
    # Server settings
    host: str = "0.0.0.0"
    port: int = 8080
    api_key: str = ""
    data_file: str = str(_BOT_DIR / "data" / "settings.json")
    alert_cooldown_sec: int = 15
    esp32_lan_ip: str = ""

    # Telegram Bot API
    telegram_bot_token: str = ""
    telegram_default_chat_ids: tuple[str, ...] = ()
    telegram_polling_enabled: bool = True
    telegram_webhook_base_url: str = ""
    telegram_webhook_secret: str = ""

    # CallMeBot (Free Telegram Voice Call)
    callmebot_enabled: bool = True
    callmebot_default_users: tuple[str, ...] = ()
    callmebot_lang: str = "vi-VN-Standard-A"
    callmebot_repeat: int = 3

    # Twilio (Real Phone Voice Call — fallback if Stringee not configured)
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_from_number: str = ""
    twilio_voice_lang: str = "vi-VN"
    twilio_voice_name: str = "Google.vi-VN-Standard-A"

    # Stringee Programmable Voice (Vietnam Direct TTS Call — Priority #1, no English trial prompt)
    stringee_api_key_sid: str = ""
    stringee_api_key_secret: str = ""
    stringee_from_number: str = ""
    stringee_voice: str = "hn_female_thutrang_phrase_48k-hsmm"
    stringee_speed: int = 0
    stringee_repeat: int = 3

    # Email OTP — 1) Twilio Verify Email, 2) Twilio SendGrid API, 3) SMTP (Gmail/Custom)
    twilio_verify_service_sid: str = ""
    sendgrid_api_key: str = ""
    sendgrid_from_email: str = ""
    sendgrid_from_name: str = "Hearth Fall Guard"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_email: str = ""
    smtp_use_tls: bool = True
    otp_expiry_sec: int = 300
    otp_max_attempts: int = 5
    otp_resend_cooldown_sec: int = 30

    # SpeedSMS Vietnam (Local SMS)
    speedsms_access_token: str = ""
    speedsms_sender: str = ""
    speedsms_type: int = 2
    speedsms_url: str = "https://api.speedsms.vn/index.php/sms/send"

    # Default country code for normalizing local numbers (e.g. 09xx -> +849xx)
    default_country_code: str = "+84"

    @classmethod
    def from_env(cls) -> "BotConfig":
        # Render / Railway / Fly.io automatically inject PORT; local uses ALERT_BOT_PORT
        port_raw = (os.getenv("PORT") or os.getenv("ALERT_BOT_PORT") or "8080").strip()
        webhook_base = (
            os.getenv("TELEGRAM_WEBHOOK_BASE_URL")
            or os.getenv("RENDER_EXTERNAL_URL")
            or ""
        ).strip().rstrip("/")
        raw_webhook_secret = os.getenv("TELEGRAM_WEBHOOK_SECRET", "").strip()
        if raw_webhook_secret and not re.fullmatch(r"[A-Za-z0-9_-]{1,256}", raw_webhook_secret):
            # Render generateValue: true emits base64 (+, /, =), which Telegram setWebhook rejects.
            webhook_secret = hashlib.sha256(raw_webhook_secret.encode("utf-8")).hexdigest()
        else:
            webhook_secret = raw_webhook_secret
        return cls(
            host=os.getenv("ALERT_BOT_HOST", "0.0.0.0"),
            port=int(port_raw),
            api_key=os.getenv("ALERT_BOT_API_KEY", "").strip(),
            data_file=os.getenv("ALERT_BOT_DATA_FILE", str(_BOT_DIR / "data" / "settings.json")),
            alert_cooldown_sec=int(os.getenv("ALERT_COOLDOWN_SEC", "15")),
            esp32_lan_ip=os.getenv("ESP32_LAN_IP", "").strip(),
            telegram_bot_token=os.getenv("TELEGRAM_BOT_TOKEN", "").strip(),
            telegram_default_chat_ids=tuple(_split_csv(os.getenv("TELEGRAM_DEFAULT_CHAT_IDS", ""))),
            telegram_polling_enabled=os.getenv("TELEGRAM_POLLING_ENABLED", "true").lower()
            not in ("0", "false", "no"),
            telegram_webhook_base_url=webhook_base,
            telegram_webhook_secret=webhook_secret,
            callmebot_enabled=os.getenv("CALLMEBOT_ENABLED", "true").lower()
            not in ("0", "false", "no"),
            callmebot_default_users=tuple(_split_csv(os.getenv("CALLMEBOT_DEFAULT_USERS", ""))),
            callmebot_lang=os.getenv("CALLMEBOT_LANG", "vi-VN-Standard-A").strip(),
            callmebot_repeat=int(os.getenv("CALLMEBOT_REPEAT", "3")),
            twilio_account_sid=os.getenv("TWILIO_ACCOUNT_SID", "").strip(),
            twilio_auth_token=os.getenv("TWILIO_AUTH_TOKEN", "").strip(),
            twilio_from_number=os.getenv("TWILIO_FROM_NUMBER", "").strip(),
            twilio_voice_lang=os.getenv("TWILIO_VOICE_LANG", "vi-VN").strip(),
            twilio_voice_name=os.getenv("TWILIO_VOICE_NAME", "Google.vi-VN-Standard-A").strip(),
            stringee_api_key_sid=os.getenv("STRINGEE_API_KEY_SID", "").strip(),
            stringee_api_key_secret=os.getenv("STRINGEE_API_KEY_SECRET", "").strip(),
            stringee_from_number=os.getenv("STRINGEE_FROM_NUMBER", "").strip(),
            stringee_voice=os.getenv("STRINGEE_VOICE", "hn_female_thutrang_phrase_48k-hsmm").strip(),
            stringee_speed=int(os.getenv("STRINGEE_SPEED", "0")),
            stringee_repeat=int(os.getenv("STRINGEE_REPEAT", "3")),
            twilio_verify_service_sid=os.getenv("TWILIO_VERIFY_SERVICE_SID", "").strip(),
            sendgrid_api_key=os.getenv("SENDGRID_API_KEY", "").strip(),
            sendgrid_from_email=os.getenv("SENDGRID_FROM_EMAIL", "").strip(),
            sendgrid_from_name=os.getenv("SENDGRID_FROM_NAME", "Hearth Fall Guard").strip(),
            smtp_host=os.getenv("SMTP_HOST", "").strip(),
            smtp_port=int(os.getenv("SMTP_PORT", "587")),
            smtp_user=os.getenv("SMTP_USER", "").strip(),
            smtp_password=os.getenv("SMTP_PASSWORD", "").strip(),
            smtp_from_email=os.getenv("SMTP_FROM_EMAIL", "").strip(),
            smtp_use_tls=os.getenv("SMTP_USE_TLS", "true").lower() not in ("0", "false", "no"),
            otp_expiry_sec=int(os.getenv("OTP_EXPIRY_SEC", "300")),
            otp_max_attempts=int(os.getenv("OTP_MAX_ATTEMPTS", "5")),
            otp_resend_cooldown_sec=int(os.getenv("OTP_RESEND_COOLDOWN_SEC", "30")),
            speedsms_access_token=os.getenv("SPEEDSMS_ACCESS_TOKEN", "").strip(),
            speedsms_sender=os.getenv("SPEEDSMS_SENDER", "").strip(),
            speedsms_type=int(os.getenv("SPEEDSMS_TYPE", "2")),
            speedsms_url=os.getenv(
                "SPEEDSMS_URL", "https://api.speedsms.vn/index.php/sms/send"
            ).strip(),
            default_country_code=os.getenv("DEFAULT_COUNTRY_CODE", "+84").strip(),
        )

    @property
    def has_telegram(self) -> bool:
        return bool(self.telegram_bot_token)

    @property
    def has_twilio(self) -> bool:
        return bool(self.twilio_account_sid and self.twilio_auth_token and self.twilio_from_number)

    @property
    def has_stringee(self) -> bool:
        return bool(self.stringee_api_key_sid and self.stringee_api_key_secret and self.stringee_from_number)

    @property
    def has_speedsms(self) -> bool:
        return bool(self.speedsms_access_token)

    @property
    def has_twilio_verify_email(self) -> bool:
        return bool(self.twilio_account_sid and self.twilio_auth_token and self.twilio_verify_service_sid)

    @property
    def has_sendgrid(self) -> bool:
        return bool(self.sendgrid_api_key and self.sendgrid_from_email)

    @property
    def has_smtp(self) -> bool:
        return bool(self.smtp_host and self.smtp_user and self.smtp_password)

    def active_providers(self) -> dict[str, bool]:
        return {
            "telegram_bot": self.has_telegram,
            "callmebot_telegram_call": self.callmebot_enabled,
            "stringee_voice_call": self.has_stringee,
            "twilio_voice_call": self.has_twilio,
            "twilio_verify_email_otp": self.has_twilio_verify_email,
            "twilio_sendgrid_email_otp": self.has_sendgrid,
            "smtp_email_otp": self.has_smtp,
        }
