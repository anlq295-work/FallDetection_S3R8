# Changelog

Mọi thay đổi đáng chú ý của dự án **Hearth (FallDetection_S3R8)** được ghi nhận tại tệp này.

## [Pre-release2.0.1]

### Loại bỏ dữ liệu mẫu & Bắt buộc thiết lập hồ sơ thực
- Xóa hoàn toàn tên và số điện thoại giả định (`Bà Lan`, `Anh Minh`, `0901234567`, danh sách Wi-Fi/phòng mẫu).
- Bắt buộc nhập **Email**, **Tên người chăm sóc** và **Tên người thân được theo dõi** ở S1 và S4; nếu chưa có tên sẽ hiển thị trung tính *"Ngôi nhà của bạn"* kèm banner nhắc thiết lập thay vì tự tạo tên giả.

### Cảnh báo khẩn cấp ĐỒNG THỜI đa kênh (Mặc định)
- Chuyển chế độ phát cảnh báo mặc định sang **Đồng thời (Simultaneous)** tới toàn bộ người thân qua **App + SMS đồng loạt + Telegram nhiều Chat/Group + Gọi nhanh trên S7** (vẫn giữ tùy chọn chế độ tuần tự trong S9).
- Bổ sung nút **Gửi SMS khẩn cấp đồng loạt 1 chạm** (điền sẵn tên người thân, phòng, thời điểm, địa chỉ & mã khóa cửa) và hàng nút **Gọi nhanh từng thành viên gia đình** ngay trên màn hình S7.
- Cơ chế **Nhận trách nhiệm (Claim Alert)** giúp đồng bộ trạng thái xử lý cho cả gia đình, tránh gọi chồng chéo.
- Bổ sung khảo sát nhanh nguyên nhân khi đánh dấu **Báo động giả** để hỗ trợ tinh chỉnh ngưỡng sàn.

### Tính năng chăm sóc người cao tuổi bổ sung
- **Chế độ Khách / Tạm dừng giám sát (Guest / Privacy Pause Mode)** tạm dừng báo động tự động khi có khách hoặc dọn nhà.
- **Xác nhận hỏi thăm an toàn hằng ngày (Daily Safe Check-In)** ngay trên trang chủ S6.
- **Lịch nhắc uống thuốc hằng ngày** trong Bộ công cụ Chăm sóc & Y tế.
- **Cảnh báo ở quá lâu / bất động theo từng phòng** (`Off / 15 / 30 / 60 phút`) trong S8.
- **Mã khóa cửa / hộp chìa khóa khẩn cấp (Door Lockbox Code)** lưu ngoại tuyến trên Thẻ Hồ sơ Y tế và hiển thị ngay trên S7 cho lực lượng cấp cứu hoặc hàng xóm.

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
