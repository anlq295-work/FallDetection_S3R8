from __future__ import annotations

import json
import re
import threading
import time
from pathlib import Path
from typing import Iterable

from .models import AiTrainingSample, AlertRecord, BotSettings, Recipient, utc_now_iso


def normalize_phone(raw_phone: str, default_country_code: str = "+84") -> str:
    """Normalizes phone numbers to E.164 format (e.g., 0912345678 -> +84912345678)."""
    cleaned = re.sub(r"[^0-9+]", "", (raw_phone or "").strip())
    if not cleaned:
        return ""
    if cleaned.startswith("+"):
        return cleaned
    if cleaned.startswith("00"):
        return "+" + cleaned[2:]
    if cleaned.startswith("0") and len(cleaned) >= 9:
        cc = default_country_code if default_country_code.startswith("+") else f"+{default_country_code}"
        return f"{cc}{cleaned[1:]}"
    if len(cleaned) >= 9:
        return f"+{cleaned}"
    return ""


def normalize_telegram_username(raw_username: str) -> str:
    u = (raw_username or "").strip()
    if not u:
        return ""
    if u.startswith("https://t.me/"):
        u = u.removeprefix("https://t.me/")
    u = u.lstrip("@").strip()
    return f"@{u}" if u else ""


class SettingsStore:
    """Thread-safe JSON persistence for alert recipients, settings, and active alerts."""

    def __init__(self, file_path: str | Path) -> None:
        self._path = Path(file_path)
        self._lock = threading.RLock()
        self._settings: BotSettings = BotSettings()
        self._alerts: dict[str, AlertRecord] = {}
        self._ai_samples: list[AiTrainingSample] = []
        self._load()

    def _load(self) -> None:
        with self._lock:
            if not self._path.exists():
                return
            try:
                raw = json.loads(self._path.read_text(encoding="utf-8"))
                if isinstance(raw, dict):
                    if "settings" in raw:
                        self._settings = BotSettings.model_validate(raw["settings"])
                    else:
                        self._settings = BotSettings.model_validate(raw)
                    for item in raw.get("recent_alerts", []):
                        rec = AlertRecord.model_validate(item)
                        self._alerts[rec.alert_id] = rec
                    for item in raw.get("ai_samples", []):
                        self._ai_samples.append(AiTrainingSample.model_validate(item))
            except Exception:
                # Start clean if file is corrupt rather than crashing emergency service
                self._settings = BotSettings()

    def _save(self) -> None:
        with self._lock:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            recent = list(self._alerts.values())[-50:]
            recent_samples = self._ai_samples[-2000:]
            payload = {
                "settings": self._settings.model_dump(),
                "recent_alerts": [a.model_dump() for a in recent],
                "ai_samples": [s.model_dump() for s in recent_samples],
            }
            tmp = self._path.with_suffix(".tmp")
            tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
            tmp.replace(self._path)

    def get_settings(self) -> BotSettings:
        with self._lock:
            return self._settings.model_copy(deep=True)

    def update_settings(self, new_settings: BotSettings) -> BotSettings:
        with self._lock:
            self._settings = new_settings.model_copy(deep=True)
            self._save()
            return self.get_settings()

    def upsert_recipient(self, recipient: Recipient) -> Recipient:
        with self._lock:
            cleaned = recipient.model_copy(
                update={
                    "name": recipient.name.strip(),
                    "phone": recipient.phone.strip(),
                    "telegram_chat_id": recipient.telegram_chat_id.strip(),
                    "telegram_username": normalize_telegram_username(recipient.telegram_username),
                }
            )
            idx = next((i for i, r in enumerate(self._settings.recipients) if r.id == cleaned.id), None)
            if idx is None and cleaned.telegram_chat_id:
                idx = next(
                    (
                        i
                        for i, r in enumerate(self._settings.recipients)
                        if r.telegram_chat_id and r.telegram_chat_id == cleaned.telegram_chat_id
                    ),
                    None,
                )
            if idx is not None:
                # Preserve existing ID if matched by telegram_chat_id
                existing = self._settings.recipients[idx]
                merged = existing.model_copy(
                    update={
                        "name": cleaned.name or existing.name,
                        "phone": cleaned.phone or existing.phone,
                        "telegram_chat_id": cleaned.telegram_chat_id or existing.telegram_chat_id,
                        "telegram_username": cleaned.telegram_username or existing.telegram_username,
                        "enabled": cleaned.enabled,
                        "is_primary": cleaned.is_primary or existing.is_primary,
                        "notify_telegram": cleaned.notify_telegram,
                        "notify_sms": cleaned.notify_sms,
                        "notify_call": cleaned.notify_call,
                    }
                )
                self._settings.recipients[idx] = merged
                self._save()
                return merged.model_copy(deep=True)

            self._settings.recipients.append(cleaned)
            self._save()
            return cleaned.model_copy(deep=True)

    def remove_recipient(self, recipient_id: str) -> bool:
        with self._lock:
            before = len(self._settings.recipients)
            self._settings.recipients = [
                r for r in self._settings.recipients if r.id != recipient_id and r.telegram_chat_id != recipient_id
            ]
            changed = len(self._settings.recipients) != before
            if changed:
                self._save()
            return changed

    def register_telegram_user(
        self,
        chat_id: str,
        name: str,
        username: str = "",
        phone: str = "",
    ) -> Recipient:
        cid = str(chat_id).strip()
        rec_id = f"tg_{cid}"
        return self.upsert_recipient(
            Recipient(
                id=rec_id,
                name=name.strip() or f"Telegram {cid}",
                phone=phone.strip(),
                telegram_chat_id=cid,
                telegram_username=normalize_telegram_username(username),
                enabled=True,
                notify_telegram=True,
                notify_sms=bool(phone.strip()),
                notify_call=True,
            )
        )

    def enabled_recipients(self) -> list[Recipient]:
        with self._lock:
            return [r.model_copy(deep=True) for r in self._settings.recipients if r.enabled]

    def seed_defaults_if_empty(
        self,
        chat_ids: Iterable[str],
        callmebot_users: Iterable[str],
        esp32_lan_ip: str = "",
    ) -> None:
        with self._lock:
            changed = False
            if esp32_lan_ip and not self._settings.esp32_lan_ip:
                self._settings.esp32_lan_ip = esp32_lan_ip
                changed = True
            if not self._settings.recipients:
                users = list(callmebot_users)
                for i, cid in enumerate(chat_ids):
                    uname = users[i] if i < len(users) else ""
                    self._settings.recipients.append(
                        Recipient(
                            id=f"env_tg_{i + 1}",
                            name=f"Người nhận #{i + 1}",
                            telegram_chat_id=cid.strip(),
                            telegram_username=normalize_telegram_username(uname),
                            enabled=True,
                        )
                    )
                    changed = True
                # Any extra CallMeBot users without chat IDs
                for j in range(len(list(chat_ids)), len(users)):
                    uname = users[j]
                    self._settings.recipients.append(
                        Recipient(
                            id=f"env_call_{j + 1}",
                            name=f"CallMeBot {uname}",
                            telegram_username=normalize_telegram_username(uname),
                            enabled=True,
                        )
                    )
                    changed = True
            if changed:
                self._save()

    # Alert records management
    def create_alert(self, record: AlertRecord) -> AlertRecord:
        with self._lock:
            self._alerts[record.alert_id] = record
            self._save()
            return record.model_copy(deep=True)

    def get_alert(self, alert_id: str) -> AlertRecord | None:
        with self._lock:
            rec = self._alerts.get(alert_id)
            return rec.model_copy(deep=True) if rec else None

    def get_latest_active_alert(self) -> AlertRecord | None:
        with self._lock:
            active = [a for a in self._alerts.values() if a.status == "active"]
            if not active:
                return None
            return active[-1].model_copy(deep=True)

    def list_recent_alerts(self, limit: int = 20) -> list[AlertRecord]:
        with self._lock:
            return [a.model_copy(deep=True) for a in list(self._alerts.values())[-limit:]][::-1]

    def update_alert(self, record: AlertRecord) -> AlertRecord:
        with self._lock:
            self._alerts[record.alert_id] = record
            self._save()
            return record.model_copy(deep=True)

    def mark_acknowledged(self, alert_id: str, by: str) -> AlertRecord | None:
        with self._lock:
            rec = self._alerts.get(alert_id)
            if not rec:
                return None
            if rec.status == "resolved":
                return rec.model_copy(deep=True)
            rec.status = "acknowledged"
            rec.acknowledged_by = by
            rec.acknowledged_at = utc_now_iso()
            self._save()
            return rec.model_copy(deep=True)

    def mark_resolved(self, alert_id: str, by: str, outcome: str) -> AlertRecord | None:
        with self._lock:
            rec = self._alerts.get(alert_id)
            if not rec:
                return None
            rec.status = "resolved"
            rec.resolved_by = by
            rec.resolved_outcome = outcome
            rec.resolved_at = utc_now_iso()
            if not rec.acknowledged_by:
                rec.acknowledged_by = by
                rec.acknowledged_at = rec.resolved_at
            self._save()
            return rec.model_copy(deep=True)

    @staticmethod
    def generate_alert_id() -> str:
        return f"fall_{int(time.time() * 1000)}"

    # Edge AI Human-in-the-Loop training samples
    def add_ai_sample(self, sample: AiTrainingSample) -> AiTrainingSample:
        with self._lock:
            sid = sample.sample_id or f"ai_{int(time.time() * 1000)}_{len(self._ai_samples) + 1}"
            stored = sample.model_copy(update={"sample_id": sid})
            # Avoid duplicate labeling for the same alert_id
            if stored.alert_id:
                self._ai_samples = [s for s in self._ai_samples if s.alert_id != stored.alert_id]
            self._ai_samples.append(stored)
            if len(self._ai_samples) > 2000:
                self._ai_samples = self._ai_samples[-2000:]
            self._save()
            return stored.model_copy(deep=True)

    def list_ai_samples(self, limit: int = 2000) -> list[AiTrainingSample]:
        with self._lock:
            return [s.model_copy(deep=True) for s in self._ai_samples[-limit:]]

    def ai_dataset_summary(self) -> dict[str, int]:
        with self._lock:
            counts = {"total": len(self._ai_samples), "STAND": 0, "SIT": 0, "LIE": 0, "FALL": 0, "false_alarms": 0}
            for s in self._ai_samples:
                if s.label in counts:
                    counts[s.label] += 1
                if s.is_false_alarm:
                    counts["false_alarms"] += 1
            return counts
