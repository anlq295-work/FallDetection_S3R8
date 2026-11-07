#include "alert_system.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>

AlertSystem::AlertSystem() 
  : strip(NUM_LEDS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800),
    lastWiFiReconnectAttempt(0),
    buzzerPinState(false),
    buzzerActiveHigh(BUZZER_ACTIVE_HIGH),
    buzzerMuted(BUZZER_DEFAULT_MUTED),
    currentPattern(BUZZER_SILENT),
    patternTimer(0),
    patternStep(0),
    nightlightActive(false),
    nightlightEndTime(0) {}

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

  strip.begin();
  strip.setBrightness(70);
  setIndicator(strip.Color(0, 0, 50), false); // Đèn xanh dương báo đang khởi động

#if ENABLE_STARTUP_BEEP
  // Âm báo Welcome khởi động hệ thống
  playBeep(80);
  delay(100);
  playBeep(80);
#endif
}

void AlertSystem::setIndicator(uint32_t color, bool buzzer) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();

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

  if (motionDetected) {
    nightlightActive = true;
    nightlightEndTime = now + NIGHTLIGHT_TIMEOUT_MS;
    // Bật đèn vàng ấm dịu nhẹ soi đường đi (Warm Golden Light)
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, strip.Color(60, 40, 10));
    }
    strip.show();
  } else if (nightlightActive) {
    if (now >= nightlightEndTime) {
      nightlightActive = false;
      // Trở về đèn ngủ ambient tối nhẹ (Warm dim)
      for (int i = 0; i < NUM_LEDS; i++) {
        strip.setPixelColor(i, strip.Color(15, 10, 5));
      }
      strip.show();
    }
  }
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
  WiFi.begin(ssid.c_str(), pass.c_str());
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 25) {
    delay(300);
    Serial.print(".");
    attempts++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WIFI] Ket noi thanh cong! IP: %s | RSSI: %d dBm\n", 
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
    return true;
  } else {
    Serial.println("[WIFI] Ket noi that bai (Timeout)!");
    return false;
  }
}

void AlertSystem::maintainWiFi(const String& ssid, const String& pass) {
  if (ssid.length() == 0) return;
  unsigned long now = millis();

  // Kiểm tra mỗi 15 giây nếu Wi-Fi bị ngắt
  if (WiFi.status() != WL_CONNECTED) {
    if (now - lastWiFiReconnectAttempt >= 15000) {
      lastWiFiReconnectAttempt = now;
      Serial.println("[WIFI] Phat hien mat mang. Dang thu ket noi lai non-blocking...");
      WiFi.disconnect();
      WiFi.reconnect();
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
