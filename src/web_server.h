#ifndef WEB_SERVER_H
#define WEB_SERVER_H

#include <Arduino.h>
#include <WebServer.h>
#include <functional>
#include "config.h"

class DeviceWebServer {
public:
  DeviceWebServer();
  void begin(std::function<String()> telemetrySupplier,
             std::function<String()> eventsSupplier,
             std::function<String()> statusSupplier,
             std::function<void(const String&)> commandHandler);
  void handle();
  void stop();
  bool isRunning() const;

private:
  WebServer server;
  bool running;
  std::function<String()> getTelemetry;
  std::function<String()> getEvents;
  std::function<String()> getStatus;
  std::function<void(const String&)> onCommand;
};

extern DeviceWebServer deviceWebServer;

#endif // WEB_SERVER_H
