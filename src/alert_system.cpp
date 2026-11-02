#include "alert_system.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

AlertSystem::AlertSystem() 
  : strip(NUM_LEDS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800),
    lastWiFiReconnectAttempt(0),
    buzzerPinState(false),
    currentPattern(BUZZER_SILENT),
    patternTimer(0),
    patternStep(0),
    nightlightActive(false),
    nightlightEndTime(0) {}

void AlertSystem::init() {
  pinMode(PIN_BUZZER, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);

  strip.begin();
  strip.setBrightness(70);
  setIndicator(strip.Color(0, 0, 50), false); // Đèn xanh dương báo đang khởi động

  // Âm báo Welcome khởi động hệ thống
  playBeep(80);
  delay(100);
  playBeep(80);
}

void AlertSystem::setIndicator(uint32_t color, bool buzzer) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();

  if (buzzer) {
    digitalWrite(PIN_BUZZER, HIGH);
    buzzerPinState = true;
  } else if (currentPattern == BUZZER_SILENT) {
    digitalWrite(PIN_BUZZER, LOW);
    buzzerPinState = false;
  }
}

void AlertSystem::setBuzzerPattern(BuzzerPattern pattern) {
  if (currentPattern != pattern) {
    currentPattern = pattern;
    patternTimer = millis();
    patternStep = 0;
    if (pattern == BUZZER_SILENT) {
      digitalWrite(PIN_BUZZER, LOW);
      buzzerPinState = false;
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
        digitalWrite(PIN_BUZZER, HIGH);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 100) {
        digitalWrite(PIN_BUZZER, LOW);
        patternStep = 2;
        patternTimer = now;
      } else if (patternStep == 2 && now - patternTimer >= 100) {
        digitalWrite(PIN_BUZZER, HIGH);
        patternStep = 3;
        patternTimer = now;
      } else if (patternStep == 3 && now - patternTimer >= 100) {
        digitalWrite(PIN_BUZZER, LOW);
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
        digitalWrite(PIN_BUZZER, HIGH);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 250) {
        digitalWrite(PIN_BUZZER, LOW);
        patternStep = 0;
        patternTimer = now;
      }
      break;

    case BUZZER_CONFIRM_BEEP:
      // Kêu xác nhận 2 tiếng rồi tự tắt
      if (patternStep == 0) {
        digitalWrite(PIN_BUZZER, HIGH);
        patternStep = 1;
        patternTimer = now;
      } else if (patternStep == 1 && now - patternTimer >= 70) {
        digitalWrite(PIN_BUZZER, LOW);
        patternStep = 2;
        patternTimer = now;
      } else if (patternStep == 2 && now - patternTimer >= 70) {
        digitalWrite(PIN_BUZZER, HIGH);
        patternStep = 3;
        patternTimer = now;
      } else if (patternStep == 3 && now - patternTimer >= 70) {
        digitalWrite(PIN_BUZZER, LOW);
        currentPattern = BUZZER_SILENT;
      }
      break;

    case BUZZER_SOS_CHIRP:
      // Âm báo khẩn cấp tức thời khi nhấn giữ nút cứu nạn
      if (now - patternTimer >= 80) {
        patternTimer = now;
        buzzerPinState = !buzzerPinState;
        digitalWrite(PIN_BUZZER, buzzerPinState ? HIGH : LOW);
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
  digitalWrite(PIN_BUZZER, HIGH);
  delay(durationMs);
  digitalWrite(PIN_BUZZER, LOW);
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

  HTTPClient http;
  String url = "https://api.telegram.org/bot" + botToken + "/sendMessage";
  http.begin(url);
  http.setTimeout(5000);
  http.addHeader("Content-Type", "application/json");

  // Đóng gói JSON chuẩn UTF-8 (hỗ trợ Tiếng Việt và Emoji không lỗi URL)
  StaticJsonDocument<512> doc;
  doc["chat_id"] = chatId;
  doc["text"] = message;
  doc["parse_mode"] = "HTML";

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  bool success = (httpCode == HTTP_CODE_OK || httpCode == 201);
  if (success) {
    Serial.printf("[TELEGRAM] Gui canh bao thanh cong toi Chat ID: %s!\n", chatId.c_str());
  } else {
    Serial.printf("[TELEGRAM] Gui that bai! Ma loi HTTP: %d\n", httpCode);
  }
  http.end();
  return success;
}

bool AlertSystem::sendSmsGateway(const String& phone, const String& content) {
  if (WiFi.status() != WL_CONNECTED || phone.length() == 0) {
    Serial.println("[SMS] Khong the gui: Wi-Fi chua ket noi hoac chua cau hinh SDT!");
    return false;
  }

  HTTPClient http;
  http.begin(DEFAULT_SMS_GATEWAY_URL);
  http.setTimeout(5000);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + String(DEFAULT_SMS_TOKEN));

  StaticJsonDocument<256> doc;
  JsonArray to = doc.createNestedArray("to");
  to.add(phone);
  doc["content"] = content;
  doc["type"] = 1;

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  bool success = (httpCode == HTTP_CODE_OK || httpCode == 200);
  if (success) {
    Serial.printf("[SMS] Gui tin nhan khan cap toi %s thanh cong!\n", phone.c_str());
  } else {
    Serial.printf("[SMS] Gui that bai! Ma loi HTTP: %d\n", httpCode);
  }
  http.end();
  return success;
}
