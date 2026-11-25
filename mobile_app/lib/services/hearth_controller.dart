import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../l10n/app_strings.dart';
import 'alert_bot_service.dart';
import 'hardware_service.dart';

class HearthController extends ChangeNotifier {
  final Esp32HardwareService hardware = Esp32HardwareService();
  final AlertBotService alertBot = AlertBotService();

  bool _initialized = false;
  AppLanguage _language = AppLanguage.vi; // Default Vietnamese
  ThemeMode _themeMode = ThemeMode.system;

  // Account & Caregiver Profile (ZERO hardcoded fake names or phones!)
  bool _signedIn = false;
  bool _setupCompleted = false;
  String _userEmail = '';
  String _carerName = '';
  String _personName = '';

  // Home data (starts clean & empty in real usage!)
  List<HearthRoom> _rooms = [];
  List<HearthEvent> _events = [];
  List<AlertContact> _contacts = [];
  List<MedicationReminder> _medications = [];

  // Simultaneous alert configuration (DEFAULT: simultaneous to ALL contacts via Telegram & Call)
  AlertDispatchMode _dispatchMode = AlertDispatchMode.simultaneous;
  int _escalationMinutes = 2; // Used only if user switches to sequential mode
  bool _channelSmsEnabled = false;
  bool _channelTelegramEnabled = true;
  bool _channelCallEnabled = true;

  // Guest / Privacy Pause Mode & Daily Check-in
  bool _guestModeActive = false;
  DateTime? _lastSafeCheckIn;

  // Remote ESP32 & Multi-Channel Alert Bot (pre-wired automatically; no user setup required)
  String _telegramBotToken = '';
  String _telegramChatId = '';
  String _alertBotUrl = kDefaultAlertBotUrl;
  String _alertBotApiKey = kDefaultAlertBotApiKey;
  String _lastBotSyncStatus = '';
  String _emergencyServiceNumber = '115';
  bool _heightInCm = false;

  // Medical tools state
  ElderlyMedicalProfile _medicalProfile = const ElderlyMedicalProfile();
  int _steadiScore = 0;
  DateTime? _steadiDate;

  // Live hardware telemetry buffer & blackbox
  final List<TelemetrySnapshot> _telemetryHistory = [];
  List<BlackboxEvent> _blackboxEvents = [];
  String _lastHardwareStatus = '';
  String? _activeRoomIdForHardware;
  final Map<String, int> _presenceHits = {};
  final Map<String, int> _absenceHits = {};

  // Active fall alert (S7)
  ActiveFallAlert? _activeAlert;
  int _escalationSecondsLeft = 0;
  Timer? _escalationTimer;
  final Timer _heartbeatWatchdog;
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
  bool get hasRequiredCareProfile => _personName.trim().isNotEmpty && _carerName.trim().isNotEmpty;
  List<HearthRoom> get rooms => List.unmodifiable(_rooms);
  List<HearthEvent> get events => List.unmodifiable(_events);
  List<AlertContact> get contacts => List.unmodifiable(_contacts);
  List<MedicationReminder> get medications => List.unmodifiable(_medications);
  AlertDispatchMode get dispatchMode => _dispatchMode;
  int get escalationMinutes => _escalationMinutes;
  bool get channelSmsEnabled => _channelSmsEnabled;
  bool get channelTelegramEnabled => _channelTelegramEnabled;
  bool get channelCallEnabled => _channelCallEnabled;
  bool get guestModeActive => _guestModeActive;
  DateTime? get lastSafeCheckIn => _lastSafeCheckIn;
  String get telegramBotToken => _telegramBotToken;
  String get telegramChatId => _telegramChatId;
  String get alertBotUrl => _alertBotUrl;
  String get alertBotApiKey => _alertBotApiKey;
  String get lastBotSyncStatus => _lastBotSyncStatus;
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

  List<AlertContact> get backupContacts =>
      _contacts.where((c) => !c.isPrimaryUser).toList(growable: false);

  AlertContact? get nextEscalationContact =>
      backupContacts.isNotEmpty ? backupContacts.first : null;

  List<String> get allEmergencyPhoneNumbers => _contacts
      .where((c) => c.notifySms || c.notifyCall)
      .map((c) => c.phone.replaceAll(RegExp(r'[^0-9+]'), ''))
      .where((p) => p.length >= 9)
      .toSet()
      .toList(growable: false);

  List<String> get allTelegramChatIds {
    final ids = <String>{};
    for (final raw in _telegramChatId.replaceAll(';', ',').split(',')) {
      final clean = raw.trim();
      if (clean.isNotEmpty) ids.add(clean);
    }
    for (final c in _contacts) {
      if (c.notifyTelegram && c.telegramChatId.trim().isNotEmpty) {
        ids.add(c.telegramChatId.trim());
      }
    }
    return ids.toList(growable: false);
  }

  List<String> get allTelegramUsernames {
    final users = <String>{};
    for (final c in _contacts) {
      if (c.notifyCall && c.telegramUsername.trim().isNotEmpty) {
        var u = c.telegramUsername.trim();
        if (!u.startsWith('@')) u = '@$u';
        users.add(u);
      }
    }
    return users.toList(growable: false);
  }

  int get alertChannelMask =>
      (_channelSmsEnabled ? 0x01 : 0) |
      (_channelTelegramEnabled ? 0x02 : 0) |
      (_channelCallEnabled ? 0x04 : 0);

  bool get hasRemoteAlertConfigured =>
      _alertBotUrl.trim().isNotEmpty ||
      (_telegramBotToken.trim().isNotEmpty && allTelegramChatIds.isNotEmpty) ||
      allTelegramUsernames.isNotEmpty;

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
    _heartbeatWatchdog = Timer.periodic(const Duration(seconds: 3), (_) => _expireStaleHardware());
  }

  void _expireStaleHardware() {
    if (_activeRoomIdForHardware == null || hardware.isLanConnected || hardware.isBleConnected) {
      return;
    }
    final idx = _rooms.indexWhere((r) => r.id == _activeRoomIdForHardware);
    if (idx < 0) return;
    final room = _rooms[idx];
    if (room.status != RoomStatus.offline &&
        DateTime.now().difference(room.lastCheckedAt) > const Duration(seconds: 8)) {
      _rooms[idx] = room.copyWith(status: RoomStatus.offline);
      notifyListeners();
    }
  }

  void _bindHardwareStreams() {
    _telemSub = hardware.telemetryStream.listen((snap) {
      _telemetryHistory.add(snap);
      if (_telemetryHistory.length > 40) _telemetryHistory.removeAt(0);

      if (_rooms.isNotEmpty) {
        final idx = _activeRoomIdForHardware != null
            ? _rooms.indexWhere((r) => r.id == _activeRoomIdForHardware)
            : 0;
        final targetIdx = idx >= 0 ? idx : 0;
        final room = _rooms[targetIdx];
        // A BLE telemetry packet alone does not prove Wi-Fi connectivity.
        // Firmware reports 0.0.0.0 until the station has a valid IP.
        final hasWifi = snap.ipAddress.isNotEmpty && snap.ipAddress != '0.0.0.0';
        final present = snap.isPersonPresent;
        final hits = (_presenceHits[room.id] ?? 0);
        final absences = (_absenceHits[room.id] ?? 0);
        final confirmedPresent = present ? hits + 1 >= 2 : false;
        final confirmedEmpty = present ? false : absences + 1 >= 3;
        if (present) {
          _presenceHits[room.id] = hits + 1;
          _absenceHits[room.id] = 0;
        } else {
          _absenceHits[room.id] = absences + 1;
          _presenceHits[room.id] = 0;
        }
        final liveStatus = confirmedPresent
            ? RoomStatus.occupied
            : (confirmedEmpty ? RoomStatus.empty : room.status);
        final newStatus = !hasWifi ? RoomStatus.offline : liveStatus;
        _rooms[targetIdx] = room.copyWith(
          status: newStatus,
          lastCheckedAt: DateTime.now(),
          lastMovementAt: present ? DateTime.now() : room.lastMovementAt,
          wifiRssi: snap.rssi != 0 ? snap.rssi : room.wifiRssi,
          lanIp: snap.ipAddress != '0.0.0.0' ? snap.ipAddress : room.lanIp,
          firmwareVersion: snap.firmwareVersion,
          sensorId: snap.deviceId.isNotEmpty ? snap.deviceId : room.sensorId,
          latestTelemetry: snap,
          clearOfflineSince: hasWifi,
        );

        // Automatically trigger S7 Fall Alert unless Guest/Privacy Pause Mode is active
        if (snap.isFallAlert && _activeAlert == null && !_guestModeActive) {
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
      if (msg == 'BLE_DISCONNECTED' && !hardware.isLanConnected) {
        _expireStaleHardware();
      }
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
    _carerName = prefs.getString('hearth_carer_name') ?? '';
    _personName = prefs.getString('hearth_person_name') ?? '';
    _dispatchMode = AlertDispatchMode.fromName(prefs.getString('hearth_dispatch_mode'));
    _escalationMinutes = prefs.getInt('hearth_escalation_min') ?? 2;
    _channelSmsEnabled = false;
    _channelTelegramEnabled = prefs.getBool('hearth_ch_tg') ?? true;
    _channelCallEnabled = prefs.getBool('hearth_ch_call') ?? true;
    _guestModeActive = prefs.getBool('hearth_guest_mode') ?? false;
    final checkInIso = prefs.getString('hearth_last_checkin');
    _lastSafeCheckIn = checkInIso != null ? DateTime.tryParse(checkInIso) : null;

    _telegramBotToken = prefs.getString('hearth_tg_token') ?? '';
    _telegramChatId = prefs.getString('hearth_tg_chat') ?? '';
    final savedBotUrl = (prefs.getString('hearth_bot_url') ?? '').trim();
    // Auto-migrate legacy local LAN dev URL to the cloud production default.
    if (savedBotUrl.isEmpty ||
        savedBotUrl == 'http://192.168.80.123:8080' ||
        savedBotUrl == 'http://127.0.0.1:8080') {
      _alertBotUrl = kDefaultAlertBotUrl;
      await prefs.setString('hearth_bot_url', _alertBotUrl);
    } else {
      _alertBotUrl = savedBotUrl;
    }
    final savedBotKey = (prefs.getString('hearth_bot_key') ?? '').trim();
    _alertBotApiKey = savedBotKey.isNotEmpty ? savedBotKey : kDefaultAlertBotApiKey;
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
        // Persisted occupancy is historical data. Require a fresh live packet
        // before showing a room as online or occupied after app restart.
        _rooms = decoded
            .whereType<Map<String, dynamic>>()
            .map(HearthRoom.fromJson)
            .map((room) => room.copyWith(status: RoomStatus.offline))
            .toList();
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

    final medsListRaw = prefs.getString('hearth_medications');
    if (medsListRaw != null) {
      try {
        final decoded = jsonDecode(medsListRaw) as List;
        _medications = decoded
            .whereType<Map<String, dynamic>>()
            .map(MedicationReminder.fromJson)
            .toList();
      } catch (_) {}
    }

    // Ensure only the signed-in primary user exists in contacts by default — NEVER fake contacts!
    if (_contacts.isEmpty && _signedIn) {
      _ensurePrimarySelfContact();
    }

    _initialized = true;
    notifyListeners();
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

  void _ensurePrimarySelfContact() {
    final displayName = _carerName.trim().isNotEmpty ? _carerName.trim() : _userEmail;
    final idx = _contacts.indexWhere((c) => c.isPrimaryUser);
    if (idx >= 0) {
      _contacts[idx] = _contacts[idx].copyWith(name: displayName);
    } else {
      _contacts.insert(
        0,
        AlertContact(
          id: 'self',
          name: displayName,
          phone: '',
          isPrimaryUser: true,
          joined: true,
        ),
      );
    }
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
    await prefs.setString('hearth_dispatch_mode', _dispatchMode.name);
    await prefs.setInt('hearth_escalation_min', _escalationMinutes);
    await prefs.setBool('hearth_ch_sms', _channelSmsEnabled);
    await prefs.setBool('hearth_ch_tg', _channelTelegramEnabled);
    await prefs.setBool('hearth_ch_call', _channelCallEnabled);
    await prefs.setBool('hearth_guest_mode', _guestModeActive);
    if (_lastSafeCheckIn != null) {
      await prefs.setString('hearth_last_checkin', _lastSafeCheckIn!.toIso8601String());
    }
    await prefs.setString('hearth_tg_token', _telegramBotToken);
    await prefs.setString('hearth_tg_chat', _telegramChatId);
    await prefs.setString('hearth_bot_url', _alertBotUrl);
    await prefs.setString('hearth_bot_key', _alertBotApiKey);
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
    await prefs.setString('hearth_medications', jsonEncode(_medications.map((e) => e.toJson()).toList()));
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
    required String carerName,
    required String personName,
    String personPhone = '',
    bool skipDirectToHome = false,
  }) async {
    _userEmail = email.trim();
    _carerName = carerName.trim();
    _personName = personName.trim();
    _medicalProfile = _medicalProfile.copyWith(
      fullName: _personName,
      personPhone: personPhone.trim().isNotEmpty ? personPhone.trim() : _medicalProfile.personPhone,
    );
    _signedIn = true;
    _ensurePrimarySelfContact();
    if (skipDirectToHome) {
      _setupCompleted = true;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateCareIdentity({
    required String carerName,
    required String personName,
    String? personPhone,
  }) async {
    _carerName = carerName.trim();
    _personName = personName.trim();
    _medicalProfile = _medicalProfile.copyWith(
      fullName: _personName,
      personPhone: personPhone?.trim() ?? _medicalProfile.personPhone,
    );
    _ensurePrimarySelfContact();
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
    int? inactivityLimitMinutes,
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
      inactivityLimitMinutes: inactivityLimitMinutes,
    );
    _rooms[idx] = updated;

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
    if (_events.length > 120) _events = _events.sublist(0, 120);
    await _persist();
    notifyListeners();
  }

  // Guest / Privacy Pause Mode & Daily Safe Check-In
  Future<void> setGuestMode(bool active) async {
    _guestModeActive = active;
    await _persist();
    notifyListeners();
  }

  Future<void> logSafeCheckIn() async {
    final now = DateTime.now();
    _lastSafeCheckIn = now;
    await logEvent(
      HearthEvent(
        id: 'ev_chk_${now.millisecondsSinceEpoch}',
        roomId: _rooms.isNotEmpty ? _rooms.first.id : 'home',
        roomName: s.s6HomeTitle(_personName),
        type: HearthEventType.safeCheckIn,
        at: now,
        resolvedBy: _carerName,
      ),
    );
  }

  // Daily Medication Schedule
  Future<void> addMedication(String name, String dosage, int hour, int minute) async {
    _medications.add(
      MedicationReminder(
        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        dosage: dosage.trim(),
        hour: hour,
        minute: minute,
      ),
    );
    _medications.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    await _persist();
    notifyListeners();
  }

  Future<void> toggleMedicationTaken(String id) async {
    final idx = _medications.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    _medications[idx] = _medications[idx].copyWith(takenToday: !_medications[idx].takenToday);
    await _persist();
    notifyListeners();
  }

  Future<void> removeMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
    await _persist();
    notifyListeners();
  }

  // Alert Dispatch Mode & Multi-Channel Contacts (S9)
  Future<void> setDispatchMode(AlertDispatchMode mode) async {
    _dispatchMode = mode;
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> setChannelPreferences({bool? sms, bool? telegram, bool? call}) async {
    if (sms != null) _channelSmsEnabled = sms;
    if (telegram != null) _channelTelegramEnabled = telegram;
    if (call != null) _channelCallEnabled = call;
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> addContact(
    String name,
    String phone, {
    String telegramPhone = '',
    String telegramChatId = '',
    String telegramUsername = '',
    bool notifyTelegram = true,
    bool notifySms = true,
    bool notifyCall = true,
  }) async {
    _contacts.add(
      AlertContact(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        phone: phone.trim(),
        telegramPhone: telegramPhone.trim(),
        telegramChatId: telegramChatId.trim(),
        telegramUsername: telegramUsername.trim(),
        isPrimaryUser: false,
        joined: telegramChatId.trim().isNotEmpty,
        notifyTelegram: notifyTelegram,
        notifySms: notifySms,
        notifyCall: notifyCall,
      ),
    );
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> updateContact(
    String id,
    String name,
    String phone, {
    String telegramPhone = '',
    String? telegramChatId,
    String? telegramUsername,
    bool? notifyTelegram,
    bool? notifySms,
    bool? notifyCall,
  }) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final cur = _contacts[index];
    final nextChatId = telegramChatId != null ? telegramChatId.trim() : cur.telegramChatId;
    _contacts[index] = cur.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      telegramPhone: telegramPhone.trim(),
      telegramChatId: nextChatId,
      telegramUsername: telegramUsername != null ? telegramUsername.trim() : cur.telegramUsername,
      joined: cur.joined || nextChatId.isNotEmpty,
      notifyTelegram: notifyTelegram ?? cur.notifyTelegram,
      notifySms: notifySms ?? cur.notifySms,
      notifyCall: notifyCall ?? cur.notifyCall,
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
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<void> updateBotServerConnection({
    required String botUrl,
    String apiKey = '',
  }) async {
    _alertBotUrl = botUrl.trim();
    _alertBotApiKey = apiKey.trim();
    await _persist();
    notifyListeners();
  }

  Future<OtpApiResult> requestLoginEmailOtp({
    required String email,
    String phone = '',
    required String carerName,
  }) {
    return alertBot.sendEmailOtp(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
      email: email,
      phone: phone,
      carerName: carerName,
      language: _language.code,
    );
  }

  Future<OtpApiResult> verifyLoginEmailOtp({
    required String email,
    String phone = '',
    required String code,
  }) {
    return alertBot.verifyEmailOtp(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
      email: email,
      phone: phone,
      code: code,
    );
  }

  Future<void> updateRemoteChannels({
    required String telegramBotToken,
    required String telegramChatId,
    String? alertBotUrl,
    String? alertBotApiKey,
  }) async {
    _telegramBotToken = telegramBotToken.trim();
    _telegramChatId = telegramChatId.trim();
    if (alertBotUrl != null) _alertBotUrl = alertBotUrl.trim();
    if (alertBotApiKey != null) _alertBotApiKey = alertBotApiKey.trim();
    await _syncRemoteChannelsToHardware();
    await _persist();
    notifyListeners();
  }

  Future<AlertBotHealthResult> checkAlertBotHealth() async {
    final res = await alertBot.checkHealth(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
    );
    _lastBotSyncStatus = res.ok ? 'Connected (${res.enabledRecipients})' : res.message;
    notifyListeners();
    return res;
  }

  /// Pulls contacts who registered via Telegram /start or /register into Hearth App contacts.
  Future<int> pullContactsFromBot() async {
    final remote = await alertBot.fetchRecipientsFromBot(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
    );
    if (remote == null) return -1;

    var addedOrUpdated = 0;
    for (final r in remote) {
      if (r.id.startsWith('tg_group_')) continue;
      final existingIdx = _contacts.indexWhere((c) =>
          c.id == r.id ||
          (r.telegramChatId.isNotEmpty && c.telegramChatId == r.telegramChatId) ||
          (r.phone.isNotEmpty && c.phone == r.phone));
      if (existingIdx >= 0) {
        final cur = _contacts[existingIdx];
        _contacts[existingIdx] = cur.copyWith(
          name: r.name.isNotEmpty ? r.name : cur.name,
          phone: r.phone.isNotEmpty ? r.phone : cur.phone,
          telegramChatId: r.telegramChatId.isNotEmpty ? r.telegramChatId : cur.telegramChatId,
          telegramUsername: r.telegramUsername.isNotEmpty ? r.telegramUsername : cur.telegramUsername,
          joined: true,
        );
      } else {
        _contacts.add(r.copyWith(joined: true));
      }
      addedOrUpdated++;
    }
    await _persist();
    notifyListeners();
    return addedOrUpdated;
  }

  Future<AlertBotDispatchResult> sendTestAlertBot({
    List<String>? channels,
    String? targetContactId,
  }) async {
    await _syncRemoteChannelsToHardware();
    final roomName = _rooms.isNotEmpty ? _rooms.first.name : 'Hearth Test';
    final channelLabel = (channels != null && channels.isNotEmpty)
        ? channels.map((e) => e.toUpperCase()).join('+')
        : 'ALL';
    final res = await alertBot.dispatchFallAlert(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
      eventType: 'test',
      roomName: roomName,
      personName: _personName.isNotEmpty ? _personName : s.personOrGeneric(''),
      simulated: true,
      note: 'Kiểm tra kênh $channelLabel từ ứng dụng Hearth',
      telegramBotToken: _telegramBotToken,
      telegramChatIds: allTelegramChatIds,
      telegramUsernames: allTelegramUsernames,
      phones: allEmergencyPhoneNumbers,
      telegramEnabled: channels == null ? _channelTelegramEnabled : channels.contains('telegram'),
      callEnabled: channels == null ? _channelCallEnabled : channels.contains('call'),
      fallbackMessage: '🧪 [TEST $channelLabel] HEARTH: Kiểm tra hệ thống cảnh báo té ngã thành công!',
      channelsOverride: channels,
      targetRecipientIds: targetContactId != null ? [targetContactId] : null,
    );
    _lastBotSyncStatus = res.summary;
    notifyListeners();
    return res;
  }

  Future<void> _syncRemoteChannelsToHardware() async {
    final phones = allEmergencyPhoneNumbers.join(',');
    final chatIds = allTelegramChatIds.join(',');
    final tgUsers = allTelegramUsernames.join(',');
    final lanIp = _rooms.isNotEmpty ? (_rooms.first.lanIp ?? hardware.activeLanIp) : hardware.activeLanIp;

    await hardware.writeContactConfig(
      phoneList: phones,
      telegramBotToken: _telegramBotToken,
      telegramChatId: chatIds,
      alertBotUrl: _alertBotUrl,
      alertBotApiKey: _alertBotApiKey,
      telegramUsers: tgUsers,
      channelMask: alertChannelMask,
      overrideLanIp: lanIp,
    );

    if (_alertBotUrl.trim().isNotEmpty) {
      final ok = await alertBot.syncSettingsToBot(
        botUrl: _alertBotUrl,
        apiKey: _alertBotApiKey,
        dispatchMode: _dispatchMode,
        escalationMinutes: _escalationMinutes,
        telegramEnabled: _channelTelegramEnabled,
        smsEnabled: _channelSmsEnabled,
        callEnabled: _channelCallEnabled,
        personName: _personName,
        homeAddress: _medicalProfile.homeAddress,
        doorCode: _medicalProfile.doorLockboxCode,
        emergencyNumber: _emergencyServiceNumber,
        esp32LanIp: lanIp ?? '',
        contacts: _contacts,
        defaultTelegramChatIds: _telegramChatId,
      );
      _lastBotSyncStatus = ok ? 'Synced to Alert Bot' : 'Bot offline (saved locally)';
    }
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

  /// Builds pre-filled simultaneous emergency SMS body containing person, room, time, address & door lockbox code.
  String buildEmergencySmsBody(ActiveFallAlert alert) {
    final timeStr = s.formatClock(alert.detectedAt);
    final addr = _medicalProfile.homeAddress.trim();
    final door = _medicalProfile.doorLockboxCode.trim();
    final extra = [
      if (addr.isNotEmpty) addr,
      if (door.isNotEmpty) 'Code: $door',
    ].join(' | ');

    switch (_language) {
      case AppLanguage.vi:
        return 'KHẨN CẤP HEARTH: ${s.personOrGeneric(alert.personName)} có thể đã bị té ngã tại ${alert.roomName} lúc $timeStr.${extra.isNotEmpty ? " ($extra)" : ""} Vui lòng kiểm tra hoặc gọi ngay!';
      case AppLanguage.en:
        return 'HEARTH EMERGENCY: ${s.personOrGeneric(alert.personName)} may have fallen in ${alert.roomName} at $timeStr.${extra.isNotEmpty ? " ($extra)" : ""} Please check or call now!';
      case AppLanguage.fr:
        return 'URGENCE HEARTH : ${s.personOrGeneric(alert.personName)} a peut-être chuté dans ${alert.roomName} à $timeStr.${extra.isNotEmpty ? " ($extra)" : ""} Merci de vérifier immédiatement !';
    }
  }

  // Fall Alert lifecycle (S7) — Simultaneous Multi-Channel by default!
  void triggerFallAlert({
    String? roomId,
    bool simulated = true,
    TelemetrySnapshot? telemetry,
  }) {
    final room = _rooms.isEmpty
        ? null
        : (roomId != null
            ? _rooms.firstWhere((r) => r.id == roomId, orElse: () => _rooms.first)
            : _rooms.first);

    final rId = room?.id ?? 'home_room';
    final rName = room?.name ?? s.roomTypeName(RoomType.bathroom);
    final now = DateTime.now();

    final notifiedIds = _dispatchMode == AlertDispatchMode.simultaneous
        ? _contacts.map((c) => c.id).toList()
        : (_contacts.isNotEmpty ? [_contacts.first.id] : <String>[]);

    _activeAlert = ActiveFallAlert(
      id: 'alert_${now.millisecondsSinceEpoch}',
      roomId: rId,
      roomName: rName,
      personName: _personName,
      detectedAt: now,
      dispatchMode: _dispatchMode,
      notifiedContactIds: notifiedIds,
      smsBroadcastReady: _channelSmsEnabled && allEmergencyPhoneNumbers.isNotEmpty,
      telegramBroadcastReady: _channelTelegramEnabled && (allTelegramChatIds.isNotEmpty || _alertBotUrl.isNotEmpty),
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

    _escalationTimer?.cancel();
    if (_dispatchMode == AlertDispatchMode.sequential) {
      _escalationSecondsLeft = _escalationMinutes * 60;
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
    } else {
      _escalationSecondsLeft = 0;
    }

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

    // Dispatch to Alert Bot Server (Telegram + SMS + Voice Call) or direct Telegram/CallMeBot if configured
    if (hasRemoteAlertConfigured && _activeAlert != null) {
      final alertSnapshot = _activeAlert!;
      unawaited(_dispatchRemoteFallAlert(alertSnapshot));
    }
  }

  Future<void> _dispatchRemoteFallAlert(ActiveFallAlert alert) async {
    final res = await alertBot.dispatchFallAlert(
      botUrl: _alertBotUrl,
      apiKey: _alertBotApiKey,
      eventType: alert.simulated ? 'test' : 'fall_impact',
      roomName: alert.roomName,
      personName: alert.personName,
      simulated: alert.simulated,
      telemetry: alert.telemetry,
      telegramBotToken: _telegramBotToken,
      telegramChatIds: allTelegramChatIds,
      telegramUsernames: allTelegramUsernames,
      phones: allEmergencyPhoneNumbers,
      telegramEnabled: _channelTelegramEnabled,
      callEnabled: _channelCallEnabled,
      fallbackMessage: buildEmergencySmsBody(alert),
    );
    if (_activeAlert?.id == alert.id) {
      _activeAlert = _activeAlert!.copyWith(
        remoteAlertId: res.alertId,
        remoteDispatchSummary: res.summary,
      );
      notifyListeners();
    }
  }

  Future<bool> acknowledgeActiveAlert() async {
    if (_activeAlert == null) return false;
    if (_phoneOfflineSimulation) return false;
    _escalationTimer?.cancel();
    final ackBy = _carerName.isNotEmpty ? _carerName : _userEmail;
    final remoteId = _activeAlert!.remoteAlertId;
    _activeAlert = _activeAlert!.copyWith(
      isAcknowledged: true,
      acknowledgedBy: ackBy,
      acknowledgedAt: DateTime.now(),
    );
    notifyListeners();
    if (remoteId != null && _alertBotUrl.trim().isNotEmpty) {
      unawaited(alertBot.acknowledgeAlert(
        botUrl: _alertBotUrl,
        apiKey: _alertBotApiKey,
        alertId: remoteId,
        by: ackBy,
      ));
    }
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
    FalseAlarmReason? falseAlarmReason,
    String? note,
  }) async {
    final alert = _activeAlert;
    if (alert == null) return;
    _escalationTimer?.cancel();
    await hardware.sendCommand('CANCEL_ALARM');

    final resolvedBy = _carerName.isNotEmpty ? _carerName : _userEmail;
    if (alert.remoteAlertId != null && _alertBotUrl.trim().isNotEmpty) {
      final outcomeKey = switch (outcome) {
        FallResolutionOutcome.personOk => 'person_ok',
        FallResolutionOutcome.neededHelp => 'needed_help',
        FallResolutionOutcome.falseAlarm => 'false_alarm',
      };
      unawaited(alertBot.resolveAlert(
        botUrl: _alertBotUrl,
        apiKey: _alertBotApiKey,
        alertId: alert.remoteAlertId!,
        by: resolvedBy,
        outcome: outcomeKey,
        note: note ?? '',
      ));
    }

    await logEvent(
      HearthEvent(
        id: 'ev_res_${DateTime.now().millisecondsSinceEpoch}',
        roomId: alert.roomId,
        roomName: alert.roomName,
        type: HearthEventType.fallResolved,
        at: DateTime.now(),
        outcome: outcome,
        falseAlarmReason: falseAlarmReason,
        resolvedBy: resolvedBy,
        note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      ),
    );

    _activeAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatWatchdog.cancel();
    _escalationTimer?.cancel();
    _telemSub?.cancel();
    _statusSub?.cancel();
    _bbSub?.cancel();
    hardware.dispose();
    super.dispose();
  }
}
