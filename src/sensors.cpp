#include "sensors.h"
#include <Wire.h>
#include <esp_heap_caps.h>
#include <esp_task_wdt.h>

static volatile bool pirTriggered = false;
static void IRAM_ATTR pirISR() {
  pirTriggered = true;
}

// Lệnh cấu hình LD2410B
static const uint8_t CMD_ENABLE_CONF[] = {0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01};
static const uint8_t CMD_ENABLE_ENG[]  = {0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0x62, 0x00, 0x04, 0x03, 0x02, 0x01};
static const uint8_t CMD_END_CONF[]    = {0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01};

SensorManager::SensorManager() 
  : currentRoiIdx(0), primaryTofDistance(0), tofHealthy(false), 
    lastTofReadTime(0), lastTofAttemptTime(0),
    radarTargetDist(0), radarPeakMotion(0), radarPeakStatic(0),
    radarTargetState(0), radarHealthy(false), lastRadarFrameTime(0),
    radarState(RADAR_WAIT_H0), radarExpectedLen(0), radarPayloadIdx(0),
    radarBaudRate(256000), lastBaudSwitchTime(0), radarBaudLocked(false),
    floorThresholdMm(FLOOR_HEIGHT_DEFAULT_MM),
    floorStartTime(0), isCurrentlyAtFloor(false),
    windowBuffer(nullptr), bufferHead(0), sampleCount(0) {
  memset(tofDistances, 0, sizeof(tofDistances));
  memset(tofHistory, 0, sizeof(tofHistory));
  memset(historyIdx, 0, sizeof(historyIdx));
  memset(radarMotionEnergies, 0, sizeof(radarMotionEnergies));
  memset(radarStaticEnergies, 0, sizeof(radarStaticEnergies));
  memset(radarPayload, 0, sizeof(radarPayload));
}

void SensorManager::recoverI2CBus(uint8_t sdaPin, uint8_t sclPin) {
  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, OUTPUT_OPEN_DRAIN);
  digitalWrite(sclPin, HIGH);
  delayMicroseconds(10);

  if (digitalRead(sdaPin) == LOW) {
    Serial.println("[I2C] Bus SDA bi treo LOW. Dang giai phong bus I2C (9 clock pulses)...");
    for (int i = 0; i < 9; i++) {
      digitalWrite(sclPin, LOW);
      delayMicroseconds(10);
      digitalWrite(sclPin, HIGH);
      delayMicroseconds(10);
      if (digitalRead(sdaPin) == HIGH) break;
    }
    pinMode(sdaPin, OUTPUT_OPEN_DRAIN);
    digitalWrite(sdaPin, LOW);
    delayMicroseconds(10);
    digitalWrite(sclPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(sdaPin, HIGH);
    delayMicroseconds(10);
  }
}

uint16_t SensorManager::computeMedian(uint16_t* arr, uint8_t size) {
  uint16_t temp[3];
  for (uint8_t i = 0; i < size; i++) temp[i] = arr[i];
  if (temp[0] > temp[1]) { uint16_t t = temp[0]; temp[0] = temp[1]; temp[1] = t; }
  if (temp[1] > temp[2]) { uint16_t t = temp[1]; temp[1] = temp[2]; temp[2] = t; }
  if (temp[0] > temp[1]) { uint16_t t = temp[0]; temp[0] = temp[1]; temp[1] = t; }
  return temp[1];
}

bool SensorManager::initTofSensor() {
  lastTofAttemptTime = millis();
  recoverI2CBus(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.setClock(100000); // 100 kHz chuan on dinh tren breadboard va day noi
  tof.setTimeout(500);

  // VL53L1X luôn dùng địa chỉ mặc định 0x29. Kiểm tra trực tiếp để tránh
  // quét 126 địa chỉ I2C và làm watchdog reset trong lúc khởi động.
  esp_task_wdt_reset();
  Wire.beginTransmission(0x29);
  bool addressFound = (Wire.endTransmission() == 0);
  esp_task_wdt_reset();

  if (!addressFound) {
    tofHealthy = false;
    return false;
  }

  if (tof.init()) {
    tof.setDistanceMode(VL53L1X::Medium);
    tof.setMeasurementTimingBudget(40000); // 40ms budget
    tof.startContinuous(40);
    tofHealthy = true;
    lastTofReadTime = millis();
    Serial.println("[SENSORS] ToF VL53L1X khoi dong thanh cong tren dia chi 0x29!");
    return true;
  } else {
    tofHealthy = false;
    return false;
  }
}

void SensorManager::configureRadarLD2410() {
  Serial2.write(CMD_ENABLE_CONF, sizeof(CMD_ENABLE_CONF));
  delay(50);
  Serial2.write(CMD_ENABLE_ENG, sizeof(CMD_ENABLE_ENG));
  delay(50);
  Serial2.write(CMD_END_CONF, sizeof(CMD_END_CONF));
  delay(50);
}

void SensorManager::checkBaudRateAutoDetect() {
  if (!radarBaudLocked && (millis() - lastBaudSwitchTime >= 2000)) {
    lastBaudSwitchTime = millis();
    radarBaudRate = (radarBaudRate == 256000) ? 115200 : 256000;
    Serial2.updateBaudRate(radarBaudRate);
    radarState = RADAR_WAIT_H0;
    configureRadarLD2410();
  }
}

bool SensorManager::init() {
  // 1. Cap phat Circular Buffer tren Octal PSRAM cua ESP32-S3R8
  if (psramFound()) {
    windowBuffer = (SensorSample*)heap_caps_malloc(sizeof(SensorSample) * WINDOW_SIZE, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (windowBuffer) {
      Serial.printf("[SENSORS] Cap phat circular buffer tren Octal PSRAM (%d bytes)\n", (int)(sizeof(SensorSample) * WINDOW_SIZE));
    }
  }
  if (!windowBuffer) {
    windowBuffer = (SensorSample*)malloc(sizeof(SensorSample) * WINDOW_SIZE);
  }
  if (!windowBuffer) {
    Serial.println("[SENSORS] Loi: khong du bo nho de cap phat sensor window buffer.");
    return false;
  }

  // 2. Cam bien hong ngoai PIR AM312
#if ENABLE_PIR_SENSOR
  pinMode(PIN_PIR, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_PIR), pirISR, RISING);
  Serial.println("[SENSORS] Khoi dong PIR AM312 thanh cong (GPIO4).");
#else
  pinMode(PIN_PIR, INPUT_PULLDOWN);
#endif

  // 3. Khoi dong ToF VL53L1X
  initTofSensor();

  // 4. Khoi dong Radar FMCW LD2410B qua Serial2 voi pullup an toan
  pinMode(PIN_RADAR_RX, INPUT_PULLUP);
  pinMode(PIN_RADAR_TX, OUTPUT);
  Serial2.begin(256000, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  radarBaudRate = 256000;
  lastBaudSwitchTime = millis();
  radarBaudLocked = false;
  radarState = RADAR_WAIT_H0;
  configureRadarLD2410();
  lastRadarFrameTime = millis();

  return true;
}

void SensorManager::processRadarPayload(uint8_t* payload, uint16_t len) {
  if (len < 10) return;
  uint8_t dataType = payload[0];

  if (dataType == 0x01 || dataType == 0x02) {
    radarTargetState = payload[2];
    uint16_t moveDist = payload[3] | ((uint16_t)payload[4] << 8);
    uint8_t  moveEnergy = payload[5];
    uint16_t statDist = payload[6] | ((uint16_t)payload[7] << 8);
    uint8_t  statEnergy = payload[8];
    uint16_t detectDist = (len >= 11) ? (payload[9] | ((uint16_t)payload[10] << 8)) : 0;

    radarPeakMotion = moveEnergy;
    radarPeakStatic = statEnergy;
    radarTargetDist = (radarTargetState == 1) ? moveDist : ((radarTargetState == 2) ? statDist : detectDist);

    if (dataType == 0x01 && len >= 30) {
      // Che do Engineering Mode: 9 cong dong nang va 9 cong tinh
      for (int i = 0; i < 9 && (13 + i < len); i++) {
        radarMotionEnergies[i] = payload[13 + i];
        if (radarMotionEnergies[i] > radarPeakMotion) {
          radarPeakMotion = radarMotionEnergies[i];
        }
      }
      for (int i = 0; i < 9 && (22 + i < len); i++) {
        radarStaticEnergies[i] = payload[22 + i];
        if (radarStaticEnergies[i] > radarPeakStatic) {
          radarPeakStatic = radarStaticEnergies[i];
        }
      }
    } else {
      // Che do Normal Mode: Tong hop nang luong theo cong cu ly (moi cong ~75cm)
      int targetGate = (radarTargetDist > 0) ? (radarTargetDist / 75) : 0;
      if (targetGate > 8) targetGate = 8;
      for (int i = 0; i < 9; i++) {
        if (i == targetGate) {
          radarMotionEnergies[i] = moveEnergy;
          radarStaticEnergies[i] = statEnergy;
        } else if (abs(i - targetGate) == 1) {
          radarMotionEnergies[i] = moveEnergy / 2;
          radarStaticEnergies[i] = statEnergy / 2;
        } else {
          radarMotionEnergies[i] = 0;
          radarStaticEnergies[i] = 0;
        }
      }
    }
  }
}

void SensorManager::parseRadarStream() {
  while (Serial2.available() > 0) {
    uint8_t b = Serial2.read();
    switch (radarState) {
      case RADAR_WAIT_H0:
        if (b == 0xF4) radarState = RADAR_WAIT_H1;
        break;
      case RADAR_WAIT_H1:
        radarState = (b == 0xF3) ? RADAR_WAIT_H2 : ((b == 0xF4) ? RADAR_WAIT_H1 : RADAR_WAIT_H0);
        break;
      case RADAR_WAIT_H2:
        radarState = (b == 0xF2) ? RADAR_WAIT_H3 : ((b == 0xF4) ? RADAR_WAIT_H1 : RADAR_WAIT_H0);
        break;
      case RADAR_WAIT_H3:
        radarState = (b == 0xF1) ? RADAR_READ_LEN0 : ((b == 0xF4) ? RADAR_WAIT_H1 : RADAR_WAIT_H0);
        break;
      case RADAR_READ_LEN0:
        radarExpectedLen = b;
        radarState = RADAR_READ_LEN1;
        break;
      case RADAR_READ_LEN1:
        radarExpectedLen |= ((uint16_t)b << 8);
        if (radarExpectedLen >= 4 && radarExpectedLen <= 60) {
          radarPayloadIdx = 0;
          radarState = RADAR_READ_PAYLOAD;
        } else {
          radarState = RADAR_WAIT_H0;
        }
        break;
      case RADAR_READ_PAYLOAD:
        if (radarPayloadIdx < sizeof(radarPayload)) {
          radarPayload[radarPayloadIdx++] = b;
        }
        if (radarPayloadIdx >= radarExpectedLen) {
          radarState = RADAR_WAIT_T0;
        }
        break;
      case RADAR_WAIT_T0:
        radarState = (b == 0xF8) ? RADAR_WAIT_T1 : RADAR_WAIT_H0;
        break;
      case RADAR_WAIT_T1:
        radarState = (b == 0xF7) ? RADAR_WAIT_T2 : RADAR_WAIT_H0;
        break;
      case RADAR_WAIT_T2:
        radarState = (b == 0xF6) ? RADAR_WAIT_T3 : RADAR_WAIT_H0;
        break;
      case RADAR_WAIT_T3:
        if (b == 0xF5) {
          radarHealthy = true;
          radarBaudLocked = true;
          lastRadarFrameTime = millis();
          processRadarPayload(radarPayload, radarExpectedLen);
        }
        radarState = RADAR_WAIT_H0;
        break;
    }
  }
  checkBaudRateAutoDetect();
}

void SensorManager::update() {
  bool currentTofValid = false;

  // 1. Doc ToF VL53L1X
  if (tofHealthy) {
    if (tof.dataReady()) {
      uint16_t rawDist = tof.read(false);
      uint8_t rangeStatus = tof.ranging_data.range_status;

      // rangeStatus 0 = Valid, 1 = Sigma Fail (nhung khoang cach van tot), 2 = Signal Fail
      if ((rangeStatus == 0 || rangeStatus == 1) && rawDist > 40 && rawDist < 4000) {
        primaryTofDistance = rawDist;
        tofDistances[0] = rawDist;
        tofDistances[1] = rawDist;
        tofDistances[2] = rawDist;

        tofHistory[0][historyIdx[0]] = rawDist;
        historyIdx[0] = (historyIdx[0] + 1) % 3;
        currentTofValid = true;
        lastTofReadTime = millis();
      }
    } else if (millis() - lastTofReadTime > 2500) {
      // ToF bi nghen dataReady -> Thu khoi dong lai
      initTofSensor();
    }
  } else if (millis() - lastTofAttemptTime > 3000) {
    // Thu khoi tao lai ToF neu truoc do chua tim thay
    initTofSensor();
  }

  // 2. Parse du lieu Radar LD2410
  parseRadarStream();

  // 3. Trang thai PIR AM312
#if ENABLE_PIR_SENSOR
  bool pirState = digitalRead(PIN_PIR) || pirTriggered;
  pirTriggered = false;
#else
  bool pirState = (radarPeakMotion >= 15);
#endif

  // Theo doi nam san bat dong keo dai
  bool floorCondition = (primaryTofDistance > 50 && primaryTofDistance <= floorThresholdMm) &&
                        (radarPeakMotion <= POST_FALL_RADAR_MOTION_MAX) &&
                        (radarPeakStatic >= POST_FALL_RADAR_STATIC_MIN);

  if (floorCondition) {
    if (!isCurrentlyAtFloor) {
      isCurrentlyAtFloor = true;
      floorStartTime = millis();
    }
  } else {
    isCurrentlyAtFloor = false;
    floorStartTime = 0;
  }

  // 4. Luu vao Circular Buffer
  if (windowBuffer) {
    SensorSample s;
    s.tof_high = tofDistances[0];
    s.tof_mid  = tofDistances[1];
    s.tof_low  = tofDistances[2];
    s.radar_motion_max = radarPeakMotion;
    s.radar_static_max = radarPeakStatic;
    s.radar_target_dist_cm = radarTargetDist;
    s.pir_active = pirState;
    s.tof_valid = currentTofValid;
    s.timestamp_ms = millis();

    windowBuffer[bufferHead] = s;
    bufferHead = (bufferHead + 1) % WINDOW_SIZE;
    if (sampleCount < WINDOW_SIZE) sampleCount++;
  }
}

bool SensorManager::isProlongedFloorInactivity(uint32_t durationMs) {
  if (isCurrentlyAtFloor && floorStartTime > 0) {
    return (millis() - floorStartTime >= durationMs);
  }
  return false;
}

void SensorManager::resetFloorTracking() {
  isCurrentlyAtFloor = false;
  floorStartTime = 0;
}

bool SensorManager::isWindowReady() {
  return sampleCount >= WINDOW_SIZE;
}

SensorSample SensorManager::getLatestSample() {
  if (!windowBuffer || sampleCount == 0) {
    SensorSample dummy = {0};
    dummy.tof_high = primaryTofDistance;
    dummy.tof_mid = primaryTofDistance;
    dummy.tof_low = primaryTofDistance;
    dummy.radar_motion_max = radarPeakMotion;
    dummy.radar_static_max = radarPeakStatic;
    dummy.radar_target_dist_cm = radarTargetDist;
    dummy.pir_active = false;
    dummy.tof_valid = tofHealthy;
    dummy.timestamp_ms = millis();
    return dummy;
  }
  int lastIdx = (bufferHead - 1 + WINDOW_SIZE) % WINDOW_SIZE;
  return windowBuffer[lastIdx];
}

void SensorManager::extractFeatures(float* features) {
  if (!windowBuffer || sampleCount < WINDOW_SIZE) {
    for (int i = 0; i < NUM_FEATURES; i++) features[i] = 0.0f;
    features[0] = (float)radarPeakMotion;
    features[1] = (float)radarPeakStatic;
    features[2] = (float)primaryTofDistance;
    features[3] = (float)primaryTofDistance;
    features[4] = (float)primaryTofDistance;
    features[6] = (float)radarTargetDist;
    return;
  }

  float maxMotion = 0.0f;
  float maxStatic = 0.0f;
  
  for (int i = 0; i < WINDOW_SIZE; i++) {
    if (windowBuffer[i].radar_motion_max > maxMotion) maxMotion = windowBuffer[i].radar_motion_max;
    if (windowBuffer[i].radar_static_max > maxStatic) maxStatic = windowBuffer[i].radar_static_max;
  }

  int newestIdx = (bufferHead - 1 + WINDOW_SIZE) % WINDOW_SIZE;

  float startHeightSum = 0;
  int startCount = 0;
  for (int i = 0; i < 5; i++) {
    int idx = (bufferHead + i) % WINDOW_SIZE;
    if (windowBuffer[idx].tof_high > 100) {
      startHeightSum += windowBuffer[idx].tof_high;
      startCount++;
    }
  }

  float endHeightSum = 0;
  int endCount = 0;
  for (int i = 0; i < 5; i++) {
    int idx = (bufferHead - 1 - i + WINDOW_SIZE) % WINDOW_SIZE;
    if (windowBuffer[idx].tof_high > 100) {
      endHeightSum += windowBuffer[idx].tof_high;
      endCount++;
    }
  }

  float avgStartHeight = (startCount > 0) ? (startHeightSum / startCount) : 0;
  float avgEndHeight   = (endCount > 0)   ? (endHeightSum / endCount)     : 0;

  float tofDropRate = 0.0f;
  if (avgStartHeight > 0 && avgEndHeight > 0) {
    tofDropRate = (avgStartHeight - avgEndHeight) / 2.0f;
    if (tofDropRate < 0.0f) tofDropRate = 0.0f;
  }

  features[0] = maxMotion;                                          // Dinh xung dong nang radar (0-100)
  features[1] = maxStatic;                                          // Nang luong tinh cuoi (0-100)
  features[2] = (float)windowBuffer[newestIdx].tof_high;            // Cu ly ToF cao (mm)
  features[3] = (float)windowBuffer[newestIdx].tof_mid;             // Cu ly ToF giua (mm)
  features[4] = (float)windowBuffer[newestIdx].tof_low;             // Cu ly ToF thap (mm)
  features[5] = tofDropRate;                                        // Toc do sut giam chieu cao (mm/s)
  features[6] = (float)windowBuffer[newestIdx].radar_target_dist_cm;// Khoang cach toi muc tieu (cm)
}

bool SensorManager::isSensorsHealthy() {
  unsigned long now = millis();
  bool radarOk = (now - lastRadarFrameTime < 4000);
  bool tofOk = (now - lastTofReadTime < 4000);
  return radarOk || tofOk;
}

void SensorManager::setFloorThreshold(uint16_t floorMm) {
  floorThresholdMm = floorMm;
}

uint16_t SensorManager::getFloorThreshold() const {
  return floorThresholdMm;
}

void SensorManager::calibrateFloor() {
  if (primaryTofDistance > 200 && primaryTofDistance < 3500) {
    floorThresholdMm = primaryTofDistance;
    Serial.printf("[SENSORS] Da hieu chuan do cao san moi: %d mm\n", floorThresholdMm);
  }
}
