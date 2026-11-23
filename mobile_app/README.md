# Hearth – Mobile App (Android, iOS, Tablet & Foldable)

Ứng dụng di động đa nền tảng (**Flutter**) cho hệ thống phát hiện té ngã không tiếp xúc **ESP32-S3R8 (VL53L1X ToF + HLK-LD2410B 24GHz Radar + PIR AM312)**, được thiết kế lại theo đặc tả **Hearth UX Spec v1** với phong cách **Liquid Glass**, hỗ trợ **3 ngôn ngữ (Tiếng Việt mặc định · English · Français)** và tự động thích ứng cho điện thoại, điện thoại gập (hinge-aware), tablet và desktop.

---

## Tính năng chính

1. **Luồng cài đặt hướng dẫn 4 bước & Đăng nhập không mật khẩu (S1 → S5 → S9):**
   - **S1 Welcome & Sign in:** Đăng nhập bằng email + mã xác thực 6 chữ số, đổi ngôn ngữ tức thì (`VI / EN / FR`).
   - **S2 Find the sensor:** Quét & ghép nối BLE thực tế với `FallDetector_S3R8` (UUID `4fafc201-...`), hiển thị cường độ sóng + trạng thái mạnh/yếu, hỗ trợ nhập mã thủ công hoặc cảm biến mô phỏng.
   - **S3 Connect to Wi-Fi:** Cấu hình mạng Wi-Fi 2.4 GHz gửi qua BLE (`CHAR_WIFI_UUID`), tiến độ 3 giai đoạn trực quan.
   - **S4 Name the room:** Chọn loại phòng trực quan, đặt tên phòng và tên người thân được chăm sóc.
   - **S5 Test the sensor:** Kiểm tra phát hiện có người thời gian thực + gửi lệnh `TEST_ALARM` bật còi/đèn trước khi bắt đầu giám sát.
2. **Giám sát hàng ngày & Cảnh báo té ngã khẩn cấp (S6, S7, S8, S9):**
   - **S6 Home:** Trả lời câu hỏi *"Mọi người có ổn không?"* trong dưới 3 giây với dòng tóm tắt trạng thái, banner ngoại tuyến ưu tiên cao nhất và danh sách phòng (2 cột trên tablet/màn hình gập, lưới 3 cột + thanh điều hướng trái trên desktop).
   - **S7 Fall Alert:** Màn hình đỏ khẩn cấp toàn màn hình (hoặc modal không thể tắt nhầm trên tablet/desktop) kèm bộ đếm thời gian chuyển cấp (escalation), nút chính **"Tôi đang xử lý"**, gọi người thân, gọi cấp cứu khu vực (`115`/`112`/`911`), tắt còi tại phòng, ghi nhận kết quả xử lý 3 mức và truy cập nhanh Sơ cứu / Hồ sơ y tế.
   - **S8 Room Detail:** Nhật ký hôm nay, sức khỏe cảm biến, điều khiển phần cứng ESP32-S3 (dữ liệu ToF/Radar trực tiếp, mô phỏng tư thế AI, lịch đèn ngủ `NIGHTLIGHT_SCHEDULE`, phân cực/tắt tiếng còi, hiệu chuẩn mặt sàn `CALIBRATE_FLOOR`, kênh Telegram/SMS, Hộp đen NVS Flash 5 sự kiện và 3 chế độ OTA).
   - **S9 Alert Contacts:** Danh sách người nhận cảnh báo theo thứ tự ưu tiên (kéo thả + nút Lên/Xuống dễ tiếp cận), chọn thời gian chờ chuyển cấp (`1 / 2 / 5 phút`).
3. **Bộ công cụ Chăm sóc & Y tế cho người cao tuổi:**
   - Hướng dẫn sơ cứu té ngã 4 bước chuẩn y khoa.
   - Thẻ Hồ sơ Y tế Khẩn cấp (nhóm máu, bệnh nền, thuốc, dị ứng, bác sĩ).
   - Bảng đánh giá nguy cơ té ngã **CDC STEADI**.
   - Báo cáo kiểm tra an toàn y tế tổng hợp & kiểm tra cập nhật GitHub Releases OTA.

---

## Chạy & Build

```bash
cd mobile_app
flutter pub get
flutter analyze
flutter test

# Chạy trên thiết bị
flutter run

# Build Android APK / iOS IPA
flutter build apk --release
flutter build ipa
```
