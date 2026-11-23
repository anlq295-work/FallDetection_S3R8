import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../l10n/app_strings.dart';
import 'hardware_service.dart';

class HearthController extends ChangeNotifier {
  final Esp32HardwareService hardware = Esp32HardwareService();

  bool _initialized = false;
  AppLanguage _language = AppLanguage.vi; // Default Vietnamese per user request
  ThemeMode _themeMode = ThemeMode.system;

  // Account & onboarding state
  bool _signedIn = false;
  bool _setupCompleted = false;
  String _userEmail = '';
  String _carerName = 'An';
  String _personName = 'Bà Lan';

  // Home data
  List<HearthRoom> _rooms = [];
  List<HearthEvent> _events = [];
  List<AlertContact> _contacts = [];
  int _escalationMinutes = 2; // 1 / 2 / 5 min

  // Remote ESP32 channels (Telegram & SMS)
  String _telegramBotToken = '';
  String _telegramChatId = '';
  String _emergencyServiceNumber = '115';
  bool _heightInCm = false;

  // Medical tools state (retained from Fall Guard S3R8)
  ElderlyMedicalProfile _medicalProfile = const ElderlyMedicalProfile();
  int _steadiScore = 0;
  DateTime? _steadiDate;

  // Live hardware telemetry buffer & blackbox
  final List<TelemetrySnapshot> _telemetryHistory = [];
  List<BlackboxEvent> _blackboxEvents = [];
  String _lastHardwareStatus = '';
  String? _activeRoomIdForHardware;

  // Active fall alert (S7)
  ActiveFallAlert? _activeAlert;
  int _escalationSecondsLeft = 0;
  Timer? _escalationTimer;
  bool _phoneOfflineSimulation = false;

  StreamSubscription<TelemetrySnapshot>? _telemSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<List<BlackboxEvent>>? _bbSub;

  // Getters
  bool get initialized => _initialized;
  AppLanguage get language => _language;
  AppStrings get s => AppStrings(_language);
  ThemeMode get themeMode => _themeMode;
  bool get signedIn => _signedIn;
  bool get setupCompleted => _setupCompleted;
  String get userEmail => _userEmail;
  String get carerName => _carerName;
  String get personName => _personName;
  List<HearthRoom> get rooms => List.unmodifiable(_rooms);
  List<HearthEvent> get events => List.unmodifiable(_events);
  List<AlertContact> get contacts => List.unmodifiable(_contacts);
  int get escalationMinutes => _escalationMinutes;
  String get telegramBotToken => _telegramBotToken;
  String get telegramChatId => _telegramChatId;
  String get emergencyServiceNumber => _emergencyServiceNumber;
  bool get heightInCm => _heightInCm;
  ElderlyMedicalProfile get medicalProfile => _medicalProfile;
  int get steadiScore => _steadiScore;
  DateTime? get steadiDate => _steadiDate;
  List<TelemetrySnapshot> get telemetryHistory => List.unmodifiable(_telemetryHistory);
  List<BlackboxEvent> get blackboxEvents => List.unmodifiable(_blackboxEvents);
  String get lastHardwareStatus => _lastHardwareStatus;
  ActiveFallAlert? get activeAlert => _activeAlert;
  int get escalationSecondsLeft => _escalationSecondsLeft;
  bool get phoneOfflineSimulation => _phoneOfflineSimulation;

  AlertContact? get nextEscalationContact {
    for (final c in _contacts) {
      if (!c.isPrimaryUser) return c;
    }
    return null;
  }

  HearthRoom? get offlineRoom {
    for (final r in _rooms) {
      if (r.status == RoomStatus.offline) return r;
    }
    return null;
  }

  HearthRoom? get mostRecentOccupiedRoom {
    final active = _rooms.where((r) => r.status != RoomStatus.offline).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => b.lastMovementAt.compareTo(a.lastMovementAt));
    return active.first;
  }

  HearthController() {
    _bindHardwareStreams();
  }

  void _bindHardwareStreams() {
    _telemSub = hardware.telemetryStream.listen((snap) {
      _telemetryHistory.add(snap);
      if (_telemetryHistory.length > 40) _telemetryHistory.removeAt(0);

      // Update bound room (or first room) with live ESP32 data
      if (_rooms.isNotEmpty) {
        final idx = _activeRoomIdForHardware != null
            ? _rooms.indexWhere((r) => r.id == _activeRoomIdForHardware)
            : 0;
        final targetIdx = idx >= 0 ? idx : 0;
        final room = _rooms[targetIdx];
        final newStatus = snap.isPersonPresent ? RoomStatus.occupied : RoomStatus.empty;
        _rooms[targetIdx] = room.copyWith(
          status: newStatus,
          lastCheckedAt: DateTime.now(),
          lastMovementAt: snap.isPersonPresent ? DateTime.now() : room.lastMovementAt,
          wifiRssi: snap.rssi != 0 ? snap.rssi : room.wifiRssi,
          lanIp: snap.ipAddress != '0.0.0.0' ? snap.ipAddress : room.lanIp,
          firmwareVersion: snap.firmwareVersion,
          latestTelemetry: snap,
          clearOfflineSince: true,
        );

        // Automatically raise S7 Fall Alert if ESP32 detects PRE_ALARM or ALERT
        if (snap.isFallAlert && _activeAlert == null) {
          triggerFallAlert(roomId: room.id, simulated: false, telemetry: snap);
        } else if (_activeAlert != null && _activeAlert!.roomId == room.id) {
          if (snap.radarMotion >= 28 && _activeAlert!.movementDetectedAt == null) {
            _activeAlert = _activeAlert!.copyWith(
              movementDetectedAt: DateTime.now(),
              telemetry: snap,
            );
          } else {
            _activeAlert = _activeAlert!.copyWith(telemetry: snap);
          }
        }
      }
      notifyListeners();
    });

    _statusSub = hardware.statusStream.listen((msg) {
      _lastHardwareStatus = msg;
      notifyListeners();
    });

    _bbSub = hardware.blackboxStream.listen((list) {
      _blackboxEvents = list;
      notifyListeners();
    });
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString('hearth_lang') ?? 'vi');
    final themeIdx = prefs.getInt('hearth_theme') ?? 0;
    _themeMode = ThemeMode.values[themeIdx.clamp(0, ThemeMode.values.length - 1)];

    _signedIn = prefs.getBool('hearth_signed_in') ?? false;
    _setupCompleted = prefs.getBool('hearth_setup_done') ?? false;
    _userEmail = prefs.getString('hearth_email') ?? '';
    _carerName = prefs.getString('hearth_carer_name') ?? 'An';
    _personName = prefs.getString('hearth_person_name') ?? _defaultPersonName(_language);
    _escalationMinutes = prefs.getInt('hearth_escalation_min') ?? 2;
    _telegramBotToken = prefs.getString('hearth_tg_token') ?? '';
    _telegramChatId = prefs.getString('hearth_tg_chat') ?? '';
    _emergencyServiceNumber =
        prefs.getString('hearth_emg_num') ?? _defaultEmergencyNumber(_language);
    _heightInCm = prefs.getBool('hearth_height_cm') ?? false;
    _steadiScore = prefs.getInt('hearth_steadi_score') ?? 0;
    final steadiIso = prefs.getString('hearth_steadi_date');
    _steadiDate = steadiIso != null ? DateTime.tryParse(steadiIso) : null;

    final medRaw = prefs.getString('hearth_med_profile');
    if (medRaw != null && medRaw.isNotEmpty) {
      _medicalProfile = ElderlyMedicalProfile.decode(medRaw);
    } else {
      _medicalProfile = ElderlyMedicalProfile(fullName: _personName);
    }

    final roomsRaw = prefs.getString('hearth_rooms');
    if (roomsRaw != null) {
      try {
        final decoded = jsonDecode(roomsRaw) as List;
        _rooms = decoded.whereType<Map<String, dynamic>>().map(HearthRoom.fromJson).toList();
      } catch (_) {}
    }

    final eventsRaw = prefs.getString('hearth_events');
    if (eventsRaw != null) {
      try {
        final decoded = jsonDecode(eventsRaw) as List;
        _events = decoded.whereType<Map<String, dynamic>>().map(HearthEvent.fromJson).toList();
      } catch (_) {}
    }

    final contactsRaw = prefs.getString('hearth_contacts');
    if (contactsRaw != null) {
      try {
        final decoded = jsonDecode(contactsRaw) as List;
        _contacts = decoded.whereType<Map<String, dynamic>>().map(AlertContact.fromJson).toList();
      } catch (_) {}
    }

    if (_contacts.isEmpty) {
      _seedDefaultContacts();
    }
    if (_rooms.isEmpty && _setupCompleted) {
      _seedDefaultHome();
    }

    _initialized = true;
    notifyListeners();
  }

  String _defaultPersonName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.vi:
        return 'Bà Lan';
      case AppLanguage.en:
        return 'Margaret';
      case AppLanguage.fr:
        return 'Marguerite';
    }
  }

  String _defaultEmergencyNumber(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.vi:
        return '115';
      case AppLanguage.en:
        return '911';
      case AppLanguage.fr:
        return '112';
    }
  }

  void _seedDefaultContacts() {
    _contacts = [
      AlertContact(
        id: 'self',
        name: _carerName,
        phone: '',
        isPrimaryUser: true,
        joined: true,
      ),
      AlertContact(
        id: 'backup_1',
        name: _language == AppLanguage.vi ? 'Anh Minh' : 'Paul Ruiz',
        phone: _language == AppLanguage.vi ? '0912 345 678' : '+34 612 345 218',
        isPrimaryUser: false,
        joined: true,
      ),
    ];
  }

  /// Seeds the realistic 3-room home from Hearth spec (Living room occupied, Bedroom empty, Bathroom offline).
  void _seedDefaultHome() {
    final now = DateTime.now();
    final livingName = s.roomTypeName(RoomType.livingRoom);
    final bedName = s.roomTypeName(RoomType.bedroom);
    final bathName = s.roomTypeName(RoomType.bathroom);

    _rooms = [
      HearthRoom(
        id: 'room_living',
        name: livingName,
        type: RoomType.livingRoom,
        status: RoomStatus.occupied,
        lastMovementAt: now.subtract(const Duration(minutes: 2)),
        sensorId: '4F2A',
        wifiSsid: 'Home_2.4G',
        wifiRssi: -52,
        lastCheckedAt: now.subtract(const Duration(minutes: 1)),
        latestTelemetry: TelemetrySnapshot(
          state: 'NORMAL',
          postureClass: 'STAND',
          confidence: 0.94,
          tofHeightMm: 1520,
          radarMotion: 22,
          radarStatic: 36,
          dropRateMmS: 0,
          pirActive: true,
          rssi: -52,
          receivedAt: now,
        ),
      ),
      HearthRoom(
        id: 'room_bedroom',
        name: bedName,
        type: RoomType.bedroom,
        status: RoomStatus.empty,
        lastMovementAt: DateTime(now.year, now.month, now.day, 7, 40),
        sensorId: '8C19',
        wifiSsid: 'Home_2.4G',
        wifiRssi: -61,
        lastCheckedAt: now.subtract(const Duration(minutes: 2)),
      ),
      HearthRoom(
        id: 'room_bathroom',
        name: bathName,
        type: RoomType.bathroom,
        status: RoomStatus.offline,
        lastMovementAt: now.subtract(const Duration(hours: 2)),
        offlineSince: now.subtract(const Duration(minutes: 42)),
        sensorId: '9B04',
        wifiSsid: 'Home_2.4G',
        wifiRssi: -84,
        lastCheckedAt: now.subtract(const Duration(minutes: 42)),
      ),
    ];

    _events = [
      HearthEvent(
        id: 'ev_1',
        roomId: 'room_living',
        roomName: livingName,
        type: HearthEventType.entered,
        at: now.subtract(const Duration(minutes: 2)),
      ),
      HearthEvent(
        id: 'ev_2',
        roomId: 'room_bathroom',
        roomName: bathName,
        type: HearthEventType.sensorOffline,
        at: now.subtract(const Duration(minutes: 42)),
      ),
      HearthEvent(
        id: 'ev_3',
        roomId: 'room_bedroom',
        roomName: bedName,
        type: HearthEventType.left,
        at: DateTime(now.year, now.month, now.day, 7, 40),
      ),
    ];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hearth_lang', _language.code);
    await prefs.setInt('hearth_theme', _themeMode.index);
    await prefs.setBool('hearth_signed_in', _signedIn);
    await prefs.setBool('hearth_setup_done', _setupCompleted);
    await prefs.setString('hearth_email', _userEmail);
    await prefs.setString('hearth_carer_name', _carerName);
    await prefs.setString('hearth_person_name', _personName);
    await prefs.setInt('hearth_escalation_min', _escalationMinutes);
    await prefs.setString('hearth_tg_token', _telegramBotToken);
    await prefs.setString('hearth_tg_chat', _telegramChatId);
    await prefs.setString('hearth_emg_num', _emergencyServiceNumber);
    await prefs.setBool('hearth_height_cm', _heightInCm);
    await prefs.setInt('hearth_steadi_score', _steadiScore);
    if (_steadiDate != null) {
      await prefs.setString('hearth_steadi_date', _steadiDate!.toIso8601String());
    }
    await prefs.setString('hearth_med_profile', _medicalProfile.encode());
    await prefs.setString('hearth_rooms', jsonEncode(_rooms.map((e) => e.toJson()).toList()));
    await prefs.setString('hearth_events', jsonEncode(_events.map((e) => e.toJson()).toList()));
    await prefs.setString('hearth_contacts', jsonEncode(_contacts.map((e) => e.toJson()).toList()));
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    await _persist();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _persist();
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required bool returningUser,
  }) async {
    _userEmail = email.trim();
    final localPart = _userEmail.split('@').first;
    if (localPart.isNotEmpty) {
      _carerName = localPart[0].toUpperCase() + localPart.substring(1);
    }
    _signedIn = true;
    if (_contacts.isNotEmpty && _contacts.first.isPrimaryUser) {
      _contacts[0] = _contacts[0].copyWith(name: _carerName);
    }
    if (returningUser) {
      _setupCompleted = true;
      if (_rooms.isEmpty) _seedDefaultHome();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> signOut() async {
    _signedIn = false;
    await _persist();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _setupCompleted = true;
    await _persist();
    notifyListeners();
  }

  Future<void> setPersonName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _personName = trimmed;
    _medicalProfile = _medicalProfile.copyWith(fullName: trimmed);
    await _persist();
    notifyListeners();
  }

  Future<HearthRoom> addOrUpdateRoom(HearthRoom room) async {
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx >= 0) {
      _rooms[idx] = room;
    } else {
      _rooms.insert(0, room);
    }
    _activeRoomIdForHardware = room.id;
    await _persist();
    notifyListeners();
    return room;
  }

  Future<void> renameRoom(String roomId, String newName) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    _rooms[idx] = _rooms[idx].copyWith(name: newName.trim());
    await _persist();
    notifyListeners();
  }

  Future<void> removeRoom(String roomId) async {
    _rooms.removeWhere((r) => r.id == roomId);
    await _persist();
    notifyListeners();
  }

  Future<void> markRoomOnlineAfterReconnect(String roomId, {String? wifiSsid, String? lanIp}) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    _rooms[idx] = _rooms[idx].copyWith(
      status: RoomStatus.empty,
      clearOfflineSince: true,
      wifiSsid: wifiSsid ?? _rooms[idx].wifiSsid,
      lanIp: lanIp ?? _rooms[idx].lanIp,
      wifiRssi: -54,
      lastCheckedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateRoomSettings(
    String roomId, {
    AlarmSoundLevel? alarmVolume,
    bool? buzzerActiveHigh,
    bool? nightlightEnabled,
    int? nightStartHour,
    int? nightStartMinute,
    int? nightEndHour,
    int? nightEndMinute,
    int? floorThresholdMm,
  }) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    final updated = _rooms[idx].copyWith(
      alarmVolume: alarmVolume,
      buzzerActiveHigh: buzzerActiveHigh,
      nightlightEnabled: nightlightEnabled,
      nightStartHour: nightStartHour,
      nightStartMinute: nightStartMinute,
      nightEndHour: nightEndHour,
      nightEndMinute: nightEndMinute,
      floorThresholdMm: floorThresholdMm,
    );
    _rooms[idx] = updated;

    // Push real hardware commands to ESP32-S3
    if (alarmVolume != null) {
      await hardware.sendCommand(
        alarmVolume == AlarmSoundLevel.mute ? 'BUZZER_MUTE' : 'BUZZER_UNMUTE',
        overrideLanIp: updated.lanIp,
      );
    }
    if (buzzerActiveHigh != null) {
      await hardware.sendCommand(
        buzzerActiveHigh ? 'BUZZER_ACTIVE_HIGH' : 'BUZZER_ACTIVE_LOW',
        overrideLanIp: updated.lanIp,
      );
    }
    if (nightlightEnabled != null ||
        nightStartHour != null ||
        nightStartMinute != null ||
        nightEndHour != null ||
        nightEndMinute != null) {
      final cmd =
          'NIGHTLIGHT_SCHEDULE:${updated.nightlightEnabled ? 1 : 0},${updated.nightStartHour},${updated.nightStartMinute},${updated.nightEndHour},${updated.nightEndMinute}';
      await hardware.sendCommand(cmd, overrideLanIp: updated.lanIp);
    }
    if (floorThresholdMm != null) {
      await hardware.writeContactConfig(floorMm: floorThresholdMm);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> logEvent(HearthEvent event) async {
    _events.insert(0, event);
    if (_events.length > 100) _events = _events.sublist(0, 100);
    await _persist();
    notifyListeners();
  }

  // Contacts & Escalation (S9)
  Future<void> addContact(String name, String phone) async {
    _contacts.add(
      AlertContact(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        phone: phone.trim(),
        isPrimaryUser: false,
        joined: false,
      ),
    );
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> removeContact(String id) async {
    _contacts.removeWhere((c) => c.id == id && !c.isPrimaryUser);
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> reorderContacts(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _contacts.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= _contacts.length) return;
    final item = _contacts.removeAt(oldIndex);
    _contacts.insert(newIndex, item);
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> moveContactByDelta(int index, int delta) async {
    final target = index + delta;
    if (index < 0 || index >= _contacts.length || target < 0 || target >= _contacts.length) return;
    final item = _contacts.removeAt(index);
    _contacts.insert(target, item);
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> setEscalationMinutes(int minutes) async {
    _escalationMinutes = minutes;
    await _persist();
    notifyListeners();
  }

  Future<void> updateRemoteChannels({
    required String telegramBotToken,
    required String telegramChatId,
  }) async {
    _telegramBotToken = telegramBotToken.trim();
    _telegramChatId = telegramChatId.trim();
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> _syncRemoteChannelsToHardware() async {
    final phones = _contacts
        .map((c) => c.phone.replaceAll(RegExp(r'[^0-9+]'), ''))
        .where((p) => p.length >= 9)
        .join(',');
    await hardware.writeContactConfig(
      phoneList: phones,
      telegramBotToken: _telegramBotToken,
      telegramChatId: _telegramChatId,
    );
  }

  Future<void> updateEmergencyNumber(String number) async {
    if (number.trim().isEmpty) return;
    _emergencyServiceNumber = number.trim();
    await _persist();
    notifyListeners();
  }

  Future<void> setHeightUnitCm(bool inCm) async {
    _heightInCm = inCm;
    await _persist();
    notifyListeners();
  }

  Future<void> saveMedicalProfile(ElderlyMedicalProfile profile) async {
    _medicalProfile = profile;
    if (profile.fullName.trim().isNotEmpty) {
      _personName = profile.fullName.trim();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> saveSteadiResult(int score) async {
    _steadiScore = score;
    _steadiDate = DateTime.now();
    await _persist();
    notifyListeners();
  }

  void setPhoneOfflineSimulation(bool offline) {
    _phoneOfflineSimulation = offline;
    notifyListeners();
  }

  // Fall Alert lifecycle (S7)
  void triggerFallAlert({
    String? roomId,
    bool simulated = true,
    TelemetrySnapshot? telemetry,
  }) {
    final room = _rooms.isEmpty
        ? null
        : (roomId != null
            ? _rooms.firstWhere((r) => r.id == roomId, orElse: () => _rooms.first)
            : _rooms.firstWhere(
                (r) => r.type == RoomType.bathroom,
                orElse: () => _rooms.first,
              ));

    final rId = room?.id ?? 'room_bathroom';
    final rName = room?.name ?? s.roomTypeName(RoomType.bathroom);
    final now = DateTime.now();

    _activeAlert = ActiveFallAlert(
      id: 'alert_${now.millisecondsSinceEpoch}',
      roomId: rId,
      roomName: rName,
      personName: _personName,
      detectedAt: now,
      simulated: simulated,
      telemetry: telemetry ??
          TelemetrySnapshot(
            state: 'ALERT',
            postureClass: 'FALL',
            confidence: 0.91,
            tofHeightMm: 280,
            radarMotion: 84,
            radarStatic: 34,
            dropRateMmS: 695,
            pirActive: true,
            receivedAt: now,
          ),
    );

    _escalationSecondsLeft = _escalationMinutes * 60;
    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeAlert == null || _activeAlert!.isAcknowledged) {
        _escalationTimer?.cancel();
        return;
      }
      if (_escalationSecondsLeft > 0) {
        _escalationSecondsLeft -= 1;
        notifyListeners();
      }
    });

    logEvent(
      HearthEvent(
        id: 'ev_fall_${now.millisecondsSinceEpoch}',
        roomId: rId,
        roomName: rName,
        type: HearthEventType.fallDetected,
        at: now,
      ),
    );
    notifyListeners();
  }

  Future<bool> acknowledgeActiveAlert() async {
    if (_activeAlert == null) return false;
    if (_phoneOfflineSimulation) {
      return false;
    }
    _escalationTimer?.cancel();
    _activeAlert = _activeAlert!.copyWith(
      isAcknowledged: true,
      acknowledgedBy: _carerName,
      acknowledgedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  Future<void> turnOffRoomAlarmOnly() async {
    if (_activeAlert == null) return;
    _activeAlert = _activeAlert!.copyWith(roomAlarmActive: false, roomLightActive: true);
    await hardware.sendCommand('BUZZER_MUTE');
    notifyListeners();
  }

  Future<void> resolveActiveAlert({
    required FallResolutionOutcome outcome,
    String? note,
  }) async {
    final alert = _activeAlert;
    if (alert == null) return;
    _escalationTimer?.cancel();
    await hardware.sendCommand('CANCEL_ALARM');

    await logEvent(
      HearthEvent(
        id: 'ev_res_${DateTime.now().millisecondsSinceEpoch}',
        roomId: alert.roomId,
        roomName: alert.roomName,
        type: HearthEventType.fallResolved,
        at: DateTime.now(),
        outcome: outcome,
        resolvedBy: _carerName,
        note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      ),
    );

    _activeAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _escalationTimer?.cancel();
    _telemSub?.cancel();
    _statusSub?.cancel();
    _bbSub?.cancel();
    hardware.dispose();
    super.dispose();
  }
}
