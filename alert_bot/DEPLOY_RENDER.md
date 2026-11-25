# Hướng dẫn chạy Hearth Alert Bot 24/7 miễn phí trên Render (0đ, không cần thẻ Visa)

Dự án đã có sẵn file [render.yaml](../render.yaml) (Blueprint) và tự động hỗ trợ **Telegram Webhook** (`RENDER_EXTERNAL_URL`) + biến môi trường `PORT` của Render.

## Bước 1: Deploy tự động từ GitHub (2 phút)
1. Vào [dashboard.render.com](https://dashboard.render.com/) → đăng nhập bằng tài khoản **GitHub** (miễn phí, không yêu cầu thẻ tín dụng).
2. Bấm **New + → Blueprint**.
3. Chọn repository **`anlq295-work/FallDetection_S3R8`** → Render tự đọc file `render.yaml` ở thư mục gốc (`region: singapore`, gói `free`, Docker).
4. Render sẽ hỏi điền các biến môi trường — copy đúng các giá trị từ file `alert_bot/.env` trên máy bạn dán vào:
   - `TELEGRAM_BOT_TOKEN`
   - `TWILIO_ACCOUNT_SID`
   - `TWILIO_AUTH_TOKEN`
   - `TWILIO_FROM_NUMBER`
   - `TWILIO_VERIFY_SERVICE_SID`
   - `SENDGRID_API_KEY`
   - `SENDGRID_FROM_EMAIL`
   - *(Tuỳ chọn)* `TELEGRAM_DEFAULT_CHAT_IDS` (điền sẵn Chat ID của bạn, VD `5933462197`, để kể cả khi Render restart cũng tự có sẵn người nhận!).
   - *(Tuỳ chọn)* `ALERT_BOT_API_KEY` (để trống nếu chưa muốn khoá, hoặc đặt mã bí mật rồi gắn giống nhau vào App/ESP32).
5. Bấm **Apply** → chờ ~2 phút build xong là bạn có link cố định dạng:
   ```text
   https://hearth-alert-bot.onrender.com
   ```
   *(Server tự nhận `RENDER_EXTERNAL_URL` và tự đăng ký Telegram Webhook tại `/api/telegram/webhook`, không cần chạy long-polling hay sợ xung đột).*

## Bước 2: Giữ Render chạy 24/7 không bao giờ ngủ bằng UptimeRobot (0đ)
Gói Render Free tự ngủ sau 15 phút không có request. Để giữ online 24/7:
1. Vào [uptimerobot.com](https://uptimerobot.com/) → đăng ký miễn phí (không cần thẻ).
2. Bấm **Add New Monitor**:
   - **Monitor Type:** `HTTP(s)`
   - **URL:** `https://hearth-alert-bot.onrender.com/health`
   - **Monitoring Interval:** `5 minutes` (hoặc `10 minutes`)
3. Bấm **Create Monitor** → server sẽ luôn thức **24/7**, tắt máy tính của bạn đi bot Telegram và API cảnh báo vẫn chạy bình thường!

## Bước 3: Gắn link Render vào ESP32-S3 & Hearth App
Khi Render deploy xong và bạn mở `https://<ten-app>.onrender.com/health` thấy `status: "ok"`:
- Nhớ **tắt bot chạy local** trên máy tính (tránh tranh chấp Telegram).
- Gửi link `https://<ten-app>.onrender.com` đó để cập nhật vào [src/config.h](../src/config.h) (`DEFAULT_ALERT_BOT_URL`) và [mobile_app/lib/core/models.dart](../mobile_app/lib/core/models.dart) (`kDefaultAlertBotUrl`) là xong!
