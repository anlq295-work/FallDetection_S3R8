# Hearth Fall Alert Bot (`alert_bot/`)

Bot đa kênh **Telegram + SMS (SpeedSMS / Twilio) + Gọi điện tự động (CallMeBot Telegram Call miễn phí / Twilio Voice tiếng Việt)** cho hệ thống phát hiện té ngã **FallDetection_S3R8 (ESP32-S3 + Flutter Hearth App)**.

## Tính năng chính

1. **Telegram Bot tương tác 2 chiều (miễn phí):**
   - Gửi cảnh báo HTML đầy đủ thông số (tốc độ rơi ToF, động năng Radar, phòng, địa chỉ, mã cửa) kèm **nút bấm trực tiếp**:
     - `✅ Tôi đang tới / Đã xác nhận` (dừng leo thang tuần tự & thông báo cho cả gia đình)
     - `🟢 An toàn / Báo động giả` (đóng sự cố & tự gửi lệnh `CANCEL_ALARM` tắt còi ESP32 nếu cùng mạng LAN)
     - `🚑 Đã gọi 115`
   - Người thân tự đăng ký nhận cảnh báo bằng `/start` hoặc `/register Tên 0912345678` — không cần dò Chat ID thủ công.
   - Điều chỉnh cài đặt ngay trên Telegram bằng `/settings`, `/contacts`, `/test`, `/status`.
2. **Nhắn tin SMS tự động:**
   - **SpeedSMS Việt Nam** (nội địa VN) và **Twilio SMS** (quốc tế/VN, tự chuẩn hóa `09xx` → `+849xx`).
3. **Gọi điện báo động tự động:**
   - **CallMeBot Telegram Voice Call (MIỄN PHÍ 100%)**: gọi đổ chuông trực tiếp trên Telegram và đọc tiếng Việt lặp 3 lần (chỉ cần người nhận có `@username` Telegram và cấp quyền 1 lần tại `@CallMeBot_txtbot` / `https://api2.callmebot.com/txt/login.php`).
   - **Twilio Voice Call**: gọi điện thoại di động thật bằng TwiML TTS tiếng Việt (`vi-VN`, lặp 3 lần).
4. **2 chế độ phát cảnh báo (đồng bộ với Settings trong Flutter App):**
   - **Đồng thời (`simultaneous`):** gửi Telegram + SMS + Call cùng lúc tới toàn bộ người đã cài đặt.
   - **Tuần tự (`sequential`):** gọi người #1 trước; nếu sau `N` phút chưa ai bấm Xác nhận sẽ tự leo thang sang người #2, #3...

---

## Cài đặt & chạy nhanh

```bash
# 1. Cài dependencies
cd alert_bot
pip install -r requirements.txt

# 2. Tạo file cấu hình .env từ mẫu
copy .env.example .env
# Mở alert_bot/.env và điền TELEGRAM_BOT_TOKEN (và SpeedSMS / Twilio nếu dùng)

# 3. Chạy Bot Server (từ thư mục gốc dự án FallDetection_S3R8)
cd ..
python -m alert_bot.run
```

Server mặc định chạy tại `http://0.0.0.0:8080` (tài liệu API tương tác tại `http://localhost:8080/docs`).

### Kết nối với Hearth Mobile App & ESP32-S3

1. Mở **Hearth App → Cài đặt (Settings) → Người nhận cảnh báo (Alert contacts)**.
2. Mở mục **Cấu hình Bot Cảnh Báo (Telegram / SMS / Call)**:
   - Nhập **URL Bot Server** (ví dụ trong LAN: `http://192.168.1.50:8080`, hoặc URL public Cloudflare Tunnel/VPS `https://...`).
   - Nhập **API Key** (nếu bạn đặt `ALERT_BOT_API_KEY` trong `.env`).
   - Nhấn **Kiểm tra kết nối** → **Đồng bộ danh bạ** → **Gửi thử cảnh báo**.
3. Khi bạn lưu cài đặt trong App, App sẽ tự đồng bộ:
   - Danh sách người nhận (Tên, SĐT, Telegram Chat ID, Telegram `@username`, kênh bật/tắt của từng người) lên **Alert Bot Server** (`PUT /api/settings`).
   - Địa chỉ Bot URL, API Key, Telegram fallback & SĐT xuống **ESP32-S3** (qua BLE hoặc Wi-Fi LAN `POST /api/config`), giúp ESP32-S3 tự gửi cảnh báo độc lập ngay cả khi điện thoại không ở nhà.

---

## Chạy kiểm thử tự động

```bash
pytest alert_bot/tests -v
```
