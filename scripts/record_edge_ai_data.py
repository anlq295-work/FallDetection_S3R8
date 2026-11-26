#!/usr/bin/env python3
"""
Hearth FallDetection_S3R8 — Real-World Edge AI Dataset Recorder
===============================================================
Thu thập trực tiếp 12 đặc trưng cảm biến thực tế từ ESP32-S3 (qua USB Serial hoặc Wi-Fi LAN)
với nhãn lớp (STAND / SIT / LIE / FALL) để lưu vào `edge_ai_data/dataset.csv`
và tùy chọn đẩy lên server Render (`/api/ai/samples`).

Ví dụ:
  # Thu 30 mẫu tư thế NGỒI NHANH qua Wi-Fi LAN của ESP32:
  python scripts/record_edge_ai_data.py --esp-ip 192.168.1.50 --label SIT --count 30

  # Thu 40 mẫu TÉ NGÃ (diễn tập trên đệm) qua cổng USB Serial COM10:
  python scripts/record_edge_ai_data.py --serial COM10 --label FALL --count 40

  # Thu và đẩy thẳng lên Render Cloud:
  python scripts/record_edge_ai_data.py --esp-ip 192.168.1.50 --label SIT --count 20 --push-url https://hearth-alert-bot.onrender.com
"""
from __future__ import annotations

import argparse
import csv
import json
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

FEATURE_NAMES = [
    "max_motion",
    "max_static",
    "tof_high",
    "tof_mid",
    "tof_low",
    "drop_rate",
    "radar_dist",
    "max_drop_rate",
    "post_motion_mean",
    "post_static_mean",
    "radar_gate_spread",
    "height_drop_delta",
]
VALID_LABELS = {"STAND", "SIT", "LIE", "FALL"}


def append_csv(csv_path: Path, rows: list[tuple[list[float], str, str]]) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    write_header = not csv_path.exists()
    with csv_path.open("a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow(["timestamp", "label", "note", "weight", *FEATURE_NAMES])
        for feats, label, note in rows:
            ts = datetime.now(timezone.utc).isoformat()
            writer.writerow([ts, label, note, "2.5", *[f"{v:.4f}" for v in feats]])


def push_to_render(push_url: str, label: str, note: str, rows: list[tuple[list[float], str, str]], api_key: str = "") -> int:
    url = push_url.rstrip("/") + "/api/ai/samples"
    pushed = 0
    for feats, lbl, nt in rows:
        payload = json.dumps({
            "label": lbl,
            "features": feats,
            "source": "recorder_cli",
            "note": nt,
            "is_false_alarm": False,
        }).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["X-API-Key"] = api_key
        req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                pushed += 1
    return pushed


def record_from_lan(esp_ip: str, label: str, note: str, count: int, interval: float) -> list[tuple[list[float], str, str]]:
    url = f"http://{esp_ip}/api/ai"
    rows: list[tuple[list[float], str, str]] = []
    print(f"[LAN] Bắt đầu thu {count} mẫu nhãn [{label}] từ {url} ...")
    for i in range(count):
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        feats = [float(x) for x in data.get("features", [])]
        if len(feats) != len(FEATURE_NAMES):
            print(f"  [!] Bỏ qua mẫu #{i + 1}: thiếu đặc trưng ({len(feats)})")
            continue
        rows.append((feats, label, note))
        print(
            f"  [{i + 1}/{count}] {label} | mot={feats[0]:.0f} stat={feats[1]:.0f} "
            f"tof=({feats[2]:.0f},{feats[3]:.0f},{feats[4]:.0f}) drop={feats[5]:.0f}/{feats[7]:.0f} gates={feats[10]:.0f}"
        )
        if i + 1 < count:
            time.sleep(interval)
    return rows


def record_from_serial(port: str, baud: int, label: str, note: str, count: int) -> list[tuple[list[float], str, str]]:
    import serial  # type: ignore

    rows: list[tuple[list[float], str, str]] = []
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = baud
    ser.dtr = False
    ser.rts = False
    ser.timeout = 1.0
    ser.open()
    try:
        # Gửi lệnh 'R' để bật chế độ stream [AI_CSV] trên ESP32-S3
        ser.write(b"R")
        print(f"[SERIAL] Đã bật stream [AI_CSV] trên {port}. Đang thu {count} mẫu nhãn [{label}] ...")
        while len(rows) < count:
            raw = ser.readline().decode("utf-8", errors="replace").strip()
            if not raw.startswith("[AI_CSV]"):
                continue
            parts = raw.removeprefix("[AI_CSV]").strip().split(",")
            if len(parts) != len(FEATURE_NAMES):
                continue
            try:
                feats = [float(x) for x in parts]
            except ValueError:
                continue
            rows.append((feats, label, note))
            print(
                f"  [{len(rows)}/{count}] {label} | mot={feats[0]:.0f} stat={feats[1]:.0f} "
                f"tof=({feats[2]:.0f},{feats[3]:.0f},{feats[4]:.0f}) drop={feats[5]:.0f}/{feats[7]:.0f}"
            )
    finally:
        # Gửi lại 'R' để tắt stream gọn gàng
        ser.write(b"R")
        ser.close()
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Record real labeled Edge AI samples from ESP32-S3")
    parser.add_argument("--label", required=True, choices=sorted(VALID_LABELS), help="Ground-truth class label")
    parser.add_argument("--esp-ip", type=str, default="", help="ESP32-S3 LAN IP (e.g. 192.168.1.50)")
    parser.add_argument("--serial", type=str, default="", help="USB Serial port (e.g. COM10)")
    parser.add_argument("--baud", type=int, default=115200, help="Serial baud rate")
    parser.add_argument("--count", type=int, default=25, help="Number of samples to record")
    parser.add_argument("--interval", type=float, default=0.35, help="Seconds between LAN samples")
    parser.add_argument("--note", type=str, default="", help="Optional scenario note (e.g. fast_sit_chair)")
    parser.add_argument("--out", type=Path, default=Path("edge_ai_data/dataset.csv"), help="Output CSV path")
    parser.add_argument("--push-url", type=str, default="", help="Optional Render Bot URL to push samples")
    parser.add_argument("--api-key", type=str, default="", help="Optional X-API-Key for Render Bot")
    args = parser.parse_args()

    if not args.esp_ip and not args.serial:
        parser.error("Cần truyền --esp-ip <IP> hoặc --serial <COM10>")

    rows = (
        record_from_lan(args.esp_ip, args.label, args.note, args.count, args.interval)
        if args.esp_ip
        else record_from_serial(args.serial, args.baud, args.label, args.note, args.count)
    )
    if not rows:
        print("[WARN] Không thu được mẫu nào.")
        return 1

    append_csv(args.out, rows)
    print(f"[OK] Đã lưu {len(rows)} mẫu vào {args.out}")

    if args.push_url:
        pushed = push_to_render(args.push_url, args.label, args.note, rows, args.api_key)
        print(f"[CLOUD] Đã đồng bộ {pushed}/{len(rows)} mẫu lên {args.push_url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
