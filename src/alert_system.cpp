#include "alert_system.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <esp_task_wdt.h>
#include <time.h>

AlertSystem::AlertSystem() 
  : strip(NUM_LEDS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800),
    currentLedColor(0xFFFFFFFF),
    lastWiFiReconnectAttempt(0),
    buzzerPinState(false),
    buzzerActiveHigh(BUZZER_ACTIVE_HIGH),
    buzzerMuted(BUZZER_DEFAULT_MUTED),
    currentPattern(BUZZER_SILENT),
    patternTimer(0),
    patternStep(0),
    nightlightActive(false),
    nightlightEndTime(0),
    nightScheduleEnabled(true),
    nightStartHour(18),
    nightStartMinute(0),
    nightEndHour(6),
    nightEndMinute(0) {}

void AlertSystem::earlyHardwareMute() {
  // 1. Đọc phân cực còi và trạng thái Mute đã lưu trong NVS Flash (nếu chưa lưu thì lấy theo config.h)
  Preferences p;
  if (p.begin("sys_cfg", true)) {
    buzzerActiveHigh = p.getBool("buz_high", BUZZER_ACTIVE_HIGH);
    buzzerMuted = p.getBool("buz_mute", (bool)BUZZER_DEFAULT_MUTED);
    p.end();
  } else {
    buzzerActiveHigh = BUZZER_ACTIVE_HIGH;
    buzzerMuted = BUZZER_DEFAULT_MUTED;
  }

  // 2. Mức điện áp để ngắt còi:
  // • Với còi kích mức Thấp (Active-LOW, nối nguồn 3.3V): Chân GPIO 5 xuất HIGH (3.3V) -> V_diff = 0V -> Còi tắt hẳn.
  // • Với còi kích mức Cao (Active-HIGH): Chân GPIO 5 xuất LOW (0V) -> Còi tắt.
  pinMode(PIN_BUZZER, OUTPUT);
  uint8_t muteLevel = buzzerActiveHigh ? LOW : HIGH;
  digitalWrite(PIN_BUZZER, muteLevel);
  buzzerPinState = false;
}

void AlertSystem::setBuzzerHardware(bool on) {
  pinMode(PIN_BUZZER, OUTPUT);
  if (buzzerMuted || !on) {
    // Trạng thái IM LẶNG:
    uint8_t muteLevel = buzzerActiveHigh ? LOW : HIGH;
    digitalWrite(PIN_BUZZER, muteLevel);
    buzzerPinState = false;
    return;
  }

  // Trạng thái BẬT CÒI BÁO ĐỘNG:
  uint8_t activeLevel = buzzerActiveHigh ? HIGH : LOW;
  digitalWrite(PIN_BUZZER, activeLevel);
  buzzerPinState = true;
}

BuzzerPattern AlertSystem::getCurrentPattern() const {
  return currentPattern;
}

void AlertSystem::setBuzzerActiveHigh(bool high) {
  buzzerActiveHigh = high;
  setBuzzerHardware(false); // Ngắt còi ngay lập tức khi đổi phân cực

  // Lưu vĩnh viễn vào NVS Flash để nhớ trạng thái qua các lần rút cắm nguồn
  Preferences p;
  if (p.begin("sys_cfg", false)) {
    p.putBool("buz_high", high);
    p.end();
  }
}

bool AlertSystem::isBuzzerActiveHigh() const {
  return buzzerActiveHigh;
}

void AlertSystem::setMuted(bool mute) {
  buzzerMuted = mute;
  setBuzzerHardware(false);

  Preferences p;
  if (p.begin("sys_cfg", false)) {
    p.putBool("buz_mute", mute);
    p.end();
  }
}

bool AlertSystem::isMuted() const {
  return buzzerMuted;
}

void AlertSystem::init() {
  earlyHardwareMute(); // Đảm bảo còi tắt tuyệt đối và đọc phân cực từ NVS

  Preferences p;
  if (p.begin("sys_cfg", true)) {
    nightScheduleEnabled = p.getBool("nl_sched", true);
    nightStartHour = p.getUChar("nl_start_h", 18);
    nightStartMinute = p.getUChar("nl_start_m", 0);
    nightEndHour = p.getUChar("nl_end_h", 6);
    nightEndMinute = p.getUChar("nl_end_m", 0);
    p.end();
  }

  strip.begin();
#ifdef LED_BRIGHTNESS
  strip.setBrightness(LED_BRIGHTNESS);
#else
  strip.setBrightness(120);
#endif
  currentLedColor = 0xFFFFFFFF;
  setIndicator(strip.Color(255, 0, 255), false); // Màu tím magenta để kiểm tra trạng thái khởi động

#if ENABLE_STARTUP_BEEP
  // Âm báo Welcome khởi động hệ thống
  playBeep(80);
  delay(100);
  playBeep(80);
#endif
}

void AlertSystem::setIndicator(uint32_t color, bool buzzer) {
  // Nhận màu theo dạng RGB (0xRRGGBB), sau đó để thư viện xử lý đúng
  // thứ tự dây của dải LED (NEO_GRB).
  const uint8_t red = (color >> 16) & 0xFF;
  const uint8_t green = (color >> 8) & 0xFF;
  const uint8_t blue = color & 0xFF;
  const uint32_t ledColor = strip.Color(red, green, blue);

  // Chỉ bắn dữ liệu ra WS2812B khi màu sắc thực sự thay đổi
  // Ngăn chặn hoàn toàn việc gọi strip.show() hàng nghìn lần/giây trong loop() gây flicker cực mạnh
  if (ledColor != currentLedColor) {
    currentLedColor = ledColor;
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, ledColor);
    }
    strip.show();
    delayMicroseconds(300); // Latch pulse an toàn tối thiểu > 50µs cho WS2812B
  }

  if (buzzer) {
    setBuzzerHardware(true);
  } else if (currentPattern == BUZZER_SILENT) {
    setBuzzerHardware(false);
  }
}

void AlertSystem::setBuzzerPattern(BuzzerPattern pattern) {
  if (currentPattern != pattern) {
    currentPattern = pattern;
    patternTimer = millis();
    patternStep = 0;
    if (pattern == BUZZER_SILENT) {
      setBuzzerHardware(false);
    }
  }
}

void AlertSystem::updateBuzzer() {
  unsigned long now = millis();

  switch (currentPattern) {
    case BUZZER_SILENT:
      break;

    case BUZZER_PRE_ALARM_PULSE:
      // Chuỗi âm thanh Pre-alarm: Bíp (100ms) -> Nghỉ (100ms) -> Bíp (100ms) -> Nghỉ (1200ms)
      if (patternStep == 0 && now - patternTimer >= 0) {
        setBuzzerHardware(true);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 100) {
        setBuzzerHardware(false);
        patternStep = 2;
        patternTimer = now;
      } else if (patternStep == 2 && now - patternTimer >= 100) {
        setBuzzerHardware(true);
        patternStep = 3;
        patternTimer = now;
      } else if (patternStep == 3 && now - patternTimer >= 100) {
        setBuzzerHardware(false);
        patternStep = 4;
        patternTimer = now;
      } else if (patternStep == 4 && now - patternTimer >= 1200) {
        patternStep = 0; // Lặp lại chu kỳ
        patternTimer = now;
      }
      break;

    case BUZZER_ALERT_SIREN:
      // Còi báo động dồn dập SOS Tầng 2: Hú 250ms -> Nghỉ 150ms
      if (patternStep == 0 && now - patternTimer >= 150) {
        setBuzzerHardware(true);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 250) {
        setBuzzerHardware(false);
        patternStep = 0;
        patternTimer = now;
      }
      break;

    case BUZZER_CONFIRM_BEEP:
      // Kêu xác nhận 2 tiếng rồi tự tắt
      if (patternStep == 0) {
        setBuzzerHardware(true);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 70) {
        setBuzzerHardware(false);
        patternStep = 2;
        patternTimer = now;
      } else if (patternStep == 2 && now - patternTimer >= 70) {
        setBuzzerHardware(true);
        patternStep = 3;
        patternTimer = now;
      } else if (patternStep == 3 && now - patternTimer >= 70) {
        setBuzzerHardware(false);
        currentPattern = BUZZER_SILENT;
      }
      break;

    case BUZZER_SOS_CHIRP:
      // Âm báo khẩn cấp tức thời khi nhấn giữ nút cứu nạn
      if (now - patternTimer >= 80) {
        patternTimer = now;
        setBuzzerHardware(!buzzerPinState);
      }
      break;
  }
}

void AlertSystem::updateNightlight(bool motionDetected) {
  unsigned long now = millis();

  if (motionDetected && isNightScheduleActive()) {
    nightlightEndTime = now + NIGHTLIGHT_TIMEOUT_MS;
    if (!nightlightActive) {
      nightlightActive = true;
      uint32_t warmColor = strip.Color(150, 100, 30);
      if (currentLedColor != warmColor) {
        currentLedColor = warmColor;
        for (int i = 0; i < NUM_LEDS; i++) {
          strip.setPixelColor(i, warmColor);
        }
        strip.show();
        delayMicroseconds(300);
      }
    }
  } else if (nightlightActive) {
    if (!isNightScheduleActive() || now >= nightlightEndTime) {
      nightlightActive = false;
      uint32_t dimColor = strip.Color(35, 22, 10);
      if (currentLedColor != dimColor) {
        currentLedColor = dimColor;
        for (int i = 0; i < NUM_LEDS; i++) {
          strip.setPixelColor(i, dimColor);
        }
        strip.show();
        delayMicroseconds(300);
      }
    }
  }
}

void AlertSystem::setNightlightSchedule(bool enabled, uint8_t startHour, uint8_t startMinute,
                                         uint8_t endHour, uint8_t endMinute) {
  nightScheduleEnabled = enabled;
  nightStartHour = startHour % 24;
  nightStartMinute = startMinute % 60;
  nightEndHour = endHour % 24;
  nightEndMinute = endMinute % 60;

  Preferences p;
  if (p.begin("sys_cfg", false)) {
    p.putBool("nl_sched", nightScheduleEnabled);
    p.putUChar("nl_start_h", nightStartHour);
    p.putUChar("nl_start_m", nightStartMinute);
    p.putUChar("nl_end_h", nightEndHour);
    p.putUChar("nl_end_m", nightEndMinute);
    p.end();
  }
}

bool AlertSystem::isNightScheduleActive() const {
  if (!nightScheduleEnabled) return true;

  time_t now = time(nullptr);
  // Chưa đồng bộ NTP: giữ hành vi cũ để đèn vẫn hoạt động khi mất Wi-Fi.
  if (now < 1577836800) return true; // 2020-01-01: thời gian chưa được NTP đồng bộ

  struct tm localTime;
  localtime_r(&now, &localTime);
  const int current = localTime.tm_hour * 60 + localTime.tm_min;
  const int start = nightStartHour * 60 + nightStartMinute;
  const int end = nightEndHour * 60 + nightEndMinute;

  if (start == end) return true;
  if (start < end) return current >= start && current < end;
  return current >= start || current < end;
}

void AlertSystem::playBeep(uint16_t durationMs) {
  setBuzzerHardware(true);
  delay(durationMs);
  setBuzzerHardware(false);
}

bool AlertSystem::connectWiFi(const String& ssid, const String& pass) {
  if (ssid.length() == 0) return false;

  Serial.printf("[WIFI] Dang ket noi toi SSID: %s ...\n", ssid.c_str());
  WiFi.mode(WIFI_STA);
  // BLE và Wi-Fi cùng chạy trên ESP32-S3. Modem sleep bắt buộc phải bật
  // khi Bluetooth đang hoạt động; tắt sleep sẽ làm Wi-Fi abort() và reset chip.
  WiFi.setSleep(true);
  WiFi.setAutoReconnect(true);

  if (pass.length() > 0) {
    WiFi.begin(ssid.c_str(), pass.c_str());
  } else {
    WiFi.begin(ssid.c_str());
  }
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 35) {
    delay(300);
    // connectWiFi() chạy trong setup(), sau khi watchdog đã bật.
    // Nếu chờ đủ 10,5 giây mà không reset WDT, ESP32 sẽ khởi động lại
    // và LED chỉ lặp lại màu xanh dương khởi động.
    esp_task_wdt_reset();
    Serial.print(".");
    attempts++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WIFI] Ket noi thanh cong! IP: %s | RSSI: %d dBm\n", 
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
    return true;
  } else {
    Serial.println("[WIFI] Ket noi ban dau timeout. He thong se tiep tuc thu ket noi lai ngam trong nen!");
    return false;
  }
}

void AlertSystem::maintainWiFi(const String& ssid, const String& pass) {
  if (ssid.length() == 0) return;
  unsigned long now = millis();

  // Kiem tra moi 10 giay neu Wi-Fi chua ket noi hoac bi rot mang
  if (WiFi.status() != WL_CONNECTED) {
    if (now - lastWiFiReconnectAttempt >= 10000) {
      lastWiFiReconnectAttempt = now;
      Serial.println("[WIFI] Dang ket noi lai WiFi ngam (non-blocking)...");
      WiFi.mode(WIFI_STA);
      // Giữ modem sleep bật vì BLE vẫn đang chạy song song.
      WiFi.setSleep(true);
      WiFi.setAutoReconnect(true);
      if (pass.length() > 0) {
        WiFi.begin(ssid.c_str(), pass.c_str());
      } else {
        WiFi.begin(ssid.c_str());
      }
    }
  }
}

bool AlertSystem::isWiFiConnected() {
  return (WiFi.status() == WL_CONNECTED);
}

bool AlertSystem::sendTelegramAlert(const String& botToken, const String& chatId, const String& message) {
  if (WiFi.status() != WL_CONNECTED || botToken.length() == 0 || chatId.length() == 0) {
    Serial.println("[TELEGRAM] Khong the gui: Wi-Fi chua ket noi hoac thieu Bot Token / Chat ID!");
    return false;
  }

  // Ho tro danh sach nhieu Chat ID / Group ID phan tach boi dau phay ',' hoac cham phay ';'
  int startIdx = 0;
  bool anySuccess = false;
  int idCount = 0;

  while (startIdx < chatId.length()) {
    int commaIdx = chatId.indexOf(',', startIdx);
    int semiIdx = chatId.indexOf(';', startIdx);
    int nextDelim = -1;
    if (commaIdx != -1 && semiIdx != -1) nextDelim = min(commaIdx, semiIdx);
    else if (commaIdx != -1) nextDelim = commaIdx;
    else nextDelim = semiIdx;

    String singleId = (nextDelim == -1) ? chatId.substring(startIdx) : chatId.substring(startIdx, nextDelim);
    singleId.trim();

    if (singleId.length() > 0) {
      idCount++;
      HTTPClient http;
      String url = "https://api.telegram.org/bot" + botToken + "/sendMessage";
      http.begin(url);
      http.setTimeout(5000);
      http.addHeader("Content-Type", "application/json");

      StaticJsonDocument<512> doc;
      doc["chat_id"] = singleId;
      doc["text"] = message;
      doc["parse_mode"] = "HTML";

      String payload;
      serializeJson(doc, payload);

      int httpCode = http.POST(payload);
      if (httpCode == HTTP_CODE_OK || httpCode == 201) {
        Serial.printf("[TELEGRAM] (#%d) Gui canh bao thanh cong toi Chat/Group ID: %s!\n", idCount, singleId.c_str());
        anySuccess = true;
      } else {
        Serial.printf("[TELEGRAM] (#%d) Gui that bai toi ID: %s! Ma loi: %d\n", idCount, singleId.c_str(), httpCode);
      }
      http.end();
    }

    if (nextDelim == -1) break;
    startIdx = nextDelim + 1;
  }

  return anySuccess;
}

bool AlertSystem::sendSmsGateway(const String& phone, const String& content) {
  if (WiFi.status() != WL_CONNECTED || phone.length() == 0) {
    Serial.println("[SMS] Khong the gui: Wi-Fi chua ket noi hoac chua cau hinh SDT!");
    return false;
  }

  // Ho tro danh sach nhieu so dien thoai phan tach boi dau phay ',' hoac cham phay ';'
  StaticJsonDocument<512> doc;
  JsonArray to = doc.createNestedArray("to");
  int phoneCount = 0;
  int startIdx = 0;

  while (startIdx < phone.length()) {
    int commaIdx = phone.indexOf(',', startIdx);
    int semiIdx = phone.indexOf(';', startIdx);
    int nextDelim = -1;
    if (commaIdx != -1 && semiIdx != -1) nextDelim = min(commaIdx, semiIdx);
    else if (commaIdx != -1) nextDelim = commaIdx;
    else nextDelim = semiIdx;

    String singlePhone = (nextDelim == -1) ? phone.substring(startIdx) : phone.substring(startIdx, nextDelim);
    singlePhone.trim();

    if (singlePhone.length() >= 9) { // So dien thoai hop le
      to.add(singlePhone);
      phoneCount++;
      Serial.printf("[SMS] Nhan so dien thoai (#%d): %s\n", phoneCount, singlePhone.c_str());
    }

    if (nextDelim == -1) break;
    startIdx = nextDelim + 1;
  }

  if (phoneCount == 0) {
    Serial.println("[SMS] Khong co so dien thoai hop le de gui!");
    return false;
  }

  doc["content"] = content;
  doc["type"] = 1;

  String payload;
  serializeJson(doc, payload);

  HTTPClient http;
  http.begin(DEFAULT_SMS_GATEWAY_URL);
  http.setTimeout(5000);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + String(DEFAULT_SMS_TOKEN));

  int httpCode = http.POST(payload);
  bool success = (httpCode == HTTP_CODE_OK || httpCode == 200);
  if (success) {
    Serial.printf("[SMS] Da phat tin nhan SMS dong loat toi %d so dien thoai thanh cong!\n", phoneCount);
  } else {
    Serial.printf("[SMS] Gui tin that bai! Ma loi HTTP: %d\n", httpCode);
  }
  http.end();
  return success;
}
