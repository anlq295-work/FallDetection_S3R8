# Fall Guard S3R8 - Mobile App (Android & iOS)

Ứng dụng di động đa nền tảng (**Flutter**) chuyên dụng kết nối Bluetooth Low Energy (BLE) với thiết bị giám sát té ngã **ESP32-S3R8 (Time-of-Flight VL53L1X + Radar mmWave LD2410B)**.

---

## 🌟 Tính năng chính

1. **Quét & Kết nối BLE thông minh:**
   - Tự động nhận diện thiết bị `FallDetector_S3R8`.
   - Hiển thị cường độ sóng RSSI và trạng thái trực tuyến.

2. **Cấu hình Wi-Fi từ xa:**
   - Nhập tên mạng (SSID) và mật khẩu Wi-Fi.
   - Gửi lệnh ghi vào NVS Flash và tự động kích hoạt ESP32 kết nối mạng, nhận phản hồi địa chỉ IP tại chỗ.

3. **Cài đặt Danh bạ Cứu hộ khẩn cấp:**
   - Cài đặt số điện thoại người thân để nhận tin nhắn SMS Gateway.
   - Cài đặt Telegram Chat ID và Bot Token để nhận tin nhắn cảnh báo định dạng HTML kèm biểu đồ thông số va chạm.
   - Tinh chỉnh ngưỡng chiều cao sàn nhà (`floor_mm`) từ 200mm - 800mm.

4. **Bảng điều khiển Giám sát Thời gian thực (Live Dashboard):**
   - **Trạng thái hệ thống (FSM):** `NORMAL`, `SUSPECTED`, `PRE_ALARM` (đếm ngược 30s), `ALERT` (cấp cứu đỏ), `ACKNOWLEDGED`, `FAULT`.
   - **Tư thế nhận diện bởi AI:** `STAND` (Đứng), `SIT` (Ngồi), `LIE` (Nằm), `FALL` (Ngã) kèm độ tin cậy Softmax (%).
   - **Thông số cảm biến liên tục:** Chiều cao ToF (mm), vận tốc rơi (mm/s), đỉnh động năng Radar va chạm (/100), năng lượng tĩnh hô hấp (/100).

5. **Phím bấm Hành động Nhanh:**
   - 🚨 **KÍCH HOẠT SOS CẤP CỨU TỪ XA:** Nút đỏ lớn kích hoạt báo động ngay lập tức từ điện thoại.
   - 🔕 **Tắt còi / Hủy báo động:** Giải tỏa sự cố từ xa khi đã có người hỗ trợ.
   - 📏 **Hiệu chuẩn sàn nhà:** Ra lệnh cho ESP32 tự động lấy mẫu mặt sàn hiện tại.
   - 🔊 **Kiểm tra còi/đèn:** Test hoạt động của còi và dải LED NeoPixel.
   - 📜 **Xem Hộp đen Sự cố:** Tải lịch sử 5 lần té ngã gần nhất lưu trong chip.

---

## 🚀 Hướng dẫn Cài đặt & Sử dụng

### 1. Dành cho Android
- **Chạy trực tiếp trên thiết bị (hoặc máy ảo Android):**
  ```bash
  cd mobile_app
  flutter run
  ```
- **Xuất file APK cài đặt (Release APK):**
  ```bash
  cd mobile_app
  flutter build apk --release
  ```
  File `.apk` tạo ra tại: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`. Chỉ cần copy file này vào điện thoại Android và mở cài đặt.

### 2. Dành cho iOS (iPhone / iPad)
- **Mở dự án trong Xcode:**
  ```bash
  cd mobile_app
  open ios/Runner.xcworkspace
  ```
- **Cấu hình Signing & Chạy:**
  1. Trong Xcode, chọn mục **Runner** -> tab **Signing & Capabilities**.
  2. Chọn **Team** (tài khoản Apple Developer miễn phí hoặc trả phí).
  3. Cắm iPhone vào máy Mac và nhấn **Run** (Cmd + R) để cài trực tiếp lên iPhone.
- **Xuất file IPA:**
  ```bash
  flutter build ipa
  ```

---

## 📡 Chi tiết Giao thức BLE (UUID Mapping)

| Đặc tính BLE | UUID | Chức năng | Định dạng dữ liệu |
| :--- | :--- | :--- | :--- |
| **Service** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Dịch vụ chính | - |
| **Wi-Fi Char** | `0beb5483-e18e-4f36-9e1b-b4d6b63c7b28` | Ghi thông tin mạng | `{"ssid":"...","pass":"..."}` |
| **Contact Char**| `1c6f8742-9a6d-4785-b9e1-e63f9b8c0011` | Đọc/Ghi danh bạ | `{"phone":"...","chat_id":"...","floor_mm":450}` |
| **Status Char** | `2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344` | Thông báo trạng thái | Chuỗi ký tự ASCII / Notify |
| **Telemetry** | `3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455` | Dữ liệu đo thời gian thực | `{"st":"NORMAL","cls":"STAND","cf":0.92,...}` |
| **Command** | `4fa0b044-9b3e-4d75-af4c-b70e901c5566` | Lệnh điều khiển | `CANCEL_ALARM`, `CALIBRATE_FLOOR`, `PANIC_SOS`,... |
