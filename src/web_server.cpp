#include "web_server.h"
#include <WiFi.h>
#include <ArduinoJson.h>
#include <Update.h>
#include <esp_task_wdt.h>

DeviceWebServer deviceWebServer;

DeviceWebServer::DeviceWebServer() : server(80), running(false) {}

void DeviceWebServer::begin(std::function<String()> telemetrySupplier,
                           std::function<String()> eventsSupplier,
                           std::function<String()> statusSupplier,
                           std::function<void(const String&)> commandHandler) {
  if (running) return;

  getTelemetry = telemetrySupplier;
  getEvents = eventsSupplier;
  getStatus = statusSupplier;
  onCommand = commandHandler;

  // Endpoint 1: GET /api/telemetry (hoặc /telemetry)
  auto handleTelemetry = [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "*");
    String telem = getTelemetry ? getTelemetry() : "{}";
    server.send(200, "application/json", telem);
  };
  server.on("/api/telemetry", HTTP_GET, handleTelemetry);
  server.on("/telemetry", HTTP_GET, handleTelemetry);

  // Endpoint 2: GET /api/events (Hộp đen NVS Flash)
  auto handleEvents = [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "*");
    String ev = getEvents ? getEvents() : "{\"events\":[]}";
    server.send(200, "application/json", ev);
  };
  server.on("/api/events", HTTP_GET, handleEvents);
  server.on("/events", HTTP_GET, handleEvents);

  // Endpoint 3: GET /api/status
  auto handleStatus = [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "*");
    String st = getStatus ? getStatus() : "{}";
    server.send(200, "application/json", st);
  };
  server.on("/api/status", HTTP_GET, handleStatus);

  // Endpoint 4: POST / GET / OPTIONS /api/command
  auto handleCommand = [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "*");

    if (server.method() == HTTP_OPTIONS) {
      server.send(204);
      return;
    }

    String cmd = "";
    if (server.hasArg("cmd")) {
      cmd = server.arg("cmd");
    } else if (server.hasArg("plain")) {
      String body = server.arg("plain");
      StaticJsonDocument<256> doc;
      if (deserializeJson(doc, body) == DeserializationError::Ok && doc.containsKey("cmd")) {
        cmd = doc["cmd"].as<String>();
      } else {
        cmd = body;
      }
    }
    cmd.trim();

    if (cmd.length() > 0 && onCommand) {
      onCommand(cmd);
      server.send(200, "application/json", "{\"status\":\"ok\",\"executed_cmd\":\"" + cmd + "\"}");
    } else {
      server.send(400, "application/json", "{\"error\":\"Missing cmd param\"}");
    }
  };
  server.on("/api/command", HTTP_GET, handleCommand);
  server.on("/api/command", HTTP_POST, handleCommand);
  server.on("/api/command", HTTP_OPTIONS, handleCommand);

  // Endpoint 5: Web OTA trực tiếp qua trình duyệt trên cùng mạng Wi-Fi
  server.on("/update", HTTP_GET, [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>FallGuard S3R8 Firmware Update</title>"
                  "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                  "<style>body{font-family:sans-serif;padding:24px;background:#0d1117;color:#c9d1d9;text-align:center}"
                  ".card{background:#161b22;border:1px solid #30363d;border-radius:12px;max-width:480px;margin:30px auto;padding:24px}"
                  "h2{color:#58a6ff;margin-top:0}input[type=file]{margin:20px 0;color:#c9d1d9}"
                  "input[type=submit]{background:#238636;color:#fff;border:none;padding:12px 24px;font-size:16px;border-radius:6px;cursor:pointer;font-weight:bold}"
                  "input[type=submit]:hover{background:#2ea043}.note{font-size:12px;color:#8b949e;margin-top:16px}</style></head>"
                  "<body><div class='card'><h2>FallGuard S3R8 Web OTA</h2>"
                  "<p>Nap truc tiep file <b>firmware.bin</b> qua Wi-Fi noi bo toc do cao</p>"
                  "<form method='POST' action='/update' enctype='multipart/form-data'>"
                  "<input type='file' name='update' accept='.bin' required><br>"
                  "<input type='submit' value='Bat dau nap Firmware'>"
                  "</form><div class='note'>Sau khi nap xong, ESP32 se tu dong kiem tra va khoi dong lai.</div></div></body></html>";
    server.send(200, "text/html", html);
  });

  server.on("/update", HTTP_POST, [this]() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "UPDATE FAILED" : "UPDATE SUCCESS! REBOOTING...");
    delay(1000);
    ESP.restart();
  }, [this]() {
    HTTPUpload& upload = server.upload();
    if (upload.status == UPLOAD_FILE_START) {
      Serial.printf("[WEB OTA] Bat dau nhan file: %s\n", upload.filename.c_str());
      esp_task_wdt_reset();
      if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      esp_task_wdt_reset();
      if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_END) {
      if (Update.end(true)) {
        Serial.printf("[WEB OTA] Nap hoan tat: %u bytes! Khoi dong lai...\n", (unsigned int)upload.totalSize);
      } else {
        Update.printError(Serial);
      }
    }
  });

  // Trang chủ mặc định: Thông tin trực quan về API
  server.on("/", HTTP_GET, [this]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>FallGuard S3R8 API</title>"
                  "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                  "<style>body{font-family:sans-serif;padding:20px;background:#0d1117;color:#c9d1d9}"
                  "h1{color:#58a6ff}a{color:#79c0ff}pre{background:#161b22;padding:12px;border-radius:6px;overflow:auto}</style></head>"
                  "<body><h1>FallGuard S3R8 Web API</h1>"
                  "<p>He thong giam sat va phat hien te nga thoi gian thuc qua Wi-Fi LAN.</p>"
                  "<ul>"
                  "<li><a href='/api/telemetry'>GET /api/telemetry</a> - Du lieu giam sat truc tiep</li>"
                  "<li><a href='/api/events'>GET /api/events</a> - Nhat ky hop den NVS Flash</li>"
                  "<li><a href='/api/status'>GET /api/status</a> - Thong so phan cung & he thong</li>"
                  "<li><a href='/update'>GET /update</a> - Web OTA nap firmware truc tiep qua Wi-Fi</li>"
                  "<li>POST /api/command?cmd=&lt;CMD&gt; - Gui lenh dieu khien tu xa</li>"
                  "</ul>"
                  "</body></html>";
    server.send(200, "text/html", html);
  });

  server.onNotFound([this]() {
    if (server.method() == HTTP_OPTIONS) {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      server.sendHeader("Access-Control-Allow-Headers", "*");
      server.send(204);
    } else {
      server.send(404, "text/plain", "FallGuard S3R8 API Server - 404 Not Found");
    }
  });

  server.begin();
  running = true;
  Serial.printf("[HTTP] Web Server da khoi dong tai cong 80! Truy cap: http://%s/\n", WiFi.localIP().toString().c_str());
}

void DeviceWebServer::handle() {
  if (running) {
    server.handleClient();
  }
}

void DeviceWebServer::stop() {
  if (running) {
    server.stop();
    running = false;
  }
}

bool DeviceWebServer::isRunning() const {
  return running;
}
