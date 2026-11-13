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
  BuzzerPattern getCurrentPattern() const;
  void updateBuzzer();
  void updateNightlight(bool motionDetected);
  void setNightlightSchedule(bool enabled, uint8_t startHour, uint8_t startMinute,
                             uint8_t endHour, uint8_t endMinute);
  bool isNightScheduleActive() const;
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
  uint32_t currentLedColor;
  unsigned long lastWiFiReconnectAttempt;
  bool buzzerPinState;
  bool buzzerActiveHigh;
  bool buzzerMuted;
  BuzzerPattern currentPattern;
  unsigned long patternTimer;
  uint8_t patternStep;

  bool nightlightActive;
  unsigned long nightlightEndTime;
  bool nightScheduleEnabled;
  uint8_t nightStartHour;
  uint8_t nightStartMinute;
  uint8_t nightEndHour;
  uint8_t nightEndMinute;
};

#endif
