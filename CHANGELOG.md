# Changelog

Mọi thay đổi đáng chú ý của dự án **Hearth (FallDetection_S3R8)** được ghi nhận tại tệp này.

## [2.0.0]

### Ứng dụng di động Hearth (Android, iOS, Tablet & Folding Phone)
- Tái thiết kế và viết lại toàn bộ ứng dụng theo đặc tả **Hearth UX Spec v1** với hiệu ứng **Liquid Glass** (kính mờ tương phản cao, hỗ trợ chế độ Sáng/Tối theo hệ thống).
- Bổ sung chuyển đổi **3 ngôn ngữ** trực tiếp trong ứng dụng: **Tiếng Việt (mặc định)**, **English** và **Français**.
- Hỗ trợ co giãn tự động (scalable UI, Dynamic Type tới 200%) và bố cục thích ứng cho **điện thoại, điện thoại gập (nhận diện bản lề), tablet (2 khung Master-Detail) và desktop (Navigation Rail + lưới đa cột)**.
- Hoàn thiện trọn bộ luồng 9 màn hình (**S1–S9**): đăng nhập Email OTP 6 chữ số, cài đặt cảm biến 4 bước qua BLE/Wi-Fi 2.4 GHz, giám sát trang chủ, màn hình cảnh báo té ngã khẩn cấp kèm đếm ngược chuyển cấp và xử lý 3 mức kết quả, chi tiết phòng, danh bạ ưu tiên kéo-thả kèm nút Lên/Xuống.
- Tích hợp đầy đủ điều khiển phần cứng ESP32-S3 (BLE GATT 6 characteristics, Wi-Fi LAN HTTP API, dữ liệu ToF/Radar trực tiếp, mô phỏng tư thế AI, lịch đèn ngủ, phân cực/tắt còi, hiệu chuẩn sàn, Telegram/SMS, Hộp đen NVS 5 sự kiện, 3 chế độ OTA) cùng bộ công cụ Y tế (Sơ cứu té ngã 4 bước, Thẻ Hồ sơ Y tế, CDC STEADI, Báo cáo kiểm tra y tế).

### Firmware ESP32-S3 & CI/CD
- Đồng bộ phiên bản mặc định **v2.0.0** cho firmware (`src/config.h`), ứng dụng di động (`pubspec.yaml`), iOS OTA (`manifest.plist`) và GitHub Actions.
- Chuẩn hóa quy trình phát hành GitHub Release duy nhất theo Semantic Version (`make_latest: true`), tự động tổng hợp ghi chú cập nhật theo từng bản phát hành và sửa toàn bộ lỗi chính tả/lọc tệp IPA.
