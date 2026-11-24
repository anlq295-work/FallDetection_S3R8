import 'dart:convert';
import 'package:flutter/material.dart';

const String kAppReleaseLabel = 'pre-release1.0.1';
const String kFirmwareDefaultVersion = 'pre-release1.0.1';

enum AppLanguage {
  vi('vi', 'Tiếng Việt', 'VI'),
  en('en', 'English', 'EN'),
  fr('fr', 'Français', 'FR');

  const AppLanguage(this.code, this.nativeName, this.shortCode);
  final String code;
  final String nativeName;
  final String shortCode;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

enum AlertDispatchMode {
  simultaneous, // Default: notify ALL contacts & channels at the exact same time
  sequential; // Optional: escalate step-by-step after wait timeout

  static AlertDispatchMode fromName(String? name) {
    return AlertDispatchMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AlertDispatchMode.simultaneous,
    );
  }
}

enum FalseAlarmReason {
  satDownQuickly,
  droppedObject,
  normalRoutine,
  guestOrPet,
  other;

  static FalseAlarmReason? fromName(String? name) {
    if (name == null) return null;
    for (final v in FalseAlarmReason.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

enum RoomType {
  livingRoom('living_room', Icons.weekend_rounded),
  bedroom('bedroom', Icons.bed_rounded),
  bathroom('bathroom', Icons.bathtub_rounded),
  kitchen('kitchen', Icons.kitchen_rounded),
  hallway('hallway', Icons.sensor_door_rounded),
  other('other', Icons.home_rounded);

  const RoomType(this.id, this.icon);
  final String id;
  final IconData icon;

  static RoomType fromId(String? id) {
    return RoomType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => RoomType.other,
    );
  }
}

enum RoomStatus {
  occupied,
  empty,
  offline;

  static RoomStatus fromName(String? name) {
    return RoomStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => RoomStatus.empty,
    );
  }
}

enum HearthEventType {
  entered,
  left,
  fallDetected,
  fallResolved,
  sensorOffline,
  testPassed,
  manualSos,
  inactivityWarning,
  safeCheckIn;

  static HearthEventType fromName(String? name) {
    return HearthEventType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => HearthEventType.entered,
    );
  }
}

enum FallResolutionOutcome {
  personOk,
  neededHelp,
  falseAlarm;

  static FallResolutionOutcome? fromName(String? name) {
    if (name == null) return null;
    for (final v in FallResolutionOutcome.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

enum AlarmSoundLevel {
  mute,
  low,
  medium,
  high;

  static AlarmSoundLevel fromName(String? name) {
    return AlarmSoundLevel.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AlarmSoundLevel.medium,
    );
  }
}

enum ConnectionTransport {
  disconnected,
  ble,
  wifiLan,
  simulated,
}

class TelemetrySnapshot {
  final String state; // NORMAL, SUSPECTED, PRE_ALARM, ALERT, ACK, RESOLVED, FAULT
  final String postureClass; // STAND, SIT, LIE, FALL
  final double confidence;
  final int tofHeightMm;
  final int radarMotion;
  final int radarStatic;
  final double dropRateMmS;
  final bool pirActive;
  final String ipAddress;
  final int rssi;
  final int uptimeSec;
  final String firmwareVersion;
  final DateTime receivedAt;

  const TelemetrySnapshot({
    this.state = 'NORMAL',
    this.postureClass = 'STAND',
    this.confidence = 0.92,
    this.tofHeightMm = 1480,
    this.radarMotion = 8,
    this.radarStatic = 24,
    this.dropRateMmS = 0,
    this.pirActive = false,
    this.ipAddress = '0.0.0.0',
    this.rssi = -56,
    this.uptimeSec = 0,
    this.firmwareVersion = kFirmwareDefaultVersion,
    required this.receivedAt,
  });

  factory TelemetrySnapshot.fromJson(Map<String, dynamic> json) {
    return TelemetrySnapshot(
      state: (json['st'] ?? 'NORMAL').toString().toUpperCase(),
      postureClass: (json['cls'] ?? 'STAND').toString().toUpperCase(),
      confidence: ((json['cf'] as num?) ?? 0.0).toDouble(),
      tofHeightMm: ((json['h'] as num?) ?? 0).toInt(),
      radarMotion: ((json['m'] as num?) ?? 0).toInt(),
      radarStatic: ((json['s'] as num?) ?? 0).toInt(),
      dropRateMmS: ((json['dr'] as num?) ?? 0).toDouble(),
      pirActive: (json['pir'] == 1 || json['pir'] == true),
      ipAddress: (json['ip'] ?? '0.0.0.0').toString(),
      rssi: ((json['rssi'] as num?) ?? 0).toInt(),
      uptimeSec: ((json['uptime'] as num?) ?? 0).toInt(),
      firmwareVersion: (json['ver'] ?? kFirmwareDefaultVersion).toString(),
      receivedAt: DateTime.now(),
    );
  }

  bool get isFallAlert => state == 'ALERT' || state == 'PRE_ALARM';
  bool get isPersonPresent =>
      pirActive || radarMotion >= 12 || radarStatic >= 15 || (tofHeightMm > 80 && tofHeightMm < 2400);
}

class BlackboxEvent {
  final int type; // 1=impact, 2=slow fall, 3=manual SOS
  final int uptimeSec;
  final double velocityMmS;
  final int motionPeak;
  final int targetDistCm;

  const BlackboxEvent({
    required this.type,
    required this.uptimeSec,
    required this.velocityMmS,
    required this.motionPeak,
    required this.targetDistCm,
  });

  factory BlackboxEvent.fromJson(Map<String, dynamic> json) {
    return BlackboxEvent(
      type: ((json['type'] as num?) ?? 1).toInt(),
      uptimeSec: ((json['sec'] as num?) ?? 0).toInt(),
      velocityMmS: ((json['vel'] as num?) ?? 0).toDouble(),
      motionPeak: ((json['mot'] as num?) ?? 0).toInt(),
      targetDistCm: ((json['dst'] as num?) ?? 0).toInt(),
    );
  }
}

class HearthRoom {
  final String id;
  final String name;
  final RoomType type;
  final RoomStatus status;
  final DateTime lastMovementAt;
  final DateTime? offlineSince;
  final String sensorId;
  final String? bleDeviceId;
  final String? lanIp;
  final String wifiSsid;
  final int wifiRssi;
  final DateTime lastCheckedAt;
  final AlarmSoundLevel alarmVolume;
  final bool buzzerActiveHigh;
  final bool nightlightEnabled;
  final int nightStartHour;
  final int nightStartMinute;
  final int nightEndHour;
  final int nightEndMinute;
  final int floorThresholdMm;
  final int inactivityLimitMinutes; // 0 = off; e.g. 30 min bathroom lingering / inactivity alert
  final String firmwareVersion;
  final TelemetrySnapshot? latestTelemetry;

  const HearthRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.lastMovementAt,
    this.offlineSince,
    required this.sensorId,
    this.bleDeviceId,
    this.lanIp,
    this.wifiSsid = '',
    this.wifiRssi = -54,
    required this.lastCheckedAt,
    this.alarmVolume = AlarmSoundLevel.medium,
    this.buzzerActiveHigh = false,
    this.nightlightEnabled = true,
    this.nightStartHour = 22,
    this.nightStartMinute = 0,
    this.nightEndHour = 7,
    this.nightEndMinute = 0,
    this.floorThresholdMm = 450,
    this.inactivityLimitMinutes = 30,
    this.firmwareVersion = kFirmwareDefaultVersion,
    this.latestTelemetry,
  });

  HearthRoom copyWith({
    String? name,
    RoomType? type,
    RoomStatus? status,
    DateTime? lastMovementAt,
    DateTime? offlineSince,
    bool clearOfflineSince = false,
    String? sensorId,
    String? bleDeviceId,
    String? lanIp,
    String? wifiSsid,
    int? wifiRssi,
    DateTime? lastCheckedAt,
    AlarmSoundLevel? alarmVolume,
    bool? buzzerActiveHigh,
    bool? nightlightEnabled,
    int? nightStartHour,
    int? nightStartMinute,
    int? nightEndHour,
    int? nightEndMinute,
    int? floorThresholdMm,
    int? inactivityLimitMinutes,
    String? firmwareVersion,
    TelemetrySnapshot? latestTelemetry,
  }) {
    return HearthRoom(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      lastMovementAt: lastMovementAt ?? this.lastMovementAt,
      offlineSince: clearOfflineSince ? null : (offlineSince ?? this.offlineSince),
      sensorId: sensorId ?? this.sensorId,
      bleDeviceId: bleDeviceId ?? this.bleDeviceId,
      lanIp: lanIp ?? this.lanIp,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiRssi: wifiRssi ?? this.wifiRssi,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      buzzerActiveHigh: buzzerActiveHigh ?? this.buzzerActiveHigh,
      nightlightEnabled: nightlightEnabled ?? this.nightlightEnabled,
      nightStartHour: nightStartHour ?? this.nightStartHour,
      nightStartMinute: nightStartMinute ?? this.nightStartMinute,
      nightEndHour: nightEndHour ?? this.nightEndHour,
      nightEndMinute: nightEndMinute ?? this.nightEndMinute,
      floorThresholdMm: floorThresholdMm ?? this.floorThresholdMm,
      inactivityLimitMinutes: inactivityLimitMinutes ?? this.inactivityLimitMinutes,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      latestTelemetry: latestTelemetry ?? this.latestTelemetry,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.id,
        'status': status.name,
        'lastMovementAt': lastMovementAt.toIso8601String(),
        'offlineSince': offlineSince?.toIso8601String(),
        'sensorId': sensorId,
        'bleDeviceId': bleDeviceId,
        'lanIp': lanIp,
        'wifiSsid': wifiSsid,
        'wifiRssi': wifiRssi,
        'lastCheckedAt': lastCheckedAt.toIso8601String(),
        'alarmVolume': alarmVolume.name,
        'buzzerActiveHigh': buzzerActiveHigh,
        'nightlightEnabled': nightlightEnabled,
        'nightStartHour': nightStartHour,
        'nightStartMinute': nightStartMinute,
        'nightEndHour': nightEndHour,
        'nightEndMinute': nightEndMinute,
        'floorThresholdMm': floorThresholdMm,
        'inactivityLimitMinutes': inactivityLimitMinutes,
        'firmwareVersion': firmwareVersion,
      };

  factory HearthRoom.fromJson(Map<String, dynamic> json) {
    return HearthRoom(
      id: json['id']?.toString() ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? '',
      type: RoomType.fromId(json['type']?.toString()),
      status: RoomStatus.fromName(json['status']?.toString()),
      lastMovementAt: DateTime.tryParse(json['lastMovementAt']?.toString() ?? '') ?? DateTime.now(),
      offlineSince: DateTime.tryParse(json['offlineSince']?.toString() ?? ''),
      sensorId: json['sensorId']?.toString() ?? 'S3R8',
      bleDeviceId: json['bleDeviceId']?.toString(),
      lanIp: json['lanIp']?.toString(),
      wifiSsid: json['wifiSsid']?.toString() ?? '',
      wifiRssi: ((json['wifiRssi'] as num?) ?? -55).toInt(),
      lastCheckedAt: DateTime.tryParse(json['lastCheckedAt']?.toString() ?? '') ?? DateTime.now(),
      alarmVolume: AlarmSoundLevel.fromName(json['alarmVolume']?.toString()),
      buzzerActiveHigh: json['buzzerActiveHigh'] == true,
      nightlightEnabled: json['nightlightEnabled'] != false,
      nightStartHour: ((json['nightStartHour'] as num?) ?? 22).toInt(),
      nightStartMinute: ((json['nightStartMinute'] as num?) ?? 0).toInt(),
      nightEndHour: ((json['nightEndHour'] as num?) ?? 7).toInt(),
      nightEndMinute: ((json['nightEndMinute'] as num?) ?? 0).toInt(),
      floorThresholdMm: ((json['floorThresholdMm'] as num?) ?? 450).toInt(),
      inactivityLimitMinutes: ((json['inactivityLimitMinutes'] as num?) ?? 30).toInt(),
      firmwareVersion: json['firmwareVersion']?.toString() ?? kFirmwareDefaultVersion,
    );
  }
}

class HearthEvent {
  final String id;
  final String roomId;
  final String roomName;
  final HearthEventType type;
  final DateTime at;
  final FallResolutionOutcome? outcome;
  final FalseAlarmReason? falseAlarmReason;
  final String? resolvedBy;
  final String? note;

  const HearthEvent({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.type,
    required this.at,
    this.outcome,
    this.falseAlarmReason,
    this.resolvedBy,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'roomName': roomName,
        'type': type.name,
        'at': at.toIso8601String(),
        'outcome': outcome?.name,
        'falseAlarmReason': falseAlarmReason?.name,
        'resolvedBy': resolvedBy,
        'note': note,
      };

  factory HearthEvent.fromJson(Map<String, dynamic> json) {
    return HearthEvent(
      id: json['id']?.toString() ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      roomId: json['roomId']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      type: HearthEventType.fromName(json['type']?.toString()),
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      outcome: FallResolutionOutcome.fromName(json['outcome']?.toString()),
      falseAlarmReason: FalseAlarmReason.fromName(json['falseAlarmReason']?.toString()),
      resolvedBy: json['resolvedBy']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class AlertContact {
  final String id;
  final String name;
  final String phone;
  final bool isPrimaryUser;
  final bool joined;
  final bool notifySms;
  final bool notifyCall;
  final bool notifyApp;

  const AlertContact({
    required this.id,
    required this.name,
    required this.phone,
    this.isPrimaryUser = false,
    this.joined = false,
    this.notifySms = true,
    this.notifyCall = true,
    this.notifyApp = true,
  });

  AlertContact copyWith({
    String? name,
    String? phone,
    bool? joined,
    bool? notifySms,
    bool? notifyCall,
    bool? notifyApp,
  }) {
    return AlertContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isPrimaryUser: isPrimaryUser,
      joined: joined ?? this.joined,
      notifySms: notifySms ?? this.notifySms,
      notifyCall: notifyCall ?? this.notifyCall,
      notifyApp: notifyApp ?? this.notifyApp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'isPrimaryUser': isPrimaryUser,
        'joined': joined,
        'notifySms': notifySms,
        'notifyCall': notifyCall,
        'notifyApp': notifyApp,
      };

  factory AlertContact.fromJson(Map<String, dynamic> json) {
    return AlertContact(
      id: json['id']?.toString() ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isPrimaryUser: json['isPrimaryUser'] == true,
      joined: json['joined'] == true,
      notifySms: json['notifySms'] != false,
      notifyCall: json['notifyCall'] != false,
      notifyApp: json['notifyApp'] != false,
    );
  }
}

class MedicationReminder {
  final String id;
  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final bool takenToday;

  const MedicationReminder({
    required this.id,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.takenToday = false,
  });

  MedicationReminder copyWith({bool? takenToday}) => MedicationReminder(
        id: id,
        name: name,
        dosage: dosage,
        hour: hour,
        minute: minute,
        takenToday: takenToday ?? this.takenToday,
      );

  String get formattedTime => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'hour': hour,
        'minute': minute,
        'takenToday': takenToday,
      };

  factory MedicationReminder.fromJson(Map<String, dynamic> json) => MedicationReminder(
        id: json['id']?.toString() ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        hour: ((json['hour'] as num?) ?? 8).toInt(),
        minute: ((json['minute'] as num?) ?? 0).toInt(),
        takenToday: json['takenToday'] == true,
      );
}

class ActiveFallAlert {
  final String id;
  final String roomId;
  final String roomName;
  final String personName;
  final DateTime detectedAt;
  final DateTime? movementDetectedAt;
  final bool roomAlarmActive;
  final bool roomLightActive;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final AlertDispatchMode dispatchMode;
  final List<String> notifiedContactIds;
  final bool smsBroadcastReady;
  final bool telegramBroadcastReady;
  final bool simulated;
  final TelemetrySnapshot? telemetry;

  const ActiveFallAlert({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.personName,
    required this.detectedAt,
    this.movementDetectedAt,
    this.roomAlarmActive = true,
    this.roomLightActive = true,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.dispatchMode = AlertDispatchMode.simultaneous,
    this.notifiedContactIds = const [],
    this.smsBroadcastReady = false,
    this.telegramBroadcastReady = false,
    this.simulated = false,
    this.telemetry,
  });

  ActiveFallAlert copyWith({
    DateTime? movementDetectedAt,
    bool? roomAlarmActive,
    bool? roomLightActive,
    bool? isAcknowledged,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    TelemetrySnapshot? telemetry,
  }) {
    return ActiveFallAlert(
      id: id,
      roomId: roomId,
      roomName: roomName,
      personName: personName,
      detectedAt: detectedAt,
      movementDetectedAt: movementDetectedAt ?? this.movementDetectedAt,
      roomAlarmActive: roomAlarmActive ?? this.roomAlarmActive,
      roomLightActive: roomLightActive ?? this.roomLightActive,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      dispatchMode: dispatchMode,
      notifiedContactIds: notifiedContactIds,
      smsBroadcastReady: smsBroadcastReady,
      telegramBroadcastReady: telegramBroadcastReady,
      simulated: simulated,
      telemetry: telemetry ?? this.telemetry,
    );
  }
}

/// Strictly empty defaults — NO generic fake names or fake phone numbers!
class ElderlyMedicalProfile {
  final String fullName;
  final int? age;
  final String bloodType;
  final String conditions;
  final String medications;
  final String allergies;
  final String primaryDoctor;
  final String doctorPhone;
  final String personPhone;
  final String insuranceId;
  final String homeAddress;
  final String doorLockboxCode; // For paramedics / neighbors arriving during a fall

  const ElderlyMedicalProfile({
    this.fullName = '',
    this.age,
    this.bloodType = '',
    this.conditions = '',
    this.medications = '',
    this.allergies = '',
    this.primaryDoctor = '',
    this.doctorPhone = '',
    this.personPhone = '',
    this.insuranceId = '',
    this.homeAddress = '',
    this.doorLockboxCode = '',
  });

  ElderlyMedicalProfile copyWith({
    String? fullName,
    int? age,
    String? bloodType,
    String? conditions,
    String? medications,
    String? allergies,
    String? primaryDoctor,
    String? doctorPhone,
    String? personPhone,
    String? insuranceId,
    String? homeAddress,
    String? doorLockboxCode,
  }) {
    return ElderlyMedicalProfile(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      bloodType: bloodType ?? this.bloodType,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      primaryDoctor: primaryDoctor ?? this.primaryDoctor,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      personPhone: personPhone ?? this.personPhone,
      insuranceId: insuranceId ?? this.insuranceId,
      homeAddress: homeAddress ?? this.homeAddress,
      doorLockboxCode: doorLockboxCode ?? this.doorLockboxCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'age': age,
        'bloodType': bloodType,
        'conditions': conditions,
        'medications': medications,
        'allergies': allergies,
        'primaryDoctor': primaryDoctor,
        'doctorPhone': doctorPhone,
        'personPhone': personPhone,
        'insuranceId': insuranceId,
        'homeAddress': homeAddress,
        'doorLockboxCode': doorLockboxCode,
      };

  factory ElderlyMedicalProfile.fromJson(Map<String, dynamic> json) {
    return ElderlyMedicalProfile(
      fullName: json['fullName']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt(),
      bloodType: json['bloodType']?.toString() ?? '',
      conditions: json['conditions']?.toString() ?? '',
      medications: json['medications']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      primaryDoctor: json['primaryDoctor']?.toString() ?? '',
      doctorPhone: json['doctorPhone']?.toString() ?? '',
      personPhone: json['personPhone']?.toString() ?? '',
      insuranceId: json['insuranceId']?.toString() ?? '',
      homeAddress: json['homeAddress']?.toString() ?? '',
      doorLockboxCode: json['doorLockboxCode']?.toString() ?? '',
    );
  }

  String encode() => jsonEncode(toJson());
  static ElderlyMedicalProfile decode(String raw) {
    try {
      return ElderlyMedicalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ElderlyMedicalProfile();
    }
  }
}

class DiscoveredSensor {
  final String id;
  final String shortCode;
  final String name;
  final int rssi;
  final bool isSimulated;
  final Object? rawBleDevice;

  const DiscoveredSensor({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.rssi,
    this.isSimulated = false,
    this.rawBleDevice,
  });

  bool get isStrongSignal => rssi >= -72;
}

class WifiNetworkCandidate {
  final String ssid;
  final int rssi;
  final bool secured;

  const WifiNetworkCandidate({
    required this.ssid,
    required this.rssi,
    this.secured = true,
  });

  bool get isStrong => rssi >= -67;
}
