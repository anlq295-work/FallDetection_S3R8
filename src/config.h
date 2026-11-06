#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// Phiên bản Firmware hệ thống
#define FIRMWARE_VERSION            "v1.1.0"

// =========================================================================
// 1. PINOUT AN TOÀN CHO ESP32-S3R8 & CẤU HÌNH CẢM BIẾN
// (LƯU Ý CỰC KỲ QUAN TRỌNG: TRÁNH TUYỆT ĐỐI CÁC CHÂN TỪ GPIO 33 ĐẾN 37 VÌ DÀNH CHO OCTAL PSRAM/OPI FLASH)
// =========================================================================
#define ENABLE_PIR_SENSOR     0     // Đặt 0: Vô hiệu hóa/ẩn PIR khi test mạch chưa có cảm biến PIR (chân GPIO 4 kéo pulldown chống nhiễu)
#define PIN_PIR               4     // PIR AM312 (Ngắt ngoài RTC)
#define PIN_BUZZER            5     // Active Buzzer 5V
#ifdef PIN_NEOPIXEL
  #undef PIN_NEOPIXEL
#endif
#define PIN_NEOPIXEL          6     // WS2812B DIN (6 bóng RGB)
#define PIN_CANCEL_BTN        0     // Nút bấm BOOT GPIO 0 (Active LOW)
#define NUM_LEDS              6

#define PIN_I2C_SDA           8     // ToF VL53L1X SDA
#define PIN_I2C_SCL           9     // ToF VL53L1X SCL

#define PIN_RADAR_RX          18    // Nối chân TX của LD2410B
#define PIN_RADAR_TX          17    // Nối chân RX của LD2410B

// =========================================================================
// 2. THÔNG SỐ LẤY MẪU VÀ CỬA SỔ TRƯỢT
// =========================================================================
#define SAMPLE_RATE_HZ        20    // 20 Hz (50ms mỗi chu kỳ lấy mẫu)
#define WINDOW_SIZE           40    // Cửa sổ trượt 2.0 giây (40 mẫu x 50ms)
#define NUM_FEATURES          7     // 7 đặc trưng không gian - động học

// =========================================================================
// 3. NGƯỠNG ĐỘ CHÍNH XÁC NHẬN DIỆN TÉ NGÃ (KINEMATIC & RADAR THRESHOLDS)
// =========================================================================
#define FALL_VELOCITY_THRESH_MM_S   550.0f  // Tốc độ sụt giảm ToF tối thiểu (>= 550 mm/s)
#define FALL_RADAR_MOTION_THRESH    40      // Đỉnh năng lượng chuyển động va chạm LD2410 (>= 40/100)
#define POST_FALL_RADAR_MOTION_MAX  25      // Năng lượng chuyển động sau ngã (bất động <= 25/100)
#define POST_FALL_RADAR_STATIC_MIN  15      // Năng lượng tĩnh hô hấp/sự hiện diện (>= 15/100)
#define FLOOR_HEIGHT_DEFAULT_MM     450     // Chiều cao sàn: <= 450mm là tư thế nằm sàn
#define STAND_HEIGHT_MIN_MM         900     // Chiều cao đứng: >= 900mm
#define SIT_HEIGHT_MIN_MM           480     // Chiều cao ngồi: 480mm - 900mm

#define IMMOBILE_VERIFY_TIME_MS     2000    // 2 giây theo dõi bất động sau chấn động
#define PRE_ALARM_TIMEOUT_MS        30000   // 30 giây Pre-alarm tại chỗ trước khi gửi SOS
#define RECOVERY_CONFIRM_TIME_MS    1500    // 1.5 giây đứng vững liên tục để tự giải trừ cảnh báo

// =========================================================================
// 4. CÁC TÍNH NĂNG MỞ RỘNG (SMART NIGHTLIGHT, SLOW FALL, SOS BUTTON, WATCHDOG)
// =========================================================================
#define SLOW_FALL_FLOOR_TIME_MS     15000   // 15 giây nằm sàn bất động -> Kích hoạt ngã chậm / ngất
#define MANUAL_SOS_HOLD_TIME_MS     3000    // 3 giây giữ nút BOOT -> Kích hoạt SOS thủ công khẩn cấp
#define NIGHTLIGHT_TIMEOUT_MS       40000   // 40 giây sáng đèn ngủ thông minh khi phát hiện bước chân
#define WDT_TIMEOUT_SECONDS         10      // 10 giây Hardware Watchdog chống treo hệ thống

// Cấu hình SMS Gateway qua Wi-Fi
#define DEFAULT_SMS_GATEWAY_URL "https://api.speedsms.vn/index.php/sms/send"
#define DEFAULT_SMS_TOKEN       "YOUR_DEFAULT_SMS_ACCESS_TOKEN"

// =========================================================================
// 5. ĐỊNH NGHĨA KẾT QUẢ PHÂN LOẠI VÀ TRẠNG THÁI HỆ THỐNG
// =========================================================================
enum AIClass {
  CLASS_STAND = 0,
  CLASS_SIT   = 1,
  CLASS_LIE   = 2,
  CLASS_FALL  = 3
};

enum SystemState {
  STATE_NORMAL,
  STATE_SUSPECTED,
  STATE_PRE_ALARM,
  STATE_ALERT,
  STATE_ACKNOWLEDGED,
  STATE_RESOLVED,
  STATE_DEVICE_FAULT
};

enum FallEventType {
  EVENT_NONE = 0,
  EVENT_FALL_IMPACT = 1,
  EVENT_SLOW_FALL   = 2,
  EVENT_MANUAL_SOS  = 3
};

#endif
