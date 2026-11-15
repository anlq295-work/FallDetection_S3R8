# FallDetection S3R8 – Sơ đồ nối chân

## Pinout theo firmware hiện tại

| Thiết bị | ESP32-S3 | Ghi chú |
|---|---:|---|
| PIR AM312 OUT | GPIO4 | VCC 3.3V, GND chung |
| Buzzer module IN | GPIO5 | Dùng transistor/MOSFET, không kéo tải trực tiếp từ GPIO |
| WS2812B DIN | GPIO6 | LED cấp 5V riêng, GND LED nối chung GND ESP32 |
| VL53L1X SDA | GPIO8 | I2C, mức logic 3.3V |
| VL53L1X SCL | GPIO9 | I2C, mức logic 3.3V |
| LD2410B TX | GPIO18 / Serial2 RX | TX radar → RX ESP32 |
| LD2410B RX | GPIO17 / Serial2 TX | RX radar ← TX ESP32 |
| Module touch OUT | GPIO7 | Active HIGH; VCC 3.3V, GND chung |

## Cấp nguồn ngoài

```text
Nguồn 5V ổn định, tối thiểu 2A
  +5V  -> chân 5V/VBUS ESP32-S3
  GND  -> GND ESP32-S3
  +5V  -> VCC WS2812B và LD2410B
  GND  -> GND WS2812B, LD2410B, PIR, VL53L1X và ESP32
```

- Không cấp nguồn ngoài vào chân `3V3`.
- Không đưa điện áp cao hơn 5V vào chân `5V/VBUS`.
- Tất cả module phải dùng chung GND.
- WS2812B 24 bóng có thể tạo dòng khởi động lớn; nên đặt tụ 470–1000 µF gần dải LED.
- Nếu LED sáng toàn bộ, nguồn 5V nên có dự phòng dòng ít nhất 2A, tốt hơn là 3A.
- GPIO5 chỉ điều khiển ngõ vào mạch driver buzzer; không cấp buzzer 5V trực tiếp từ GPIO.
- Không nối OUT module touch vào GPIO0; GPIO0 là chân BOOT và có thể làm ESP32 vào chế độ download khi chạm lúc khởi động.

## Vì sao USB-UART chạy nhưng nguồn ngoài mất BLE?

Khả năng cao là nguồn ngoài bị sụt áp khi LED/cảm biến khởi động, bị thiếu GND chung, hoặc cấp nhầm chân nguồn. Cũng cần kiểm tra GPIO0 không bị kéo xuống LOW vì ESP32 sẽ vào chế độ nạp firmware thay vì chạy chương trình.

Khi thử lại, đo đồng thời tại chân 5V và 3V3 trong 1–2 giây đầu. Nếu đường 3V3 tụt dưới khoảng 3.1V, hãy đổi nguồn 5V khỏe hơn và giảm tải LED lúc khởi động.
