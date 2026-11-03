#ifndef OTA_MANAGER_H
#define OTA_MANAGER_H

#include <Arduino.h>

class OtaManager {
public:
  OtaManager();
  
  // OTA qua Wi-Fi (HTTP/HTTPS) - Tải trực tiếp firmware.bin từ URL / GitHub Release
  bool performHttpOta(const String& url);

  // OTA qua sóng Bluetooth Low Energy (BLE OTA chunk stream)
  bool startBleOta(size_t fileSize);
  bool writeBleOtaChunk(const uint8_t* data, size_t len);
  bool endBleOta();
  void abortBleOta();
  bool isOtaInProgress() const { return _otaInProgress; }
  int getOtaProgressPercent() const;

private:
  bool _otaInProgress;
  size_t _totalBytes;
  size_t _writtenBytes;
};

extern OtaManager otaManager;

#endif // OTA_MANAGER_H
