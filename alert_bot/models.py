from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Literal
from pydantic import BaseModel, Field


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class ChannelToggles(BaseModel):
    telegram: bool = True
    sms: bool = False
    call: bool = True


class Recipient(BaseModel):
    id: str = Field(..., min_length=1)
    name: str = Field(..., min_length=1)
    phone: str = ""
    telegram_chat_id: str = ""
    telegram_username: str = ""  # Used by CallMeBot free Telegram voice call (with or without @)
    enabled: bool = True
    is_primary: bool = False
    notify_telegram: bool = True
    notify_sms: bool = False
    notify_call: bool = True


class BotSettings(BaseModel):
    dispatch_mode: Literal["simultaneous", "sequential"] = "simultaneous"
    escalation_minutes: int = Field(default=2, ge=1, le=30)
    channels: ChannelToggles = Field(default_factory=ChannelToggles)
    person_name: str = ""
    home_address: str = ""
    door_code: str = ""
    emergency_number: str = "115"
    esp32_lan_ip: str = ""
    recipients: list[Recipient] = Field(default_factory=list)


class FallAlertRequest(BaseModel):
    event_type: Literal["fall_impact", "slow_fall", "manual_sos", "test"] = "fall_impact"
    room_name: str = "Phòng đang giám sát"
    person_name: str = ""
    velocity_mm_s: float = 0.0
    motion_peak: int = 0
    target_dist_cm: int = 0
    tof_height_mm: int = 0
    confidence: float = 0.0
    device_id: str = ""
    device_ip: str = ""
    uptime_sec: int = 0
    simulated: bool = False
    note: str = ""
    location: dict[str, float] | None = None
    # Optional per-request overrides (e.g. from ESP32 NVS if settings.json has no recipients yet)
    fallback_phones: list[str] = Field(default_factory=list)
    fallback_chat_ids: list[str] = Field(default_factory=list)
    fallback_telegram_users: list[str] = Field(default_factory=list)
    # Optional channel & recipient filtering for targeted test buttons (e.g. ["sms"], ["call"], ["telegram"])
    channels_override: list[Literal["telegram", "sms", "call"]] | None = None
    target_recipient_ids: list[str] | None = None
    use_fallback_only: bool = False
    # Optional Edge AI 12-feature snapshot & diagnostics for Human-in-the-Loop continuous learning
    ai_features: list[float] = Field(default_factory=list)
    ai_diagnostics: dict[str, Any] = Field(default_factory=dict)


class DeliveryResult(BaseModel):
    recipient_id: str
    recipient_name: str
    channel: Literal["telegram", "sms", "call"]
    provider: str
    target: str
    ok: bool
    detail: str = ""
    message_id: int | None = None


class AlertRecord(BaseModel):
    alert_id: str
    event_type: str
    room_name: str
    person_name: str
    created_at: str = Field(default_factory=utc_now_iso)
    status: Literal["active", "acknowledged", "resolved"] = "active"
    acknowledged_by: str | None = None
    acknowledged_at: str | None = None
    resolved_by: str | None = None
    resolved_outcome: str | None = None
    resolved_at: str | None = None
    simulated: bool = False
    device_id: str = ""
    device_ip: str = ""
    notified_recipient_ids: list[str] = Field(default_factory=list)
    deliveries: list[DeliveryResult] = Field(default_factory=list)
    ai_features: list[float] = Field(default_factory=list)
    ai_diagnostics: dict[str, Any] = Field(default_factory=dict)


class AcknowledgeRequest(BaseModel):
    by: str = "Người chăm sóc"


class ResolveRequest(BaseModel):
    by: str = "Người chăm sóc"
    outcome: Literal["person_ok", "needed_help", "false_alarm"] = "person_ok"
    false_alarm_reason: str = ""
    note: str = ""


class AiTrainingSample(BaseModel):
    sample_id: str = ""
    created_at: str = Field(default_factory=utc_now_iso)
    label: Literal["STAND", "SIT", "LIE", "FALL"] = "SIT"
    features: list[float] = Field(default_factory=list)
    source: str = "user_feedback"
    alert_id: str = ""
    outcome: str = ""
    reason: str = ""
    note: str = ""
    is_false_alarm: bool = False
    device_id: str = ""
    room_name: str = ""


class OtpSendRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=254)
    phone: str = ""
    carer_name: str = ""
    language: Literal["vi", "en", "fr"] = "vi"


class OtpVerifyRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=254)
    phone: str = ""
    code: str = Field(..., min_length=4, max_length=10)
