#!/usr/bin/env python3
"""
Hearth FallDetection_S3R8 — Edge AI Trainer & C Header Exporter
===============================================================
Huấn luyện mạng nơ-ron MLP (12 -> 24 -> 12 -> 4) bằng NumPy (Adam + Class-Weighted Cross-Entropy
+ L2 Weight Decay + Hard-Negative Oversampling) và xuất trực tiếp sang `src/model_data.h` cho ESP32-S3.

12 đặc trưng đầu vào (khớp tuyệt đối với `SensorManager::extractFeatures` trong `src/sensors.cpp`):
  0: max_motion        (0..100)    Đỉnh động năng radar 2s
  1: max_static        (0..100)    Đỉnh tĩnh năng radar 2s
  2: tof_high          (mm)        ToF vùng Cao
  3: tof_mid           (mm)        ToF vùng Giữa
  4: tof_low           (mm)        ToF vùng Thấp
  5: drop_rate         (mm/s)      Tốc độ rơi TB cửa sổ 2s
  6: radar_dist        (cm)        Cự ly mục tiêu radar
  7: max_drop_rate     (mm/s)      Tốc độ rơi đỉnh cửa sổ con 0.5s
  8: post_motion_mean  (0..100)    Động năng TB 0.5s cuối
  9: post_static_mean  (0..100)    Tĩnh năng TB 0.5s cuối
 10: radar_gate_spread (0..9)      Số cổng radar hoạt động (năng lượng >= 20)
 11: height_drop_delta (mm)        Tổng độ sụt giảm chiều cao trong 2s

Các lớp đầu ra (khớp `enum AIClass` trong `src/config.h`):
  0: STAND  (đứng / đi lại / phòng trống / nhiễu nhẹ)
  1: SIT    (ngồi / ngồi nhanh xuống ghế / làm rơi đồ)
  2: LIE    (nằm chậm lên giường / sàn)
  3: FALL   (té ngã va chạm mạnh hoặc ngã trượt)

Ví dụ chạy:
  # 1) Huấn luyện khởi tạo (bootstrap vật lý + hard-negatives) -> xuất src/model_data.h:
  python scripts/train_edge_ai.py

  # 2) Kéo thêm nhãn phản hồi thật từ Render + ghép CSV thu tại nhà rồi huấn luyện lại:
  python scripts/train_edge_ai.py --pull-url https://hearth-alert-bot.onrender.com --csv edge_ai_data/dataset.csv
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np

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
CLASS_NAMES = ["STAND", "SIT", "LIE", "FALL"]
LABEL_TO_IDX = {
    "STAND": 0,
    "EMPTY": 0,
    "WALK": 0,
    "NOISE": 0,
    "NORMAL": 0,
    "SIT": 1,
    "FAST_SIT": 1,
    "DROPPED_OBJECT": 1,
    "FALSE_ALARM": 1,
    "LIE": 2,
    "SLEEP": 2,
    "FALL": 3,
    "TRUE_FALL": 3,
    "FALL_IMPACT": 3,
    "SLOW_FALL": 3,
}


def generate_physics_bootstrap(n_per_class: int = 500, seed: int = 42) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Sinh tập dữ liệu vật lý thực tế (gồm cả hard-negatives: ngồi nhanh, rơi đồ, thú cưng/quạt)."""
    rng = np.random.default_rng(seed)
    xs: list[np.ndarray] = []
    ys: list[int] = []
    ws: list[float] = []

    def clip_feat(v: list[float]) -> np.ndarray:
        arr = np.array(v, dtype=np.float32)
        arr[0] = np.clip(arr[0], 0, 100)
        arr[1] = np.clip(arr[1], 0, 100)
        arr[2] = np.clip(arr[2], 0, 3800)
        arr[3] = np.clip(arr[3], 0, 3800)
        arr[4] = np.clip(arr[4], 0, 3800)
        arr[5] = np.clip(arr[5], 0, 2500)
        arr[6] = np.clip(arr[6], 0, 600)
        arr[7] = np.clip(arr[7], 0, 3500)
        arr[8] = np.clip(arr[8], 0, 100)
        arr[9] = np.clip(arr[9], 0, 100)
        arr[10] = np.clip(arr[10], 0, 9)
        arr[11] = np.clip(arr[11], 0, 2200)
        return arr

    # --- CLASS 0: STAND (đứng, đi lại, phòng trống, quạt/rèm nhiễu) ---
    for i in range(n_per_class):
        mode = i % 4
        if mode == 0:  # Đứng yên / đi chậm
            h = rng.normal(1350, 220)
            mot = rng.normal(28, 14)
            stat = rng.normal(35, 15)
            xs.append(clip_feat([
                mot, stat, h, h - rng.normal(80, 40), h - rng.normal(140, 60),
                rng.uniform(0, 120), rng.normal(160, 60), rng.uniform(0, 200),
                mot * rng.uniform(0.5, 1.0), stat * rng.uniform(0.7, 1.0),
                rng.integers(2, 5), rng.uniform(0, 180),
            ]))
        elif mode == 1:  # Đi lại nhanh (động năng cao nhưng không sụt chiều cao)
            h = rng.normal(1250, 200)
            mot = rng.normal(68, 16)
            stat = rng.normal(40, 15)
            xs.append(clip_feat([
                mot, stat, h, h - rng.normal(60, 40), h - rng.normal(100, 60),
                rng.uniform(0, 220), rng.normal(170, 70), rng.uniform(50, 360),
                rng.normal(52, 16), stat * rng.uniform(0.6, 1.0),
                rng.integers(3, 7), rng.uniform(0, 260),
            ]))
        elif mode == 2:  # Phòng trống / ToF 0
            xs.append(clip_feat([
                rng.uniform(0, 12), rng.uniform(0, 12), 0, 0, 0,
                0, rng.uniform(0, 40), 0, rng.uniform(0, 10), rng.uniform(0, 10),
                rng.integers(0, 2), 0,
            ]))
        else:  # Nhiễu quạt / thú cưng (hard-negative: động năng có thể cao nhưng 1-2 cổng & độ cao không rơi)
            xs.append(clip_feat([
                rng.normal(45, 18), rng.normal(18, 10),
                rng.normal(1900, 300), rng.normal(1800, 300), rng.normal(1200, 350),
                rng.uniform(0, 180), rng.normal(240, 90), rng.uniform(0, 320),
                rng.normal(38, 15), rng.normal(15, 8),
                rng.integers(1, 3), rng.uniform(0, 200),
            ]))
        ys.append(0)
        ws.append(1.0)

    # --- CLASS 1: SIT (ngồi bình thường + HARD-NEGATIVE ngồi mạnh xuống ghế + làm rơi đồ) ---
    for i in range(n_per_class):
        mode = i % 3
        if mode == 0:  # Ngồi yên bình thường
            h_mid = rng.normal(680, 100)
            mot = rng.normal(22, 12)
            stat = rng.normal(45, 15)
            xs.append(clip_feat([
                mot, stat, h_mid + rng.normal(350, 120), h_mid, h_mid - rng.normal(90, 40),
                rng.uniform(40, 260), rng.normal(145, 50), rng.uniform(80, 380),
                rng.normal(15, 8), stat * rng.uniform(0.75, 1.0),
                rng.integers(2, 5), rng.uniform(120, 420),
            ]))
            ws.append(1.0)
        elif mode == 1:  # HARD-NEGATIVE: Ngồi phịch nhanh xuống ghế (tốc độ rơi cao ~450-680mm/s nhưng dừng ở 520-760mm!)
            h_mid = rng.normal(640, 80)
            mot = rng.normal(58, 14)
            stat = rng.normal(48, 14)
            delta = rng.uniform(350, 560)
            xs.append(clip_feat([
                mot, stat, h_mid + rng.normal(450, 150), h_mid, h_mid - rng.normal(70, 35),
                delta / 2.0, rng.normal(150, 45), rng.uniform(480, 780),
                rng.normal(28, 12), stat * rng.uniform(0.75, 1.0),
                rng.integers(2, 5), delta,
            ]))
            ws.append(1.8)
        else:  # HARD-NEGATIVE: Làm rơi đồ vật xuống sàn (tốc độ rơi nhanh nhưng post_static rất thấp / ít cổng)
            xs.append(clip_feat([
                rng.normal(48, 16), rng.normal(12, 7),
                rng.normal(1300, 250), rng.normal(1100, 250), rng.normal(380, 100),
                rng.uniform(250, 520), rng.normal(160, 60), rng.uniform(550, 1100),
                rng.normal(32, 14), rng.normal(8, 5),
                rng.integers(1, 3), rng.uniform(400, 800),
            ]))
            ws.append(1.8)
        ys.append(1)

    # --- CLASS 2: LIE (nằm chậm lên giường/sàn — không có xung va chạm mạnh) ---
    for i in range(n_per_class):
        h_low = rng.normal(320, 85)
        mot = rng.normal(18, 10)
        stat = rng.normal(48, 16)
        delta = rng.uniform(50, 380)
        xs.append(clip_feat([
            mot, stat, rng.normal(1950, 350), rng.normal(1600, 350), h_low,
            delta / 2.0, rng.normal(165, 55), rng.uniform(40, 340),
            rng.normal(8, 5), stat * rng.uniform(0.7, 1.0),
            rng.integers(2, 6), delta,
        ]))
        ys.append(2)
        ws.append(1.0)

    # --- CLASS 3: FALL (té ngã va chạm mạnh + ngã trượt bất động sát sàn) ---
    for i in range(n_per_class):
        mode = i % 3
        if mode in (0, 1):  # Té ngã va chạm điển hình
            h_low = rng.normal(250, 90)
            mot = rng.normal(82, 13)
            stat = rng.normal(46, 15)
            delta = rng.uniform(720, 1350)
            xs.append(clip_feat([
                mot, stat, rng.normal(2200, 350), rng.normal(1850, 350), h_low,
                delta / 2.0, rng.normal(160, 55), rng.uniform(850, 2100),
                rng.normal(11, 7), rng.normal(36, 12),
                rng.integers(4, 9), delta,
            ]))
        else:  # Té ngã từ tư thế ngồi hoặc ngã trượt có xung trung bình-mạnh
            h_low = rng.normal(280, 95)
            mot = rng.normal(64, 12)
            stat = rng.normal(42, 14)
            delta = rng.uniform(520, 950)
            xs.append(clip_feat([
                mot, stat, rng.normal(2050, 350), rng.normal(1650, 350), h_low,
                delta / 2.0, rng.normal(155, 50), rng.uniform(620, 1300),
                rng.normal(10, 6), rng.normal(34, 11),
                rng.integers(3, 8), delta,
            ]))
        ys.append(3)
        ws.append(1.5)  # Ưu tiên Recall bắt ngã

    return np.vstack(xs), np.array(ys, dtype=np.int64), np.array(ws, dtype=np.float32)


def load_csv_dataset(csv_path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    if not csv_path.exists():
        return np.empty((0, len(FEATURE_NAMES)), dtype=np.float32), np.empty((0,), dtype=np.int64), np.empty((0,), dtype=np.float32)
    xs: list[list[float]] = []
    ys: list[int] = []
    ws: list[float] = []
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            raw_label = (row.get("label") or "").strip().upper()
            if raw_label not in LABEL_TO_IDX:
                continue
            try:
                feats = [float(row[k]) for k in FEATURE_NAMES]
            except (KeyError, ValueError, TypeError):
                continue
            weight = float(row.get("weight") or 2.5)
            xs.append(feats)
            ys.append(LABEL_TO_IDX[raw_label])
            ws.append(weight)
    if not xs:
        return np.empty((0, len(FEATURE_NAMES)), dtype=np.float32), np.empty((0,), dtype=np.int64), np.empty((0,), dtype=np.float32)
    return np.array(xs, dtype=np.float32), np.array(ys, dtype=np.int64), np.array(ws, dtype=np.float32)


def pull_remote_dataset(base_url: str, api_key: str = "") -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    url = base_url.rstrip("/") + "/api/ai/dataset"
    headers = {"Accept": "application/json"}
    if api_key:
        headers["X-API-Key"] = api_key
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    samples = data.get("samples", [])
    xs: list[list[float]] = []
    ys: list[int] = []
    ws: list[float] = []
    for s in samples:
        raw_label = str(s.get("label", "")).strip().upper()
        if raw_label not in LABEL_TO_IDX:
            continue
        feats = s.get("features") or []
        if len(feats) != len(FEATURE_NAMES):
            continue
        xs.append([float(v) for v in feats])
        ys.append(LABEL_TO_IDX[raw_label])
        # Hard-negative / real user feedback gets 3x weight so model learns fast from real room errors
        ws.append(3.5 if s.get("is_false_alarm") else 3.0)
    if not xs:
        return np.empty((0, len(FEATURE_NAMES)), dtype=np.float32), np.empty((0,), dtype=np.int64), np.empty((0,), dtype=np.float32)
    return np.array(xs, dtype=np.float32), np.array(ys, dtype=np.int64), np.array(ws, dtype=np.float32)


def softmax(logits: np.ndarray) -> np.ndarray:
    shifted = logits - np.max(logits, axis=1, keepdims=True)
    exps = np.exp(shifted)
    return exps / np.sum(exps, axis=1, keepdims=True)


def train_mlp(
    X_train: np.ndarray,
    y_train: np.ndarray,
    w_train: np.ndarray,
    X_val: np.ndarray,
    y_val: np.ndarray,
    epochs: int = 260,
    lr: float = 0.008,
    weight_decay: float = 1e-4,
    batch_size: int = 64,
    seed: int = 42,
) -> dict[str, np.ndarray]:
    rng = np.random.default_rng(seed)
    n_in, h1, h2, n_out = X_train.shape[1], 24, 12, 4

    # He initialization for ReLU layers
    params = {
        "W1": (rng.standard_normal((n_in, h1)) * np.sqrt(2.0 / n_in)).astype(np.float32),
        "b1": np.zeros(h1, dtype=np.float32),
        "W2": (rng.standard_normal((h1, h2)) * np.sqrt(2.0 / h1)).astype(np.float32),
        "b2": np.zeros(h2, dtype=np.float32),
        "W3": (rng.standard_normal((h2, n_out)) * np.sqrt(2.0 / h2)).astype(np.float32),
        "b3": np.zeros(n_out, dtype=np.float32),
    }
    m = {k: np.zeros_like(v) for k, v in params.items()}
    v = {k: np.zeros_like(v) for k, v in params.items()}
    beta1, beta2, eps = 0.9, 0.999, 1e-8

    best_score = -1.0
    best_params = {k: val.copy() for k, val in params.items()}
    step = 0
    n = X_train.shape[0]

    for epoch in range(1, epochs + 1):
        perm = rng.permutation(n)
        for start in range(0, n, batch_size):
            idx = perm[start : start + batch_size]
            xb, yb, wb = X_train[idx], y_train[idx], w_train[idx]
            bs = xb.shape[0]

            # Forward
            z1 = xb @ params["W1"] + params["b1"]
            a1 = np.maximum(0.0, z1)
            z2 = a1 @ params["W2"] + params["b2"]
            a2 = np.maximum(0.0, z2)
            logits = a2 @ params["W3"] + params["b3"]
            probs = softmax(logits)

            # Weighted cross-entropy gradient
            dlogits = probs.copy()
            dlogits[np.arange(bs), yb] -= 1.0
            w_norm = (wb / np.sum(wb))[:, None]
            dlogits *= w_norm

            grads = {
                "W3": a2.T @ dlogits + weight_decay * params["W3"],
                "b3": np.sum(dlogits, axis=0),
            }
            da2 = dlogits @ params["W3"].T
            dz2 = da2 * (z2 > 0)
            grads["W2"] = a1.T @ dz2 + weight_decay * params["W2"]
            grads["b2"] = np.sum(dz2, axis=0)

            da1 = dz2 @ params["W2"].T
            dz1 = da1 * (z1 > 0)
            grads["W1"] = xb.T @ dz1 + weight_decay * params["W1"]
            grads["b1"] = np.sum(dz1, axis=0)

            step += 1
            for k in params:
                m[k] = beta1 * m[k] + (1 - beta1) * grads[k]
                v[k] = beta2 * v[k] + (1 - beta2) * (grads[k] ** 2)
                m_hat = m[k] / (1 - beta1 ** step)
                v_hat = v[k] / (1 - beta2 ** step)
                params[k] -= lr * m_hat / (np.sqrt(v_hat) + eps)

        if epoch % 10 == 0 or epoch == epochs:
            val_probs = forward_mlp(X_val, params)
            val_preds = np.argmax(val_probs, axis=1)
            acc = float(np.mean(val_preds == y_val))
            fall_mask = y_val == 3
            fall_recall = float(np.mean(val_preds[fall_mask] == 3)) if np.any(fall_mask) else acc
            non_fall_mask = y_val != 3
            far = float(np.mean(val_preds[non_fall_mask] == 3)) if np.any(non_fall_mask) else 0.0
            # Objective prioritizes high Fall Recall + low False Alarm Rate + overall accuracy
            score = 0.50 * fall_recall + 0.30 * acc + 0.20 * (1.0 - far)
            if score > best_score:
                best_score = score
                best_params = {k: val.copy() for k, val in params.items()}

    return best_params


def forward_mlp(X: np.ndarray, params: dict[str, np.ndarray]) -> np.ndarray:
    a1 = np.maximum(0.0, X @ params["W1"] + params["b1"])
    a2 = np.maximum(0.0, a1 @ params["W2"] + params["b2"])
    return softmax(a2 @ params["W3"] + params["b3"])


def format_c_1d(name: str, arr: np.ndarray) -> str:
    vals = ", ".join(f"{float(x):.6f}f" for x in arr)
    return f"static const float {name}[{len(arr)}] = {{{vals}}};"


def format_c_2d(name: str, arr: np.ndarray) -> str:
    rows, cols = arr.shape
    lines = [f"static const float {name}[{rows}][{cols}] = {{"]
    for r in range(rows):
        vals = ", ".join(f"{float(x):.6f}f" for x in arr[r])
        comma = "," if r < rows - 1 else ""
        lines.append(f"  {{{vals}}}{comma}")
    lines.append("};")
    return "\n".join(lines)


def export_model_header(
    out_path: Path,
    model_version: str,
    means: np.ndarray,
    stds: np.ndarray,
    params: dict[str, np.ndarray],
    metrics: dict[str, Any],
    nn_weight: float,
) -> None:
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    content = f"""#ifndef MODEL_DATA_H
#define MODEL_DATA_H

// =========================================================================
// AUTO-GENERATED BY scripts/train_edge_ai.py — DO NOT EDIT WEIGHTS BY HAND
// Model Version : {model_version}
// Generated UTC : {generated_at}
// Architecture  : 12 -> 24 (ReLU) -> 12 (ReLU) -> 4 (Softmax: STAND/SIT/LIE/FALL)
// Val Accuracy  : {metrics['accuracy']:.4f} | Fall Recall: {metrics['fall_recall']:.4f} | FAR: {metrics['false_alarm_rate']:.4f}
// Real Samples  : {metrics['real_samples']} | Total Samples: {metrics['total_samples']}
// =========================================================================

#define EDGE_AI_MODEL_VERSION    "{model_version}"
#define EDGE_AI_INPUT_DIM        12
#define EDGE_AI_HIDDEN1_DIM      24
#define EDGE_AI_HIDDEN2_DIM      12
#define EDGE_AI_OUTPUT_DIM       4
#define EDGE_AI_NN_WEIGHT        {nn_weight:.2f}f
#define EDGE_AI_FALL_CONF_THRESH 0.62f

{format_c_1d("EDGE_AI_MEANS", means)}
{format_c_1d("EDGE_AI_STDS", stds)}

{format_c_2d("EDGE_AI_W1", params["W1"])}
{format_c_1d("EDGE_AI_B1", params["b1"])}

{format_c_2d("EDGE_AI_W2", params["W2"])}
{format_c_1d("EDGE_AI_B2", params["b2"])}

{format_c_2d("EDGE_AI_WOUT", params["W3"])}
{format_c_1d("EDGE_AI_BOUT", params["b3"])}

#endif // MODEL_DATA_H
"""
    out_path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Train Hearth Edge AI MLP and export src/model_data.h")
    parser.add_argument("--csv", type=Path, default=Path("edge_ai_data/dataset.csv"), help="Local CSV dataset path")
    parser.add_argument("--pull-url", type=str, default="", help="Render/Bot URL to pull labeled feedback samples")
    parser.add_argument("--api-key", type=str, default="", help="Optional X-API-Key for Render Bot")
    parser.add_argument("--out", type=Path, default=Path("src/model_data.h"), help="Output C header path")
    parser.add_argument("--bootstrap-per-class", type=int, default=450, help="Physics bootstrap samples per class")
    parser.add_argument("--epochs", type=int, default=260, help="Training epochs")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    args = parser.parse_args()

    real_X_parts: list[np.ndarray] = []
    real_y_parts: list[np.ndarray] = []
    real_w_parts: list[np.ndarray] = []

    if args.csv.exists():
        cx, cy, cw = load_csv_dataset(args.csv)
        if len(cy) > 0:
            print(f"[DATA] Loaded {len(cy)} real samples from {args.csv}")
            real_X_parts.append(cx)
            real_y_parts.append(cy)
            real_w_parts.append(cw)

    if args.pull_url:
        try:
            rx, ry, rw = pull_remote_dataset(args.pull_url, args.api_key)
            print(f"[DATA] Pulled {len(ry)} labeled feedback samples from {args.pull_url}")
            if len(ry) > 0:
                real_X_parts.append(rx)
                real_y_parts.append(ry)
                real_w_parts.append(rw)
        except Exception as exc:
            print(f"[WARN] Could not pull remote dataset from {args.pull_url}: {exc}", file=sys.stderr)

    real_count = sum(len(y) for y in real_y_parts)
    X_parts = list(real_X_parts)
    y_parts = list(real_y_parts)
    w_parts = list(real_w_parts)

    # Keep physics bootstrap whenever real data is small so every class stays well-represented
    if args.bootstrap_per_class > 0:
        bx, by, bw = generate_physics_bootstrap(n_per_class=args.bootstrap_per_class, seed=args.seed)
        X_parts.append(bx)
        y_parts.append(by)
        w_parts.append(bw)

    X_all = np.vstack(X_parts)
    y_all = np.concatenate(y_parts)
    w_all = np.concatenate(w_parts)

    # Stratified 80/20 split
    rng = np.random.default_rng(args.seed)
    train_idx: list[int] = []
    val_idx: list[int] = []
    for c in range(4):
        c_idx = np.where(y_all == c)[0]
        rng.shuffle(c_idx)
        cut = max(1, int(len(c_idx) * 0.8))
        train_idx.extend(c_idx[:cut].tolist())
        val_idx.extend(c_idx[cut:].tolist())

    X_tr, y_tr, w_tr = X_all[train_idx], y_all[train_idx], w_all[train_idx]
    X_va, y_va = X_all[val_idx], y_all[val_idx]

    means = np.mean(X_tr, axis=0).astype(np.float32)
    stds = np.std(X_tr, axis=0).astype(np.float32)
    stds = np.where(stds < 1e-3, 1.0, stds).astype(np.float32)

    X_tr_n = (X_tr - means) / stds
    X_va_n = (X_va - means) / stds

    params = train_mlp(X_tr_n, y_tr, w_tr, X_va_n, y_va, epochs=args.epochs, seed=args.seed)
    val_probs = forward_mlp(X_va_n, params)
    val_preds = np.argmax(val_probs, axis=1)

    accuracy = float(np.mean(val_preds == y_va))
    fall_tp = int(np.sum((y_va == 3) & (val_preds == 3)))
    fall_fn = int(np.sum((y_va == 3) & (val_preds != 3)))
    fall_fp = int(np.sum((y_va != 3) & (val_preds == 3)))
    non_fall = int(np.sum(y_va != 3))
    fall_recall = fall_tp / max(1, fall_tp + fall_fn)
    fall_precision = fall_tp / max(1, fall_tp + fall_fp)
    fall_f1 = 2 * fall_precision * fall_recall / max(1e-9, fall_precision + fall_recall)
    far = fall_fp / max(1, non_fall)

    # Increase neural weight automatically as real labeled samples grow
    nn_weight = 0.55 if real_count >= 100 else (0.45 if real_count >= 20 else 0.40)
    version = f"mlp12-v{datetime.now(timezone.utc).strftime('%Y%m%d')}-r{real_count}"

    metrics = {
        "accuracy": accuracy,
        "fall_recall": fall_recall,
        "fall_precision": fall_precision,
        "fall_f1": fall_f1,
        "false_alarm_rate": far,
        "real_samples": real_count,
        "total_samples": int(len(y_all)),
    }
    export_model_header(args.out, version, means, stds, params, metrics, nn_weight)

    print("=== EDGE AI TRAINING REPORT ===")
    print(f"Model Version    : {version}")
    print(f"Samples          : total={len(y_all)} (real={real_count}, bootstrap={len(y_all) - real_count})")
    print(f"Val Accuracy     : {accuracy * 100:.2f}%")
    print(f"Fall Recall      : {fall_recall * 100:.2f}% (TP={fall_tp}, FN={fall_fn})")
    print(f"Fall Precision   : {fall_precision * 100:.2f}% (FP={fall_fp})")
    print(f"Fall F1-Score    : {fall_f1 * 100:.2f}%")
    print(f"False Alarm Rate : {far * 100:.2f}%")
    print(f"NN Fusion Weight : {nn_weight:.2f}")
    print(f"Exported Header  : {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
