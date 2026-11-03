#include "ota_manager.h"
#include "ble_provision.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPUpdate.h>
#include <Update.h>
#include <esp_task_wdt.h>

OtaManager otaManager;

OtaManager::OtaManager() 
  : _otaInProgress(false), _totalBytes(0), _writtenBytes(0) {}

int OtaManager::getOtaProgressPercent() const {
  if (_totalBytes == 0) return 0;
  return (_writtenBytes * 100) / _totalBytes;
}

bool OtaManager::performHttpOta(const String& url) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[OTA] Wi-Fi chua ket noi! Khong the thuc hien HTTP OTA.");
    bleProvision.updateStatus("OTA_ERROR:WIFI_DISCONNECTED");
    return false;
  }

  Serial.printf("[OTA] Bat dau tai firmware tu URL: %s\n", url.c_str());
  bleProvision.updateStatus("OTA_STARTING");

  // Reset Watchdog truoc khi download
  esp_task_wdt_reset();

  WiFiClientSecure client;
  client.setInsecure(); // Bo qua kiem tra chung chi SSL certificate chain de tai nhanh tu GitHub

  httpUpdate.setLedPin(-1); // Khong dung den LED mac dinh cua thu vien
  httpUpdate.rebootOnUpdate(false); // Tu reboot thu cong sau khi gui status bao ve App

  httpUpdate.onProgress([](size_t current, size_t total) {
    esp_task_wdt_reset();
    if (total > 0) {
      int pct = (current * 100) / total;
      static int lastReportedPct = -1;
      if (pct != lastReportedPct && (pct % 5 == 0 || pct == 100)) {
        lastReportedPct = pct;
        String statusMsg = "OTA_PROGRESS:" + String(pct);
        bleProvision.updateStatus(statusMsg);
        Serial.printf("[OTA HTTP] Tien do: %d%% (%u / %u bytes)\n", pct, (unsigned int)current, (unsigned int)total);
      }
    }
  });

  t_httpUpdate_return ret = httpUpdate.update(client, url);

  switch (ret) {
    case HTTP_UPDATE_FAILED:
      Serial.printf("[OTA] That bai: Ma loi (%d): %s\n", httpUpdate.getLastError(), httpUpdate.getLastErrorString().c_str());
      bleProvision.updateStatus("OTA_ERROR:" + httpUpdate.getLastErrorString());
      return false;

    case HTTP_UPDATE_NO_UPDATES:
      Serial.println("[OTA] May chu bao khong co ban cap nhat moi.");
      bleProvision.updateStatus("OTA_NO_UPDATES");
      return false;

    case HTTP_UPDATE_OK:
      Serial.println("[OTA] Cap nhat firmware thanh cong 100%! Dang chuan bi khoi dong lai...");
      bleProvision.updateStatus("OTA_SUCCESS_REBOOTING");
      delay(1500);
      ESP.restart();
      return true;
  }

  return false;
}

bool OtaManager::startBleOta(size_t fileSize) {
  esp_task_wdt_reset();
  Serial.printf("[OTA BLE] Bat dau phien nap firmware qua BLE (Kich thuoc: %u bytes)...\n", (unsigned int)fileSize);

  if (!Update.begin(fileSize > 0 ? fileSize : UPDATE_SIZE_UNKNOWN)) {
    Serial.printf("[OTA BLE] Update.begin loi: %d\n", Update.getError());
    bleProvision.updateStatus("OTA_ERROR:BEGIN_FAILED");
    _otaInProgress = false;
    return false;
  }

  _otaInProgress = true;
  _totalBytes = fileSize;
  _writtenBytes = 0;
  bleProvision.updateStatus("OTA_READY");
  return true;
}

bool OtaManager::writeBleOtaChunk(const uint8_t* data, size_t len) {
  if (!_otaInProgress) return false;
  esp_task_wdt_reset();

  size_t written = Update.write(const_cast<uint8_t*>(data), len);
  if (written != len) {
    Serial.printf("[OTA BLE] Ghi loi! Da ghi: %u / %u bytes\n", (unsigned int)written, (unsigned int)len);
    Update.abort();
    _otaInProgress = false;
    bleProvision.updateStatus("OTA_ERROR:WRITE_FAILED");
    return false;
  }

  _writtenBytes += len;
  if (_totalBytes > 0) {
    int pct = (_writtenBytes * 100) / _totalBytes;
    static int lastBlePct = -1;
    if (pct != lastBlePct && (pct % 5 == 0 || pct == 100)) {
      lastBlePct = pct;
      bleProvision.updateStatus("OTA_PROGRESS:" + String(pct));
      Serial.printf("[OTA BLE] Tien do: %d%% (%u / %u bytes)\n", pct, (unsigned int)_writtenBytes, (unsigned int)_totalBytes);
    }
  }

  return true;
}

bool OtaManager::endBleOta() {
  if (!_otaInProgress) return false;
  esp_task_wdt_reset();

  if (!Update.end(true)) {
    Serial.printf("[OTA BLE] Update.end that bai! Ma loi: %d\n", Update.getError());
    _otaInProgress = false;
    bleProvision.updateStatus("OTA_ERROR:VERIFY_FAILED");
    return false;
  }

  if (!Update.isFinished()) {
    Serial.println("[OTA BLE] Update chua hoan tat day du!");
    _otaInProgress = false;
    bleProvision.updateStatus("OTA_ERROR:INCOMPLETE");
    return false;
  }

  Serial.println("[OTA BLE] Nap firmware qua BLE thanh cong 100%! Dang khoi dong lai...");
  _otaInProgress = false;
  bleProvision.updateStatus("OTA_SUCCESS_REBOOTING");
  delay(1500);
  ESP.restart();
  return true;
}

void OtaManager::abortBleOta() {
  if (_otaInProgress) {
    Serial.println("[OTA BLE] Nguoi dung hoac App da huy bo OTA.");
    Update.abort();
    _otaInProgress = false;
    _totalBytes = 0;
    _writtenBytes = 0;
    bleProvision.updateStatus("OTA_ABORTED");
  }
}
