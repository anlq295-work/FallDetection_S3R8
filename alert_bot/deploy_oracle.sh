#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Hearth Fall Alert Bot — Oracle Cloud Always Free (Ubuntu ARM64/AMD64) Setup
# Chạy trên máy chủ Oracle Cloud:
#   bash alert_bot/deploy_oracle.sh
# Hoặc bật kèm HTTPS tự động (khi đã trỏ DNS tên miền về IP máy chủ):
#   BOT_DOMAIN=bot.tenmiencuaban.com bash alert_bot/deploy_oracle.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[1/5] Kiểm tra file cấu hình .env..."
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  echo "  -> Đã tạo alert_bot/.env từ mẫu."
  echo "  -> Hãy điền TELEGRAM_BOT_TOKEN, TWILIO_*, SENDGRID_* vào alert_bot/.env rồi chạy lại script này!"
  exit 1
fi

mkdir -p data

echo "[2/5] Kiểm tra Docker & Docker Compose..."
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
fi

if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y docker-compose-plugin
fi

echo "[3/5] Mở cổng tường lửa Ubuntu trên Oracle Cloud (8080, 80, 443)..."
if command -v iptables >/dev/null 2>&1; then
  for port in 8080 80 443; do
    if ! sudo iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
      sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport "$port" -j ACCEPT || true
    fi
  done
  if command -v netfilter-persistent >/dev/null 2>&1; then
    sudo netfilter-persistent save || true
  fi
fi

echo "[4/5] Khởi chạy Hearth Alert Bot 24/7 bằng Docker Compose..."
if [[ -n "${BOT_DOMAIN:-}" ]]; then
  echo "  -> Bật HTTPS tự động (Caddy Let's Encrypt) cho tên miền: $BOT_DOMAIN"
  sudo BOT_DOMAIN="$BOT_DOMAIN" docker compose --profile https up -d --build
else
  sudo docker compose up -d --build
fi

echo "[5/5] Kiểm tra sức khỏe server (/health)..."
sleep 4
curl -fsS http://127.0.0.1:8080/health
echo ""
echo "================================================================="
echo "  Hearth Alert Bot đã chạy 24/7!"
if [[ -n "${BOT_DOMAIN:-}" ]]; then
  echo "  URL công khai: https://${BOT_DOMAIN}"
else
  PUB_IP="$(curl -fsS https://ifconfig.me 2>/dev/null || echo '<ORACLE_PUBLIC_IP>')"
  echo "  URL công khai: http://${PUB_IP}:8080"
fi
echo "  Xem log realtime: sudo docker logs -f hearth-alert-bot"
echo "================================================================="
