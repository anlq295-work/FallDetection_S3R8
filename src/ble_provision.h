#ifndef BLE_PROVISION_H
#define BLE_PROVISION_H

#include "config.h"
#include <Arduino.h>

struct FallEventRecord {
  uint8_t  eventType;
  uint32_t timestampSec;
  float    velocityMmS;
  uint8_t  motionPeak;
  uint16_t targetDistCm;
};

class BleProvisioning {
public:
  BleProvisioning();
  void init(const char* deviceName);
  bool loadCredentials(String& ssid, String& pass, String& phone, String& chatId, String& botToken, uint16_t& floorThresh);
  void saveFloorThreshold(uint16_t floorMm);
  void updateStatus(const String& statusMsg);
  void sendTelemetry(const String& telemetryJson);
  bool isClientConnected();
  bool isRebootRequested();
  bool checkAndClearCommand(String& cmdOut);

  // Ghi nhật ký sự kiện vào bộ nhớ Flash NVS (Hộp đen sự kiện)
  void logFallEvent(FallEventType type, float velocity, uint8_t motion, uint16_t dist);
  String getEventHistoryJson();
  void clearHistory();

private:
};

extern BleProvisioning bleProvision;

#endif
