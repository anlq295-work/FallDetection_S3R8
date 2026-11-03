#include "config.h"
#include "sensors.h"
#include "edge_ai.h"
#include "alert_system.h"
#include "ble_provision.h"
#include "ota_manager.h"
#include <WiFi.h>
#include <esp_task_wdt.h>

SensorManager sensorMgr;
EdgeAIEngine  aiEngine;
AlertSystem   alertSys;

SystemState currentState = STATE_NORMAL;
FallEventType currentEventType = EVENT_NONE;

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

String wifiSSID, wifiPass, emergencyPhone, telegramChatId, telegramBotToken;
uint16_t configuredFloorMm = FLOOR_HEIGHT_DEFAULT_MM;

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

void processBleCommands() {
  String cmd;
  if (bleProvision.checkAndClearCommand(cmd)) {
    if (cmd == "CALIBRATE_FLOOR") {
      sensorMgr.calibrateFloor();
      configuredFloorMm = sensorMgr.getFloorThreshold();
      bleProvision.saveFloorThreshold(configuredFloorMm);
      bleProvision.updateStatus("FLOOR_CALIBRATED_OK:" + String(configuredFloorMm));
    } else if (cmd == "CANCEL_ALARM") {
      Serial.println("[BLE] Nhan lenh tu App: Huy canh bao khan cap");
      currentState = STATE_RESOLVED;
      alertSys.setIndicator(0x00FF00, false);
      alertSys.setBuzzerPattern(BUZZER_CONFIRM_BEEP);
      sensorMgr.resetFloorTracking();
      delay(1000);
      currentState = STATE_NORMAL;
      alertSys.setBuzzerPattern(BUZZER_SILENT);
      bleProvision.updateStatus("ALARM_CANCELLED_REMOTE");
    } else if (cmd == "TEST_ALARM") {
      Serial.println("[BLE] Nhan lenh tu App: Test bao dong");
      alertSys.setIndicator(0xFF0000, true);
      alertSys.playBeep(400);
      alertSys.setIndicator(0x00FF00, false);
      bleProvision.updateStatus("TEST_ALARM_COMPLETED");
    } else if (cmd == "PANIC_SOS") {
      Serial.println("[BLE] Nhan lenh SOS tu xa tu ung dung!");
      currentEventType = EVENT_MANUAL_SOS;
      currentState = STATE_ALERT;
    } else if (cmd == "GET_HISTORY") {
      String histJson = bleProvision.getEventHistoryJson();
      Serial.printf("[BLE] Gui lich su hop den NVS (%d bytes): %s\n", histJson.length(), histJson.c_str());
      bleProvision.sendTelemetry(histJson);
      bleProvision.updateStatus("HISTORY_SENT");
    } else if (cmd == "ADD_TEST_EVENT") {
      bleProvision.logFallEvent(EVENT_FALL_IMPACT, 680.0f, 88, 165);
      String histJson = bleProvision.getEventHistoryJson();
      Serial.printf("[BLE] Da tao su kien test hop den: %s\n", histJson.c_str());
      bleProvision.sendTelemetry(histJson);
      bleProvision.updateStatus("TEST_EVENT_ADDED");
    } else if (cmd == "CLEAR_HISTORY") {
      bleProvision.clearHistory();
      bleProvision.updateStatus("HISTORY_CLEARED_OK");
    } else if (cmd.startsWith("OTA_HTTP:")) {
      String url = cmd.substring(9);
      url.trim();
      Serial.printf("[BLE] Nhan lenh OTA qua Wi-Fi: %s\n", url.c_str());
      alertSys.setIndicator(0x800080, false); // Mau tim chi bao dang nap OTA
      otaManager.performHttpOta(url);
    } else if (cmd == "OTA_LATEST" || cmd == "OTA_GITHUB_LATEST") {
      String latestUrl = "https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/build/firmware.bin";
      Serial.printf("[BLE] Nhan lenh OTA ban moi nhat tu GitHub: %s\n", latestUrl.c_str());
      alertSys.setIndicator(0x800080, false); // Mau tim chi bao dang nap OTA
      otaManager.performHttpOta(latestUrl);
    }
  }

  if (bleProvision.isRebootRequested()) {
    Serial.println("[SYSTEM] Nhan yeu cau khoi dong lai tu BLE...");
    delay(800);
    ESP.restart();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1. Khởi tạo Hardware Task Watchdog Timer (10 giây) chống treo chip
  esp_task_wdt_init(WDT_TIMEOUT_SECONDS, true);
  esp_task_wdt_add(NULL);

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

  // 3. Khởi động BLE GATT Server để ứng dụng di động cấu hình và giám sát
  bleProvision.init("FallDetector_S3R8");

  // 4. Đọc cấu hình NVS Flash
  if (bleProvision.loadCredentials(wifiSSID, wifiPass, emergencyPhone, telegramChatId, telegramBotToken, configuredFloorMm)) {
    sensorMgr.setFloorThreshold(configuredFloorMm);
    Serial.printf("[SYSTEM] Da tai cau hinh: Wi-Fi=%s | SDT=%s | Nguong san=%d mm\n", 
                  wifiSSID.c_str(), emergencyPhone.c_str(), configuredFloorMm);
    
    if (alertSys.connectWiFi(wifiSSID, wifiPass)) {
      String ipNotice = "CONNECTED_IP:" + WiFi.localIP().toString();
      bleProvision.updateStatus(ipNotice);
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

  // 6. Khởi động bộ suy luận mạng Nơ-ron Edge AI
  if (!aiEngine.init()) {
    Serial.println("[LOI] Khoi tao Edge AI Engine that bai!");
    currentState = STATE_DEVICE_FAULT;
  }

  if (currentState != STATE_DEVICE_FAULT) {
    alertSys.setIndicator(0x00FF00, false);
    delay(800);
  }
}

void loop() {
  // Reset Watchdog Timer ngăn chip bị treo
  esp_task_wdt_reset();

  unsigned long now = millis();

  // 1. Cập nhật âm thanh còi phi chặn (Non-blocking buzzer patterns)
  alertSys.updateBuzzer();

  // 2. Xử lý nút bấm vật lý và lệnh điều khiển từ xa qua BLE
  handleButtonInput();
  processBleCommands();

  // 3. Duy trì kết nối Wi-Fi ngầm (non-blocking)
  alertSys.maintainWiFi(wifiSSID, wifiPass);

  // 4. Chu kỳ lấy mẫu 20 Hz (50ms)
  if (now - lastSampleTime >= (1000 / SAMPLE_RATE_HZ)) {
    lastSampleTime = now;
    sensorMgr.update();

    // 5. Suy luận trạng thái khi cửa sổ trượt đủ 40 mẫu (2 giây)
    if (sensorMgr.isWindowReady() && currentState != STATE_DEVICE_FAULT) {
      float features[NUM_FEATURES];
      sensorMgr.extractFeatures(features);

      float confidence = 0.0f;
      FallDiagnostic diag;
      AIClass predictedClass = aiEngine.predictWithDiagnostics(features, &confidence, &diag);

      // Gửi Telemetry thời gian thực qua BLE mỗi 250ms cho App điện thoại
      if (now - lastTelemetryTime >= 250) {
        lastTelemetryTime = now;
        const char* classNames[] = {"STAND", "SIT", "LIE", "FALL"};
        const char* stateNames[] = {"NORMAL", "SUSPECTED", "PRE_ALARM", "ALERT", "ACK", "RESOLVED", "FAULT"};

        char telemBuf[160];
        snprintf(telemBuf, sizeof(telemBuf), 
                 "{\"st\":\"%s\",\"cls\":\"%s\",\"cf\":%.2f,\"h\":%d,\"m\":%d,\"s\":%d,\"dr\":%.0f}",
                 stateNames[currentState], classNames[predictedClass], confidence,
                 (int)features[2], (int)features[0], (int)features[1], features[5]);
        bleProvision.sendTelemetry(String(telemBuf));
      }

      // Đèn ngủ thông minh: Tự động soi đường khi phát hiện người thức dậy ban đêm
      if (currentState == STATE_NORMAL) {
        SensorSample s = sensorMgr.getLatestSample();
        bool humanMoving = s.pir_active || (s.radar_motion_max >= 15);
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
