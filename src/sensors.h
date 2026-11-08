#ifndef SENSORS_H
#define SENSORS_H

#include "config.h"
#include <VL53L1X.h>

struct SensorSample {
  uint16_t tof_high;
  uint16_t tof_mid;
  uint16_t tof_low;
  uint8_t  radar_motion_max;
  uint8_t  radar_static_max;
  uint16_t radar_target_dist_cm;
  bool     pir_active;
  bool     tof_valid;
  uint32_t timestamp_ms;
};

class SensorManager {
public:
  SensorManager();
  bool init();
  void update();
  bool isWindowReady();
  void extractFeatures(float* features);
  SensorSample getLatestSample();
  bool isSensorsHealthy();
  
  void setFloorThreshold(uint16_t floorMm);
  uint16_t getFloorThreshold() const;
  void calibrateFloor();

  // Phát hiện ngã chậm / nằm sàn bất động kéo dài (Prolonged Floor Inactivity)
  bool isProlongedFloorInactivity(uint32_t durationMs);
  void resetFloorTracking();

  uint16_t getPrimaryTofDistance() const { return primaryTofDistance; }
  uint8_t  getRadarPeakMotion() const { return radarPeakMotion; }
  uint8_t  getRadarPeakStatic() const { return radarPeakStatic; }
  uint16_t getRadarTargetDist() const { return radarTargetDist; }
  uint8_t  getRadarTargetState() const { return radarTargetState; }
  bool     isTofHealthy() const { return tofHealthy; }
  bool     isRadarHealthy() const { return radarHealthy; }

private:
  VL53L1X tof;
  uint8_t currentRoiIdx;
  uint16_t tofDistances[3];
  uint16_t primaryTofDistance;
  uint16_t tofHistory[3][3]; // Bộ lọc trung vị 3 mẫu cho 3 vùng ROI
  uint8_t  historyIdx[3];
  bool     tofHealthy;
  uint32_t lastTofReadTime;
  uint32_t lastTofAttemptTime;
  
  uint8_t  radarMotionEnergies[9];
  uint8_t  radarStaticEnergies[9];
  uint16_t radarTargetDist;
  uint8_t  radarPeakMotion;
  uint8_t  radarPeakStatic;
  uint8_t  radarTargetState;
  bool     radarHealthy;
  uint32_t lastRadarFrameTime;

  // Radar State Machine Parser & Auto-Baud Detection
  enum RadarParserState {
    RADAR_WAIT_H0 = 0,
    RADAR_WAIT_H1,
    RADAR_WAIT_H2,
    RADAR_WAIT_H3,
    RADAR_READ_LEN0,
    RADAR_READ_LEN1,
    RADAR_READ_PAYLOAD,
    RADAR_WAIT_T0,
    RADAR_WAIT_T1,
    RADAR_WAIT_T2,
    RADAR_WAIT_T3
  };
  RadarParserState radarState;
  uint16_t radarExpectedLen;
  uint16_t radarPayloadIdx;
  uint8_t  radarPayload[64];
  uint32_t radarBaudRate;
  uint32_t lastBaudSwitchTime;
  bool     radarBaudLocked;

  uint16_t floorThresholdMm;

  // Theo dõi thời gian nằm sát sàn
  unsigned long floorStartTime;
  bool isCurrentlyAtFloor;

  SensorSample* windowBuffer; // Bộ đệm trượt cấp phát trên Octal PSRAM của ESP32-S3R8
  int bufferHead;
  int sampleCount;

  bool initTofSensor();
  void checkBaudRateAutoDetect();
  void parseRadarStream();
  void processRadarPayload(uint8_t* payload, uint16_t len);
  void configureRadarLD2410();
  uint16_t computeMedian(uint16_t* arr, uint8_t size);
  void recoverI2CBus(uint8_t sdaPin, uint8_t sclPin);
};

#endif
