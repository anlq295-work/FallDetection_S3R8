from __future__ import annotations

import asyncio
import hashlib
import hmac
import html
import json
import re
import secrets
import smtplib
import time
from dataclasses import dataclass
from email.message import EmailMessage

import httpx

from ..config import BotConfig
from ..storage import normalize_phone

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


@dataclass
class OtpSendResult:
    ok: bool
    provider: str
    expires_in_sec: int = 300
    detail: str = ""


@dataclass
class OtpVerifyResult:
    ok: bool
    provider: str
    detail: str = ""


@dataclass
class _StoredOtp:
    salt: str
    code_hash: str
    expires_at: float
    sent_at: float
    attempts: int = 0
    provider: str = "local"
    verify_target: str = ""


def _hash_code(salt: str, code: str) -> str:
    return hashlib.sha256(f"{salt}:{code}".encode("utf-8")).hexdigest()


def _build_otp_email(code: str, carer_name: str, language: str, minutes: int) -> tuple[str, str, str]:
    greeting_name = carer_name.strip()
    if language == "en":
        subject = f"[Hearth] Your sign-in verification code: {code}"
        hi = f"Hello {greeting_name}," if greeting_name else "Hello,"
        plain = (
            f"{hi}\n\n"
            f"Your Hearth Fall Guard verification code is: {code}\n"
            f"This code expires in {minutes} minutes. Do not share it with anyone.\n"
        )
        body_html = (
            f"<div style='font-family:system-ui,sans-serif;max-width:520px;margin:0 auto;padding:24px'>"
            f"<h2 style='color:#0f766e'>🛡️ Hearth Fall Guard</h2>"
            f"<p>{html.escape(hi)}</p>"
            f"<p>Use the verification code below to finish signing in to the Hearth app:</p>"
            f"<div style='font-size:32px;font-weight:800;letter-spacing:8px;padding:16px 20px;"
            f"background:#f0fdfa;border:1px solid #99f6e4;border-radius:12px;text-align:center;color:#115e59'>"
            f"{html.escape(code)}</div>"
            f"<p style='color:#64748b;font-size:13px;margin-top:16px'>"
            f"This code expires in {minutes} minutes. If you did not request this, you can safely ignore it.</p></div>"
        )
        return subject, plain, body_html

    if language == "fr":
        subject = f"[Hearth] Votre code de connexion : {code}"
        hi = f"Bonjour {greeting_name}," if greeting_name else "Bonjour,"
        plain = (
            f"{hi}\n\n"
            f"Votre code de vérification Hearth Fall Guard est : {code}\n"
            f"Ce code expire dans {minutes} minutes.\n"
        )
        body_html = (
            f"<div style='font-family:system-ui,sans-serif;max-width:520px;margin:0 auto;padding:24px'>"
            f"<h2 style='color:#0f766e'>🛡️ Hearth Fall Guard</h2>"
            f"<p>{html.escape(hi)}</p>"
            f"<p>Saisissez le code ci-dessous dans l’application Hearth :</p>"
            f"<div style='font-size:32px;font-weight:800;letter-spacing:8px;padding:16px 20px;"
            f"background:#f0fdfa;border:1px solid #99f6e4;border-radius:12px;text-align:center;color:#115e59'>"
            f"{html.escape(code)}</div>"
            f"<p style='color:#64748b;font-size:13px;margin-top:16px'>"
            f"Ce code expire dans {minutes} minutes.</p></div>"
        )
        return subject, plain, body_html

    # Default Vietnamese
    subject = f"[Hearth] Mã xác nhận đăng nhập của bạn: {code}"
    hi = f"Xin chào {greeting_name}," if greeting_name else "Xin chào,"
    plain = (
        f"{hi}\n\n"
        f"Mã xác nhận OTP đăng nhập ứng dụng Hearth Fall Guard của bạn là: {code}\n"
        f"Mã có hiệu lực trong {minutes} phút. Vui lòng không chia sẻ mã này cho người khác.\n"
    )
    body_html = (
        f"<div style='font-family:system-ui,sans-serif;max-width:520px;margin:0 auto;padding:24px'>"
        f"<h2 style='color:#0f766e'>🛡️ Hearth Fall Guard</h2>"
        f"<p>{html.escape(hi)}</p>"
        f"<p>Nhập mã OTP 6 chữ số bên dưới để hoàn tất kết nối vào ứng dụng Hearth:</p>"
        f"<div style='font-size:32px;font-weight:800;letter-spacing:8px;padding:16px 20px;"
        f"background:#f0fdfa;border:1px solid #99f6e4;border-radius:12px;text-align:center;color:#115e59'>"
        f"{html.escape(code)}</div>"
        f"<p style='color:#64748b;font-size:13px;margin-top:16px'>"
        f"Mã có hiệu lực trong {minutes} phút. Nếu bạn không yêu cầu đăng nhập, hãy bỏ qua email này.</p></div>"
    )
    return subject, plain, body_html


class EmailOtpService:
    """Sends & verifies 6-digit login email OTPs via Twilio Verify Email, Twilio SendGrid, or SMTP."""

    def __init__(self, config: BotConfig, client: httpx.AsyncClient | None = None) -> None:
        self._config = config
        self._client = client
        self._store: dict[str, _StoredOtp] = {}

    @property
    def configured(self) -> bool:
        return (
            self._config.has_twilio_verify_email
            or self._config.has_sendgrid
            or self._config.has_smtp
        )

    def _normalize_email(self, email: str) -> str:
        return (email or "").strip().lower()

    async def send_otp(
        self, email: str, carer_name: str = "", language: str = "vi", phone: str = ""
    ) -> OtpSendResult:
        clean_email = self._normalize_email(email)
        if not _EMAIL_RE.match(clean_email):
            return OtpSendResult(ok=False, provider="none", detail="Địa chỉ email không hợp lệ")

        now = time.monotonic()
        existing = self._store.get(clean_email)
        if existing and self._config.otp_resend_cooldown_sec > 0:
            elapsed = now - existing.sent_at
            if elapsed < self._config.otp_resend_cooldown_sec:
                wait_left = int(self._config.otp_resend_cooldown_sec - elapsed) + 1
                return OtpSendResult(
                    ok=False,
                    provider=existing.provider,
                    detail=f"Vui lòng đợi {wait_left} giây trước khi gửi lại mã",
                )

        # 1. Twilio Verify API (Email Channel — uses SendGrid Dynamic Template linked in Twilio Console)
        if self._config.has_twilio_verify_email:
            res = await self._send_twilio_verify(clean_email, channel="email", language=language)
            if res.ok:
                self._store[clean_email] = _StoredOtp(
                    salt="",
                    code_hash="",
                    expires_at=now + self._config.otp_expiry_sec,
                    sent_at=now,
                    provider="twilio_verify_email",
                    verify_target=clean_email,
                )
                return res

            # Automatic fallback to direct SendGrid/SMTP or Twilio Verify SMS if Verify Email fails
            if self._config.has_sendgrid or self._config.has_smtp:
                fallback = await self._send_local_email_otp(clean_email, carer_name, language, now)
                if fallback.ok:
                    return fallback

            e164_phone = normalize_phone(phone, self._config.default_country_code)
            if e164_phone:
                sms_res = await self._send_twilio_verify(e164_phone, channel="sms", language=language)
                if sms_res.ok:
                    self._store[clean_email] = _StoredOtp(
                        salt="",
                        code_hash="",
                        expires_at=now + self._config.otp_expiry_sec,
                        sent_at=now,
                        provider="twilio_verify_sms",
                        verify_target=e164_phone,
                    )
                    return sms_res
            return res

        # 2. Direct Email providers (SendGrid / SMTP) when Twilio Verify is not configured
        if self._config.has_sendgrid or self._config.has_smtp:
            return await self._send_local_email_otp(clean_email, carer_name, language, now)

        return OtpSendResult(
            ok=False,
            provider="unconfigured",
            detail=(
                "Chưa cấu hình Email OTP trong alert_bot/.env "
                "(điền TWILIO_VERIFY_SERVICE_SID, SENDGRID_API_KEY, hoặc SMTP_HOST/USER/PASSWORD)"
            ),
        )

    async def _send_local_email_otp(
        self, clean_email: str, carer_name: str, language: str, now: float
    ) -> OtpSendResult:
        code = f"{secrets.randbelow(1_000_000):06d}"
        minutes = max(1, round(self._config.otp_expiry_sec / 60))
        subject, plain, body_html = _build_otp_email(code, carer_name, language, minutes)
        res = (
            await self._send_via_sendgrid(clean_email, subject, plain, body_html)
            if self._config.has_sendgrid
            else await self._send_via_smtp(clean_email, subject, plain, body_html)
        )
        if res.ok:
            salt = secrets.token_hex(16)
            self._store[clean_email] = _StoredOtp(
                salt=salt,
                code_hash=_hash_code(salt, code),
                expires_at=now + self._config.otp_expiry_sec,
                sent_at=now,
                attempts=0,
                provider=res.provider,
                verify_target=clean_email,
            )
        return res

    async def verify_otp(self, email: str, code: str, phone: str = "") -> OtpVerifyResult:
        clean_email = self._normalize_email(email)
        clean_code = (code or "").strip()
        if not _EMAIL_RE.match(clean_email):
            return OtpVerifyResult(ok=False, provider="none", detail="Email không hợp lệ")
        if not clean_code.isdigit() or len(clean_code) != 6:
            return OtpVerifyResult(ok=False, provider="none", detail="Mã OTP phải gồm đúng 6 chữ số")

        rec = self._store.get(clean_email)

        # 1. Twilio Verify API verification (handles both active session and post-restart verify)
        use_twilio_verify = (
            (rec is not None and rec.provider in ("twilio_verify_email", "twilio_verify_sms"))
            or (rec is None and self._config.has_twilio_verify_email)
        )
        if use_twilio_verify:
            target = (rec.verify_target if rec and rec.verify_target else "") or clean_email
            if rec is None and phone:
                maybe_phone = normalize_phone(phone, self._config.default_country_code)
                if maybe_phone:
                    res_em = await self._verify_twilio_verify(clean_email, clean_code)
                    if res_em.ok:
                        return res_em
                    return await self._verify_twilio_verify(maybe_phone, clean_code)
            res = await self._verify_twilio_verify(target, clean_code)
            if res.ok:
                self._store.pop(clean_email, None)
            return res

        # 2. Local verification (SendGrid / SMTP)
        if rec is None:
            return OtpVerifyResult(
                ok=False,
                provider="local",
                detail="Chưa gửi mã OTP hoặc mã đã hết hạn. Vui lòng bấm gửi lại mã.",
            )

        now = time.monotonic()
        if now > rec.expires_at:
            self._store.pop(clean_email, None)
            return OtpVerifyResult(
                ok=False,
                provider=rec.provider,
                detail="Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.",
            )

        rec.attempts += 1
        if rec.attempts > self._config.otp_max_attempts:
            self._store.pop(clean_email, None)
            return OtpVerifyResult(
                ok=False,
                provider=rec.provider,
                detail="Bạn đã nhập sai quá số lần quy định. Vui lòng yêu cầu mã OTP mới.",
            )

        candidate_hash = _hash_code(rec.salt, clean_code)
        if hmac.compare_digest(candidate_hash, rec.code_hash):
            self._store.pop(clean_email, None)
            return OtpVerifyResult(ok=True, provider=rec.provider, detail="Xác thực OTP thành công")

        left = max(0, self._config.otp_max_attempts - rec.attempts)
        return OtpVerifyResult(
            ok=False,
            provider=rec.provider,
            detail=f"Mã OTP không chính xác (còn {left} lần thử).",
        )

    async def _send_twilio_verify(
        self, target: str, channel: str = "email", language: str = "vi"
    ) -> OtpSendResult:
        url = (
            f"https://verify.twilio.com/v2/Services/"
            f"{self._config.twilio_verify_service_sid}/Verifications"
        )
        form: dict[str, str] = {"To": target, "Channel": channel, "Locale": language}
        if channel == "email":
            form["ChannelConfiguration"] = json.dumps(
                {
                    "substitutions": {
                        "twilio_time_limit": "10",
                    }
                }
            )
        provider_name = "twilio_verify_email" if channel == "email" else "twilio_verify_sms"
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
            detail = (
                f"Đã gửi mã OTP qua {'Email (Twilio Verify)' if channel == 'email' else 'SMS (Twilio Verify)'}"
                if ok
                else f"HTTP {resp.status_code}: {resp.text[:180]}"
            )
            return OtpSendResult(
                ok=ok,
                provider=provider_name,
                expires_in_sec=self._config.otp_expiry_sec,
                detail=detail,
            )
        except Exception as exc:
            return OtpSendResult(ok=False, provider=provider_name, detail=str(exc))

    async def _verify_twilio_verify(self, email: str, code: str) -> OtpVerifyResult:
        url = (
            f"https://verify.twilio.com/v2/Services/"
            f"{self._config.twilio_verify_service_sid}/VerificationCheck"
        )
        form = {"To": email, "Code": code}
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
            data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
            approved = resp.status_code in (200, 201) and data.get("status") == "approved"
            detail = (
                "Xác thực thành công qua Twilio Verify"
                if approved
                else str(data.get("message") or "Mã OTP không đúng hoặc đã hết hạn")
            )
            return OtpVerifyResult(ok=approved, provider="twilio_verify_email", detail=detail)
        except Exception as exc:
            return OtpVerifyResult(ok=False, provider="twilio_verify_email", detail=str(exc))

    async def _send_via_sendgrid(
        self, to_email: str, subject: str, plain: str, body_html: str
    ) -> OtpSendResult:
        url = "https://api.sendgrid.com/v3/mail/send"
        payload = {
            "personalizations": [{"to": [{"email": to_email}]}],
            "from": {
                "email": self._config.sendgrid_from_email,
                "name": self._config.sendgrid_from_name,
            },
            "subject": subject,
            "content": [
                {"type": "text/plain", "value": plain},
                {"type": "text/html", "value": body_html},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self._config.sendgrid_api_key}",
            "Content-Type": "application/json",
        }
        try:
            if self._client is not None:
                resp = await self._client.post(url, json=payload, headers=headers, timeout=12.0)
            else:
                async with httpx.AsyncClient(timeout=12.0) as client:
                    resp = await client.post(url, json=payload, headers=headers)
            ok = resp.status_code in (200, 202)
            detail = "Đã gửi mã OTP qua Twilio SendGrid" if ok else f"HTTP {resp.status_code}: {resp.text[:180]}"
            return OtpSendResult(
                ok=ok,
                provider="twilio_sendgrid_email",
                expires_in_sec=self._config.otp_expiry_sec,
                detail=detail,
            )
        except Exception as exc:
            return OtpSendResult(ok=False, provider="twilio_sendgrid_email", detail=str(exc))

    async def _send_via_smtp(
        self, to_email: str, subject: str, plain: str, body_html: str
    ) -> OtpSendResult:
        msg = EmailMessage()
        from_addr = self._config.smtp_from_email or self._config.smtp_user
        msg["Subject"] = subject
        msg["From"] = f"{self._config.sendgrid_from_name} <{from_addr}>"
        msg["To"] = to_email
        msg.set_content(plain)
        msg.add_alternative(body_html, subtype="html")

        def _blocking_send() -> None:
            if self._config.smtp_port == 465 and not self._config.smtp_use_tls:
                with smtplib.SMTP_SSL(self._config.smtp_host, self._config.smtp_port, timeout=12) as srv:
                    srv.login(self._config.smtp_user, self._config.smtp_password)
                    srv.send_message(msg)
            else:
                with smtplib.SMTP(self._config.smtp_host, self._config.smtp_port, timeout=12) as srv:
                    if self._config.smtp_use_tls:
                        srv.starttls()
                    srv.login(self._config.smtp_user, self._config.smtp_password)
                    srv.send_message(msg)

        try:
            await asyncio.to_thread(_blocking_send)
            return OtpSendResult(
                ok=True,
                provider="smtp_email",
                expires_in_sec=self._config.otp_expiry_sec,
                detail="Đã gửi mã OTP qua SMTP Email",
            )
        except Exception as exc:
            return OtpSendResult(ok=False, provider="smtp_email", detail=str(exc))
