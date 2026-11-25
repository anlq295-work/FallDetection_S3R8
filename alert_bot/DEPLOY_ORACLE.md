# Hướng dẫn chạy Hearth Alert Bot 24/7 miễn phí trên Oracle Cloud Always Free

## Bước 1: Tạo máy ảo Ubuntu Always Free trên Oracle Cloud
1. Đăng ký / đăng nhập [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/).
2. Vào **Compute → Instances → Create Instance**:
   - **Image:** `Ubuntu 22.04` hoặc `Ubuntu 24.04` (Always Free Eligible).
   - **Shape:** `VM.Standard.A1.Flex` (Ampere ARM — miễn phí tới 4 OCPU / 24GB RAM; chọn **1 OCPU, 6GB RAM** là dư sức) hoặc `VM.Standard.E2.1.Micro` (AMD 1GB RAM).
   - **Networking:** Đảm bảo chọn **Assign a public IPv4 address**.
   - **SSH Keys:** Bấm **Save Private Key** để SSH vào máy chủ.
3. Mở cổng trên **Oracle Cloud Firewall (VCN Security List)**:
   - Ở trang chi tiết Instance → bấm vào tên **Subnet** → bấm vào **Default Security List** → **Add Ingress Rules**:
     - **Source CIDR:** `0.0.0.0/0`
     - **IP Protocol:** `TCP`
     - **Destination Port Range:** `8080` *(và thêm `80,443` nếu dùng tên miền HTTPS)*.

---

## Bước 2: Clone code & copy `.env` lên máy chủ
```bash
ssh -i <file_key.key> ubuntu@<ORACLE_PUBLIC_IP>

git clone https://github.com/anlq295-work/FallDetection_S3R8.git
cd FallDetection_S3R8/alert_bot
cp .env.example .env
nano .env
```
Điền các biến của bạn vào `.env` (đặc biệt nên đặt thêm `ALERT_BOT_API_KEY=<chuỗi_bí_mật>` khi chạy công khai trên Internet).

---

## Bước 3: Chạy 1 lệnh cài Docker & bật 24/7
- **Nếu dùng trực tiếp qua IP (`http://<ORACLE_PUBLIC_IP>:8080`):**
  ```bash
  bash alert_bot/deploy_oracle.sh
  ```
- **Nếu có tên miền riêng (tự động cấp chứng chỉ SSL HTTPS miễn phí bằng Caddy):**
  Trỏ bản ghi DNS `A` của tên miền (VD `bot.tenmien.id.vn`) về `<ORACLE_PUBLIC_IP>`, sau đó chạy:
  ```bash
  BOT_DOMAIN=bot.tenmien.id.vn bash alert_bot/deploy_oracle.sh
  ```

Script tự động cài Docker, mở luật `iptables` mặc định của Oracle Ubuntu, bật `restart: unless-stopped` (tự chạy lại nếu VPS reboot), và lưu bền vững danh bạ trong `alert_bot/data/settings.json`.

---

## Bước 4: Cập nhật URL 24/7 vào ESP32-S3 & Hearth App
1. Trong [src/config.h](../src/config.h): cập nhật `DEFAULT_ALERT_BOT_URL` (hỗ trợ cả `http://` lẫn `https://` qua `WiFiClientSecure`) và `DEFAULT_ALERT_BOT_API_KEY` (nếu có) rồi nạp lại firmware.
2. Trong [mobile_app/lib/core/models.dart](../mobile_app/lib/core/models.dart): cập nhật `kDefaultAlertBotUrl` (và `kDefaultAlertBotApiKey`) hoặc truyền lúc build:
   ```bash
   flutter build apk --release --dart-define=ALERT_BOT_URL=https://bot.tenmien.id.vn
   ```

## Lệnh quản trị nhanh trên VPS
```bash
# Xem log bot Telegram & cảnh báo theo thời gian thực
sudo docker logs -f hearth-alert-bot

# Cập nhật code mới nhất từ GitHub và khởi động lại
cd ~/FallDetection_S3R8 && git pull && cd alert_bot && sudo docker compose up -d --build
```
