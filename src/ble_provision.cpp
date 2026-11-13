#include "ble_provision.h"
#include "ota_manager.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <ArduinoJson.h>

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_WIFI_UUID         "0beb5483-e18e-4f36-9e1b-b4d6b63c7b28"
#define CHAR_CONTACT_UUID      "1c6f8742-9a6d-4785-b9e1-e63f9b8c0011"
#define CHAR_STATUS_UUID       "2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344"
#define CHAR_TELEMETRY_UUID    "3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455"
#define CHAR_CMD_UUID          "4fa0b044-9b3e-4d75-af4c-b70e901c5566"
#define CHAR_OTA_UUID          "5e1c0155-ac5d-4e86-be5d-c81f012d6677"

static Preferences prefs;
static Preferences evtPrefs;
static BLEServer* pServer = nullptr;
static BLECharacteristic* pStatusChar = nullptr;
static BLECharacteristic* pContactChar = nullptr;
static BLECharacteristic* pTelemetryChar = nullptr;
static BLECharacteristic* pCmdChar = nullptr;
static BLECharacteristic* pOtaChar = nullptr;

static bool bleConnected = false;
static bool rebootFlag = false;
static String pendingCommand = "";
static portMUX_TYPE cmdMux = portMUX_INITIALIZER_UNLOCKED;

BleProvisioning bleProvision;

class ServerCB: public BLEServerCallbacks {
  void onConnect(BLEServer* p) { 
    bleConnected = true; 
    Serial.println("[BLE] App Android/Client da ket noi!");
  }
  void onDisconnect(BLEServer* p) { 
    bleConnected = false; 
    Serial.println("[BLE] App ngat ket noi. Phat lai quang ba...");
    p->startAdvertising();
  }
};

class WifiCB: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String val = pChar->getValue().c_str();
    if (val.length() > 0) {
      StaticJsonDocument<256> doc;
      DeserializationError err = deserializeJson(doc, val);
      if (!err) {
        prefs.begin("sys_cfg", false);
        if (doc.containsKey("ssid")) prefs.putString("wifi_ssid", doc["ssid"].as<String>());
        if (doc.containsKey("pass")) prefs.putString("wifi_pass", doc["pass"].as<String>());
        prefs.end();

        bleProvision.updateStatus("WIFI_SAVED_REBOOTING");
        rebootFlag = true;
      }
    }
  }
};

class ContactCB: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String val = pChar->getValue().c_str();
    if (val.length() > 0) {
      StaticJsonDocument<512> doc;
      DeserializationError err = deserializeJson(doc, val);
      if (!err) {
        prefs.begin("sys_cfg", false);
        if (doc.containsKey("phone")) prefs.putString("emg_phone", doc["phone"].as<String>());
        if (doc.containsKey("chat_id")) prefs.putString("emg_chat_id", doc["chat_id"].as<String>());
        if (doc.containsKey("bot_token")) prefs.putString("bot_token", doc["bot_token"].as<String>());
        if (doc.containsKey("floor_mm")) prefs.putUShort("floor_thresh", doc["floor_mm"].as<uint16_t>());
        prefs.end();

        bleProvision.updateStatus("CONFIG_UPDATED_OK");
      }
    }
  }
};

class CmdCB: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String val = pChar->getValue().c_str();
    val.trim();
    if (val.length() > 0) {
      portENTER_CRITICAL(&cmdMux);
      pendingCommand = val;
      portEXIT_CRITICAL(&cmdMux);
      Serial.printf("[BLE] Nhan lenh tu App: %s\n", val.c_str());
    }
  }
};

class OtaCB: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    uint8_t* pData = pChar->getData();
    size_t len = pChar->getLength();
    if (len == 0) return;

    if (len >= 10 && memcmp(pData, "OTA_BEGIN:", 10) == 0) {
      String str = "";
      for (size_t i = 10; i < len; i++) str += (char)pData[i];
      size_t fileSize = str.toInt();
      otaManager.startBleOta(fileSize);
    } else if (len == 7 && memcmp(pData, "OTA_END", 7) == 0) {
      otaManager.endBleOta();
    } else if (len == 9 && memcmp(pData, "OTA_ABORT", 9) == 0) {
      otaManager.abortBleOta();
    } else {
      otaManager.writeBleOtaChunk(pData, len);
    }
  }
};

BleProvisioning::BleProvisioning() {}

void BleProvisioning::init(const char* deviceName) {
  BLEDevice::init(deviceName);
  BLEDevice::setMTU(512);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCB());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  BLECharacteristic* pWifiChar = pService->createCharacteristic(
                      CHAR_WIFI_UUID, BLECharacteristic::PROPERTY_WRITE);
  pWifiChar->setCallbacks(new WifiCB());

  pContactChar = pService->createCharacteristic(
                      CHAR_CONTACT_UUID, 
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pContactChar->setCallbacks(new ContactCB());

  pStatusChar = pService->createCharacteristic(
                      CHAR_STATUS_UUID, 
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());

  pTelemetryChar = pService->createCharacteristic(
                      CHAR_TELEMETRY_UUID, 
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pTelemetryChar->addDescriptor(new BLE2902());

  pCmdChar = pService->createCharacteristic(
                      CHAR_CMD_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCmdChar->setCallbacks(new CmdCB());

  pOtaChar = pService->createCharacteristic(
                      CHAR_OTA_UUID, 
                      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  pOtaChar->setCallbacks(new OtaCB());

  prefs.begin("sys_cfg", true);
  StaticJsonDocument<512> doc;
  doc["phone"] = prefs.isKey("emg_phone") ? prefs.getString("emg_phone") : "";
  doc["chat_id"] = prefs.isKey("emg_chat_id") ? prefs.getString("emg_chat_id") : "";
  doc["floor_mm"] = prefs.getUShort("floor_thresh", FLOOR_HEIGHT_DEFAULT_MM);
  prefs.end();

  String payload;
  serializeJson(doc, payload);
  pContactChar->setValue(payload.c_str());

  pService->start();
  
  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("[BLE] Khoi dong BLE GATT Server thanh cong. Ten thiet bi: FallDetector_S3R8");
}

void BleProvisioning::updateStatus(const String& statusMsg) {
  if (pStatusChar) {
    pStatusChar->setValue(statusMsg.c_str());
    if (bleConnected) pStatusChar->notify();
  }
}

void BleProvisioning::sendTelemetry(const String& telemetryJson) {
  if (pTelemetryChar && bleConnected) {
    pTelemetryChar->setValue(telemetryJson.c_str());
    pTelemetryChar->notify();
  }
}

bool BleProvisioning::isClientConnected() {
  return bleConnected;
}

bool BleProvisioning::isRebootRequested() {
  return rebootFlag;
}

bool BleProvisioning::checkAndClearCommand(String& cmdOut) {
  portENTER_CRITICAL(&cmdMux);
  if (pendingCommand.length() > 0) {
    cmdOut = pendingCommand;
    pendingCommand = "";
    portEXIT_CRITICAL(&cmdMux);
    return true;
  }
  portEXIT_CRITICAL(&cmdMux);
  return false;
}

void BleProvisioning::saveFloorThreshold(uint16_t floorMm) {
  prefs.begin("sys_cfg", false);
  prefs.putUShort("floor_thresh", floorMm);
  prefs.end();
}

bool BleProvisioning::loadCredentials(String& ssid, String& pass, String& phone, String& chatId, String& botToken, uint16_t& floorThresh) {
  prefs.begin("sys_cfg", true);
  ssid        = prefs.getString("wifi_ssid", "");
  pass        = prefs.getString("wifi_pass", "");
  phone       = prefs.isKey("emg_phone") ? prefs.getString("emg_phone") : "";
  chatId      = prefs.isKey("emg_chat_id") ? prefs.getString("emg_chat_id") : "";
  botToken    = prefs.isKey("bot_token") ? prefs.getString("bot_token") : "";
  floorThresh = prefs.getUShort("floor_thresh", FLOOR_HEIGHT_DEFAULT_MM);
  prefs.end();

  return (ssid.length() > 0);
}

void BleProvisioning::logFallEvent(FallEventType type, float velocity, uint8_t motion, uint16_t dist) {
  evtPrefs.begin("evt_log", false);
  uint8_t count = evtPrefs.getUChar("count", 0);
  uint8_t head = evtPrefs.getUChar("head", 0);

  char key[16];
  snprintf(key, sizeof(key), "e%d_t", head);
  evtPrefs.putUChar(key, (uint8_t)type);
  snprintf(key, sizeof(key), "e%d_s", head);
  evtPrefs.putUInt(key, (uint32_t)(millis() / 1000));
  snprintf(key, sizeof(key), "e%d_v", head);
  evtPrefs.putFloat(key, velocity);
  snprintf(key, sizeof(key), "e%d_m", head);
  evtPrefs.putUChar(key, motion);
  snprintf(key, sizeof(key), "e%d_d", head);
  evtPrefs.putUShort(key, dist);

  head = (head + 1) % 5;
  if (count < 5) count++;

  evtPrefs.putUChar("head", head);
  evtPrefs.putUChar("count", count);
  evtPrefs.end();

  Serial.printf("[BLACKBOX] Da ghi nhan su co vao Flash NVS: Loai=%d, V=%.1f, Mot=%d\n", type, velocity, motion);
}

String BleProvisioning::getEventHistoryJson() {
  evtPrefs.begin("evt_log", true);
  uint8_t count = evtPrefs.getUChar("count", 0);
  uint8_t head = evtPrefs.getUChar("head", 0);

  StaticJsonDocument<512> doc;
  JsonArray arr = doc.createNestedArray("events");

  // Đọc từ sự kiện mới nhất về cũ nhất
  for (int i = 0; i < count; i++) {
    int idx = (head - 1 - i + 5) % 5;
    char key[16];
    JsonObject item = arr.createNestedObject();
    snprintf(key, sizeof(key), "e%d_t", idx);
    item["type"] = evtPrefs.getUChar(key, 0);
    snprintf(key, sizeof(key), "e%d_s", idx);
    item["sec"] = evtPrefs.getUInt(key, 0);
    snprintf(key, sizeof(key), "e%d_v", idx);
    item["vel"] = evtPrefs.getFloat(key, 0);
    snprintf(key, sizeof(key), "e%d_m", idx);
    item["mot"] = evtPrefs.getUChar(key, 0);
    snprintf(key, sizeof(key), "e%d_d", idx);
    item["dst"] = evtPrefs.getUShort(key, 0);
  }
  evtPrefs.end();

  String out;
  serializeJson(doc, out);
  return out;
}

void BleProvisioning::clearHistory() {
  evtPrefs.begin("evt_log", false);
  evtPrefs.clear();
  evtPrefs.end();
  Serial.println("[BLACKBOX] Da xoa toan bo nhat ky su co.");
}
