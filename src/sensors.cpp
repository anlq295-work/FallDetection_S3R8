#include "sensors.h"
#include <Wire.h>
#include <esp_heap_caps.h>

static volatile bool pirTriggered = false;
static void IRAM_ATTR pirISR() {
  pirTriggered = true;
}

// Tâm SPAD Array 16x16 cho ToF VL53L1X: 
// 0: Cao (ROI 199), 1: Giữa (ROI 175), 2: Thấp (ROI 151)
const uint8_t ROI_CENTERS[3] = {199, 175, 151};

// Lệnh cấu hình LD2410B
static const uint8_t CMD_ENABLE_CONF[] = {0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01};
static const uint8_t CMD_ENABLE_ENG[]  = {0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0x62, 0x00, 0x04, 0x03, 0x02, 0x01};
static const uint8_t CMD_END_CONF[]    = {0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01};

SensorManager::SensorManager() 
  : currentRoiIdx(0), tofHealthy(false), lastTofReadTime(0),
    radarTargetDist(0), radarPeakMotion(0), radarPeakStatic(0),
    radarTargetState(0), radarHealthy(false), lastRadarFrameTime(0),
    floorThresholdMm(FLOOR_HEIGHT_DEFAULT_MM),
    floorStartTime(0), isCurrentlyAtFloor(false),
    windowBuffer(nullptr), bufferHead(0), sampleCount(0) {
  memset(tofDistances, 0, sizeof(tofDistances));
  memset(tofHistory, 0, sizeof(tofHistory));
  memset(historyIdx, 0, sizeof(historyIdx));
  memset(radarMotionEnergies, 0, sizeof(radarMotionEnergies));
  memset(radarStaticEnergies, 0, sizeof(radarStaticEnergies));
}

void SensorManager::recoverI2CBus(uint8_t sdaPin, uint8_t sclPin) {
  // Chuẩn công nghiệp: Nếu slave I2C treo đường SDA ở mức LOW, phát 9 xung clock trên SCL để nhả bus
  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, OUTPUT_OPEN_DRAIN);
  digitalWrite(sclPin, HIGH);
  delayMicroseconds(10);

  if (digitalRead(sdaPin) == LOW) {
    Serial.println("[I2C] Phat hien bus SDA bi treo LOW. Dang thuc hien Bus Recovery (9 clock pulses)...");
    for (int i = 0; i < 9; i++) {
      digitalWrite(sclPin, LOW);
      delayMicroseconds(10);
      digitalWrite(sclPin, HIGH);
      delayMicroseconds(10);
      if (digitalRead(sdaPin) == HIGH) break;
    }
    // Tao dieu kien STOP tren I2C
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

void SensorManager::configureRadarLD2410() {
  Serial2.write(CMD_ENABLE_CONF, sizeof(CMD_ENABLE_CONF));
  delay(50);
  Serial2.write(CMD_ENABLE_ENG, sizeof(CMD_ENABLE_ENG));
  delay(50);
  Serial2.write(CMD_END_CONF, sizeof(CMD_END_CONF));
  delay(50);
}

bool SensorManager::init() {
  // 1. Cấp phát Circular Buffer trên Octal PSRAM của ESP32-S3R8
  if (psramFound()) {
    windowBuffer = (SensorSample*)heap_caps_malloc(sizeof(SensorSample) * WINDOW_SIZE, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (windowBuffer) {
      Serial.printf("[SENSORS] Cap phat thanh cong circular buffer tren Octal PSRAM (%d bytes)\n", (int)(sizeof(SensorSample) * WINDOW_SIZE));
    }
  }
  if (!windowBuffer) {
    windowBuffer = (SensorSample*)malloc(sizeof(SensorSample) * WINDOW_SIZE);
    Serial.println("[SENSORS] Cap phat buffer tren SRAM noi.");
  }
  if (!windowBuffer) return false;

  // 2. Cảm biến chuyển động hồng ngoại PIR
#if ENABLE_PIR_SENSOR
  pinMode(PIN_PIR, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_PIR), pirISR, RISING);
  Serial.println("[SENSORS] Khoi dong PIR AM312 thanh cong.");
#else
  // Chế độ test tạm khi chưa gắn PIR: Kéo chân GPIO 4 xuống PULLDOWN để chống nhiễu điện từ nổi
  pinMode(PIN_PIR, INPUT_PULLDOWN);
  Serial.println("[SENSORS] PIR tam an / vo hieu hoa khi test: Su dung 100% Radar FMCW 24GHz.");
#endif

  // 3. Phục hồi và khởi động bus I2C cho ToF VL53L1X
  recoverI2CBus(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.setClock(400000);
  tof.setTimeout(500);

  if (tof.init()) {
    tof.setDistanceMode(VL53L1X::Medium);
    tof.setMeasurementTimingBudget(33000); // 33ms budget
    setTofRoi(0);
    tof.startContinuous(33);
    tofHealthy = true;
    lastTofReadTime = millis();
    Serial.println("[SENSORS] Khoi dong ToF VL53L1X thanh cong!");
  } else {
    Serial.println("[CANH BAO] Khong tim thay ToF VL53L1X tren bus I2C!");
    tofHealthy = false;
  }

  // 4. Radar mmWave FMCW LD2410B qua Serial2 (256000 bps)
  Serial2.begin(256000, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  delay(100);
  configureRadarLD2410();
  lastRadarFrameTime = millis();

  return true;
}

void SensorManager::setTofRoi(uint8_t roiIdx) {
  tof.setROISize(16, 6);
  tof.setROICenter(ROI_CENTERS[roiIdx]);
}

void SensorManager::parseRadarStream() {
  while (Serial2.available() >= 10) {
    if (Serial2.peek() != 0xF4) {
      Serial2.read();
      continue;
    }
    
    if (Serial2.available() < 4) return;
    uint8_t h[4];
    Serial2.readBytes(h, 4);
    if (h[0] != 0xF4 || h[1] != 0xF3 || h[2] != 0xF2 || h[3] != 0xF1) {
      continue;
    }

    if (Serial2.available() < 2) return;
    uint8_t lenBytes[2];
    Serial2.readBytes(lenBytes, 2);
    uint16_t frameLen = lenBytes[0] | (lenBytes[1] << 8);

    if (frameLen > 64 || frameLen < 4) {
      continue;
    }

    unsigned long waitStart = millis();
    while (Serial2.available() < (frameLen + 4) && (millis() - waitStart < 15)) {
      delayMicroseconds(50);
    }
    if (Serial2.available() < (frameLen + 4)) return;

    uint8_t payload[64];
    Serial2.readBytes(payload, frameLen);

    uint8_t tail[4];
    Serial2.readBytes(tail, 4);
    if (tail[0] != 0xF8 || tail[1] != 0xF7 || tail[2] != 0xF6 || tail[3] != 0xF5) {
      continue;
    }

    radarHealthy = true;
    lastRadarFrameTime = millis();

    uint8_t dataType = payload[0];
    if (dataType == 0x01) {
      radarTargetState = payload[2];
      uint16_t moveDist = payload[3] | (payload[4] << 8);
      uint8_t  moveEnergy = payload[5];
      uint16_t statDist = payload[6] | (payload[7] << 8);
      uint8_t  statEnergy = payload[8];
      uint16_t detectDist = payload[9] | (payload[10] << 8);

      radarPeakMotion = moveEnergy;
      radarPeakStatic = statEnergy;
      radarTargetDist = (radarTargetState == 1) ? moveDist : ((radarTargetState == 2) ? statDist : detectDist);
    } else if (dataType == 0x02) {
      radarTargetState = payload[2];
      uint16_t moveDist = payload[3] | (payload[4] << 8);
      uint8_t  moveEnergy = payload[5];
      uint16_t statDist = payload[6] | (payload[7] << 8);
      uint8_t  statEnergy = payload[8];
      uint16_t detectDist = payload[9] | (payload[10] << 8);

      radarTargetDist = (radarTargetState == 1) ? moveDist : ((radarTargetState == 2) ? statDist : detectDist);
      radarPeakMotion = moveEnergy;
      radarPeakStatic = statEnergy;

      if (frameLen >= 30) {
        for (int i = 0; i < 9 && (13 + i < frameLen); i++) {
          radarMotionEnergies[i] = payload[13 + i];
          if (radarMotionEnergies[i] > radarPeakMotion) {
            radarPeakMotion = radarMotionEnergies[i];
          }
        }
        for (int i = 0; i < 9 && (22 + i < frameLen); i++) {
          radarStaticEnergies[i] = payload[22 + i];
          if (radarStaticEnergies[i] > radarPeakStatic) {
            radarPeakStatic = radarStaticEnergies[i];
          }
        }
      }
    }
  }
}

void SensorManager::update() {
  bool currentTofValid = false;

  if (tofHealthy && tof.dataReady()) {
    uint16_t rawDist = tof.read(false);
    uint8_t rangeStatus = tof.ranging_data.range_status;

    if (rangeStatus == 0 && rawDist > 50 && rawDist < 4000) {
      tofHistory[currentRoiIdx][historyIdx[currentRoiIdx]] = rawDist;
      historyIdx[currentRoiIdx] = (historyIdx[currentRoiIdx] + 1) % 3;
      tofDistances[currentRoiIdx] = computeMedian(tofHistory[currentRoiIdx], 3);
      currentTofValid = true;
      lastTofReadTime = millis();
    }

    currentRoiIdx = (currentRoiIdx + 1) % 3;
    setTofRoi(currentRoiIdx);
    tof.startContinuous(33);
  }

  parseRadarStream();

#if ENABLE_PIR_SENSOR
  bool pirState = digitalRead(PIN_PIR) || pirTriggered;
  pirTriggered = false;
#else
  bool pirState = false; // Tạm ẩn PIR: không cần ngắt hay đọc chân nổi
#endif

  // Theo dõi nạn nhân nằm sát sàn bất động kéo dài (Slow fall / Slump detection)
  bool floorCondition = (tofDistances[2] > 50 && tofDistances[2] <= floorThresholdMm) &&
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
    return dummy;
  }
  int lastIdx = (bufferHead - 1 + WINDOW_SIZE) % WINDOW_SIZE;
  return windowBuffer[lastIdx];
}

void SensorManager::extractFeatures(float* features) {
  if (!windowBuffer || sampleCount < WINDOW_SIZE) {
    for (int i = 0; i < NUM_FEATURES; i++) features[i] = 0.0f;
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

  features[0] = maxMotion;                                          // Đỉnh xung động năng radar (0-100)
  features[1] = maxStatic;                                          // Năng lượng tĩnh cuối (0-100)
  features[2] = (float)windowBuffer[newestIdx].tof_high;            // Cự ly ROI cao (mm)
  features[3] = (float)windowBuffer[newestIdx].tof_mid;             // Cự ly ROI giữa (mm)
  features[4] = (float)windowBuffer[newestIdx].tof_low;             // Cự ly ROI thấp (mm)
  features[5] = tofDropRate;                                        // Tốc độ sụt giảm chiều cao (mm/s)
  features[6] = (float)windowBuffer[newestIdx].radar_target_dist_cm;// Khoảng cách tới mục tiêu (cm)
}

bool SensorManager::isSensorsHealthy() {
  unsigned long now = millis();
  bool radarOk = (now - lastRadarFrameTime < 3000);
  bool tofOk = !tofHealthy || (now - lastTofReadTime < 3000);
  return radarOk && tofOk;
}

void SensorManager::setFloorThreshold(uint16_t floorMm) {
  floorThresholdMm = floorMm;
}

uint16_t SensorManager::getFloorThreshold() const {
  return floorThresholdMm;
}

void SensorManager::calibrateFloor() {
  if (tofDistances[2] > 200 && tofDistances[2] < 3000) {
    floorThresholdMm = tofDistances[2];
    Serial.printf("[SENSORS] Da hieu chuan do cao san moi: %d mm\n", floorThresholdMm);
  }
}
