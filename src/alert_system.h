#ifndef ALERT_SYSTEM_H
#define ALERT_SYSTEM_H

#include "config.h"
#include <Adafruit_NeoPixel.h>

enum BuzzerPattern {
  BUZZER_SILENT,
  BUZZER_PRE_ALARM_PULSE,
  BUZZER_ALERT_SIREN,
  BUZZER_CONFIRM_BEEP,
  BUZZER_SOS_CHIRP
};

class AlertSystem {
public:
  AlertSystem();
  void earlyHardwareMute();
  void init();
  void setIndicator(uint32_t color, bool buzzer);
  void setBuzzerPattern(BuzzerPattern pattern);
  void updateBuzzer();
  void updateNightlight(bool motionDetected);
  void playBeep(uint16_t durationMs);
  void setBuzzerHardware(bool on);
  void setBuzzerActiveHigh(bool high);
  bool isBuzzerActiveHigh() const;
  void setMuted(bool mute);
  bool isMuted() const;
  
  bool connectWiFi(const String& ssid, const String& pass);
  void maintainWiFi(const String& ssid, const String& pass);
  bool isWiFiConnected();

  bool sendTelegramAlert(const String& botToken, const String& chatId, const String& message);
  bool sendSmsGateway(const String& phone, const String& content);

private:
  Adafruit_NeoPixel strip;
  unsigned long lastWiFiReconnectAttempt;
  bool buzzerPinState;
  bool buzzerActiveHigh;
  bool buzzerMuted;
  BuzzerPattern currentPattern;
  unsigned long patternTimer;
  uint8_t patternStep;

  bool nightlightActive;
  unsigned long nightlightEndTime;
};

#endif
