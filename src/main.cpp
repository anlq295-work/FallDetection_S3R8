#include "config.h"
#include "sensors.h"
#include "edge_ai.h"
#include "alert_system.h"
#include "ble_provision.h"
#include "ota_manager.h"
#include "web_server.h"
#include <WiFi.h>
#include <esp_task_wdt.h>
#include <esp_idf_version.h>
#include <nvs_flash.h>
#include <ArduinoJson.h>
#include <time.h>

SensorManager sensorMgr;
EdgeAIEngine  aiEngine;
AlertSystem   alertSys;

SystemState currentState = STATE_NORMAL;
FallEventType currentEventType = EVENT_NONE;

String wifiSSID, wifiPass, emergencyPhone, telegramChatId, telegramBotToken;
uint16_t configuredFloorMm = FLOOR_HEIGHT_DEFAULT_MM;

// Dữ liệu Telemetry thời gian thực được cập nhật cho cả BLE và Wi-Fi Web Server
AIClass lastPredictedClass = CLASS_STAND;
float lastConfidence = 0.0f;
float lastFeatures[NUM_FEATURES] = {0};
bool lastPirState = false;

String getSystemTelemetryJson() {
  const char* classNames[] = {"STAND", "SIT", "LIE", "FALL"};
  const char* stateNames[] = {"NORMAL", "SUSPECTED", "PRE_ALARM", "ALERT", "ACK", "RESOLVED", "FAULT"};

  int h = (lastFeatures[2] > 0) ? (int)lastFeatures[2] : (int)sensorMgr.getPrimaryTofDistance();
  int m = (lastFeatures[0] > 0) ? (int)lastFeatures[0] : (int)sensorMgr.getRadarPeakMotion();
  int s = (lastFeatures[1] > 0) ? (int)lastFeatures[1] : (int)sensorMgr.getRadarPeakStatic();

  char telemBuf[256];
  snprintf(telemBuf, sizeof(telemBuf),
    "{\"st\":\"%s\",\"cls\":\"%s\",\"cf\":%.2f,\"h\":%d,\"m\":%d,\"s\":%d,\"dr\":%.0f,\"pir\":%d,\"ip\":\"%s\",\"rssi\":%d,\"uptime\":%lu,\"ver\":\"%s\"}",
    stateNames[currentState], classNames[lastPredictedClass], lastConfidence,
    h, m, s, lastFeatures[5],
    (int)lastPirState, (WiFi.status() == WL_CONNECTED) ? WiFi.localIP().toString().c_str() : "0.0.0.0",
    (WiFi.status() == WL_CONNECTED) ? WiFi.RSSI() : 0, (millis() / 1000), FIRMWARE_VERSION);
  return String(telemBuf);
}

String getSystemStatusJson() {
  StaticJsonDocument<384> doc;
  doc["version"] = FIRMWARE_VERSION;
  doc["state"] = currentState;
  doc["ip"] = (WiFi.status() == WL_CONNECTED) ? WiFi.localIP().toString() : "DISCONNECTED";
  doc["rssi"] = (WiFi.status() == WL_CONNECTED) ? WiFi.RSSI() : 0;
  doc["floor_mm"] = configuredFloorMm;
  doc["buzzer_active_high"] = alertSys.isBuzzerActiveHigh();
  doc["buzzer_muted"] = alertSys.isMuted();
  doc["pir_enabled"] = ENABLE_PIR_SENSOR;
  doc["pir_active"] = lastPirState;
  doc["free_heap"] = ESP.getFreeHeap();
  doc["uptime_sec"] = millis() / 1000;
  String out;
  serializeJson(doc, out);
  return out;
}

unsigned long lastSampleTime = 0;
unsigned long lastTelemetryTime = 0;
unsigned long stateTimer = 0;
unsigned long preAlarmStart = 0;
unsigned long recoveryTimer = 0;
bool recoveryTracking = false;

// Thông số sự kiện va chạm ghi nhận
float recordedImpactVelocity = 0.0f;
uint8_t recordedImpactMotion = 0;
uint16_t recordedTargetDist = 0;

// Quản lý nút bấm vật lý GPIO 0 (BOOT): Nhấn nhả (Hủy) vs Nhấn giữ 3s (SOS thủ công)
static unsigned long btnPressStartTime = 0;
static bool btnIsHeld = false;
static bool sosTriggeredByHold = false;

void handleButtonInput() {
  int btnState = digitalRead(PIN_CANCEL_BTN);

  if (btnState == LOW) {
    if (!btnIsHeld) {
      btnIsHeld = true;
      btnPressStartTime = millis();
      sosTriggeredByHold = false;
    } else {
      // Nhấn giữ nút BOOT trong 3 giây -> Kích hoạt SOS khẩn cấp bằng tay (Panic Button)
      if (!sosTriggeredByHold && (millis() - btnPressStartTime >= MANUAL_SOS_HOLD_TIME_MS)) {
        sosTriggeredByHold = true;
        Serial.println("[PANIC] Nguoi dung nhan giu nut 3 giay -> KICH HOAT SOS THU CONG KHAN CAP!");
        currentEventType = EVENT_MANUAL_SOS;
        recordedImpactVelocity = 0.0f;
        recordedImpactMotion = 100;
        recordedTargetDist = 0;
        currentState = STATE_ALERT;
      }
    }
  } else {
    if (btnIsHeld) {
      unsigned long holdDuration = millis() - btnPressStartTime;
      btnIsHeld = false;

      // Nhấn nhả thông thường (< 2.5s) để giải tỏa / hủy báo động
      if (!sosTriggeredByHold && holdDuration > 50 && holdDuration < MANUAL_SOS_HOLD_TIME_MS) {
        if (currentState == STATE_PRE_ALARM || currentState == STATE_ALERT || currentState == STATE_ACKNOWLEDGED) {
          Serial.println("[USER] Da bam nut vat ly GPIO 0 -> Giai toa su co!");
          currentState = STATE_RESOLVED;
          alertSys.setIndicator(0x00FF00, false);
          alertSys.setBuzzerPattern(BUZZER_CONFIRM_BEEP);
          bleProvision.updateStatus("ALERT_MANUALLY_CANCELLED");
          sensorMgr.resetFloorTracking();
          delay(1000);
          currentState = STATE_NORMAL;
          alertSys.setBuzzerPattern(BUZZER_SILENT);
        }
      }
    }
  }
}

void executeSystemCommand(const String& cmd) {
  if (cmd == "CALIBRATE_FLOOR") {
    sensorMgr.calibrateFloor();
    configuredFloorMm = sensorMgr.getFloorThreshold();
    bleProvision.saveFloorThreshold(configuredFloorMm);
    bleProvision.updateStatus("FLOOR_CALIBRATED_OK:" + String(configuredFloorMm));
  } else if (cmd == "CANCEL_ALARM") {
    Serial.println("[CMD] Nhan lenh: Huy canh bao khan cap");
    currentState = STATE_RESOLVED;
    alertSys.setIndicator(0x00FF00, false);
    alertSys.setBuzzerPattern(BUZZER_CONFIRM_BEEP);
    sensorMgr.resetFloorTracking();
    delay(1000);
    currentState = STATE_NORMAL;
    alertSys.setBuzzerPattern(BUZZER_SILENT);
    bleProvision.updateStatus("ALARM_CANCELLED_REMOTE");
  } else if (cmd == "TEST_ALARM") {
    Serial.println("[CMD] Nhan lenh: Test bao dong");
    alertSys.setIndicator(0xFF0000, true);
    alertSys.playBeep(400);
    alertSys.setIndicator(0x00FF00, false);
    bleProvision.updateStatus("TEST_ALARM_COMPLETED");
  } else if (cmd == "PANIC_SOS") {
    Serial.println("[CMD] Nhan lenh SOS tu xa!");
    currentEventType = EVENT_MANUAL_SOS;
    recordedImpactVelocity = 0.0f;
    recordedImpactMotion = 100;
    recordedTargetDist = 0;
    currentState = STATE_ALERT;
  } else if (cmd == "GET_HISTORY") {
    String histJson = bleProvision.getEventHistoryJson();
    Serial.printf("[CMD] Gui lich su hop den NVS (%d bytes)\n", histJson.length());
    bleProvision.sendTelemetry(histJson);
    bleProvision.updateStatus("HISTORY_SENT");
  } else if (cmd == "ADD_TEST_EVENT") {
    bleProvision.logFallEvent(EVENT_FALL_IMPACT, 680.0f, 88, 165);
    String histJson = bleProvision.getEventHistoryJson();
    Serial.printf("[CMD] Da tao su kien test hop den: %s\n", histJson.c_str());
    bleProvision.sendTelemetry(histJson);
    bleProvision.updateStatus("TEST_EVENT_ADDED");
  } else if (cmd == "CLEAR_HISTORY") {
    bleProvision.clearHistory();
    bleProvision.updateStatus("HISTORY_CLEARED_OK");
  } else if (cmd == "GET_VERSION") {
    bleProvision.updateStatus(String("FIRMWARE_VERSION:") + FIRMWARE_VERSION);
  } else if (cmd == "BUZZER_ACTIVE_LOW" || cmd == "SET_BUZZER_LOW") {
    alertSys.setBuzzerActiveHigh(false);
    bleProvision.updateStatus("BUZZER_MODE:ACTIVE_LOW");
    Serial.println("[CMD] Da chuyen sang coi kich muc Thap (Active-LOW)!");
  } else if (cmd == "BUZZER_ACTIVE_HIGH" || cmd == "SET_BUZZER_HIGH") {
    alertSys.setBuzzerActiveHigh(true);
    bleProvision.updateStatus("BUZZER_MODE:ACTIVE_HIGH");
    Serial.println("[CMD] Da chuyen sang coi kich muc Cao (Active-HIGH)!");
  } else if (cmd == "BUZZER_MUTE") {
    alertSys.setMuted(true);
    bleProvision.updateStatus("BUZZER_MUTED");
    Serial.println("[CMD] Da tat coi hoan toan (Mute)!");
  } else if (cmd == "BUZZER_UNMUTE") {
    alertSys.setMuted(false);
    bleProvision.updateStatus("BUZZER_UNMUTED");
    Serial.println("[CMD] Da bat lai coi (Unmute)!");
  } else if (cmd == "TEST_BEEP") {
    alertSys.playBeep(200);
    bleProvision.updateStatus("BEEP_TEST_OK");
  } else if (cmd.startsWith("NIGHTLIGHT_SCHEDULE:")) {
    int enabled, startHour, startMinute, endHour, endMinute;
    String payload = cmd.substring(String("NIGHTLIGHT_SCHEDULE:").length());
    if (sscanf(payload.c_str(), "%d,%d,%d,%d,%d", &enabled, &startHour, &startMinute, &endHour, &endMinute) == 5 &&
        startHour >= 0 && startHour < 24 && startMinute >= 0 && startMinute < 60 &&
        endHour >= 0 && endHour < 24 && endMinute >= 0 && endMinute < 60) {
      alertSys.setNightlightSchedule(enabled != 0, startHour, startMinute, endHour, endMinute);
      bleProvision.updateStatus("NIGHTLIGHT_SCHEDULE_SAVED");
    } else {
      bleProvision.updateStatus("NIGHTLIGHT_SCHEDULE_ERROR");
    }
  } else if (cmd.startsWith("OTA_HTTP:")) {
    String url = cmd.substring(9);
    url.trim();
    Serial.printf("[CMD] Nhan lenh OTA qua Wi-Fi: %s\n", url.c_str());
    alertSys.setIndicator(0x800080, false);
    otaManager.performHttpOta(url);
  } else if (cmd == "OTA_LATEST" || cmd == "OTA_GITHUB_LATEST") {
    String latestUrl = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/firmware.bin";
    Serial.printf("[CMD] Nhan lenh OTA ban moi nhat tu GitHub: %s\n", latestUrl.c_str());
    alertSys.setIndicator(0x800080, false);
    otaManager.performHttpOta(latestUrl);
  } else if (cmd == "REBOOT") {
    Serial.println("[CMD] Khoi dong lai chip ESP32-S3...");
    delay(500);
    ESP.restart();
  }
}

void processBleCommands() {
  String cmd;
  if (bleProvision.checkAndClearCommand(cmd)) {
    executeSystemCommand(cmd);
  }

  if (bleProvision.isRebootRequested()) {
    Serial.println("[SYSTEM] Nhan yeu cau khoi dong lai tu BLE...");
    delay(800);
    ESP.restart();
  }
}

void setup() {
  // 1. KHỞI TẠO NVS FLASH AN TOÀN (Tự động format/sửa lỗi nếu trắng flash hoặc thiếu trang)
  esp_err_t nvs_err = nvs_flash_init();
  if (nvs_err == ESP_ERR_NVS_NO_FREE_PAGES || nvs_err == ESP_ERR_NVS_NEW_VERSION_FOUND || nvs_err == ESP_ERR_NVS_NOT_FOUND) {
    nvs_flash_erase();
    nvs_flash_init();
  }

  // 2. TẮT CÒI PHẦN CỨNG NGAY TRONG MICROGIÂY ĐẦU TIÊN (Trước mọi delay và Serial)
  alertSys.earlyHardwareMute();

  Serial.begin(115200);
  delay(100);

  Serial.printf("[BUZZER] Boot initial: Polarity=%s | Muted=%s | GPIO5=%d (3.3V quiet for 3V3 Active-LOW)\n",
                alertSys.isBuzzerActiveHigh() ? "ACTIVE-HIGH (0V quiet)" : "ACTIVE-LOW (3.3V quiet)",
                alertSys.isMuted() ? "YES" : "NO",
                digitalRead(PIN_BUZZER));

  // Watchdog được đăng ký ở cuối setup(), sau khi BLE, Wi-Fi và cảm biến
  // đã khởi tạo xong. Đăng ký quá sớm làm reset trong lúc boot.

  // 2. Kiểm tra phần cứng ESP32-S3 N16R8 và bộ nhớ Octal PSRAM OPI
  Serial.println("\n=======================================================");
  Serial.println("  HE THONG GIAM SAT VA PHAT HIEN TE NGA - ESP32-S3 N16R8");
  Serial.println("  (Time-of-Flight VL53L1X + 24GHz FMCW Radar LD2410B)");
  Serial.println("  + 16MB Flash, 8MB Octal PSRAM, Smart Nightlight & WDT");
  Serial.println("=======================================================");
  Serial.printf("[MEM] SRAM noi kha dung: %d KB\n", ESP.getFreeHeap() / 1024);
  Serial.printf("[FLASH] Kich thuoc Flash: %d MB\n", ESP.getFlashChipSize() / (1024 * 1024));
  if (psramFound()) {
    Serial.printf("[MEM] Octal PSRAM OPI kha dung: %d MB\n", ESP.getFreePsram() / (1024 * 1024));
  } else {
    Serial.println("[CANH BAO] KHONG TIM THAY PSRAM! Kiem tra menu OPI PSRAM trong IDE.");
  }

  pinMode(PIN_CANCEL_BTN, INPUT_PULLUP);
  alertSys.init();
  delay(1000); // Giữ màu khởi động đủ lâu để kiểm tra trực tiếp
  delay(150); // Khoảng đệm ổn định nguồn điện LED trước khi khởi động sóng vô tuyến BLE
  Serial.println("[BOOT] LED init xong, bat dau BLE...");

  // 3. Khởi động BLE GATT Server để ứng dụng di động cấu hình và giám sát
  bleProvision.init("FallDetector_S3R8");
  Serial.println("[BOOT] BLE init xong, bat dau doc cau hinh...");

  // 4. Đọc cấu hình NVS Flash
  if (bleProvision.loadCredentials(wifiSSID, wifiPass, emergencyPhone, telegramChatId, telegramBotToken, configuredFloorMm)) {
    sensorMgr.setFloorThreshold(configuredFloorMm);
    Serial.printf("[SYSTEM] Da tai cau hinh: Wi-Fi=%s | SDT=%s | Nguong san=%d mm\n", 
                  wifiSSID.c_str(), emergencyPhone.c_str(), configuredFloorMm);
    
    if (alertSys.connectWiFi(wifiSSID, wifiPass)) {
      configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
      String ipNotice = "CONNECTED_IP:" + WiFi.localIP().toString();
      bleProvision.updateStatus(ipNotice);
      deviceWebServer.begin(
        getSystemTelemetryJson,
        []() { return bleProvision.getEventHistoryJson(); },
        getSystemStatusJson,
        executeSystemCommand
      );
    } else {
      bleProvision.updateStatus("WIFI_CONNECT_FAILED");
    }
  } else {
    Serial.println("[SYSTEM] Chua co cau hinh Wi-Fi. Mo App Android ket noi BLE de setup!");
    bleProvision.updateStatus("WAITING_BLE_CONFIG");
  }

  // 5. Khởi động cụm cảm biến đa phương thức (PIR + ToF + Radar LD2410B)
  if (!sensorMgr.init()) {
    Serial.println("[LOI] Khoi tao cum cam bien that bai!");
    currentState = STATE_DEVICE_FAULT;
  }
  Serial.printf("[BOOT] Sensor init xong, state=%d\n", currentState);

  // 6. Khởi động bộ suy luận mạng Nơ-ron Edge AI
  if (!aiEngine.init()) {
    Serial.println("[LOI] Khoi tao Edge AI Engine that bai!");
    currentState = STATE_DEVICE_FAULT;
  }
  Serial.printf("[BOOT] AI init xong, state=%d\n", currentState);

  if (currentState != STATE_DEVICE_FAULT) {
    alertSys.setIndicator(0x00FF00, false);
    Serial.println("[SYSTEM] SETUP COMPLETE - LED xanh la, bat dau vong lap.");
    delay(800);
  } else {
    Serial.println("[SYSTEM] SETUP COMPLETE - STATE_DEVICE_FAULT.");
  }

  // Chỉ bắt đầu giám sát watchdog sau khi setup đã hoàn tất.
#if ESP_IDF_VERSION >= ESP_IDF_VERSION_VAL(5, 0, 0)
  esp_task_wdt_config_t twdt_config = {
      .timeout_ms = WDT_TIMEOUT_SECONDS * 1000,
      .idle_core_mask = 0,
      .trigger_panic = true,
  };
  esp_task_wdt_reconfigure(&twdt_config);
  esp_task_wdt_add(NULL);
#else
  esp_task_wdt_init(WDT_TIMEOUT_SECONDS, true);
  esp_task_wdt_add(NULL);
#endif
  Serial.println("[BOOT] Watchdog da bat sau setup.");
}

void handleSerialCommands() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == 'T' || c == 't') {
      Serial.println("[CMD] Thu coi: Phat tieng beep 200ms...");
      alertSys.playBeep(200);
      Serial.println("[CMD] Thu coi xong.");
    } else if (c == 'H' || c == 'h') {
      alertSys.setMuted(false);
      alertSys.setBuzzerActiveHigh(true);
      Serial.println("[CMD] Chuyen phan cuc: Active-HIGH (Mute=High-Z, Beep=3.3V)");
    } else if (c == 'L' || c == 'l') {
      alertSys.setMuted(false);
      alertSys.setBuzzerActiveHigh(false);
      Serial.println("[CMD] Chuyen phan cuc: Active-LOW (Mute=High-Z, Beep=0V)");
    } else if (c == 'M' || c == 'm') {
      alertSys.setMuted(!alertSys.isMuted());
      Serial.printf("[CMD] Trang thai Mute: %s\n", alertSys.isMuted() ? "BAT (Yen lang)" : "TAT (Co coi)");
    } else if (c == 'S' || c == 's') {
      Serial.printf("[STATUS] State=%d | Pattern=%d | BuzHigh=%d | Muted=%d | PinVal=%d\n",
                    currentState, alertSys.getCurrentPattern(), alertSys.isBuzzerActiveHigh(),
                    alertSys.isMuted(), digitalRead(PIN_BUZZER));
    }
  }
}

void loop() {
  // Reset Watchdog Timer ngăn chip bị treo
  esp_task_wdt_reset();

  unsigned long now = millis();
  static SystemState lastLoggedState = STATE_NORMAL;
  if (currentState != lastLoggedState) {
    Serial.printf("[FSM] State changed: %d -> %d at %lu ms\n", lastLoggedState, currentState, now);
    lastLoggedState = currentState;
  }

  // 1. Cập nhật âm thanh còi phi chặn (Non-blocking buzzer patterns)
  alertSys.updateBuzzer();

  // 2. Xử lý nút bấm vật lý, lệnh điều khiển từ xa qua BLE và Serial
  handleButtonInput();
  processBleCommands();
  handleSerialCommands();

  // 3. Duy trì kết nối Wi-Fi ngầm (non-blocking) & Web Server API
  alertSys.maintainWiFi(wifiSSID, wifiPass);
  static bool lastWifiConnectedState = false;
  bool isWifiNow = (WiFi.status() == WL_CONNECTED);
  if (isWifiNow) {
    if (!deviceWebServer.isRunning()) {
      deviceWebServer.begin(
        getSystemTelemetryJson,
        []() { return bleProvision.getEventHistoryJson(); },
        getSystemStatusJson,
        executeSystemCommand
      );
    }
    deviceWebServer.handle();

    if (!lastWifiConnectedState) {
      lastWifiConnectedState = true;
      String ipNotice = "CONNECTED_IP:" + WiFi.localIP().toString();
      bleProvision.updateStatus(ipNotice);
      Serial.printf("[WIFI] Da cap IP thanh cong: %s\n", WiFi.localIP().toString().c_str());
    }
  } else {
    if (deviceWebServer.isRunning()) {
      deviceWebServer.stop();
    }
    lastWifiConnectedState = false;
  }

  // Luôn gửi Telemetry thời gian thực qua BLE mỗi 250ms cho App điện thoại
  if (now - lastTelemetryTime >= 250) {
    lastTelemetryTime = now;
    bleProvision.sendTelemetry(getSystemTelemetryJson());
  }

  // 4. Chu kỳ lấy mẫu 20 Hz (50ms)
  if (now - lastSampleTime >= (1000 / SAMPLE_RATE_HZ)) {
    lastSampleTime = now;
    sensorMgr.update();

    // Cập nhật giá trị tức thời từ cảm biến
    lastPirState = sensorMgr.getLatestSample().pir_active;

    // 5. Suy luận trạng thái khi cửa sổ trượt đủ 40 mẫu (2 giây)
    if (sensorMgr.isWindowReady() && currentState != STATE_DEVICE_FAULT) {
      float features[NUM_FEATURES];
      sensorMgr.extractFeatures(features);

      float confidence = 0.0f;
      FallDiagnostic diag;
      AIClass predictedClass = aiEngine.predictWithDiagnostics(features, &confidence, &diag);

      // Lưu trữ trạng thái telemetry mới nhất cho cả BLE và Wi-Fi Server
      lastPredictedClass = predictedClass;
      lastConfidence = confidence;
      memcpy(lastFeatures, features, sizeof(features));

      // Đèn ngủ thông minh: Tự động soi đường khi phát hiện người thức dậy ban đêm
      if (currentState == STATE_NORMAL) {
        SensorSample s = sensorMgr.getLatestSample();
#if ENABLE_PIR_SENSOR
        bool humanMoving = s.pir_active || (s.radar_motion_max >= 15);
#else
        // Khi không có PIR, dùng 100% Radar FMCW 24GHz (LD2410B) để nhận diện chuyển động & hiện diện
        bool humanMoving = (s.radar_motion_max >= 15);
#endif
        alertSys.updateNightlight(humanMoving);
      }

      // KÍCH HOẠT TÉ NGÃ 1: Cú ngã va chạm động năng mạnh (High-velocity Fall Impact)
      if (predictedClass == CLASS_FALL && currentState == STATE_NORMAL) {
        recordedImpactVelocity = features[5];
        recordedImpactMotion = (uint8_t)features[0];
        recordedTargetDist = (uint16_t)features[6];
        currentEventType = EVENT_FALL_IMPACT;

        Serial.printf("[EVENT] Phat hien xung va cham! V_drop=%.1f mm/s, Mot_peak=%d -> Chuyen sang SUSPECTED\n", 
                      recordedImpactVelocity, recordedImpactMotion);
        currentState = STATE_SUSPECTED;
        stateTimer = now;
      }

      // KÍCH HOẠT TÉ NGÃ 2: Ngã chậm / Ngất lịm / Nằm sàn bất động kéo dài quá 15s (Slow Fall / Slump)
      if (currentState == STATE_NORMAL && sensorMgr.isProlongedFloorInactivity(SLOW_FALL_FLOOR_TIME_MS)) {
        Serial.println("[EVENT] Phat hien nan nhan nam bat dong duoi san qua 15 giay! -> Kich hoat PRE-ALARM ngã chậm");
        recordedImpactVelocity = 0.0f;
        recordedImpactMotion = sensorMgr.getLatestSample().radar_motion_max;
        recordedTargetDist = sensorMgr.getLatestSample().radar_target_dist_cm;
        currentEventType = EVENT_SLOW_FALL;

        currentState = STATE_PRE_ALARM;
        preAlarmStart = now;
        recoveryTracking = false;
        alertSys.setBuzzerPattern(BUZZER_PRE_ALARM_PULSE);
      }
    }
  }

  // 6. Máy trạng thái hữu hạn FSM (Finite State Machine)
  switch (currentState) {
    case STATE_NORMAL:
      // Sau khi khởi động, đưa LED về trạng thái sẵn sàng màu xanh lá.
      // Nếu không có dòng này, LED giữ nguyên màu xanh dương khởi động.
      alertSys.setIndicator(0x00FF00, false);
      alertSys.setBuzzerPattern(BUZZER_SILENT);
      break;

    case STATE_SUSPECTED: {
      alertSys.setIndicator(0x332200, false);

      // Sau 2 giây theo dõi chuyển động sau va chạm
      if (now - stateTimer >= IMMOBILE_VERIFY_TIME_MS) {
        float f[NUM_FEATURES];
        sensorMgr.extractFeatures(f);
        float conf = 0.0f;
        FallDiagnostic diag;
        AIClass postPosture = aiEngine.predictWithDiagnostics(f, &conf, &diag);

        SensorSample latest = sensorMgr.getLatestSample();

        bool isAtFloor = (f[4] > 50 && f[4] <= configuredFloorMm) || (postPosture == CLASS_LIE);
        bool isImmobile = (latest.radar_motion_max <= POST_FALL_RADAR_MOTION_MAX);
        bool hasBreathing = (latest.radar_static_max >= POST_FALL_RADAR_STATIC_MIN);

        if (isAtFloor && isImmobile && hasBreathing) {
          Serial.println("[EVENT] Xac nhan nan nhan bat dong sat san -> KICH HOAT PRE-ALARM!");
          currentState = STATE_PRE_ALARM;
          preAlarmStart = now;
          recoveryTracking = false;
          alertSys.setBuzzerPattern(BUZZER_PRE_ALARM_PULSE);
        } else {
          Serial.println("[FILTER] Nguoi di chuyen tiep hoac khong phai nam san -> Bo qua bao dong gia.");
          currentState = STATE_NORMAL;
          alertSys.setBuzzerPattern(BUZZER_SILENT);
        }
      }
      break;
    }

    case STATE_PRE_ALARM: {
      // TẦNG 1: Cảnh báo tại chỗ 30s (LED vàng chớp nháy + Còi bíp đôi nhịp điệu)
      bool blink = ((now / 250) % 2 == 0);
      alertSys.setIndicator(blink ? 0xFFA500 : 0x000000, false);

      // TỰ ĐỘNG GIẢI TRỪ BÁO ĐỘNG KHI TỰ ĐỨNG DẬY:
      float f[NUM_FEATURES];
      sensorMgr.extractFeatures(f);
      float conf = 0.0f;
      AIClass curPosture = aiEngine.predict(f, &conf);

      bool upright = (curPosture == CLASS_STAND || curPosture == CLASS_SIT || f[2] >= STAND_HEIGHT_MIN_MM);
      if (upright) {
        if (!recoveryTracking) {
          recoveryTracking = true;
          recoveryTimer = now;
        } else if (now - recoveryTimer >= RECOVERY_CONFIRM_TIME_MS) {
          Serial.println("[RECOVERED] Nan nhan da tu dung day thanh cong! -> Tu dong huy Pre-alarm");
          currentState = STATE_RESOLVED;
          alertSys.setIndicator(0x00FF00, false);
          alertSys.setBuzzerPattern(BUZZER_CONFIRM_BEEP);
          sensorMgr.resetFloorTracking();
          bleProvision.updateStatus("VICTIM_AUTO_RECOVERED");
          delay(1200);
          currentState = STATE_NORMAL;
          alertSys.setBuzzerPattern(BUZZER_SILENT);
          break;
        }
      } else {
        recoveryTracking = false;
      }

      // Hết 30 giây Pre-alarm không hủy -> Kích hoạt Cấp cứu Tầng 2!
      if (now - preAlarmStart >= PRE_ALARM_TIMEOUT_MS) {
        Serial.println("[TIMEOUT] Het 30 giay! KICH HOAT CANH BAO KHAN CAP CAP CUU (TANG 2)!");
        currentState = STATE_ALERT;
      }
      break;
    }

    case STATE_ALERT: {
      // TẦNG 2: Còi hú dồn dập SOS + LED đỏ chớp khẩn cấp
      alertSys.setIndicator(0xFF0000, false);
      alertSys.setBuzzerPattern(BUZZER_ALERT_SIREN);

      // Ghi nhận vào Hộp đen Flash NVS
      bleProvision.logFallEvent(currentEventType, recordedImpactVelocity, recordedImpactMotion, recordedTargetDist);

      const char* reasonStr = "Phat hien va cham te nga manh!";
      if (currentEventType == EVENT_SLOW_FALL) {
        reasonStr = "Nan nhan nam bat dong duoi san qua 15 giay (Nghi ngo dot quy / nga cham)!";
      } else if (currentEventType == EVENT_MANUAL_SOS) {
        reasonStr = "Nguoi dung chu dong nhan giu nut cap cuu SOS!";
      }

      char msg[380];
      snprintf(msg, sizeof(msg),
        "🚨 <b>CANH BAO NGUY HIEM: %s</b>\n"
        "Ly do: <i>%s</i>\n"
        "----------------------------\n"
        "• Toc do roi: <b>%.0f mm/s</b>\n"
        "• Dong nang: <b>%d/100</b>\n"
        "• Cu ly Radar: <b>%d cm</b>\n"
        "• Thoi gian he thong: %lu giay\n"
        "⚠️ <b>Kiem tra phong va ho tro ngay lap tuc!</b>",
        (currentEventType == EVENT_MANUAL_SOS) ? "NUT BAM SOS KHAN CAP" : "PHAT HIEN TE NGA",
        reasonStr, recordedImpactVelocity, recordedImpactMotion, recordedTargetDist, (now / 1000));

      alertSys.sendTelegramAlert(telegramBotToken, telegramChatId, String(msg));
      alertSys.sendSmsGateway(emergencyPhone, 
        "CANH BAO KHAN CAP: Phat hien te nga hoac nut SOS da bam! Kiem tra ngay!");

      bleProvision.updateStatus("EMERGENCY_DISPATCHED");
      currentState = STATE_ACKNOWLEDGED;
      break;
    }

    case STATE_ACKNOWLEDGED:
      // Tắt còi sau khi gửi tin để tránh làm hoảng loạn, duy trì LED đỏ nhấp nháy tại hiện trường
      alertSys.setBuzzerPattern(BUZZER_SILENT);
      alertSys.setIndicator(((now / 500) % 2 == 0) ? 0xFF0000 : 0x000000, false);
      break;

    case STATE_DEVICE_FAULT:
      alertSys.setBuzzerPattern(BUZZER_SILENT);
      alertSys.setIndicator(((now / 200) % 2 == 0) ? 0x9600FF : 0x000000, false);
      
      if (now - stateTimer >= 5000) {
        stateTimer = now;
        if (sensorMgr.init()) {
          Serial.println("[RECOVERY] Khoi phuc cam bien thanh cong!");
          currentState = STATE_NORMAL;
        }
      }
      break;

    default:
      currentState = STATE_NORMAL;
      break;
  }
}
