part of 'main.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final ValueNotifier<int> _telemetryRevision = ValueNotifier<int>(0);
  // Trạng thái kết nối BLE
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = "Chưa kết nối thiết bị";
  List<ScanResult> _scanResults = [];
  final Map<String, int> _rssiMap = {};

  // Các Characteristic được tìm thấy
  BluetoothCharacteristic? _wifiChar;
  BluetoothCharacteristic? _contactChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _otaChar;
  final ValueNotifier<String> _otaStatusNotifier = ValueNotifier<String>("");

  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _telemetrySub;
  Timer? _telemetryPollTimer;
  String _telemetryBuffer = '';

  // Controllers cho form cấu hình
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  double _floorThreshold = 450;

  // Giám sát trực tiếp qua mạng Wi-Fi LAN (Direct Wi-Fi Telemetry)
  String _deviceIp = "";
  final TextEditingController _deviceIpController = TextEditingController();
  bool _isWifiMonitoringEnabled = false;
  bool _isWifiConnected = false;
  int _wifiDelayMs = 0;
  Timer? _wifiPollTimer;
  int _wifiFailureCount = 0;

  // Dữ liệu Telemetry thời gian thực
  String _sysState = "DISCONNECTED";
  String _aiPosture = "UNKNOWN";
  double _aiConfidence = 0.0;
  int _tofHeight = 0;
  int _radarMotion = 0;
  int _radarStatic = 0;
  double _dropRate = 0.0;
  String _deviceFirmwareVersion = "v1.2.0";
  List<dynamic> _eventHistory = [];
  final List<Map<String, double>> _telemetryHistory = <Map<String, double>>[];
  bool _isLoadingHistory = false;

  void _consumeTelemetryBytes(List<int> value, {String source = 'BLE'}) {
    final chunk = utf8.decode(value, allowMalformed: true);
    if (chunk.isEmpty) return;
    // Android có thể chia notify thành nhiều mảnh khi MTU chưa được nâng đủ.
    // Chỉ parse khi đã ghép đủ một JSON hoàn chỉnh.
    _telemetryBuffer += chunk;
    if (_telemetryBuffer.length > 4096) {
      final start = _telemetryBuffer.lastIndexOf('{');
      _telemetryBuffer = start >= 0 ? _telemetryBuffer.substring(start) : '';
    }
    try {
      final parsed = jsonDecode(_telemetryBuffer);
      if (parsed is! Map<String, dynamic>) return;
      final complete = _telemetryBuffer;
      _telemetryBuffer = '';
      _applyTelemetryData(parsed, complete.length, source);
    } catch (_) {
      // Chưa đủ mảnh JSON, chờ notify tiếp theo.
    }
  }

  void _applyTelemetryData(Map<String, dynamic> data, int byteCount, String source) {
    try {
      debugPrint('[$source] Telemetry $byteCount bytes: ${jsonEncode(data)}');
      if (!mounted) return;
      setState(() {
        if (data.containsKey('events')) {
          _eventHistory = data['events'] as List<dynamic>? ?? [];
          _isLoadingHistory = false;
        } else if (data.containsKey('st')) {
          _sysState = data['st']?.toString() ?? 'NORMAL';
          _aiPosture = data['cls']?.toString() ?? 'STAND';
          _aiConfidence = (data['cf'] as num?)?.toDouble() ?? 0.0;
          _tofHeight = (data['h'] as num?)?.toInt() ?? 0;
          _radarMotion = (data['m'] as num?)?.toInt() ?? 0;
          _radarStatic = (data['s'] as num?)?.toInt() ?? 0;
          _dropRate = (data['dr'] as num?)?.toDouble() ?? 0.0;
          if (data['ver'] != null) _deviceFirmwareVersion = data['ver'].toString();
          _telemetryHistory.add({
            'h': _tofHeight.toDouble(),
            'm': _radarMotion.toDouble(),
            's': _radarStatic.toDouble(),
            'cf': _aiConfidence,
          });
          if (_telemetryHistory.length > 120) _telemetryHistory.removeAt(0);
        }
      });
      _telemetryRevision.value++;
    } catch (e) {
      debugPrint('[$source] Invalid telemetry payload ($byteCount bytes): $e');
    }
  }

  // Lịch sử thiết bị từng kết nối & Cài đặt chung của App
  List<Map<String, dynamic>> _deviceHistory = [];
  bool _alarmSoundEnabled = true;
  bool _alarmVibrateEnabled = true;
  double _alarmVolume = 0.8;
  bool _autoEmergency115 = false;
  bool _autoReconnect = true;
  String _heightUnit = "mm";
  String _tempUnit = "°C";

  // Tính năng 1, 2, 3, 4, 6, 7 (Y tế, Cảnh báo khẩn cấp, CDC STEADI, Báo cáo & Widget)
  ElderlyMedicalProfile _medicalProfile = ElderlyMedicalProfile();
  int _cdcSteadiScore = 0;
  DateTime? _cdcSteadiDate;
  bool _inactivityAlertEnabled = true;
  int _inactivityThresholdMinutes = 30;
  String _monitoredRoomName = "Nhà tắm / Toilet";
  DateTime? _roomPresenceStartTime;
  int _roomPresenceSeconds = 0;
  Timer? _inactivityTicker;
  bool _isInactivityAlertShowing = false;
  int _inactivityIncidentsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _loadGeneralSettings();
    _loadDeviceHistory();
    _loadMedicalProfile();
    _loadCdcData();
    _loadInactivitySettings();
    _startInactivityTicker();
  }

  Future<void> _loadMedicalProfile() async {
    final p = await ElderlyMedicalProfile.load();
    setState(() => _medicalProfile = p);
  }

  Future<void> _loadCdcData() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('cdc_steadi_last_score') ?? 0;
    final dateStr = prefs.getString('cdc_steadi_last_date');
    DateTime? dt;
    if (dateStr != null) dt = DateTime.tryParse(dateStr);
    setState(() {
      _cdcSteadiScore = score;
      _cdcSteadiDate = dt;
    });
  }

  Future<void> _loadInactivitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inactivityAlertEnabled = prefs.getBool('inactivity_enabled') ?? true;
      _inactivityThresholdMinutes = prefs.getInt('inactivity_threshold_min') ?? 30;
      _monitoredRoomName = prefs.getString('inactivity_room_name') ?? "Nhà tắm / Toilet";
      _inactivityIncidentsCount = prefs.getInt('inactivity_incidents_count') ?? 0;
    });
  }

  Future<void> _saveInactivitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('inactivity_enabled', _inactivityAlertEnabled);
    await prefs.setInt('inactivity_threshold_min', _inactivityThresholdMinutes);
    await prefs.setString('inactivity_room_name', _monitoredRoomName);
  }

  void _startInactivityTicker() {
    _inactivityTicker?.cancel();
    _inactivityTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isConnected && !_isWifiConnected) {
        if (_roomPresenceStartTime != null) {
          setState(() {
            _roomPresenceStartTime = null;
            _roomPresenceSeconds = 0;
          });
        }
        return;
      }

      // Nếu radar phát hiện có người (motion hoặc static) hoặc ToF có cự ly
      final bool hasPresence = (_radarMotion > 5 || _radarStatic > 10 || (_tofHeight > 100 && _tofHeight < 3000));
      if (hasPresence) {
        _roomPresenceStartTime ??= DateTime.now();
        final elapsed = DateTime.now().difference(_roomPresenceStartTime!).inSeconds;
        setState(() {
          _roomPresenceSeconds = elapsed;
        });

        // Kiểm tra vượt ngưỡng lưu trú bất động
        if (_inactivityAlertEnabled && !_isInactivityAlertShowing && elapsed >= (_inactivityThresholdMinutes * 60)) {
          _triggerInactivityAlarm();
        }
      } else {
        // Nếu không có người quá 45 giây thì reset bộ đếm
        if (_roomPresenceStartTime != null && DateTime.now().difference(_roomPresenceStartTime!).inSeconds > 45) {
          setState(() {
            _roomPresenceStartTime = null;
            _roomPresenceSeconds = 0;
          });
        }
      }
    });
  }

  void _triggerInactivityAlarm() async {
    setState(() {
      _isInactivityAlertShowing = true;
      _inactivityIncidentsCount++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('inactivity_incidents_count', _inactivityIncidentsCount);

    if (!mounted) return;
    _showCriticalEmergencyDialog(
      isFall: false,
      reason: "CẢNH BÁO BẤT THƯỜNG: Người thân đã ở trong [$_monitoredRoomName] liên tục $_inactivityThresholdMinutes phút mà không có chuyển động lớn! Nghi ngờ đột quỵ hoặc ngất xỉu.",
    );
  }

  void _showCriticalEmergencyDialog({bool isFall = true, String? reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CriticalEmergencyAlarmDialog(
        isFall: isFall,
        customReason: reason,
        profile: _medicalProfile,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
        dropRate: _dropRate,
        roomName: _monitoredRoomName,
        onCancelAlarm: () {
          _sendCommand("CANCEL_ALARM");
          setState(() {
            _isInactivityAlertShowing = false;
            _roomPresenceStartTime = DateTime.now(); // reset timer
            _roomPresenceSeconds = 0;
          });
        },
        onOpenMedicalId: _openMedicalIdCard,
        onOpenFirstAid: () => showFirstAidGuideModal(context),
      ),
    );
  }

  void _openMedicalIdCard() {
    showDialog(
      context: context,
      builder: (ctx) => EmergencyMedicalIdCardDialog(
        profile: _medicalProfile,
        onEdit: _openMedicalProfileEdit,
      ),
    );
  }

  void _openMedicalProfileEdit() {
    showDialog(
      context: context,
      builder: (ctx) => MedicalProfileEditDialog(
        profile: _medicalProfile,
        onSaved: (p) => setState(() => _medicalProfile = p),
      ),
    );
  }

  void _openCdcSteadiAssessment() {
    showDialog(
      context: context,
      builder: (ctx) => CdcSteadiAssessmentDialog(
        onCompleted: (score, risk) {
          setState(() {
            _cdcSteadiScore = score;
            _cdcSteadiDate = DateTime.now();
          });
        },
      ),
    );
  }

  void _openMedicalAuditReport() {
    showDialog(
      context: context,
      builder: (ctx) => MedicalAuditReportDialog(
        profile: _medicalProfile,
        eventHistory: _eventHistory,
        cdcScore: _cdcSteadiScore,
        cdcDate: _cdcSteadiDate,
        inactivityEventsCount: _inactivityIncidentsCount,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
      ),
    );
  }

  void _openLockscreenWidgetPreview() {
    showDialog(
      context: context,
      builder: (ctx) => LockscreenWidgetPreviewDialog(
        posture: _aiPosture,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
        roomName: _monitoredRoomName,
        sysState: _sysState,
      ),
    );
  }

  void _openInactivitySettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("Giám sát lưu trú & Ngất xỉu nhà tắm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("Bật cảnh báo bất động / ngất xỉu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Hú còi khi lưu lại quá lâu không vận động", style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _inactivityAlertEnabled,
                onChanged: (val) {
                  setSheetState(() => _inactivityAlertEnabled = val);
                  setState(() => _inactivityAlertEnabled = val);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 10),
              const Text("Ngưỡng thời gian cảnh báo bất động:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text("15 phút")),
                  ButtonSegment(value: 30, label: Text("30 phút")),
                  ButtonSegment(value: 45, label: Text("45 phút")),
                  ButtonSegment(value: 60, label: Text("60 phút")),
                ],
                selected: {_inactivityThresholdMinutes},
                onSelectionChanged: (val) {
                  setSheetState(() => _inactivityThresholdMinutes = val.first);
                  setState(() => _inactivityThresholdMinutes = val.first);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 14),
              const Text("Vị trí khu vực lắp đặt thiết bị:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "Nhà tắm / Toilet", label: Text("Nhà tắm")),
                  ButtonSegment(value: "Phòng ngủ", label: Text("Phòng ngủ")),
                  ButtonSegment(value: "Phòng khách", label: Text("Phòng khách")),
                  ButtonSegment(value: "Hành lang", label: Text("Hành lang")),
                  ButtonSegment(value: "Nhà bếp", label: Text("Nhà bếp")),
                  ButtonSegment(value: "Khác", label: Text("Khác"))
                ],
                selected: {_monitoredRoomName},
                onSelectionChanged: (val) {
                  setSheetState(() => _monitoredRoomName = val.first);
                  setState(() => _monitoredRoomName = val.first);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đóng"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tải cài đặt chung từ bộ nhớ
  Future<void> _loadGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('saved_device_ip') ?? "";
    final wifiMon = prefs.getBool('wifi_monitoring_enabled') ?? false;

    setState(() {
      _alarmSoundEnabled = prefs.getBool('alarm_sound') ?? true;
      _alarmVibrateEnabled = prefs.getBool('alarm_vibrate') ?? true;
      _alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      _autoEmergency115 = prefs.getBool('auto_emergency_115') ?? false;
      _autoReconnect = prefs.getBool('auto_reconnect') ?? true;
      _heightUnit = prefs.getString('height_unit') ?? "mm";
      _tempUnit = prefs.getString('temp_unit') ?? "°C";
      _deviceIp = savedIp;
      _deviceIpController.text = savedIp;
      _isWifiMonitoringEnabled = wifiMon;
    });

    if (_isWifiMonitoringEnabled && _deviceIp.isNotEmpty) {
      _startWifiPolling();
    }
  }

  // Lưu cấu hình giám sát trực tiếp qua Wi-Fi
  Future<void> _saveWifiMonitoringSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_device_ip', _deviceIp);
    await prefs.setBool('wifi_monitoring_enabled', _isWifiMonitoringEnabled);
  }

  // Lưu cài đặt chung vào bộ nhớ
  Future<void> _saveGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_sound', _alarmSoundEnabled);
    await prefs.setBool('alarm_vibrate', _alarmVibrateEnabled);
    await prefs.setDouble('alarm_volume', _alarmVolume);
    await prefs.setBool('auto_emergency_115', _autoEmergency115);
    await prefs.setBool('auto_reconnect', _autoReconnect);
    await prefs.setString('height_unit', _heightUnit);
    await prefs.setString('temp_unit', _tempUnit);
  }

  // Tải lịch sử thiết bị từng kết nối
  Future<void> _loadDeviceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('saved_devices_history');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _deviceHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } catch (_) {}
    }

    // Tự động kết nối lại thiết bị gần nhất nếu bật Auto-Reconnect
    if (_autoReconnect && !_isConnected && _deviceHistory.isNotEmpty) {
      final mostRecentId = _deviceHistory.first['id'];
      if (mostRecentId != null && mostRecentId.toString().isNotEmpty) {
        _connectToDevice(BluetoothDevice.fromId(mostRecentId.toString()));
      }
    }
  }

  // Lưu thiết bị vào lịch sử kết nối
  Future<void> _saveDeviceToHistory(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final String id = device.remoteId.str;
    final String devName = device.platformName.isEmpty ? "FallDetector_S3R8" : device.platformName;

    int existingIdx = _deviceHistory.indexWhere((d) => d['id'] == id);
    String customName = devName;
    if (existingIdx >= 0 && _deviceHistory[existingIdx]['customName'] != null) {
      customName = _deviceHistory[existingIdx]['customName'];
    }

    final record = {
      'id': id,
      'name': devName,
      'customName': customName,
      'lastConnected': DateTime.now().toIso8601String(),
      'rssi': _rssiMap[id] ?? -60,
    };

    if (existingIdx >= 0) {
      _deviceHistory.removeAt(existingIdx);
    }
    _deviceHistory.insert(0, record);

    await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
    setState(() {});
  }

  // Xóa thiết bị khỏi lịch sử
  Future<void> _removeDeviceFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _deviceHistory.removeWhere((d) => d['id'] == id);
    await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
    setState(() {});
  }

  // Đổi tên vị trí đặt thiết bị trong lịch sử (VD: Phòng ngủ, Nhà vệ sinh)
  Future<void> _renameDeviceInHistory(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    int idx = _deviceHistory.indexWhere((d) => d['id'] == id);
    if (idx >= 0) {
      _deviceHistory[idx]['customName'] = newName.trim().isEmpty ? _deviceHistory[idx]['name'] : newName.trim();
      await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
      setState(() {});
    }
  }

  @override
  void dispose() {
    _wifiPollTimer?.cancel();
    _deviceIpController.dispose();
    _inactivityTicker?.cancel();
    _scanSub?.cancel();
    _statusSub?.cancel();
    _telemetrySub?.cancel();
    _telemetryPollTimer?.cancel();
    _telemetryRevision.dispose();
    _ssidController.dispose();
    _passController.dispose();
    _phoneController.dispose();
    _chatIdController.dispose();
    _botTokenController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
    }
  }

  // Quét thiết bị BLE
  void _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _statusMessage = "Đang quét thiết bị FallDetector_S3R8...";
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results.where((r) {
            String name = r.device.platformName;
            return name.contains("FallDetector") ||
                   r.advertisementData.serviceUuids.any((u) => u.str128.toLowerCase().contains(serviceUuid.toLowerCase()));
          }).toList();

          for (var r in results) {
            _rssiMap[r.device.remoteId.str] = r.rssi;
          }
        });
      });

      await Future.delayed(const Duration(seconds: 6));
      setState(() {
        _isScanning = false;
        if (_scanResults.isEmpty && !_isConnected) {
          _statusMessage = "Không tìm thấy thiết bị. Hãy chắc chắn ESP32-S3 đang bật!";
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "Lỗi khi quét BLE: $e";
      });
    }
  }

  // Kết nối tới ESP32-S3 N16R8
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _statusMessage = "Đang kết nối tới ${device.platformName.isEmpty ? 'FallDetector_S3R8' : device.platformName}...";
    });

    try {
      await device.connect(license: License.nonprofit, autoConnect: false, timeout: const Duration(seconds: 10));

      // Yêu cầu MTU 512 bytes để nhận chuỗi JSON Hộp đen dài mà không bị đứt đoạn
      if (Platform.isAndroid) {
        try {
          final mtu = await device.requestMtu(512);
          debugPrint('[BLE] Negotiated MTU: $mtu (payload max ${mtu - 3} bytes)');
        } catch (_) {}
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _statusMessage = "Đã kết nối thành công!";
      });

      // Lưu thiết bị vào lịch sử ghép nối thành công
      _saveDeviceToHistory(device);

      // Lắng nghe trạng thái ngắt kết nối
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _sysState = "DISCONNECTED";
            _statusMessage = "Thiết bị đã ngắt kết nối";
          });
        }
      });

      // Khám phá dịch vụ BLE
      List<BluetoothService> services = await device.discoverServices();
      _wifiChar = null;
      _contactChar = null;
      _statusChar = null;
      _telemetryChar = null;
      _cmdChar = null;
      _otaChar = null;
      for (var s in services) {
        for (var c in s.characteristics) {
          String u = c.uuid.str128.toLowerCase();
          debugPrint('[BLE] Char $u read=${c.properties.read} notify=${c.properties.notify} write=${c.properties.write}');
          if (u == charWifiUuid.toLowerCase()) _wifiChar = c;
          if (u == charContactUuid.toLowerCase()) _contactChar = c;
          if (u == charStatusUuid.toLowerCase()) _statusChar = c;
          if (u == charTelemetryUuid.toLowerCase()) _telemetryChar = c;
          if (u == charCmdUuid.toLowerCase()) _cmdChar = c;
          if (u == charOtaUuid.toLowerCase()) _otaChar = c;
        }
      }

      // Dự phòng cho Android/GATT cache: nhận diện telemetry bằng payload JSON,
      // không phụ thuộc hoàn toàn vào UUID.
      if (_telemetryChar == null) {
        for (final service in services) {
          for (final candidate in service.characteristics) {
            if (!candidate.properties.read || !candidate.properties.notify) continue;
            try {
              final probe = await candidate.read();
              final text = utf8.decode(probe, allowMalformed: true);
              final parsed = jsonDecode(text);
              if (parsed is Map<String, dynamic> &&
                  (parsed.containsKey('st') || parsed.containsKey('events'))) {
                _telemetryChar = candidate;
                debugPrint('[BLE] Telemetry fallback selected: ${candidate.uuid.str128}');
                break;
              }
            } catch (_) {
              // Đây có thể là status/contact characteristic; tiếp tục thử kênh khác.
            }
          }
          if (_telemetryChar != null) break;
        }
      }

      // Đọc cấu hình danh bạ & ngưỡng sàn hiện tại từ chip
      final discovered = [_wifiChar, _contactChar, _statusChar, _telemetryChar, _cmdChar, _otaChar].whereType<BluetoothCharacteristic>().length;
      debugPrint('[BLE] Discovered $discovered/6 characteristics');
      if (_cmdChar == null) {
        _showSnackbar('BLE command channel not found. Please reflash firmware and reconnect.', Colors.red);
        debugPrint('[BLE] Missing command characteristic: $charCmdUuid');
      }
      await _readCurrentContacts();

      // Đăng ký nhận thông báo Status Notify
      if (_statusChar != null) {
        await _statusChar!.setNotifyValue(true);
        _statusSub?.cancel();
        _statusSub = _statusChar!.onValueReceived.listen((value) {
          String msg = utf8.decode(value);
          setState(() {
            _statusMessage = msg;
          });
          _handleStatusNotification(msg);
        });
      }

      // Đăng ký nhận Telemetry thời gian thực & Dữ liệu Hộp đen
      if (_telemetryChar != null) {
        try {
          await _telemetryChar!.setNotifyValue(true);
        } catch (e) {
          debugPrint('[BLE] Enable telemetry notify failed: $e');
        }
        _telemetrySub?.cancel();
        _telemetryBuffer = '';
        _telemetrySub = _telemetryChar!.onValueReceived.listen((value) => _consumeTelemetryBytes(value));
        try {
          final initial = await _telemetryChar!.read();
          if (initial.isNotEmpty) _consumeTelemetryBytes(initial, source: 'BLE-READ');
        } catch (e) {
          debugPrint('[BLE] Initial telemetry read failed: $e');
        }
        _telemetryPollTimer?.cancel();
        _telemetryPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
          try {
            final value = await _telemetryChar?.read();
            if (value != null && value.isNotEmpty) _consumeTelemetryBytes(value, source: 'BLE-READ');
          } catch (e) {
            debugPrint('[BLE-READ] Poll failed: $e');
          }
        });
      }

      // Tự động tải lịch sử hộp đen ngay sau khi kết nối
      _fetchHistory();
      _sendCommand("GET_VERSION");

    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _statusMessage = "Kết nối thất bại: $e";
      });
    }
  }

  void _disconnect() async {
    await _connectedDevice?.disconnect();
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
      _sysState = "DISCONNECTED";
      _statusMessage = "Đã ngắt kết nối";
    });
  }

  Future<void> _readCurrentContacts() async {
    if (_contactChar == null) return;
    try {
      List<int> bytes = await _contactChar!.read();
      if (bytes.isNotEmpty) {
        String jsonStr = utf8.decode(bytes);
        Map<String, dynamic> data = jsonDecode(jsonStr);
        setState(() {
          _phoneController.text = data["phone"] ?? "";
          _chatIdController.text = data["chat_id"] ?? "";
          if (data.containsKey("floor_mm")) {
            _floorThreshold = (data["floor_mm"] as num).toDouble();
          }
        });
      }
    } catch (_) {}
  }

  void _handleStatusNotification(String msg) {
    if (msg.startsWith("CONNECTED_IP:")) {
      String ip = msg.replaceAll("CONNECTED_IP:", "").trim();
      setState(() {
        _deviceIp = ip;
        _deviceIpController.text = ip;
      });
      _saveWifiMonitoringSettings();
      _showSnackbar("ESP32 đã kết nối Wi-Fi! IP: $ip (Tự động lưu)", Colors.green);
      if (!_isWifiMonitoringEnabled) {
        _toggleWifiMonitoring(true);
      }
    } else if (msg == "WIFI_CONNECT_FAILED") {
      _showSnackbar("ESP32 kết nối Wi-Fi thất bại! Kiểm tra mật khẩu.", Colors.red);
    } else if (msg == "CONFIG_UPDATED_OK") {
      _showSnackbar("Cấu hình danh bạ đã lưu thành công!", Colors.green);
    } else if (msg == "NETWORK_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("Đã xóa cấu hình Wi-Fi. Thiết bị đang khởi động lại.", Colors.orange);
    } else if (msg == "FACTORY_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("Đã khôi phục toàn bộ mặc định. Thiết bị đang khởi động lại.", Colors.orange);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_SAVED") {
      _showSnackbar("Lịch night light đã lưu vào ESP32!", Colors.green);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_ERROR") {
      _showSnackbar("Lịch night light không hợp lệ.", Colors.red);
    } else if (msg == "EMERGENCY_DISPATCHED") {
      _showCriticalEmergencyDialog(isFall: true);
    } else if (msg == "HISTORY_SENT") {
      _showSnackbar("Đã tải dữ liệu hộp đen NVS!", Colors.blueAccent);
    } else if (msg == "HISTORY_CLEARED_OK") {
      setState(() {
        _eventHistory.clear();
      });
      _showSnackbar("Đã xóa sạch nhật ký hộp đen!", Colors.orange);
    } else if (msg == "TEST_EVENT_ADDED") {
      _showSnackbar("Đã thêm sự cố mẫu vào hộp đen NVS!", Colors.green);
    } else if (msg.startsWith("FIRMWARE_VERSION:")) {
      setState(() {
        _deviceFirmwareVersion = msg.replaceFirst("FIRMWARE_VERSION:", "").trim();
      });
    } else if (msg.startsWith("OTA_")) {
      _otaStatusNotifier.value = msg;
      if (msg == "OTA_SUCCESS_REBOOTING") {
        _showSnackbar("Nạp firmware ESP32 thành công 100%! Thiết bị đang khởi động lại...", Colors.green);
      } else if (msg.startsWith("OTA_ERROR:")) {
        _showSnackbar("Lỗi cập nhật firmware: ${msg.replaceFirst('OTA_ERROR:', '')}", Colors.red);
      }
    }
  }

  // Gửi cấu hình Wi-Fi
  Future<void> _sendWifiConfig() async {
    if (_wifiChar == null) {
      _showSnackbar("Chưa kết nối BLE với thiết bị!", Colors.red);
      return;
    }
    String ssid = _ssidController.text.trim();
    String pass = _passController.text.trim();
    if (ssid.isEmpty) {
      _showSnackbar("Vui lòng nhập tên Wi-Fi (SSID)!", Colors.orange);
      return;
    }

    Map<String, String> payload = {"ssid": ssid, "pass": pass};
    String jsonStr = jsonEncode(payload);

    try {
      await _wifiChar!.write(utf8.encode(jsonStr), withoutResponse: false);
      _showSnackbar("Đã gửi Wi-Fi. Thiết bị đang khởi động lại để kết nối...", Colors.blue);
    } catch (e) {
      _showSnackbar("Gửi Wi-Fi thất bại: $e", Colors.red);
    }
  }

  // Gửi cấu hình danh bạ khẩn cấp
  Future<void> _sendContactsConfig() async {
    if (_contactChar == null) {
      _showSnackbar("Chưa kết nối BLE với thiết bị!", Colors.red);
      return;
    }

    Map<String, dynamic> payload = {
      "phone": _phoneController.text.trim(),
      "chat_id": _chatIdController.text.trim(),
      "floor_mm": _floorThreshold.toInt(),
    };
    if (_botTokenController.text.trim().isNotEmpty) {
      payload["bot_token"] = _botTokenController.text.trim();
    }

    String jsonStr = jsonEncode(payload);
    try {
      await _contactChar!.write(utf8.encode(jsonStr), withoutResponse: false);
      _showSnackbar("Đang lưu cấu hình...", Colors.blue);
    } catch (e) {
      _showSnackbar("Lưu danh bạ thất bại: $e", Colors.red);
    }
  }

  // Gửi lệnh điều khiển
  Future<void> _sendCommand(String cmd) async {
    if (_cmdChar == null) {
      _showSnackbar("Chưa kết nối BLE!", Colors.red);
      return;
    }
    try {
      await _cmdChar!.write(utf8.encode(cmd), withoutResponse: false);
    } catch (e) {
      _showSnackbar("Lỗi gửi lệnh $cmd: $e", Colors.red);
    }
  }

  // Đọc lịch sử sự kiện Hộp đen
  Future<void> _fetchHistory() async {
    if (!_isConnected) return;
    setState(() {
      _isLoadingHistory = true;
    });
    await _sendCommand("GET_HISTORY");
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  // =========================================================================
  // GIÁM SÁT TRỰC TIẾP QUA MẠNG WI-FI NỘI BỘ (DIRECT WI-FI LAN TELEMETRY)
  // =========================================================================
  void _toggleWifiMonitoring(bool enabled) {
    setState(() {
      _isWifiMonitoringEnabled = enabled;
      if (!enabled) {
        _isWifiConnected = false;
        _wifiDelayMs = 0;
      }
    });
    _saveWifiMonitoringSettings();
    if (enabled) {
      _startWifiPolling();
    } else {
      _stopWifiPolling();
    }
  }

  void _startWifiPolling() {
    _wifiPollTimer?.cancel();
    _pollWifiTelemetry();
    // Thăm dò dữ liệu liên tục mỗi 700ms qua HTTP LAN
    _wifiPollTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _pollWifiTelemetry();
    });
  }

  void _stopWifiPolling() {
    _wifiPollTimer?.cancel();
    _wifiPollTimer = null;
  }

  Future<void> _pollWifiTelemetry() async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty || !_isWifiMonitoringEnabled) return;

    final stopwatch = Stopwatch()..start();
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);

    try {
      final uri = Uri.parse('http://$ip/api/telemetry');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 1500));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);

        if (!mounted) return;
        setState(() {
          _isWifiConnected = true;
          _wifiDelayMs = stopwatch.elapsedMilliseconds;
          _wifiFailureCount = 0;

          if (data.containsKey("st")) {
            final oldState = _sysState;
            _sysState = data["st"] ?? "NORMAL";
            _aiPosture = data["cls"] ?? "STAND";
            _aiConfidence = (data["cf"] as num?)?.toDouble() ?? 0.0;
            _tofHeight = (data["h"] as num?)?.toInt() ?? 0;
            _radarMotion = (data["m"] as num?)?.toInt() ?? 0;
            _radarStatic = (data["s"] as num?)?.toInt() ?? 0;
            _dropRate = (data["dr"] as num?)?.toDouble() ?? 0.0;
            if (data.containsKey("ver") && data["ver"] != null) {
              _deviceFirmwareVersion = data["ver"].toString();
            }
            _telemetryHistory.add({
              'h': _tofHeight.toDouble(),
              'm': _radarMotion.toDouble(),
              's': _radarStatic.toDouble(),
              'cf': _aiConfidence,
            });
            if (_telemetryHistory.length > 120) _telemetryHistory.removeAt(0);

            if (oldState != "ALERT" && _sysState == "ALERT") {
              _showCriticalEmergencyDialog(isFall: true);
            }
            _telemetryRevision.value++;
          }
        });
      } else {
        _handleWifiPollFailure();
      }
    } catch (_) {
      _handleWifiPollFailure();
    } finally {
      client.close();
    }
  }

  void _handleWifiPollFailure() {
    if (!mounted) return;
    _wifiFailureCount++;
    if (_wifiFailureCount >= 3 && _isWifiConnected) {
      setState(() {
        _isWifiConnected = false;
      });
    }
  }

  Future<void> _sendWifiCommand(String cmd) async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty) {
      _showSnackbar("Vui lòng nhập địa chỉ IP của thiết bị trước!", Colors.orange);
      return;
    }

    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2000);
    try {
      final uri = Uri.parse('http://$ip/api/command?cmd=$cmd');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        _showSnackbar("Đã gửi lệnh qua Wi-Fi: $cmd", Colors.green);
        _pollWifiTelemetry();
      } else {
        _showSnackbar("Gửi lệnh qua Wi-Fi thất bại (HTTP ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Không thể kết nối Wi-Fi tới $ip: $e", Colors.red);
    } finally {
      client.close();
    }
  }

  Future<void> _fetchHistoryOverWifi() async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty) {
      _showSnackbar("Vui lòng nhập địa chỉ IP của thiết bị trước!", Colors.orange);
      return;
    }

    setState(() => _isLoadingHistory = true);
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 3000);
    try {
      final uri = Uri.parse('http://$ip/api/events');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 3500));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        if (data.containsKey("events")) {
          setState(() {
            _eventHistory = data["events"];
            _isLoadingHistory = false;
          });
          _showSnackbar("Đã tải hộp đen qua Wi-Fi (${_eventHistory.length} sự cố)", Colors.blueAccent);
          return;
        }
      }
    } catch (_) {}
    finally {
      client.close();
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showWifiIpDialog() {
    _deviceIpController.text = _deviceIp;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text("Cấu hình IP Wi-Fi"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhập địa chỉ IP mạng nội bộ của thiết bị ESP32 (hiển thị khi ESP32 kết nối Wi-Fi):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceIpController,
              decoration: const InputDecoration(
                labelText: "Địa chỉ IP",
                hintText: "192.168.1.xxx",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              "Mẹo: Địa chỉ IP cũng sẽ tự động lưu khi thiết bị kết nối Wi-Fi qua Bluetooth.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () {
              final newIp = _deviceIpController.text.trim();
              if (newIp.isNotEmpty) {
                setState(() {
                  _deviceIp = newIp;
                });
                _saveWifiMonitoringSettings();
                _toggleWifiMonitoring(true);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Lưu & Kết nối"),
          ),
        ],
      ),
    );
  }

  // Mở màn hình quản trị chi tiết thiết bị (Gồm Giám sát, Hộp đen và Cài đặt)
  void _openDeviceDetail(BluetoothDevice device, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ValueListenableBuilder<int>(
          valueListenable: _telemetryRevision,
          builder: (context, _, _) => DeviceDetailScreen(
          device: device,
          isConnected: _isConnected,
          initialTabIndex: initialTab,
          // Dữ liệu thời gian thực
          sysState: _sysState,
          aiPosture: _aiPosture,
          aiConfidence: _aiConfidence,
          tofHeight: _tofHeight,
          radarMotion: _radarMotion,
          radarStatic: _radarStatic,
          dropRate: _dropRate,
          eventHistory: _eventHistory,
          isLoadingHistory: _isLoadingHistory,
          telemetryHistory: _telemetryHistory,
          // Controllers
          ssidController: _ssidController,
          passController: _passController,
          phoneController: _phoneController,
          chatIdController: _chatIdController,
          botTokenController: _botTokenController,
          floorThreshold: _floorThreshold,
          onFloorThresholdChanged: (val) {
            setState(() {
              _floorThreshold = val;
            });
          },
          // Callbacks
          onSaveWifi: _sendWifiConfig,
          onSaveContacts: _sendContactsConfig,
          onDisconnect: () {
            _disconnect();
            Navigator.pop(ctx);
          },
          onSendCommand: _sendCommand,
          onFetchHistory: _fetchHistory,
          onRefreshContacts: _readCurrentContacts,
          otaChar: _otaChar,
          otaStatusNotifier: _otaStatusNotifier,
          firmwareVersion: _deviceFirmwareVersion,
          // Wi-Fi Telemetry & Commands
          deviceIp: _deviceIp,
          isWifiConnected: _isWifiConnected,
          wifiDelayMs: _wifiDelayMs,
          onSendWifiCommand: _sendWifiCommand,
          onFetchWifiHistory: _fetchHistoryOverWifi,
          ),
        ),
      ),
    );
  }

  // Định dạng thời gian kết nối gần nhất
  String _formatLastSeen(DateTime? dt) {
    if (dt == null) return "Gần đây";
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // Hộp thoại đổi tên vị trí thiết bị trong lịch sử
  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đặt tên vị trí thiết bị"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Đặt tên theo phòng để dễ theo dõi (VD: Phòng ngủ Ông Bà, Nhà tắm tầng 2, Phòng khách):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Tên vị trí",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _renameDeviceInHistory(id, controller.text);
            },
            child: const Text("Lưu tên"),
          ),
        ],
      ),
    );
  }

  // Mở màn hình Cài đặt chung của ứng dụng
  void _openGeneralSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => GeneralSettingsScreen(
          alarmSound: _alarmSoundEnabled,
          alarmVibrate: _alarmVibrateEnabled,
          alarmVolume: _alarmVolume,
          autoEmergency115: _autoEmergency115,
          autoReconnect: _autoReconnect,
          heightUnit: _heightUnit,
          tempUnit: _tempUnit,
          deviceHistoryCount: _deviceHistory.length,
          onSettingsChanged: (sound, vib, vol, em115, autoRec, hUnit, tUnit) {
            setState(() {
              _alarmSoundEnabled = sound;
              _alarmVibrateEnabled = vib;
              _alarmVolume = vol;
              _autoEmergency115 = em115;
              _autoReconnect = autoRec;
              _heightUnit = hUnit;
              _tempUnit = tUnit;
            });
            _saveGeneralSettings();
          },
          onClearHistory: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_devices_history');
            setState(() {
              _deviceHistory.clear();
            });
          },
        ),
      ),
    );
  }

  // Widget hiển thị danh sách thiết bị từng kết nối
  Widget _buildDeviceHistoryList() {
    return Column(
      children: _deviceHistory.map((item) {
        final String id = item['id'] ?? '';
        final String customName = item['customName'] ?? item['name'] ?? 'FallDetector_S3R8';
        final String rawName = item['name'] ?? 'FallDetector_S3R8';
        final String lastTime = item['lastConnected'] != null
            ? _formatLastSeen(DateTime.tryParse(item['lastConnected']))
            : "Gần đây";
        final bool isCurrent = _isConnected && _connectedDevice?.remoteId.str == id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isCurrent ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isCurrent ? Colors.green : Colors.grey.withValues(alpha: 0.25),
              width: isCurrent ? 1.6 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isCurrent ? Colors.green.withValues(alpha: 0.2) : Colors.blueGrey.withValues(alpha: 0.15),
              child: Icon(
                isCurrent ? Icons.sensors : Icons.history,
                color: isCurrent ? Colors.green : Colors.blueGrey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    customName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text("Đang kết nối", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  "$rawName | ID: $id",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Lần kết nối cuối: $lastTime",
                  style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrent)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _connectToDevice(BluetoothDevice.fromId(id)),
                    child: const Text("Kết nối lại", style: TextStyle(fontSize: 12)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.green),
                    tooltip: "Vào chi tiết thiết bị",
                    onPressed: () {
                      if (_connectedDevice != null) _openDeviceDetail(_connectedDevice!);
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'rename') {
                      _showRenameDialog(id, customName);
                    } else if (val == 'delete') {
                      _removeDeviceFromHistory(id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text("Đổi tên phòng / vị trí"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text("Quên thiết bị này", style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              if (isCurrent && _connectedDevice != null) {
                _openDeviceDetail(_connectedDevice!);
              } else {
                _connectToDevice(BluetoothDevice.fromId(id));
              }
            },
          ),
        );
      }).toList(),
    );
  }

  // Widget hiển thị trạng thái màn hình khóa & trực tiếp (Feature 6 & 1)
  Widget _buildGlanceableLiveStatusCard() {
    final bool isActivelyMonitored = _isConnected || _isWifiConnected;
    final Color badgeColor = _sysState == "ALERT"
        ? Colors.redAccent
        : (_sysState == "PRE_ALARM" ? Colors.orangeAccent : (isActivelyMonitored ? Colors.greenAccent : Colors.grey));
    final int minutes = _roomPresenceSeconds ~/ 60;
    final int seconds = _roomPresenceSeconds % 60;
    final double progress = (_inactivityThresholdMinutes > 0)
        ? (_roomPresenceSeconds / (_inactivityThresholdMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: badgeColor.withValues(alpha: 0.06),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sysState == "ALERT" ? Icons.emergency : (isActivelyMonitored ? Icons.shield : Icons.shield_outlined),
                    color: badgeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActivelyMonitored
                            ? (_sysState == "ALERT"
                                ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP"
                                : (_isWifiConnected && !_isConnected
                                    ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂŒÃƒÂ‚Ã‚Â GIÁM SÁT TRỰC TIẾP QUA WI-FI"
                                    : (_isWifiConnected && _isConnected
                                        ? "🟢 GIÁM SÁT KÉP (BLE + WI-FI)"
                                        : "🟢 AN TOÀN - ĐANG GIÁM SÁT BLE 24/7")))
                            : "⚪ CHỜ KẾT NỐI (BLUETOOTH HOẶC WI-FI)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: badgeColor),
                      ),
                      Text(
                        "Khu vực: $_monitoredRoomName • ${_medicalProfile.fullName}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.widgets_outlined, size: 20),
                  tooltip: "Mô phỏng Widget Màn hình khóa",
                  onPressed: _openLockscreenWidgetPreview,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh tiến trình lưu trú nhà tắm & bất động
            if (isActivelyMonitored) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Text("Hiện diện: ${minutes}p ${seconds}s", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("Ngưỡng an toàn: < ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.85 ? Colors.redAccent : (progress > 0.6 ? Colors.orangeAccent : Colors.tealAccent),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3 thông số mini
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatusChip("Tư thế AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatusChip("Độ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatusChip("Radar 24GHz", "$_radarMotion%", Icons.radar, Colors.orangeAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Giám sát trực tiếp qua Wi-Fi LAN
  Widget _buildWifiMonitoringCard() {
    final bool isOnline = _isWifiConnected;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;
    final Color statusColor = !_isWifiMonitoringEnabled
        ? Colors.grey
        : (isOnline ? Colors.tealAccent : Colors.orangeAccent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề và nút bật/tắt Wi-Fi
            Row(
              children: [
                Icon(
                  _isWifiMonitoringEnabled ? Icons.wifi : Icons.wifi_off,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Giám sát trực tiếp qua Wi-Fi (LAN)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _isWifiMonitoringEnabled
                            ? (_deviceIp.isEmpty
                                ? "Chưa cấu hình địa chỉ IP thiết bị"
                                : "IP: $_deviceIp • ${isOnline ? 'Độ trễ: ${_wifiDelayMs}ms' : 'Đang kết nối...'}")
                            : "Theo dõi từ xa xuyên phòng không cần Bluetooth",
                        style: TextStyle(fontSize: 11, color: isOnline ? Colors.tealAccent : Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isWifiMonitoringEnabled,
                  activeThumbColor: Colors.tealAccent,
                  onChanged: (val) {
                    if (val && _deviceIp.isEmpty) {
                      _showWifiIpDialog();
                    } else {
                      _toggleWifiMonitoring(val);
                    }
                  },
                ),
              ],
            ),

            if (_isWifiMonitoringEnabled) ...[
              const Divider(height: 16),
              // Thanh địa chỉ IP và công cụ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOnline ? Colors.green : Colors.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.sensors : Icons.sync,
                          size: 13,
                          color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? "Đang truyền (${_wifiDelayMs}ms)" : "Chờ phản hồi...",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text("Đổi IP", style: TextStyle(fontSize: 11)),
                        onPressed: _showWifiIpDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.cyanAccent),
                        tooltip: "Làm mới dữ liệu Wi-Fi ngay",
                        onPressed: _pollWifiTelemetry,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bảng dữ liệu thông số trực tiếp nhận qua Wi-Fi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  runAlignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("Tư thế AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("Độ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("Động năng", "$_radarMotion/100", Icons.directions_run, Colors.orangeAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("Nhịp thở", "$_radarStatic/100", Icons.air, Colors.tealAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Nút hành động nhanh Wi-Fi
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: compact ? screenWidth - 60 : (screenWidth - 68) / 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.emergency, size: 16),
                      label: const Text("SOS Wi-Fi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _sendWifiCommand("PANIC_SOS"),
                    ),
                  ),
                  SizedBox(
                    width: compact ? screenWidth - 60 : (screenWidth - 68) / 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.volume_off, size: 16),
                      label: const Text("Tắt còi Wi-Fi", style: TextStyle(fontSize: 12)),
                      onPressed: () => _sendWifiCommand("CANCEL_ALARM"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.blueAccent),
                    tooltip: "Tải hộp đen NVS qua Wi-Fi",
                    onPressed: _fetchHistoryOverWifi,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWifiMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMiniStatusChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // Thanh công cụ y tế & đánh giá nhanh 1 chạm (Feature 2, 7, 3, 1)
  Widget _buildQuickHealthActionBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
          children: [
            ActionChip(
              avatar: const Icon(Icons.badge, size: 16, color: Colors.redAccent),
              label: const Text("Thẻ Y Tế", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalIdCard,
            ),
            ActionChip(
              avatar: const Icon(Icons.quiz, size: 16, color: Colors.blueAccent),
              label: Text("Khám CDC: $_cdcSteadiScoređ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.4)),
              onPressed: _openCdcSteadiAssessment,
            ),
            ActionChip(
              avatar: const Icon(Icons.description, size: 16, color: Colors.tealAccent),
              label: const Text("Báo Cáo Y Khoa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalAuditReport,
            ),
            ActionChip(
              avatar: const Icon(Icons.bathtub, size: 16, color: Colors.amberAccent),
              label: Text("Giám sát: ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.amber.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
              onPressed: _openInactivitySettingsSheet,
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tập hợp danh sách thiết bị (đưa thiết bị đã kết nối lên đầu)
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    List<BluetoothDevice> displayedDevices = [];
    if (_connectedDevice != null && _isConnected) {
      displayedDevices.add(_connectedDevice!);
    }
    for (var r in _scanResults) {
      if (_connectedDevice == null || r.device.remoteId != _connectedDevice!.remoteId) {
        displayedDevices.add(r.device);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Fall Guard S3R8', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (compact)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'medical') {
                  _openMedicalIdCard();
                } else if (value == 'report') {
                  _openMedicalAuditReport();
                } else if (value == 'device') {
                  if (_isConnected && _connectedDevice != null) _openDeviceDetail(_connectedDevice!);
                } else if (value == 'settings') {
                  _openGeneralSettings();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'medical', child: Text('Thẻ Y tế khẩn cấp')),
                PopupMenuItem(value: 'report', child: Text('Báo cáo y khoa')),
                PopupMenuItem(value: 'device', child: Text('Thiết bị đang kết nối')),
                PopupMenuItem(value: 'settings', child: Text('Cài đặt chung')),
              ],
            ),
          if (!compact) ...[
            IconButton(
              icon: const Icon(Icons.badge, color: Colors.redAccent),
              tooltip: "Thẻ Y Tế Khẩn Cấp",
              onPressed: _openMedicalIdCard,
            ),
            IconButton(
              icon: const Icon(Icons.description, color: Colors.tealAccent),
              tooltip: "Báo Cáo Y Khoa Định Kỳ",
              onPressed: _openMedicalAuditReport,
            ),
            IconButton(
              icon: Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: _isConnected ? Colors.greenAccent : Colors.grey,
              ),
              tooltip: _isConnected ? "Đã kết nối" : "Chưa kết nối",
              onPressed: () {
                if (_isConnected && _connectedDevice != null) {
                  _openDeviceDetail(_connectedDevice!);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: "Cài đặt chung",
              onPressed: _openGeneralSettings,
            ),
          ],
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ trạng thái Glanceable Live Status Card (Feature 6 & 1)
            _buildGlanceableLiveStatusCard(),

            // Thẻ giám sát trực tiếp qua Wi-Fi LAN
            _buildWifiMonitoringCard(),

            // Thanh công cụ y tế nhanh 1 chạm (Feature 2, 7, 3, 1)
            _buildQuickHealthActionBar(),

            // Nút Quét thiết bị trên cùng
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isScanning ? "Đang quét xung quanh..." : "Quét thiết bị FallDetector_S3R8"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // PHẦN 1: LỊCH SỬ THIẾT BỊ TỪNG KẾT NỐI (PAIRED / HISTORY DEVICES)
            if (_deviceHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text("Thiết bị từng kết nối:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Text("${_deviceHistory.length} thiết bị đã lưu", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              _buildDeviceHistoryList(),
              const SizedBox(height: 14),
            ],

            // PHẦN 2: THIẾT BỊ TÌM THẤY QUA QUÉT BLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thiết bị tìm thấy xung quanh:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (displayedDevices.isNotEmpty)
                  Text("${displayedDevices.length} thiết bị", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: displayedDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_searching, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _isScanning ? "Đang tìm kiếm sóng Bluetooth..." : "Nhấn 'Quét' để tìm thiết bị FallDetector_S3R8",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedDevices.length,
                      itemBuilder: (ctx, idx) {
                        final device = displayedDevices[idx];
                        final bool isThisConnected = _isConnected && _connectedDevice?.remoteId == device.remoteId;
                        final String devName = device.platformName.isEmpty ? "FallDetector_S3R8" : device.platformName;
                        final int? rssi = _rssiMap[device.remoteId.str];

                        // Thiết bị đã kết nối: Viền xanh lá, hiển thị xanh "Đã kết nối", có nút Ngắt (Đã xóa "Chạm để cài đặt")
                        if (isThisConnected) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.green.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.green, width: 1.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openDeviceDetail(device),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.sensors, color: Colors.green, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            devName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 15),
                                              SizedBox(width: 5),
                                              Text(
                                                "Đã kết nối",
                                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "RSSI: ${rssi != null ? '$rssi dBm' : 'Tốt'} | ID: ${device.remoteId}",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Nút ngắt kết nối trực tiếp
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _disconnect,
                                      child: const Text("Ngắt", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right, color: Colors.green),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Thiết bị chưa kết nối
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _connectToDevice(device),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.devices, color: Colors.blueAccent, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          devName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "RSSI: ${rssi != null ? '$rssi dBm' : '--'} | ID: ${device.remoteId}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text("Kết nối"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH QUẢN TRỊ THIẾT BỊ: GỒM 3 TAB (GIÁM SÁT, HỘP ĐEN & GRAPH, CÀI ĐẶT)
// =========================================================================
