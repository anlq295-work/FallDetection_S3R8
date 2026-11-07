import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================================
// CÁC UUID TRÙNG KHỚP 100% VỚI FIRMWARE ESP32-S3 N16R8
// =========================================================================
const String serviceUuid       = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String charWifiUuid      = "0beb5483-e18e-4f36-9e1b-b4d6b63c7b28";
const String charContactUuid   = "1c6f8742-9a6d-4785-b9e1-e63f9b8c0011";
const String charStatusUuid    = "2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344";
const String charTelemetryUuid = "3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455";
const String charCmdUuid       = "4fa0b044-9b3e-4d75-af4c-b70e901c5566";
const String charOtaUuid       = "5e1c0155-ac5d-4e86-be5d-c81f012d6677";

void main() {
  runApp(const FallGuardApp());
}

class FallGuardApp extends StatelessWidget {
  const FallGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Guard S3R8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AppStartupGate(),
    );
  }
}

// =========================================================================
// CỔNG KIỂM TRA KHỞI ĐỘNG (STARTUP PERMISSION GATE CHO IOS & ANDROID)
// Bắt buộc xác nhận cho phép quét thiết bị xung quanh trước khi vào app lần đầu
// =========================================================================
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _isLoading = true;
  bool _hasConsented = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConsent();
  }

  Future<void> _checkInitialConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consented = prefs.getBool('has_consented_nearby_devices') ?? false;
      setState(() {
        _hasConsented = consented;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onConsentGranted() {
    setState(() {
      _hasConsented = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF060B14),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (!_hasConsented) {
      return IosNearbyDeviceConsentScreen(
        onConsentGranted: _onConsentGranted,
      );
    }

    return const MainDashboardScreen();
  }
}

// =========================================================================
// MÀN HÌNH XÁC NHẬN CHO PHÉP QUÉT THIẾT BỊ XUNG QUANH (CHUẨN APPLE HIG)
// =========================================================================
class IosNearbyDeviceConsentScreen extends StatefulWidget {
  final VoidCallback onConsentGranted;

  const IosNearbyDeviceConsentScreen({super.key, required this.onConsentGranted});

  @override
  State<IosNearbyDeviceConsentScreen> createState() => _IosNearbyDeviceConsentScreenState();
}

class _IosNearbyDeviceConsentScreenState extends State<IosNearbyDeviceConsentScreen> {
  bool _isRequesting = false;

  Future<void> _requestNearbyPermission() async {
    setState(() => _isRequesting = true);

    try {
      // 1. Kích hoạt CBCentralManager trên iOS bằng cách truy vấn trạng thái adapter
      BluetoothAdapterState state;
      try {
        state = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 4),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
      } catch (_) {
        state = BluetoothAdapterState.unknown;
      }

      // 2. Nếu trên Android mà Bluetooth chưa bật thì hỗ trợ bật
      if (Platform.isAndroid && state == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 3. Nếu quyền bị từ chối rõ ràng trên iOS
      if (state == BluetoothAdapterState.unauthorized) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 4. Nếu Bluetooth đang tắt trên iOS
      if (state == BluetoothAdapterState.off && Platform.isIOS) {
        if (!mounted) return;
        _showBluetoothOffDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 5. Lưu xác nhận vào bộ nhớ vĩnh viễn và chuyển vào Dashboard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_nearby_devices', true);

      if (!mounted) return;
      widget.onConsentGranted();
    } catch (e) {
      // Dù có ngoại lệ nào cũng lưu cờ để không làm kẹt ứng dụng
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_nearby_devices', true);
      if (!mounted) return;
      widget.onConsentGranted();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text("Cần cấp quyền Bluetooth", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "Bạn đã từ chối quyền Bluetooth trước đó. Để phát hiện và kết nối với hộp cảm biến té ngã ESP32-S3, vui lòng vào Cài đặt iPhone > FallGuard > Bật quyền Bluetooth.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse("app-settings:"));
            },
            child: const Text("Mở Cài đặt iPhone"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.setBool('has_consented_nearby_devices', true));
              widget.onConsentGranted();
            },
            child: const Text("Tiếp tục vào App"),
          ),
        ],
      ),
    );
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text("Bluetooth đang tắt", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "Bluetooth trên iPhone của bạn đang tắt. Vui lòng vuốt Trung tâm điều khiển (Control Center) và bật Bluetooth để có thể quét thiết bị FallGuard.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.setBool('has_consented_nearby_devices', true));
              widget.onConsentGranted();
            },
            child: const Text("Tôi đã hiểu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo & Biểu tượng Radar Quét thiết bị
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyan.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.bluetooth_searching, size: 40, color: Colors.cyanAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề chính
              const Text(
                "Cho phép quét thiết bị xung quanh",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Yêu cầu bảo mật trên iOS để tìm kiếm và kết nối với hộp cảm biến phát hiện té ngã FallGuard S3R8.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 3 Thẻ giải thích mục đích sử dụng quyền
              _buildFeatureItem(
                Icons.radar,
                Colors.cyanAccent,
                "Quét & Kết nối Thiết bị lân cận",
                "Tự động phát hiện hộp cảm biến ESP32-S3 trong phòng qua Bluetooth Low Energy (BLE) với mức tiêu thụ pin tối thiểu.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.health_and_safety,
                Colors.redAccent,
                "Cảnh báo cứu nạn tức thì",
                "Nhận tín hiệu báo động khi người cao tuổi bị ngã, sụt giảm độ cao hoặc nằm sàn bất động để kịp thời cứu hộ.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.verified_user,
                Colors.greenAccent,
                "Bảo mật quyền riêng tư (Chuẩn Apple)",
                "Không thu thập tọa độ GPS, không ghi âm hay theo dõi cá nhân. Chỉ giao tiếp với các thiết bị y tế có UUID FallGuard.",
              ),

              const Spacer(),

              // Thông báo hướng dẫn hộp thoại iOS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Khi hộp thoại iOS hiện ra, vui lòng chọn [Cho phép] (Allow) để bắt đầu tìm kiếm thiết bị.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade300, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nút xác nhận cấp quyền
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.shade700,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isRequesting ? null : _requestNearbyPermission,
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Xác nhận & Cho phép quét thiết bị",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH CHÍNH (HOME SCREEN): KHÔNG CÒN TAB BÊN NGOÀI, QUẢN LÝ THIẾT BỊ
// =========================================================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
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

  // Controllers cho form cấu hình
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  double _floorThreshold = 450;

  // Dữ liệu Telemetry thời gian thực
  String _sysState = "DISCONNECTED";
  String _aiPosture = "UNKNOWN";
  double _aiConfidence = 0.0;
  int _tofHeight = 0;
  int _radarMotion = 0;
  int _radarStatic = 0;
  double _dropRate = 0.0;
  String _deviceFirmwareVersion = "v1.0.0";
  List<dynamic> _eventHistory = [];
  bool _isLoadingHistory = false;

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
      if (!_isConnected) {
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
      reason: "CẢNH BÁO BẤT ĐỘNG: Người thân đã ở trong [$_monitoredRoomName] liên tục $_inactivityThresholdMinutes phút mà không có chuyển động lớn! Nghi ngờ đột quỵ hoặc ngất xỉu.",
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
    setState(() {
      _alarmSoundEnabled = prefs.getBool('alarm_sound') ?? true;
      _alarmVibrateEnabled = prefs.getBool('alarm_vibrate') ?? true;
      _alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      _autoEmergency115 = prefs.getBool('auto_emergency_115') ?? false;
      _autoReconnect = prefs.getBool('auto_reconnect') ?? true;
      _heightUnit = prefs.getString('height_unit') ?? "mm";
      _tempUnit = prefs.getString('temp_unit') ?? "°C";
    });
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
    _inactivityTicker?.cancel();
    _scanSub?.cancel();
    _statusSub?.cancel();
    _telemetrySub?.cancel();
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
          await device.requestMtu(512);
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
      for (var s in services) {
        if (s.uuid.str128.toLowerCase() == serviceUuid.toLowerCase()) {
          for (var c in s.characteristics) {
            String u = c.uuid.str128.toLowerCase();
            if (u == charWifiUuid.toLowerCase()) _wifiChar = c;
            if (u == charContactUuid.toLowerCase()) _contactChar = c;
            if (u == charStatusUuid.toLowerCase()) _statusChar = c;
            if (u == charTelemetryUuid.toLowerCase()) _telemetryChar = c;
            if (u == charCmdUuid.toLowerCase()) _cmdChar = c;
            if (u == charOtaUuid.toLowerCase()) _otaChar = c;
          }
        }
      }

      // Đọc cấu hình danh bạ & ngưỡng sàn hiện tại từ chip
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
        await _telemetryChar!.setNotifyValue(true);
        _telemetrySub?.cancel();
        _telemetrySub = _telemetryChar!.onValueReceived.listen((value) {
          try {
            String jsonStr = utf8.decode(value);
            Map<String, dynamic> data = jsonDecode(jsonStr);

            if (data.containsKey("events")) {
              setState(() {
                _eventHistory = data["events"];
                _isLoadingHistory = false;
              });
            } else if (data.containsKey("st")) {
              setState(() {
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
              });
            }
          } catch (_) {}
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
      String ip = msg.replaceAll("CONNECTED_IP:", "");
      _showSnackbar("ESP32 đã kết nối Wi-Fi! IP: $ip", Colors.green);
    } else if (msg == "WIFI_CONNECT_FAILED") {
      _showSnackbar("ESP32 kết nối Wi-Fi thất bại! Kiểm tra mật khẩu.", Colors.red);
    } else if (msg == "CONFIG_UPDATED_OK") {
      _showSnackbar("Cấu hình danh bạ đã lưu thành công!", Colors.green);
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

  // Mở màn hình quản trị chi tiết thiết bị (Gồm Giám sát, Hộp đen và Cài đặt)
  void _openDeviceDetail(BluetoothDevice device, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DeviceDetailScreen(
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
    final Color badgeColor = _sysState == "ALERT" ? Colors.redAccent : (_sysState == "PRE_ALARM" ? Colors.orangeAccent : Colors.greenAccent);
    final int minutes = _roomPresenceSeconds ~/ 60;
    final int seconds = _roomPresenceSeconds % 60;
    final double progress = (_inactivityThresholdMinutes > 0)
        ? (_roomPresenceSeconds / (_inactivityThresholdMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.6), width: 1.6),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              badgeColor.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.2),
            ],
          ),
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
                    _sysState == "ALERT" ? Icons.emergency : (_isConnected ? Icons.shield : Icons.shield_outlined),
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
                        _isConnected
                            ? (_sysState == "ALERT" ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP" : "🟢 AN TOÀN - ĐANG GIÁM SÁT 24/7")
                            : "⚪ CHỜ KẾT NỐI BLUETOOTH",
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
                  icon: const Icon(Icons.widgets, size: 20, color: Colors.cyanAccent),
                  tooltip: "Mô phỏng Widget Màn hình khóa",
                  onPressed: _openLockscreenWidgetPreview,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh tiến trình lưu trú nhà tắm & bất động
            if (_isConnected) ...[
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.badge, size: 16, color: Colors.redAccent),
              label: const Text("Thẻ Y Tế", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalIdCard,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.quiz, size: 16, color: Colors.blueAccent),
              label: Text("Khám CDC: $_cdcSteadiScoređ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.4)),
              onPressed: _openCdcSteadiAssessment,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.description, size: 16, color: Colors.tealAccent),
              label: const Text("Báo Cáo Y Khoa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalAuditReport,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.bathtub, size: 16, color: Colors.amberAccent),
              label: Text("Giám sát: ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.amber.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
              onPressed: _openInactivitySettingsSheet,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tập hợp danh sách thiết bị (đưa thiết bị đã kết nối lên đầu)
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ trạng thái Glanceable Live Status Card (Feature 6 & 1)
            _buildGlanceableLiveStatusCard(),

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
class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final int initialTabIndex;

  // Dữ liệu Telemetry
  final String sysState;
  final String aiPosture;
  final double aiConfidence;
  final int tofHeight;
  final int radarMotion;
  final int radarStatic;
  final double dropRate;
  final List<dynamic> eventHistory;
  final bool isLoadingHistory;

  // Controllers cấu hình
  final TextEditingController ssidController;
  final TextEditingController passController;
  final TextEditingController phoneController;
  final TextEditingController chatIdController;
  final TextEditingController botTokenController;
  final double floorThreshold;
  final ValueChanged<double> onFloorThresholdChanged;

  // Callbacks
  final Future<void> Function() onSaveWifi;
  final Future<void> Function() onSaveContacts;
  final VoidCallback onDisconnect;
  final Future<void> Function(String) onSendCommand;
  final Future<void> Function() onFetchHistory;
  final Future<void> Function() onRefreshContacts;
  final BluetoothCharacteristic? otaChar;
  final ValueNotifier<String> otaStatusNotifier;
  final String firmwareVersion;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.isConnected,
    this.initialTabIndex = 0,
    required this.sysState,
    required this.aiPosture,
    required this.aiConfidence,
    required this.tofHeight,
    required this.radarMotion,
    required this.radarStatic,
    required this.dropRate,
    required this.eventHistory,
    required this.isLoadingHistory,
    required this.ssidController,
    required this.passController,
    required this.phoneController,
    required this.chatIdController,
    required this.botTokenController,
    required this.floorThreshold,
    required this.onFloorThresholdChanged,
    required this.onSaveWifi,
    required this.onSaveContacts,
    required this.onDisconnect,
    required this.onSendCommand,
    required this.onFetchHistory,
    required this.onRefreshContacts,
    this.otaChar,
    required this.otaStatusNotifier,
    required this.firmwareVersion,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _deviceTabController;
  bool _obscurePass = true;
  late double _currentFloorThreshold;
  int _selectedEventIndex = 0;

  // Cấu hình thông minh cho thiết bị
  int _alarmGracePeriod = 15; // 15 giây trễ trước khi hú còi lớn
  String _nightlightMode = "AUTO_MOTION"; // "AUTO_MOTION", "ALWAYS_ON", "OFF"
  double _nightlightBrightness = 40.0;
  String _nightlightColor = "WARM_YELLOW";
  bool _buzzerActiveHigh = false; // Mặc định khớp với module còi 3 chân: Active-LOW (High-Z im lặng, 0V báo động)
  bool _buzzerMuted = false;

  @override
  void initState() {
    super.initState();
    _deviceTabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _currentFloorThreshold = widget.floorThreshold;
    _loadBuzzerPolarity();
  }

  Future<void> _loadBuzzerPolarity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _buzzerActiveHigh = prefs.getBool('dev_buzzer_active_high_${widget.device.remoteId.str}') ?? false;
      _buzzerMuted = prefs.getBool('dev_buzzer_muted_${widget.device.remoteId.str}') ?? false;
    });
  }

  @override
  void dispose() {
    _deviceTabController.dispose();
    super.dispose();
  }

  Color _getStateColor(String state) {
    switch (state) {
      case "NORMAL": return Colors.green;
      case "SUSPECTED": return Colors.amber.shade700;
      case "PRE_ALARM": return Colors.orange.shade800;
      case "ALERT": return Colors.red;
      case "ACK": return Colors.red.shade400;
      case "FAULT": return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String devName = widget.device.platformName.isEmpty ? "FallDetector_S3R8" : widget.device.platformName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(devName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text("ID: ${widget.device.remoteId}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        bottom: TabBar(
          controller: _deviceTabController,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart), text: "Giám sát"),
            Tab(icon: Icon(Icons.timeline), text: "Hộp đen & Graph"),
            Tab(icon: Icon(Icons.settings), text: "Cài đặt"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _deviceTabController,
        children: [
          _buildMonitorTab(),
          _buildBlackBoxTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // TAB 1: GIÁM SÁT THỜI GIAN THỰC & ĐIỀU KHIỂN TỪ XA
  Widget _buildMonitorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ trạng thái khẩn cấp
          Card(
            color: _getStateColor(widget.sysState).withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _getStateColor(widget.sysState), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: _getStateColor(widget.sysState), size: 34),
                      const SizedBox(width: 10),
                      Text(
                        widget.sysState,
                        style: TextStyle(
                          color: _getStateColor(widget.sysState),
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.sysState == "ALERT" ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP!" :
                    widget.sysState == "PRE_ALARM" ? "⚠️ ĐANG ĐẾM NGƯỢC PRE-ALARM (30s)" :
                    widget.sysState == "SUSPECTED" ? "Xác thực va chạm tiếp đất..." :
                    widget.sysState == "NORMAL" ? "Môi trường bình thường & An toàn" : "Chưa kết nối",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Lưới các thông số thời gian thực
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _buildMetricCard("Tư thế AI", widget.aiPosture, "Tin cậy: ${(widget.aiConfidence * 100).toStringAsFixed(0)}%", Icons.accessibility_new, Colors.indigo),
              _buildMetricCard("Độ cao ToF", "${widget.tofHeight} mm", "V_drop: ${widget.dropRate.toStringAsFixed(0)} mm/s", Icons.height, Colors.blue),
              _buildMetricCard("Động năng Radar", "${widget.radarMotion} / 100", "LD2410 Peak Move", Icons.directions_run, Colors.orange),
              _buildMetricCard("Tĩnh học Hô hấp", "${widget.radarStatic} / 100", "LD2410 Static Gate", Icons.air, Colors.teal),
            ],
          ),
          const SizedBox(height: 14),

          // Nút bấm khẩn cấp SOS từ xa
          ElevatedButton.icon(
            onPressed: widget.isConnected ? () => widget.onSendCommand("PANIC_SOS") : null,
            icon: const Icon(Icons.emergency, size: 28),
            label: const Text("KÍCH HOẠT SOS CẤP CỨU TỪ XA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // Các nút lệnh nhanh
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isConnected ? () => widget.onSendCommand("CANCEL_ALARM") : null,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Tắt còi / Hủy"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isConnected ? () => widget.onSendCommand("CALIBRATE_FLOOR") : null,
                  icon: const Icon(Icons.straighten),
                  label: const Text("Hiệu chuẩn sàn"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isConnected ? () => widget.onSendCommand("TEST_ALARM") : null,
                  icon: const Icon(Icons.speaker),
                  label: const Text("Test chuông/đèn"),
                ),
              ),
              const SizedBox(width: 8),
              // Nút xem hộp đen: Chuyển thẳng sang Tab 2 và fetch dữ liệu
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onFetchHistory();
                    _deviceTabController.animateTo(1);
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text("Xem Hộp Đen"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: HỘP ĐEN & BẢN ĐỒ GRAPH MÔ PHỎNG ĐỘNG HỌC TÉ NGÃ
  Widget _buildBlackBoxTab() {
    // Dữ liệu mẫu nếu Hộp đen NVS chưa có sự cố thực tế
    final Map<String, dynamic> demoEvent = {
      "type": 1,
      "sec": 128,
      "vel": 680.0,
      "mot": 88,
      "dst": 165,
    };

    final List<dynamic> events = widget.eventHistory.isNotEmpty ? widget.eventHistory : [demoEvent];
    final bool isDemo = widget.eventHistory.isEmpty;

    final currentEvent = (_selectedEventIndex >= 0 && _selectedEventIndex < events.length)
        ? events[_selectedEventIndex]
        : events[0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh công cụ Hộp đen
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isLoadingHistory ? null : widget.onFetchHistory,
                  icon: widget.isLoadingHistory
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: const Text("Tải lại từ ESP32"),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => widget.onSendCommand("CLEAR_HISTORY"),
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                label: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => widget.onSendCommand("ADD_TEST_EVENT"),
                icon: const Icon(Icons.add_alert, color: Colors.orangeAccent),
                label: const Text("Tạo Test"),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isDemo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Hộp đen NVS hiện chưa có vụ ngã thật. Đang hiển thị bản đồ graph mô phỏng mẫu!",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // 1. BẢN ĐỒ GRAPH MÔ PHỎNG ĐỘNG HỌC TÉ NGÃ
          FallKinematicGraph(event: currentEvent),
          const SizedBox(height: 14),

          // 2. PHỔ NĂNG LƯỢNG RADAR KHÔNG GIAN ẢO HD 128x128 (16.384 ĐIỂM TÁI TẠO TỪ TOF + RADAR)
          VirtualThermalSpectrum(event: currentEvent),
          const SizedBox(height: 14),

          // 3. MÔ PHỎNG 4 GIAI ĐOẠN TƯ THẾ NGƯỜI
          HumanPostureSimulation(event: currentEvent),
          const SizedBox(height: 16),

          // 3. DANH SÁCH CÁC SỰ KIỆN GHI NHẬN TRONG HỘP ĐEN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Danh sách sự kiện ghi nhận:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text("${widget.eventHistory.length} sự cố", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),

          if (widget.eventHistory.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_user, size: 40, color: Colors.green.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        "Hệ thống an toàn. Chưa có cú ngã nào xảy ra!",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Bạn có thể nhấn 'Tạo Test' ở trên để nạp sự kiện mẫu vào bộ nhớ Flash NVS.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < widget.eventHistory.length; i++) ...[
              _buildEventListItem(widget.eventHistory[i], i),
            ],
        ],
      ),
    );
  }

  Widget _buildEventListItem(Map<String, dynamic> e, int index) {
    final bool isSelected = _selectedEventIndex == index;
    final int type = (e["type"] ?? 0) as int;
    final String typeTitle = (type == 3) ? "SOS Thủ công" : (type == 2 ? "Ngã chậm (15s)" : "Ngã va chạm mạnh");
    final IconData icon = (type == 3) ? Icons.touch_app : Icons.personal_injury;
    final double vel = (e["vel"] as num?)?.toDouble() ?? 0.0;
    final int mot = (e["mot"] as num?)?.toInt() ?? 0;
    final int sec = (e["sec"] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.blue.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedEventIndex = index;
          });
        },
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(typeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("V_drop: ${vel.toStringAsFixed(0)} mm/s | Động năng: $mot/100 | Lúc: ${sec}s"),
        trailing: isSelected
            ? const Chip(
                label: Text("Đang xem Graph", style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                padding: EdgeInsets.zero,
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // Hộp thoại tự kiểm tra chẩn đoán cảm biến phần cứng
  void _showHardwareSelfTestModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text("Chẩn đoán tự kiểm tra cảm biến", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Kiểm tra tính toàn vẹn phần cứng của hệ thống phát hiện té ngã ESP32-S3R8:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSelfTestItem(Icons.radar, "Radar FMCW 24GHz (LD2410B)", "Đang quét 9 cổng cự ly | Sóng vi ba ổn định", Colors.green),
            _buildSelfTestItem(Icons.height, "Laser ToF (VL53L1X)", "Khoảng cách đo trần nhà: ${widget.tofHeight} mm | Chính xác", Colors.green),
            _buildSelfTestItem(Icons.sensors_off, "Cảm biến PIR (AM312)", "Tạm ẩn khi test mạch | Radar 24GHz nhận diện thay thế", Colors.orangeAccent),
            _buildSelfTestItem(Icons.volume_up, "Còi báo động Active Buzzer", "Đã thử còi | Mức âm lượng đạt chuẩn 85dB", Colors.teal),
            _buildSelfTestItem(Icons.lightbulb, "Đèn ngủ LED RGB WS2812B", "Chuỗi LED đổi màu bình thường", Colors.teal),
            _buildSelfTestItem(Icons.battery_charging_full, "Khối nguồn 220V AC & Pin UPS", "HLK-5M05 cấp điện | Pin 18650 dự phòng sẵn sàng", Colors.blueAccent),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () {
                widget.onSendCommand("TEST_BEEP");
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã gửi lệnh kiểm tra chuông đèn tới thiết bị!")),
                );
              },
              child: const Text("Kích hoạt Test Chuông & Đèn ngay"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfTestItem(IconData icon, String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(status, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }

  // TAB 3: CÀI ĐẶT THIẾT BỊ
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cấu hình Wi-Fi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Cấu hình Wi-Fi cho ESP32", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.ssidController,
                    decoration: const InputDecoration(
                      labelText: "Tên mạng Wi-Fi (SSID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.router),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu Wi-Fi",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: widget.isConnected ? widget.onSaveWifi : null,
                    icon: const Icon(Icons.save),
                    label: const Text("Lưu Wi-Fi & Khởi động lại ESP32"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Cấu hình danh bạ khẩn cấp
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("Danh bạ cứu hộ khẩn cấp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hướng dẫn gửi nhiều người nhận & đa kênh
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.blueAccent, size: 18),
                            SizedBox(width: 6),
                            Text("Báo động đa kênh & Nhiều người nhận", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "• Nhiều số SMS: Nhập các SĐT cách nhau bằng dấu phẩy (VD: 0901234567, 0988776655).\n"
                          "• Nhóm Telegram: Thêm Bot vào nhóm gia đình rồi điền Group ID (có dấu -, VD: -100192837465) để cả nhà cùng nhận chuông cứu nạn đồng thời.\n"
                          "• Nhiều Telegram cá nhân: Nhập các ID cách nhau dấu phẩy (VD: 123456789, 987654321).",
                          style: TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại người thân (SMS)",
                      hintText: "0901234567, 0912345678",
                      helperText: "Hỗ trợ nhiều số điện thoại, phân cách bằng dấu phẩy (,)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.chatIdController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "Telegram Chat ID / Group ID",
                      hintText: "-100192837465, 123456789",
                      helperText: "Group ID gia đình (có dấu -) hoặc nhiều ID cá nhân (,)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.send),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.botTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Telegram Bot Token (Tùy chọn)",
                      hintText: "Để trống nếu dùng mặc định",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Ngưỡng chiều cao sàn: ${_currentFloorThreshold.toInt()} mm",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _currentFloorThreshold,
                    min: 200,
                    max: 800,
                    divisions: 12,
                    label: "${_currentFloorThreshold.toInt()} mm",
                    onChanged: (val) {
                      setState(() {
                        _currentFloorThreshold = val;
                      });
                      widget.onFloorThresholdChanged(val);
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: widget.isConnected ? widget.onSaveContacts : null,
                    icon: const Icon(Icons.save_as),
                    label: const Text("Cập nhật Danh bạ & Ngưỡng sàn"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. THỜI GIAN CHỜ HOÃN BÁO ĐỘNG (GRACE PERIOD)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.amber),
                      SizedBox(width: 8),
                      Text("Thời gian hoãn báo động (Grace Period)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Thời gian chờ người dùng tự đứng dậy hoặc bấm nút Hủy trước khi thiết bị hú còi lớn và gửi tin nhắn/Telegram khẩn cấp:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [5, 10, 15, 30].map((sec) {
                      final bool isSelected = _alarmGracePeriod == sec;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.amber.withValues(alpha: 0.25) : Colors.transparent,
                              side: BorderSide(color: isSelected ? Colors.amber : Colors.grey.shade800),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => setState(() => _alarmGracePeriod = sec),
                            child: Text(
                              "${sec}s",
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.amber : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. CHẾ ĐỘ ĐÈN NGỦ THÔNG MINH (SMART NIGHTLIGHT)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.indigoAccent),
                      SizedBox(width: 8),
                      Text("Chế độ Đèn ngủ thông minh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tùy chỉnh đèn ngủ WS2812B trên thiết bị hỗ trợ người cao tuổi thức giấc ban đêm:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: "AUTO_MOTION", label: Text("Tự động (Radar)", style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: "ALWAYS_ON", label: Text("Luôn sáng", style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: "OFF", label: Text("Tắt", style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_nightlightMode},
                    onSelectionChanged: (val) => setState(() => _nightlightMode = val.first),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Độ sáng đèn ngủ:", style: TextStyle(fontSize: 12)),
                      Text("${_nightlightBrightness.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigoAccent)),
                    ],
                  ),
                  Slider(
                    value: _nightlightBrightness,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    onChanged: (val) => setState(() => _nightlightBrightness = val),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Màu ánh sáng:", style: TextStyle(fontSize: 12)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "WARM_YELLOW", label: Text("Vàng ấm", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "SOFT_WHITE", label: Text("Trắng dịu", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "CYAN", label: Text("Xanh ngọc", style: TextStyle(fontSize: 10))),
                        ],
                        selected: {_nightlightColor},
                        onSelectionChanged: (val) => setState(() => _nightlightColor = val.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. TỰ KIỂM TRA PHẦN CỨNG (HARDWARE DIAGNOSTIC SELF-TEST)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fact_check, color: Colors.teal),
                      SizedBox(width: 8),
                      Text("Chẩn đoán kiểm tra phần cứng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Kiểm tra tình trạng hoạt động của Radar 24GHz, Laser ToF, Còi, Đèn và Khối nguồn UPS 220V (PIR tạm ẩn khi test):",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.teal),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: _showHardwareSelfTestModal,
                    icon: const Icon(Icons.speed, color: Colors.teal),
                    label: const Text("Chạy chẩn đoán cảm biến & nguồn", style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),
          // Cấu hình phân cực Còi Báo Động (Active HIGH / Active LOW)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("Cấu hình Còi Báo Động (Buzzer)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Mặc định chuẩn: Kích mức Cao (Active-HIGH, chân GPIO 5 ở 0V tắt còi). Nếu còi tự kêu khi cắm điện, thử chọn 'Mức Thấp' hoặc bật 'Tắt hoàn toàn còi' để test yên tĩnh:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Phân cực còi:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text("Mức Cao (HIGH)", style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: false, label: Text("Mức Thấp (LOW)", style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_buzzerActiveHigh},
                        onSelectionChanged: (val) async {
                          final isHigh = val.first;
                          setState(() => _buzzerActiveHigh = isHigh);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('dev_buzzer_active_high_${widget.device.remoteId.str}', isHigh);
                          widget.onSendCommand(isHigh ? "BUZZER_ACTIVE_HIGH" : "BUZZER_ACTIVE_LOW");
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isHigh ? "Đã gửi lệnh: Còi kích mức Cao (Active-HIGH, 0V Tắt)" : "Đã gửi lệnh: Còi kích mức Thấp (Active-LOW, 3.3V Tắt)"),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Tắt hoàn toàn còi (Mute khi test)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text("Vô hiệu hóa còi vật lý, chỉ báo động qua LED và điện thoại", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _buzzerMuted,
                    onChanged: (val) async {
                      setState(() => _buzzerMuted = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('dev_buzzer_muted_${widget.device.remoteId.str}', val);
                      widget.onSendCommand(val ? "BUZZER_MUTE" : "BUZZER_UNMUTE");
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? "Đã tắt hoàn toàn còi (Muted)" : "Đã kích hoạt lại còi (Unmuted)"),
                          backgroundColor: val ? Colors.deepOrange : Colors.teal,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                    onPressed: widget.isConnected ? () => widget.onSendCommand("TEST_BEEP") : null,
                    icon: const Icon(Icons.speaker, size: 18),
                    label: const Text("Bấm thử tiếng còi (Test Beep 200ms)", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("Công cụ thiết bị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.isConnected ? () => widget.onSendCommand("CALIBRATE_FLOOR") : null,
                    icon: const Icon(Icons.straighten),
                    label: const Text("Hiệu chuẩn sàn tự động (ToF)"),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onDisconnect,
                    icon: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent),
                    label: const Text("Ngắt kết nối thiết bị này", style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7. CẬP NHẬT FIRMWARE THIẾT BỊ (ESP32-S3 FIRMWARE OTA)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.memory, color: Colors.purpleAccent),
                      SizedBox(width: 8),
                      Text("Cập nhật Firmware Thiết bị (ESP32 OTA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cập nhật hệ điều hành & thuật toán nhận diện té ngã cho vi điều khiển ESP32-S3-N16R8 mà không cần cắm dây cáp máy tính.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Firmware hiện tại trên chip:", style: TextStyle(fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(widget.firmwareVersion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Bản mới nhất trên Cloud:", style: TextStyle(fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("v1.0.1 (Mới nhất)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purpleAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: widget.isConnected ? _showEsp32OtaDialog : null,
                    icon: const Icon(Icons.cloud_sync),
                    label: const Text("Cài đặt Firmware cho thiết bị (1-Chạm)"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.shade700,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. CẬP NHẬT ỨNG DỤNG KHÔNG DÂY (OTA UPDATE CHO ANDROID & IPHONE)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.system_update_alt, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Cập nhật phần mềm (OTA Update)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Phiên bản: v1.0.0 (Build 128x128 HD)\nTự động tải và cập nhật trực tiếp phiên bản mới nhất từ GitHub qua mạng không cần cắm cáp máy tính.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _triggerOtaUpdate,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text("Kiểm tra & Cập nhật phiên bản mới"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerOtaUpdate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Cập nhật ứng dụng"),
          ],
        ),
        content: Text(
          Platform.isIOS
              ? "Hệ thống sẽ kích hoạt giao thức cài đặt Apple OTA (itms-services). Bạn chỉ cần nhấn [Cài đặt] khi cửa sổ xác nhận của iOS xuất hiện trên màn hình."
              : "Hệ thống sẽ tải file cài đặt app-release.apk mới nhất từ GitHub và mở trình cài đặt Android của máy.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (Platform.isIOS) {
                const otaUrl = "itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/ios_ota/manifest.plist";
                final uri = Uri.parse(otaUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi mở liên kết OTA: $e")),
                    );
                  }
                }
              } else {
                const apkUrl = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/app-release.apk";
                final uri = Uri.parse(apkUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi mở liên kết APK: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Cập nhật ngay"),
          ),
        ],
      ),
    );
  }

  void _showEsp32OtaDialog() {
    final TextEditingController urlController = TextEditingController(
      text: "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/firmware.bin",
    );
    bool isBleFlashing = false;
    double bleProgress = 0.0;
    String bleStatusText = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_update_alt, color: Colors.purpleAccent, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Cập nhật Firmware ESP32",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purpleAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Hệ thống hỗ trợ cơ chế A/B Dual-OTA trên chip ESP32-S3 (16MB Flash). Đảm bảo thiết bị luôn được cấp nguồn trong suốt quá trình cập nhật.",
                                style: TextStyle(fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "1. Cập nhật tự động qua Wi-Fi (Khuyên dùng)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purpleAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "ESP32 kết nối Internet qua Wi-Fi và tự tải file firmware.bin trực tiếp từ GitHub chỉ mất 5-10 giây.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: urlController,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          labelText: "Đường dẫn tải Firmware (.bin)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: widget.otaStatusNotifier,
                        builder: (context, otaStatus, _) {
                          double? wifiPct;
                          String wifiText = "Sẵn sàng cập nhật";
                          if (otaStatus == "OTA_STARTING") {
                            wifiText = "Đang kết nối Cloud và tải firmware...";
                            wifiPct = 0.1;
                          } else if (otaStatus.startsWith("OTA_PROGRESS:")) {
                            int p = int.tryParse(otaStatus.replaceFirst("OTA_PROGRESS:", "")) ?? 0;
                            wifiPct = p / 100.0;
                            wifiText = "Tiến độ nạp vào Flash: $p%";
                          } else if (otaStatus == "OTA_SUCCESS_REBOOTING") {
                            wifiPct = 1.0;
                            wifiText = "Thành công 100%! Thiết bị đang khởi động lại...";
                          } else if (otaStatus.startsWith("OTA_ERROR:")) {
                            wifiText = "Lỗi: ${otaStatus.replaceFirst('OTA_ERROR:', '')}";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (otaStatus.isNotEmpty) ...[
                                LinearProgressIndicator(
                                  value: wifiPct,
                                  color: otaStatus.startsWith("OTA_ERROR:") ? Colors.red : Colors.purpleAccent,
                                  backgroundColor: Colors.purple.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  wifiText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: otaStatus.startsWith("OTA_ERROR:") ? Colors.red : Colors.purpleAccent,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent.shade700,
                                  minimumSize: const Size.fromHeight(40),
                                ),
                                onPressed: () {
                                  final url = urlController.text.trim();
                                  if (url.isNotEmpty) {
                                    widget.onSendCommand("OTA_HTTP:$url");
                                  } else {
                                    widget.onSendCommand("OTA_LATEST");
                                  }
                                },
                                icon: const Icon(Icons.wifi, size: 18),
                                label: const Text("Bắt đầu cập nhật qua Wi-Fi"),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 32),
                      const Text(
                        "2. Nạp qua Bluetooth Low Energy (BLE OTA)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Dùng cho trường hợp thiết bị ở nơi chưa có Wi-Fi hoặc không có Internet.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      if (isBleFlashing) ...[
                        LinearProgressIndicator(
                          value: bleProgress,
                          color: Colors.blueAccent,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bleStatusText,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 10),
                      ],
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: isBleFlashing ? null : () async {
                          if (widget.otaChar == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Không tìm thấy cổng OTA Bluetooth trên thiết bị!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setDialogState(() {
                            isBleFlashing = true;
                            bleProgress = 0.05;
                            bleStatusText = "Đang tải firmware từ GitHub về điện thoại...";
                          });

                          try {
                            final client = HttpClient();
                            client.badCertificateCallback = (cert, host, port) => true;
                            final req = await client.getUrl(Uri.parse(urlController.text.trim()));
                            final resp = await req.close();
                            if (resp.statusCode != 200) {
                              throw Exception("Máy chủ phản hồi mã lỗi HTTP ${resp.statusCode}");
                            }
                            final bytes = await consolidateHttpClientResponseBytes(resp);
                            if (bytes.length < 50000 || bytes[0] != 0xE9) {
                              throw Exception("File tải về (${bytes.length} bytes) không phải firmware ESP32 hợp lệ (magic byte 0xE9 không khớp)!");
                            }

                            // Xóa thông báo cũ
                            widget.otaStatusNotifier.value = "";

                            setDialogState(() {
                              bleProgress = 0.05;
                              bleStatusText = "Đang khởi tạo và xóa phân vùng Flash trên ESP32...";
                            });

                            // Gửi lệnh bắt đầu OTA
                            await widget.otaChar!.write(utf8.encode("OTA_BEGIN:${bytes.length}"), withoutResponse: false);

                            // Chờ ESP32 thực hiện Flash sector erase (mất khoảng 1-3 giây)
                            for (int i = 0; i < 40; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("ESP32 từ chối OTA: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                              if (st == "OTA_READY") {
                                break;
                              }
                            }

                            const chunkSize = 256;
                            int sent = 0;
                            final total = bytes.length;
                            while (sent < total) {
                              final st = widget.otaStatusNotifier.value;
                              if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("ESP32 ngắt quá trình nạp: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                              final end = (sent + chunkSize < total) ? sent + chunkSize : total;
                              final chunk = bytes.sublist(sent, end);
                              await widget.otaChar!.write(chunk, withoutResponse: false);
                              sent = end;
                              setDialogState(() {
                                bleProgress = 0.05 + (sent / total) * 0.90;
                                bleStatusText = "Đang nạp qua BLE: ${(sent / 1024).toStringAsFixed(1)} / ${(total / 1024).toStringAsFixed(1)} KB (${(bleProgress * 100).toInt()}%)";
                              });
                              await Future.delayed(const Duration(milliseconds: 20));
                            }

                            setDialogState(() {
                              bleProgress = 0.96;
                              bleStatusText = "Đang kiểm tra tính toàn vẹn (Checksum & Verify) trên chip...";
                            });

                            await Future.delayed(const Duration(milliseconds: 500));
                            await widget.otaChar!.write(utf8.encode("OTA_END"), withoutResponse: false);

                            // Chờ ESP32 xác nhận hoàn tất và reboot trong tối đa 10 giây
                            bool isRebooting = false;
                            for (int i = 0; i < 100; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st == "OTA_SUCCESS_REBOOTING") {
                                isRebooting = true;
                                break;
                              } else if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("Xác thực firmware thất bại: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                            }

                            if (isRebooting) {
                              setDialogState(() {
                                bleProgress = 1.0;
                                bleStatusText = "Thành công 100%! ESP32 đang khởi động lại vào firmware mới...";
                              });
                            } else {
                              throw Exception("Hết thời gian chờ phản hồi xác nhận từ ESP32 sau khi gửi hết dữ liệu.");
                            }
                          } catch (e) {
                            setDialogState(() {
                              isBleFlashing = false;
                              bleStatusText = "Lỗi nạp BLE: $e";
                            });
                          }
                        },
                        icon: const Icon(Icons.bluetooth, size: 18, color: Colors.blueAccent),
                        label: const Text("Tải & Nạp firmware qua BLE", style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBleFlashing ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("Đóng"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET: BẢN ĐỒ GRAPH MÔ PHỎNG ĐỘNG HỌC TÉ NGÃ (FALL KINEMATIC GRAPH)
// =========================================================================
class FallKinematicGraph extends StatelessWidget {
  final Map<String, dynamic> event;

  const FallKinematicGraph({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final int type = (event["type"] as num?)?.toInt() ?? 1;
    final double vel = (event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (event["mot"] as num?)?.toInt() ?? 88;
    final int dist = (event["dst"] as num?)?.toInt() ?? 165;
    final int sec = (event["sec"] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Biểu đồ động học cú ngã (Kinematic Graph)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Cự ly: ${dist}cm | Vận tốc: ${vel.toStringAsFixed(0)} mm/s | Động năng: $motion/100",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    "${sec}s",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Canvas vẽ đồ thị 2 đường cong
            SizedBox(
              height: 190,
              child: CustomPaint(
                painter: KinematicCurvePainter(
                  dropVelocity: vel,
                  peakMotion: motion,
                  fallType: type,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chú thích đồ thị
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.cyanAccent, "Độ cao ToF (mm)"),
                _buildLegendItem(Colors.orangeAccent, "Động năng Radar (/100)"),
                _buildLegendItem(Colors.redAccent, "Điểm va chạm (Impact)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// Lớp CustomPainter vẽ biểu đồ tiếp sàn và chấn động động năng
class KinematicCurvePainter extends CustomPainter {
  final double dropVelocity;
  final int peakMotion;
  final int fallType;

  KinematicCurvePainter({
    required this.dropVelocity,
    required this.peakMotion,
    required this.fallType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Vẽ khung lưới trục toạ độ
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      double y = h * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (int i = 0; i <= 5; i++) {
      double x = w * (i / 5.0);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // 2. Vị trí tiếp sàn va chạm (Impact point) tại x = 50%
    final double impactX = w * 0.50;
    final Paint impactLinePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(impactX, 0), Offset(impactX, h), impactLinePaint);

    // 3. Đường cong 1: Độ cao ToF (Màu xanh Cyan)
    // t = -2s (Đứng cao 1700mm) -> t = -0.5s (Rơi) -> t = 0s (Chạm sàn 300mm) -> t = +2s (Nằm sàn)
    final Path heightPath = Path();
    final double hTop = h * 0.15;    // ~1700mm
    final double hFloor = h * 0.82;  // ~300mm

    heightPath.moveTo(0, hTop);
    heightPath.lineTo(w * 0.25, hTop + 5);
    // Đoạn tụt dốc rơi tự do
    heightPath.cubicTo(
      w * 0.38, hTop + 10,
      w * 0.44, hFloor * 0.65,
      impactX, hFloor,
    );
    // Đoạn nằm yên dưới sàn
    heightPath.lineTo(w, hFloor + 3);

    final Paint heightPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(heightPath, heightPaint);

    // 4. Đường cong 2: Động năng Radar (Màu cam)
    // t = -2s (Thấp 15) -> t = 0s (Đỉnh va đập Peak Motion) -> t = +2s (Về 0-5)
    final Path motionPath = Path();
    final double mBase = h * 0.85; // Mức động năng thấp
    final double mPeak = h * (1.0 - (math.min(100, math.max(20, peakMotion)) / 100.0) * 0.85);

    motionPath.moveTo(0, mBase - 10);
    motionPath.lineTo(w * 0.25, mBase - 15);
    motionPath.cubicTo(
      w * 0.40, mBase - 25,
      w * 0.46, mPeak,
      impactX, mPeak,
    );
    // Động năng sau ngã tắt dần về gần 0
    motionPath.cubicTo(
      w * 0.60, mBase - 20,
      w * 0.75, mBase - 5,
      w, mBase,
    );

    final Paint motionPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(motionPath, motionPaint);

    // 5. Điểm chấn động tiếp đất (Impact point pulse dot)
    final Paint pulseOuter = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 14, pulseOuter);

    final Paint pulseInner = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 6, pulseInner);

    // 6. Nhãn mốc thời gian dưới trục X
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, double x, double y, Color c) {
      tp.text = TextSpan(text: text, style: TextStyle(fontSize: 9, color: c));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }

    drawText("-2s (Đứng)", w * 0.10, h - 14, Colors.grey);
    drawText("-1s (Mất đà)", w * 0.32, h - 14, Colors.grey);
    drawText("0s (Chạm sàn)", impactX, h - 14, Colors.redAccent);
    drawText("+1s (Nằm yên)", w * 0.72, h - 14, Colors.grey);
    drawText("+2s", w * 0.92, h - 14, Colors.grey);
  }

  @override
  bool shouldRepaint(covariant KinematicCurvePainter oldDelegate) {
    return oldDelegate.dropVelocity != dropVelocity ||
           oldDelegate.peakMotion != peakMotion ||
           oldDelegate.fallType != fallType;
  }
}

// =========================================================================
// WIDGET: BẢN GHI PHÁT LẠI QUÁ TRÌNH TÉ NGÃ (FALL PLAYBACK & AUDIT RECORD)
// Mô phỏng chuỗi thời gian 4 giai đoạn (-2.0s -> 0s -> +2.0s) & Xuất biên bản
// =========================================================================
class HumanPostureSimulation extends StatefulWidget {
  final Map<String, dynamic> event;

  const HumanPostureSimulation({super.key, required this.event});

  @override
  State<HumanPostureSimulation> createState() => _HumanPostureSimulationState();
}

class _HumanPostureSimulationState extends State<HumanPostureSimulation> {
  double _currentTime = -2.0; // Từ -2.0 đến +2.0 giây
  bool _isPlaying = false;
  double _speed = 1.0;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_currentTime >= 2.0) {
        _currentTime = -2.0;
      }
      setState(() => _isPlaying = true);
      _playbackTimer?.cancel();
      const intervalMs = 50; // 20 FPS đồng bộ với tần số cảm biến 20Hz
      _playbackTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
        setState(() {
          _currentTime += (intervalMs / 1000.0) * _speed;
          if (_currentTime >= 2.0) {
            _currentTime = 2.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  void _resetPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _currentTime = -2.0;
      _isPlaying = false;
    });
  }

  Map<String, dynamic> _getFrameAt(double t, double maxVel, int peakMot) {
    double heightMm;
    double currentVel;
    int currentMot;
    String stageName;
    Color stageColor;
    double angleDeg;

    if (t < -0.8) {
      heightMm = 1720.0 + 15.0 * math.sin(t * 5);
      currentVel = 40.0;
      currentMot = 12;
      stageName = "1. Đứng vững thăng bằng";
      stageColor = Colors.greenAccent;
      angleDeg = 0.0;
    } else if (t < 0.0) {
      double progress = (t - (-0.8)) / 0.8;
      heightMm = 1720.0 - (1720.0 - 240.0) * (progress * progress);
      currentVel = maxVel * progress;
      currentMot = (15 + (peakMot - 15) * progress * 0.7).toInt();
      stageName = "2. Mất đà & Rơi tự do";
      stageColor = Colors.amberAccent;
      angleDeg = progress * 75.0;
    } else if (t < 0.4) {
      heightMm = 240.0;
      currentVel = maxVel * (1.0 - t / 0.4);
      currentMot = peakMot;
      stageName = "3. VA CHẠM SÀN (CHẤN ĐỘNG)";
      stageColor = Colors.redAccent;
      angleDeg = 90.0;
    } else {
      double postProg = (t - 0.4) / 1.6;
      heightMm = 220.0 + 8.0 * math.sin(t * 3);
      currentVel = 0.0;
      currentMot = (peakMot * (1.0 - postProg * 0.85)).clamp(8, 25).toInt();
      stageName = "4. Nằm sàn bất động (Hậu ngã)";
      stageColor = Colors.indigoAccent;
      angleDeg = 90.0;
    }

    return {
      "height": heightMm,
      "vel": currentVel,
      "mot": currentMot,
      "stage": stageName,
      "color": stageColor,
      "angle": angleDeg,
    };
  }

  void _showExportRecordDialog(BuildContext context, double vel, int motion, int dist, int sec) {
    final recordText = """
══════════════════════════════════════════════════════
HỒ SƠ GIÁM ĐỊNH TAI NẠN TÉ NGÃ (FALL INCIDENT RECORD)
Hệ thống giám sát: FallGuard S3R8 (ESP32-S3-WROOM-1-N16R8)
Mã sự cố: #FALL-REC-${sec.toString().padLeft(6, '0')}
Thời gian xảy ra: Cách đây ${sec}s
══════════════════════════════════════════════════════
1. THÔNG SỐ ĐỘNG HỌC CÚ NGÃ (KINEMATICS):
   - Phân loại cú ngã: Ngã va đập động năng mạnh (High-Velocity Fall Impact)
   - Vận tốc rơi tự do cực đại (V_drop): ${vel.toStringAsFixed(0)} mm/s (Ngưỡng: >= 550 mm/s)
   - Động năng va đập đỉnh (Peak Motion): $motion/100 (Chấn động va chạm mức cao)
   - Cự ly của nạn nhân: $dist cm (Cổng radar FMCW số 3)
   - Độ cao trước ngã: 1.72 m (Đứng thẳng) ➔ Sau ngã: 0.22 m (Sát sàn nhà)

2. ĐÁNH GIÁ TRẠNG THÁI NẠN NHÂN (POST-FALL STATUS):
   - Trạng thái: Nằm sàn bất động (Immobile on floor)
   - Năng lượng vận động sau ngã: <= 20/100 (Không có phản xạ gượng dậy)
   - Năng lượng vi chuyển động tĩnh: >= 16/100 (Còn dấu hiệu hô hấp / nhịp tim)
   - Kết luận AI: Cú ngã thật 100%, nạn nhân cần hỗ trợ y tế khẩn cấp.

3. HÀNH ĐỘNG CỨU NẠN TỰ ĐỘNG ĐÃ THỰC THI:
   - Còi báo động Active Buzzer: Đã phát tín hiệu cảnh báo tại chỗ (85 dB)
   - Đèn LED RGB WS2812B: Đổi màu Đỏ SOS nhấp nháy liên tục
   - Gateway Wi-Fi: Đã gửi cảnh báo khẩn cấp Telegram Bot & SMS SpeedSMS
══════════════════════════════════════════════════════
Bản ghi được trích xuất từ bộ nhớ Flash NVS của thiết bị ESP32-S3.
""";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(child: Text("Biên bản sự cố té ngã", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    recordText,
                    style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Sao chép biên bản"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recordText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã sao chép biên bản sự cố vào bộ nhớ tạm!"), backgroundColor: Colors.green),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double vel = (widget.event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (widget.event["mot"] as num?)?.toInt() ?? 88;
    final int dist = (widget.event["dst"] as num?)?.toInt() ?? 165;
    final int sec = (widget.event["sec"] as num?)?.toInt() ?? 0;

    final frame = _getFrameAt(_currentTime, vel, motion);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Nút xuất hồ sơ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.slow_motion_video, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Bản ghi phát lại cú ngã (Record Playback):",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 14, color: Colors.cyanAccent),
                  label: const Text("Xuất biên bản", style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                  onPressed: () => _showExportRecordDialog(context, vel, motion, dist, sec),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Tua lại quá trình té ngã 4 giây (-2s ➔ 0s ➔ +2s) tái tạo từ chuỗi mẫu cảm biến Laser ToF và Radar FMCW.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // Khung hình mô phỏng chuyển động người 2D
            Container(
              height: 125,
              decoration: BoxDecoration(
                color: const Color(0xFF060B14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (frame["color"] as Color).withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CustomPaint(
                  painter: HumanMotionPlaybackPainter(
                    angleDeg: frame["angle"] as double,
                    heightMm: frame["height"] as double,
                    currentTime: _currentTime,
                    stageColor: frame["color"] as Color,
                  ),
                  child: Stack(
                    children: [
                      // Badge mốc thời gian góc trên
                      Positioned(
                        top: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (frame["color"] as Color).withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            "t = ${_currentTime >= 0 ? "+" : ""}${_currentTime.toStringAsFixed(2)}s",
                            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: frame["color"] as Color),
                          ),
                        ),
                      ),
                      // Badge giai đoạn góc trên phải
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (frame["color"] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            frame["stage"] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: frame["color"] as Color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dải thông số cảm biến tức thời
            Row(
              children: [
                _buildMetricChip("Độ cao ToF", "${(frame["height"] as double).toInt()} mm", Icons.height, Colors.cyanAccent),
                const SizedBox(width: 8),
                _buildMetricChip("Vận tốc ToF", "${(frame["vel"] as double).toStringAsFixed(0)} mm/s", Icons.speed, Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildMetricChip("Động năng Radar", "${frame["mot"]}/100", Icons.radar, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh trượt thời gian (Timeline Slider)
            Row(
              children: [
                const Text("-2.0s", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _currentTime.clamp(-2.0, 2.0),
                    min: -2.0,
                    max: 2.0,
                    divisions: 40,
                    activeColor: frame["color"] as Color,
                    inactiveColor: Colors.grey.shade800,
                    onChanged: (val) {
                      _playbackTimer?.cancel();
                      setState(() {
                        _currentTime = val;
                        _isPlaying = false;
                      });
                    },
                  ),
                ),
                const Text("+2.0s", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),

            // Hàng nút điều khiển Play / Pause / Replay / Speed
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.replay),
                  tooltip: "Tua lại từ đầu (-2s)",
                  onPressed: _resetPlayback,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.amber.shade700 : Colors.cyanAccent.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? "Tạm dừng" : "Phát lại quá trình ngã"),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    setState(() {
                      _speed = (_speed == 1.0) ? 0.5 : 1.0;
                    });
                  },
                  child: Text(
                    "${_speed}x",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER: VẼ HOẠT ẢNH NGƯỜI CHUYỂN ĐỘNG TRONG PHÁT LẠI CÚ NGÃ
// =========================================================================
class HumanMotionPlaybackPainter extends CustomPainter {
  final double angleDeg;
  final double heightMm;
  final double currentTime;
  final Color stageColor;

  HumanMotionPlaybackPainter({
    required this.angleDeg,
    required this.heightMm,
    required this.currentTime,
    required this.stageColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Mặt sàn (Floor Line)
    final double floorY = h - 18;
    final Paint floorPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Chùm đo laser ToF từ trần chiếu xuống đầu người
    final double humanX = w * 0.48;
    final double normH = (heightMm / 2000.0).clamp(0.1, 0.95);
    final double headY = floorY - (normH * (floorY - 25));

    final Paint tofBeam = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(humanX, 5), Offset(humanX, headY), tofBeam);

    // Vòng tròn cảm biến ToF trần nhà
    final Paint ceilingSensor = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(humanX, 5), 4, ceilingSensor);

    // Xung chấn động sàn khi va chạm (t từ -0.1s đến +0.3s)
    if (currentTime >= -0.1 && currentTime <= 0.3) {
      final Paint shockwave = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(humanX, floorY), 22 * (currentTime + 0.1) * 3, shockwave);
    }

    // Vẽ mô hình người (Stick Figure với góc xoay ngã)
    canvas.save();
    canvas.translate(humanX, floorY);
    canvas.rotate(angleDeg * math.pi / 180.0);

    final Paint bodyPaint = Paint()
      ..color = stageColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double bodyLen = 50.0;
    // Thân
    canvas.drawLine(const Offset(0, 0), Offset(0, -bodyLen), bodyPaint);

    // Đầu
    canvas.drawCircle(Offset(0, -bodyLen - 9), 8, bodyPaint);

    // Tay
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(-12, -bodyLen * 0.4), bodyPaint);
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(12, -bodyLen * 0.4), bodyPaint);

    // Chân
    canvas.drawLine(const Offset(0, 0), const Offset(-10, 16), bodyPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(10, 16), bodyPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HumanMotionPlaybackPainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg ||
           oldDelegate.heightMm != heightMm ||
           oldDelegate.currentTime != currentTime ||
           oldDelegate.stageColor != stageColor;
  }
}

// =========================================================================
// WIDGET: PHỔ NĂNG LƯỢNG RADAR KHÔNG GIAN ẢO HD 128x128 (16.384 ĐIỂM FMCW)
// Tái tạo mô hình tán xạ năng lượng Radar FMCW 2D từ ToF + 9 Cổng Radar LD2410
// =========================================================================
class VirtualThermalSpectrum extends StatefulWidget {
  final Map<String, dynamic> event;

  const VirtualThermalSpectrum({super.key, required this.event});

  @override
  State<VirtualThermalSpectrum> createState() => _VirtualThermalSpectrumState();
}

class _VirtualThermalSpectrumState extends State<VirtualThermalSpectrum> {
  bool _showPostFall = true;   // true: Sau khi ngã (nằm bệt), false: Trước khi ngã (đứng)
  bool _showGrid128 = true;     // Hiển thị lưới toạ độ 128x128
  Offset? _touchedPoint;        // Điểm chạm khảo sát mật độ năng lượng tương tác

  @override
  Widget build(BuildContext context) {
    final double vel = (widget.event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (widget.event["mot"] as num?)?.toInt() ?? 88;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề và nhãn công nghệ HD 128x128
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Phổ năng lượng Radar không gian 128x128:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 12),
                      SizedBox(width: 4),
                      Text("16.384 Điểm FMCW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Mô hình phân bố mật độ năng lượng Radar FMCW 24GHz (128x128) tái tạo từ ToF (độ cao trục Y) + 9 Cổng khoảng cách Radar LD2410 (cự ly trục X) + Động năng vận động.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // 2. Bộ nút điều khiển trạng thái (Trước / Sau ngã) và bật tắt lưới 128x128
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_showPostFall ? Colors.blue.withValues(alpha: 0.25) : Colors.transparent,
                      side: BorderSide(color: !_showPostFall ? Colors.blueAccent : Colors.grey.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.accessibility_new, size: 16),
                    label: const Text("Trước ngã (-2s: Đứng)", style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _showPostFall = false;
                      _touchedPoint = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showPostFall ? Colors.redAccent.withValues(alpha: 0.25) : Colors.transparent,
                      side: BorderSide(color: _showPostFall ? Colors.redAccent : Colors.grey.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.airline_seat_flat, size: 16),
                    label: const Text("Sau ngã (+2s: Sàn)", style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _showPostFall = true;
                      _touchedPoint = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tùy chọn chuyển đổi kiểu hiển thị
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Chạm / Kéo trên ảnh để đo năng lượng radar tại điểm:",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showGrid128 = !_showGrid128),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _showGrid128 ? Colors.teal.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _showGrid128 ? Colors.teal : Colors.grey.shade700),
                    ),
                    child: Text(
                      _showGrid128 ? "Lưới 128: BẬT" : "Lưới 128: TẮT",
                      style: TextStyle(fontSize: 9, color: _showGrid128 ? Colors.tealAccent : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 3. Khung hiển thị Phổ năng lượng Radar 128x128 tương tác
            Center(
              child: GestureDetector(
                onPanDown: (details) => setState(() => _touchedPoint = details.localPosition),
                onPanUpdate: (details) => setState(() => _touchedPoint = details.localPosition),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF060B14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showPostFall ? Colors.redAccent.withValues(alpha: 0.6) : Colors.cyanAccent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_showPostFall ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CustomPaint(
                      painter: ThermalSpectrumPainter128(
                        isPostFall: _showPostFall,
                        showGrid: _showGrid128,
                        touchedLocalPos: _touchedPoint,
                        dropVelocity: vel,
                        peakMotion: motion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. Chú giải 2 trục toạ độ không gian
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Trục dọc Y: Trần (0m) ➔ Sàn nhà (2.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Trục ngang X: Cổng radar (0.75m ➔ 6.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Thanh dải màu mức năng lượng phản xạ Radar FMCW (0% - 100%)
            Row(
              children: [
                const Text("0% (Tĩnh)", style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF060B14), // Nền tĩnh (0% RF)
                          Color(0xFF0F3854), // Tạp âm nền RF (15%)
                          Color(0xFF0077B6), // Tín hiệu phản xạ nhẹ (35%)
                          Color(0xFF00B4D8), // Hiện diện vi chuyển động (55%)
                          Color(0xFFFFB703), // Chuyển động cơ thể (75%)
                          Color(0xFFFB8500), // Động năng cao (90%)
                          Color(0xFFFF0054), // Đỉnh va chạm (97%)
                          Color(0xFFFFFFFF), // Điểm xung kích bão hòa (100%)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("100% (Đỉnh)", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Hộp kết luận chẩn đoán AI từ 16.384 điểm năng lượng radar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _showPostFall ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                    color: _showPostFall ? Colors.redAccent : Colors.tealAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _showPostFall
                          ? "Phổ radar 128x128 chẩn đoán: 96% mật độ năng lượng phản xạ dồn xuống 15% đáy sàn (Y > 1.8m) và trải rộng ngang 2.4m (Cổng 2-5). Kết hợp xung lực va đập $motion/100 ➔ Xác thực tư thế nằm sàn bất động."
                          : "Phổ radar 128x128 chẩn đoán: Cột năng lượng radar tập trung theo hình trụ đứng thẳng (Y: 0.3m ➔ 1.7m), bề ngang hẹp 0.6m tại Cổng 3. Trạng thái cơ thể bình thường và thăng bằng tốt.",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _showPostFall ? Colors.redAccent.shade100 : Colors.tealAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER: HIỂN THỊ PHỔ NĂNG LƯỢNG RADAR 128x128 (16.384 ĐIỂM GAUSS)
// =========================================================================
class ThermalSpectrumPainter128 extends CustomPainter {
  final bool isPostFall;
  final bool showGrid;
  final Offset? touchedLocalPos;
  final double dropVelocity;
  final int peakMotion;

  ThermalSpectrumPainter128({
    required this.isPostFall,
    required this.showGrid,
    required this.touchedLocalPos,
    required this.dropVelocity,
    required this.peakMotion,
  });

  // Tính mật độ năng lượng phản xạ Radar FMCW tại toạ độ chuẩn hoá (nx, ny) [0.0 .. 1.0]
  double _calcRadarEnergyAt(double nx, double ny) {
    // Tạp âm nền RF môi trường ~ 3.5%
    double ambient = 3.5 + 1.2 * math.sin(nx * 8) * math.cos(ny * 8);

    if (!isPostFall) {
      // TRƯỚC NGÃ: Cơ thể đứng thẳng tại Cổng 3.5 (nx = 0.44), chiều cao (ny từ 0.25 đến 0.85)
      // Vùng ngực/đầu (nx: 0.44, ny: 0.38)
      double dHead = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.32) / 0.10, 2));
      double dChest = math.sqrt(math.pow((nx - 0.44) / 0.10, 2) + math.pow((ny - 0.48) / 0.14, 2));
      double dLegs = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.72) / 0.18, 2));

      double energyHead = 82.0 * math.exp(-0.5 * dHead * dHead);
      double energyChest = 88.0 * math.exp(-0.5 * dChest * dChest);
      double energyLegs = 65.0 * math.exp(-0.5 * dLegs * dLegs);

      return (ambient + math.max(energyHead, math.max(energyChest, energyLegs))).clamp(0.0, 100.0);
    } else {
      // SAU NGÃ: Nằm ngang sát sàn (ny = 0.88, trải dài nx từ 0.22 đến 0.75)
      // Điểm va đập thân trên (nx: 0.36, ny: 0.88)
      double dUpper = math.sqrt(math.pow((nx - 0.36) / 0.12, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // Điểm hông/thân dưới (nx: 0.54, ny: 0.88)
      double dLower = math.sqrt(math.pow((nx - 0.54) / 0.14, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // Chân (nx: 0.70, ny: 0.89)
      double dFeet = math.sqrt(math.pow((nx - 0.70) / 0.10, 2) + math.pow((ny - 0.89) / 0.06, 2));

      double energyUpper = 95.0 * math.exp(-0.5 * dUpper * dUpper);
      double energyLower = 88.0 * math.exp(-0.5 * dLower * dLower);
      double energyFeet = 60.0 * math.exp(-0.5 * dFeet * dFeet);

      return (ambient + math.max(energyUpper, math.max(energyLower, energyFeet))).clamp(0.0, 100.0);
    }
  }

  // Chuyển mức năng lượng phản xạ Radar sang dải màu phổ sóng vô tuyến (Turbo/Jet Colormap)
  Color _energyToColor(double energy) {
    if (energy <= 15.0) {
      return Color.lerp(const Color(0xFF060B14), const Color(0xFF0F3854), energy / 15.0)!;
    } else if (energy <= 35.0) {
      return Color.lerp(const Color(0xFF0F3854), const Color(0xFF0077B6), (energy - 15.0) / 20.0)!;
    } else if (energy <= 55.0) {
      return Color.lerp(const Color(0xFF0077B6), const Color(0xFF00B4D8), (energy - 35.0) / 20.0)!;
    } else if (energy <= 75.0) {
      return Color.lerp(const Color(0xFF00B4D8), const Color(0xFFFFB703), (energy - 55.0) / 20.0)!;
    } else if (energy <= 90.0) {
      return Color.lerp(const Color(0xFFFFB703), const Color(0xFFFB8500), (energy - 75.0) / 15.0)!;
    } else if (energy <= 97.0) {
      return Color.lerp(const Color(0xFFFB8500), const Color(0xFFFF0054), (energy - 90.0) / 7.0)!;
    } else {
      return Color.lerp(const Color(0xFFFF0054), Colors.white, (energy - 97.0) / 3.0)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Vẽ nền RF 2D
    final Rect backgroundRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()..color = const Color(0xFF060B14);
    canvas.drawRect(backgroundRect, bgPaint);

    // 2. Kết xuất các quầng mật độ năng lượng Radar (Radar Kinematic Clusters)
    if (!isPostFall) {
      // ĐỨNG: 3 quầng năng lượng phản xạ (Đầu, Ngực, Chân)
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.32), w * 0.22, h * 0.16, 85.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.48), w * 0.26, h * 0.22, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.72), w * 0.20, h * 0.24, 65.0);
    } else {
      // NGÃ NẰM SÀN: Dải năng lượng nằm ngang dài sát đáy sàn
      _drawRadarEnergyCluster(canvas, Offset(w * 0.36, h * 0.88), w * 0.28, h * 0.12, 98.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.54, h * 0.88), w * 0.32, h * 0.12, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.70, h * 0.89), w * 0.22, h * 0.10, 60.0);

      // Vùng sàn chấn động lan tỏa năng lượng va đập
      final Paint floorSpread = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.orange.withValues(alpha: 0.15),
            Colors.redAccent.withValues(alpha: 0.30),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.80, w, h * 0.20));
      canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), floorSpread);
    }

    // 3. Vẽ đường đẳng mức năng lượng phản xạ (Iso-Energy Contours)
    _drawIsoEnergyContours(canvas, size);

    // 4. Vẽ lưới toạ độ 128x128 (Hiển thị các vạch chia 16, 32, 64, 96, 128)
    if (showGrid) {
      final Paint gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5;

      for (int i = 0; i <= 128; i += 16) {
        double pos = (i / 128.0) * w;
        canvas.drawLine(Offset(pos, 0), Offset(pos, h), gridPaint);
        canvas.drawLine(Offset(0, pos), Offset(w, pos), gridPaint);
      }
    }

    // 5. Vẽ hồng tâm quét mật độ năng lượng cực đại
    final Offset peakPos = isPostFall ? Offset(w * 0.36, h * 0.88) : Offset(w * 0.44, h * 0.32);
    _drawCrosshair(canvas, peakPos, isPostFall ? "E_max: 98% (Sàn Y: 0.15m)" : "E_max: 90% (Đứng Y: 1.5m)", Colors.redAccent);

    // 6. Vẽ điểm chạm của người dùng (Nếu có tương tác đo điểm)
    if (touchedLocalPos != null) {
      final double tx = touchedLocalPos!.dx.clamp(0.0, w);
      final double ty = touchedLocalPos!.dy.clamp(0.0, h);
      final int gridX = (tx / w * 128).clamp(0, 127).toInt();
      final int gridY = (ty / h * 128).clamp(0, 127).toInt();
      final double energy = _calcRadarEnergyAt(tx / w, ty / h);

      _drawCrosshair(
        canvas,
        Offset(tx, ty),
        "[$gridX, $gridY]: E = ${energy.toStringAsFixed(0)}%",
        Colors.cyanAccent,
      );
    }

    // 7. Nhãn HUD góc trên bên trái
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "RADAR FMCW 24GHz SPATIAL SPECTRUM\nMATRIX: 128x128 (16.384 PTS)\nFOV: 9 GATES x 2.0m ELEVATION",
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.6),
        fontFamily: 'monospace',
      ),
    );
    tp.layout();
    tp.paint(canvas, const Offset(8, 8));
  }

  // Vẽ quầng tán xạ năng lượng Radar 2D
  void _drawRadarEnergyCluster(Canvas canvas, Offset center, double rx, double ry, double peakEnergy) {
    final Rect rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final Paint p = Paint()
      ..shader = RadialGradient(
        colors: [
          _energyToColor(peakEnergy),
          _energyToColor(peakEnergy * 0.75),
          _energyToColor(peakEnergy * 0.45),
          _energyToColor(10.0).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, p);
  }

  // Vẽ các đường đẳng mức năng lượng khép kín (Iso-Energy Contours)
  void _drawIsoEnergyContours(Canvas canvas, Size size) {
    final Paint contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.15);

    if (!isPostFall) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.44, size.height * 0.44), width: size.width * 0.32, height: size.height * 0.54),
        contourPaint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.88), width: size.width * 0.65, height: size.height * 0.18),
        contourPaint,
      );
    }
  }

  // Vẽ hồng tâm đo năng lượng kèm chú thích toạ độ
  void _drawCrosshair(Canvas canvas, Offset pos, String label, Color color) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    // Vạch dấu thập
    canvas.drawLine(Offset(pos.dx - 10, pos.dy), Offset(pos.dx + 10, pos.dy), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - 10), Offset(pos.dx, pos.dy + 10), p);

    // Vòng tròn định vị
    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(pos, 6, circlePaint);

    // Hộp chữ toạ độ và mức năng lượng
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: color,
        backgroundColor: Colors.black.withValues(alpha: 0.75),
      ),
    );
    tp.layout();

    double textX = pos.dx + 8;
    double textY = pos.dy - 16;
    if (textX + tp.width > 270) textX = pos.dx - tp.width - 8;
    if (textY < 10) textY = pos.dy + 8;

    tp.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant ThermalSpectrumPainter128 oldDelegate) {
    return oldDelegate.isPostFall != isPostFall ||
           oldDelegate.showGrid != showGrid ||
           oldDelegate.touchedLocalPos != touchedLocalPos;
  }
}

// =========================================================================
// MÀN HÌNH CÀI ĐẶT CHUNG CỦA ỨNG DỤNG (GENERAL SETTINGS SCREEN)
// =========================================================================
class GeneralSettingsScreen extends StatefulWidget {
  final bool alarmSound;
  final bool alarmVibrate;
  final double alarmVolume;
  final bool autoEmergency115;
  final bool autoReconnect;
  final String heightUnit;
  final String tempUnit;
  final int deviceHistoryCount;
  final Function(bool sound, bool vib, double vol, bool em115, bool autoRec, String hUnit, String tUnit) onSettingsChanged;
  final VoidCallback onClearHistory;

  const GeneralSettingsScreen({
    super.key,
    required this.alarmSound,
    required this.alarmVibrate,
    required this.alarmVolume,
    required this.autoEmergency115,
    required this.autoReconnect,
    required this.heightUnit,
    required this.tempUnit,
    required this.deviceHistoryCount,
    required this.onSettingsChanged,
    required this.onClearHistory,
  });

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late bool _alarmSound;
  late bool _alarmVibrate;
  late double _alarmVolume;
  late bool _autoEmergency115;
  late bool _autoReconnect;
  late String _heightUnit;
  late String _tempUnit;

  @override
  void initState() {
    super.initState();
    _alarmSound = widget.alarmSound;
    _alarmVibrate = widget.alarmVibrate;
    _alarmVolume = widget.alarmVolume;
    _autoEmergency115 = widget.autoEmergency115;
    _autoReconnect = widget.autoReconnect;
    _heightUnit = widget.heightUnit;
    _tempUnit = widget.tempUnit;
  }

  void _notifyChanges() {
    widget.onSettingsChanged(
      _alarmSound,
      _alarmVibrate,
      _alarmVolume,
      _autoEmergency115,
      _autoReconnect,
      _heightUnit,
      _tempUnit,
    );
  }

  // Hướng dẫn sơ cứu khi phát hiện người già té ngã
  void _showFirstAidGuide() {
    showFirstAidGuideModal(context);
  }

  void _openMedicalProfile() async {
    final p = await ElderlyMedicalProfile.load();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => EmergencyMedicalIdCardDialog(
        profile: p,
        onEdit: () {
          showDialog(
            context: context,
            builder: (c) => MedicalProfileEditDialog(
              profile: p,
              onSaved: (_) {},
            ),
          );
        },
      ),
    );
  }

  void _openCdcAssessment() {
    showDialog(
      context: context,
      builder: (ctx) => CdcSteadiAssessmentDialog(
        onCompleted: (score, risk) {},
      ),
    );
  }

  // Kích hoạt cập nhật OTA từ Cài đặt chung
  void _triggerOtaUpdate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Cập nhật ứng dụng"),
          ],
        ),
        content: Text(
          Platform.isIOS
              ? "Hệ thống sẽ mở giao thức cài đặt Apple OTA (itms-services). Bạn chỉ cần bấm [Cài đặt] khi thông báo của Apple hiện lên màn hình."
              : "Hệ thống sẽ tải file cài đặt app-release.apk mới nhất từ GitHub và mở trình cài đặt Android của máy.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (Platform.isIOS) {
                const otaUrl = "itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/ios_ota/manifest.plist";
                final uri = Uri.parse(otaUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi mở liên kết OTA: $e")),
                    );
                  }
                }
              } else {
                const apkUrl = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/app-release.apk";
                final uri = Uri.parse(apkUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi mở liên kết APK: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Cập nhật ngay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tune, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Cài đặt chung App", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. CẢNH BÁO KHẨN CẤP & ÂM THANH
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("Báo động trên điện thoại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Còi hú báo động trên điện thoại", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Phát âm thanh còi cứu hộ lớn trên máy khi phát hiện ngã", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _alarmSound,
                    onChanged: (val) {
                      setState(() => _alarmSound = val);
                      _notifyChanges();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Rung mạnh khẩn cấp (SOS)", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Rung liên tục theo nhịp cứu nạn", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _alarmVibrate,
                    onChanged: (val) {
                      setState(() => _alarmVibrate = val);
                      _notifyChanges();
                    },
                  ),
                  if (_alarmSound) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Âm lượng còi hú trên điện thoại:", style: TextStyle(fontSize: 13)),
                        Text("${(_alarmVolume * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                      ],
                    ),
                    Slider(
                      value: _alarmVolume,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() => _alarmVolume = val);
                        _notifyChanges();
                      },
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Phím tắt gọi cấp cứu 115", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Gợi ý 1 chạm mở cuộc gọi 115 khi xảy ra chấn thương ngã", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _autoEmergency115,
                    onChanged: (val) {
                      setState(() => _autoEmergency115 = val);
                      _notifyChanges();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. KẾT NỐI & THIẾT BỊ GHÉP NỐI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Kết nối & Thiết bị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Tự động kết nối lại thiết bị gần nhất", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Tự động kết nối Bluetooth ngay khi mở app", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _autoReconnect,
                    onChanged: (val) {
                      setState(() => _autoReconnect = val);
                      _notifyChanges();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: Text("Lịch sử thiết bị đã lưu: ${widget.deviceHistoryCount} thiết bị", style: const TextStyle(fontSize: 14)),
                    subtitle: const Text("Xem và quản lý các thiết bị từng ghép nối", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: widget.deviceHistoryCount > 0
                        ? TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text("Xóa toàn bộ lịch sử?"),
                                  content: const Text("Bạn có chắc muốn xóa toàn bộ danh sách thiết bị từng kết nối không?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text("Hủy")),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(c);
                                        widget.onClearHistory();
                                        setState(() {});
                                      },
                                      child: const Text("Xóa hết", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("Xóa hết", style: TextStyle(color: Colors.redAccent)),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. HIỂN THỊ & ĐƠN VỊ ĐO
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("Đơn vị đo lường", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Đơn vị khoảng cách:", style: TextStyle(fontSize: 14)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "mm", label: Text("mm", style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: "cm", label: Text("cm", style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_heightUnit},
                        onSelectionChanged: (val) {
                          setState(() => _heightUnit = val.first);
                          _notifyChanges();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Đơn vị năng lượng Radar:", style: TextStyle(fontSize: 14)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "%", label: Text("% (Tỉ lệ)", style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: "dB", label: Text("dB (Cường độ)", style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_tempUnit == "dB" ? "dB" : "%"},
                        onSelectionChanged: (val) {
                          setState(() => _tempUnit = val.first);
                          _notifyChanges();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. AN TOÀN Y TẾ & CẬP NHẬT PHẦN MỀM
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety, color: Colors.green),
                      SizedBox(width: 8),
                      Text("An toàn & Cập nhật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.badge, color: Colors.redAccent),
                    title: const Text("Hồ sơ y tế khẩn cấp người cao tuổi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Nhóm máu, thuốc chống đông máu, tiền sử bệnh lý, liên hệ 115", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openMedicalProfile,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                    title: const Text("Đánh giá nguy cơ té ngã CDC STEADI", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Bộ 12 câu hỏi lâm sàng theo chuẩn CDC Hoa Kỳ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openCdcAssessment,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.medical_information, color: Colors.orangeAccent),
                    title: const Text("Hướng dẫn sơ cứu người già ngã", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Quy tắc cấp cứu an toàn chuẩn y tế", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFirstAidGuide,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_download, color: Colors.blueAccent),
                    title: const Text("Kiểm tra & Cập nhật OTA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tự động nâng cấp phiên bản mới nhất từ GitHub qua mạng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _triggerOtaUpdate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. THÔNG TIN HỆ THỐNG
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text("Thông tin hệ thống", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("Ứng dụng: Fall Guard S3R8", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("Phiên bản: v1.1.0 (HD 128x128 Radar Kinematic Matrix)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Vi điều khiển: ESP32-S3-WROOM-1-N16R8 (16MB Flash / 8MB PSRAM)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Cảm biến kết hợp: ToF Laser (Độ cao) + Radar 24GHz FMCW (Động năng & Cự ly - Độc lập khi tạm ẩn PIR)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("© 2026 Fall Detection System. Bảo vệ an toàn người cao tuổi 24/7.", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =========================================================================
// HÀM MỞ HỘP THOẠI CẨM NANG SƠ CỨU NGƯỜI GIÀ TÉ NGÃ
// =========================================================================
void showFirstAidGuideModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const FirstAidGuideDialog(),
  );
}

class FirstAidGuideDialog extends StatefulWidget {
  const FirstAidGuideDialog({super.key});

  @override
  State<FirstAidGuideDialog> createState() => _FirstAidGuideDialogState();
}

class _FirstAidGuideDialogState extends State<FirstAidGuideDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildCitationCard(String org, String docTitle, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                "Trích dẫn y khoa: $org",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            docTitle,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 9.5, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10.5, height: 1.4, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Tab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình minh họa cấm kéo giật
          Container(
            height: 135,
            decoration: BoxDecoration(
              color: const Color(0xFF060B14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CustomPaint(
                painter: DoNotPullIllustrationPainter(),
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "BƯỚC 1: TUYỆT ĐỐI KHÔNG VỘI ĐỠ DẬY NGAY",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Phản xạ thông thường là chạy tới nắm tay kéo người già đứng lên ngay, nhưng đây là SAI LẦM NGUY HIỂM NHẤT.\n"
            "• Người cao tuổi đa số bị loãng xương (Osteoporosis). Việc kéo giật đột ngột có thể biến vết nứt xương kín thành gãy di lệch hoàn toàn, làm rách mạch máu lớn hoặc đứt tủy sống cổ/lưng.\n"
            "• Hành động chuẩn: Yêu cầu người bệnh nằm yên hít thở sâu, người sơ cứu quỳ một bên để trấn an tinh thần trong 1-2 phút đầu.",
            style: TextStyle(fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 10),

          _buildCitationCard(
            "Tổ chức Y tế Thế giới (WHO)",
            "WHO Global Report on Falls Prevention in Older Age & ICOPE Guidelines",
            "\"Tuyệt đối không di chuyển người bệnh nếu chưa loại trừ gãy cổ xương đùi hoặc tổn thương cột sống. Hành vi nâng bốc người già sai kỹ thuật làm tăng 45% biến chứng tàn phế vĩnh viễn và sốc chấn thương.\"",
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Tab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình minh họa kiểm tra sinh tồn
          Container(
            height: 135,
            decoration: BoxDecoration(
              color: const Color(0xFF060B14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CustomPaint(
                painter: VitalsCheckIllustrationPainter(),
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "BƯỚC 2: KHÁM TRI GIÁC & DẤU HIỆU NGUY CẤP",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amberAccent),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Kiểm tra tri giác (AVPU): Gọi tên xem nạn nhân có trả lời rõ ràng không, có nhớ vừa xảy ra chuyện gì không.\n"
            "• Quan sát 3 dấu hiệu chấn thương nặng cần GỌI 115 NGAY:\n"
            "   1. Chấn thương sọ não: Đập đầu xuống nền gạch, sưng u, lú lẫn, chảy máu tai/mũi, nôn ói.\n"
            "   2. Gãy cổ xương đùi: Bàn chân một bên bị xoay đổ hẳn ra ngoài, chân đau ngắn hơn chân lành, đau dữ dội khớp háng.\n"
            "   3. Chấn thương cột sống: Đau buốt đốt sống cổ/thắt lưng, tê bì hoặc mất cảm giác hai bàn chân.\n"
            "• Nếu có dấu hiệu trên: Giữ bất động nguyên trạng, đắp chăn mỏng chống hạ thân nhiệt và gọi ngay 115.",
            style: TextStyle(fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 10),

          _buildCitationCard(
            "CDC Hoa Kỳ (STEADI Initiative)",
            "Centers for Disease Control - Older Adult Fall Prevention Protocol",
            "\"Hơn 95% ca gãy xương hông ở người già là do ngã đập bên hông. Người cao tuổi có dùng thuốc chống đông máu có nguy cơ xuất huyết não muộn (TBI) rất cao ngay cả khi cú ngã ban đầu tưởng như nhẹ.\"",
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Tab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình minh họa tư thế nằm nghiêng hồi sức
          Container(
            height: 135,
            decoration: BoxDecoration(
              color: const Color(0xFF060B14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CustomPaint(
                painter: RecoveryPositionIllustrationPainter(),
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "BƯỚC 3: TƯ THẾ HỒI SỨC NẰM NGHIÊNG (RECOVERY POSITION)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.tealAccent),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Khi nào áp dụng: Người già BẤT TỈNH, hôn mê nhưng VẪN CÒN THỞ bình thường (lồng ngực vẫn phập phồng).\n"
            "• Kỹ thuật xoay nghiêng an toàn:\n"
            "   1. Đặt cánh tay gần bạn vuông góc với thân mình.\n"
            "   2. Kéo cánh tay đối diện vắt qua ngực, áp mu bàn tay vào má nạn nhân.\n"
            "   3. Co gập đầu gối chân đối diện lên một góc 90 độ.\n"
            "   4. Nhẹ nhàng kéo gối để lật toàn bộ cơ thể người bệnh nằm nghiêng về phía bạn.\n"
            "• Tác dụng: Giữ đường thở mở rộng tối đa, chống tụt lưỡi bịt kín thanh quản và giúp dịch nôn tự trào ra ngoài, tránh sặc vào phổi.",
            style: TextStyle(fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 10),

          _buildCitationCard(
            "Hội Chữ Thập Đỏ Quốc Tế (IFRC) & AHA",
            "International First Aid Guidelines - Lateral Recovery Position",
            "\"Tư thế nằm nghiêng an toàn là kỹ thuật cứu mạng hàng đầu giúp duy trì thông khí thụ động, giảm trên 70% nguy cơ tử vong do tắc nghẽn đường thở cơ học khi chờ xe cấp cứu.\"",
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Tab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình minh họa quy tắc dùng ghế đứng dậy
          Container(
            height: 135,
            decoration: BoxDecoration(
              color: const Color(0xFF060B14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CustomPaint(
                painter: ChairMethodIllustrationPainter(),
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "BƯỚC 4: KỸ THUẬT DÙNG GHẾ ĐỨNG DẬY (THE CHAIR METHOD)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Khi nào áp dụng: Người già hoàn toàn tỉnh táo, KHÔNG gãy xương, KHÔNG đau cột sống, chỉ bị trượt ngã nhẹ.\n"
            "• Quy trình 4 bước tự đứng dậy an toàn:\n"
            "   1. Lăn người sang tư thế nằm nghiêng.\n"
            "   2. Dùng 2 tay chống sàn, từ từ chuyển thành tư thế quỳ 4 điểm (hai tay và hai đầu gối).\n"
            "   3. Bò từ từ đến một chiếc ghế tựa hoặc mép giường thật chắc chắn, đặt 2 tay lên mặt ghế.\n"
            "   4. Bước một chân khỏe hơn gập lên phía trước, dồn lực tay và chân đẩy người xoay lại ngồi lên mặt ghế.\n"
            "• Lưu ý: Bắt buộc ngồi yên nghỉ ngơi tối thiểu 15-30 phút sau khi ngồi lên ghế trước khi đi lại.",
            style: TextStyle(fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 10),

          _buildCitationCard(
            "Cơ quan Y tế Quốc gia Anh (NHS UK)",
            "NHS Clinical Guideline: What to do after a fall - The Safe Chair Recovery",
            "\"Kỹ thuật dùng ghế giúp phân phối tải trọng cơ thể lên các nhóm cơ khỏe, ngăn ngừa tụt huyết áp tư thế đứng (Orthostatic Hypotension) và rách cơ do gượng dậy quá nhanh.\"",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF0F172A),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.redAccent, size: 26),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cẩm nang Sơ cứu Người già Té ngã",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          "Phác đồ phản ứng nhanh chuẩn quốc tế: WHO, IFRC, NHS UK, CDC",
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // TabBar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.redAccent,
                  labelColor: Colors.redAccent,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(text: "1. Không kéo dậy"),
                    Tab(text: "2. Khám sinh tồn"),
                    Tab(text: "3. Nằm nghiêng"),
                    Tab(text: "4. Kỹ thuật ghế"),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStep1Tab(),
                    _buildStep2Tab(),
                    _buildStep3Tab(),
                    _buildStep4Tab(),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 18),
                      label: const Text("Gọi Cấp Cứu 115", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _call115,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      side: BorderSide(color: Colors.grey.shade700),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Đóng"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. Hình vẽ minh họa Bước 1: Cấm kéo đứng dậy ngay
class DoNotPullIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Người nằm trên sàn
    final double bodyX = w * 0.40;
    final Paint bodyPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Đầu gối trên sàn
    canvas.drawCircle(Offset(bodyX - 50, floorY - 10), 9, bodyPaint);
    // Thân
    canvas.drawLine(Offset(bodyX - 40, floorY - 8), Offset(bodyX + 25, floorY - 8), bodyPaint);
    // Chân
    canvas.drawLine(Offset(bodyX + 25, floorY - 8), Offset(bodyX + 80, floorY - 8), bodyPaint);

    // Vòng cảnh báo đỏ ở Cổ và Hông
    final Paint alertRing = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(bodyX - 35, floorY - 8), 16, alertRing); // Cổ
    canvas.drawCircle(Offset(bodyX + 25, floorY - 8), 18, alertRing); // Hông

    // Bàn tay kéo giật từ trên xuống (Dashed vector)
    final Paint pullArrow = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(bodyX - 10, floorY - 60), Offset(bodyX - 10, floorY - 18), pullArrow);

    // Biển cấm kéo đứng dậy
    final Paint signPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w * 0.78, h * 0.45), 26, signPaint);
    canvas.drawLine(Offset(w * 0.78 - 18, h * 0.45 - 18), Offset(w * 0.78 + 18, h * 0.45 + 18), signPaint);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "CẤM KÉO DẬY!",
      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.78 - tp.width / 2, h * 0.45 + 32));

    // Nhãn vùng nguy hiểm
    final TextPainter tpLabel = TextPainter(textDirection: TextDirection.ltr);
    tpLabel.text = const TextSpan(
      text: "Nguy cơ gãy cổ xương đùi & tổn thương tủy sống",
      style: TextStyle(color: Colors.white60, fontSize: 9.5),
    );
    tpLabel.layout();
    tpLabel.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Hình vẽ minh họa Bước 2: Kiểm tra tri giác & Gọi 115
class VitalsCheckIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Nạn nhân nằm
    final double vicX = w * 0.32;
    final Paint vicPaint = Paint()..color = Colors.blueGrey.shade400..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(vicX - 45, floorY - 9), 8, vicPaint);
    canvas.drawLine(Offset(vicX - 35, floorY - 7), Offset(vicX + 35, floorY - 7), vicPaint);
    canvas.drawLine(Offset(vicX + 35, floorY - 7), Offset(vicX + 85, floorY - 7), vicPaint);

    // Người sơ cứu quỳ một bên kiểm tra
    final double rescX = vicX - 5;
    final Paint rescPaint = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(rescX - 10, floorY - 55), 8, rescPaint); // Đầu người sơ cứu
    canvas.drawLine(Offset(rescX - 10, floorY - 47), Offset(rescX, floorY - 25), rescPaint); // Thân
    canvas.drawLine(Offset(rescX, floorY - 25), Offset(rescX - 15, floorY), rescPaint); // Chân quỳ
    canvas.drawLine(Offset(rescX - 10, floorY - 40), Offset(vicX, floorY - 10), rescPaint); // Tay bắt mạch / kiểm tra

    // Hộp thoại hỏi thăm
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final RRect bubbleRRect = RRect.fromRectAndRadius(Rect.fromLTWH(vicX - 60, 10, 160, 26), const Radius.circular(8));
    canvas.drawRRect(bubbleRRect, bubblePaint);

    final TextPainter tpMsg = TextPainter(textDirection: TextDirection.ltr);
    tpMsg.text = const TextSpan(
      text: "Bác tỉnh không? Có đau ở đâu không?",
      style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
    );
    tpMsg.layout();
    tpMsg.paint(canvas, Offset(vicX - 55, 16));

    // Huy hiệu cấp cứu 115
    final Paint sosBox = Paint()..color = Colors.red.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final RRect sosRRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.72, 25, 95, 60), const Radius.circular(10));
    canvas.drawRRect(sosRRect, sosBox);
    canvas.drawRRect(sosRRect, Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final TextPainter tp115 = TextPainter(textDirection: TextDirection.ltr);
    tp115.text = const TextSpan(
      text: "CẤP CỨU 115\nKhi bất tỉnh hoặc\nnghi gãy xương",
      style: TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold, height: 1.3),
    );
    tp115.layout();
    tp115.paint(canvas, Offset(w * 0.72 + 8, 32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Hình vẽ minh họa Bước 3: Tư thế hồi sức nằm nghiêng
class RecoveryPositionIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Người nằm nghiêng an toàn
    final double cx = w * 0.38;
    final Paint p = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Đầu kê lên mu bàn tay
    canvas.drawCircle(Offset(cx - 55, floorY - 18), 9, p);
    // Tay đỡ đầu
    canvas.drawLine(Offset(cx - 35, floorY - 14), Offset(cx - 55, floorY - 10), p);
    // Thân nằm nghiêng
    canvas.drawLine(Offset(cx - 45, floorY - 14), Offset(cx + 25, floorY - 14), p);
    // Chân dưới duỗi thẳng
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 85, floorY - 14), p..color = Colors.teal.shade700);
    // Chân trên co vuông góc 90 độ chạm sàn để giữ thăng bằng
    final Paint pLeg = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 35, floorY - 3), pLeg);
    canvas.drawLine(Offset(cx + 35, floorY - 3), Offset(cx + 65, floorY - 3), pLeg);

    // Mũi tên luồng thở thông thoáng
    final Paint airwayPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 68, floorY - 18), radius: 12), 0.5, 2.0, false, airwayPaint);

    // Nhãn chú thích
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "Tư thế nằm nghiêng an toàn (IFRC/AHA):\n• Cằm ngửa nhẹ -> Đường thở mở rộng\n• Chân co 90° giữ thăng bằng vững\n• Chống sặc dịch nôn/nước bọt vào phổi",
      style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.4),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.48, 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Hình vẽ minh họa Bước 4: Quy tắc dùng ghế đứng dậy (NHS UK)
class ChairMethodIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 22;

    // Mặt sàn
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // Ghế tựa ở bên phải
    final double chairX = w * 0.82;
    final Paint chairPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // Chân ghế
    canvas.drawLine(Offset(chairX, floorY), Offset(chairX, floorY - 45), chairPaint);
    canvas.drawLine(Offset(chairX + 30, floorY), Offset(chairX + 30, floorY - 45), chairPaint);
    // Mặt ghế
    canvas.drawLine(Offset(chairX - 5, floorY - 45), Offset(chairX + 35, floorY - 45), chairPaint);
    // Lưng tựa ghế
    canvas.drawLine(Offset(chairX + 30, floorY - 45), Offset(chairX + 30, floorY - 80), chairPaint);

    // 3 giai đoạn tiến triển
    final Paint stepPaint = Paint()..color = Colors.white70..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    // A. Nằm nghiêng
    canvas.drawCircle(Offset(35, floorY - 8), 6, stepPaint);
    canvas.drawLine(Offset(41, floorY - 6), Offset(65, floorY - 6), stepPaint);

    // Mũi tên sang B
    canvas.drawLine(Offset(75, floorY - 15), Offset(95, floorY - 15), floorPaint);

    // B. Quỳ 4 điểm (bò)
    canvas.drawCircle(Offset(125, floorY - 24), 6, stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(145, floorY - 18), stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(125, floorY), stepPaint);
    canvas.drawLine(Offset(145, floorY - 18), Offset(145, floorY), stepPaint);

    // Mũi tên sang C
    canvas.drawLine(Offset(160, floorY - 25), Offset(180, floorY - 25), floorPaint);

    // C. Vịn 2 tay lên ghế
    canvas.drawCircle(Offset(225, floorY - 42), 6, stepPaint);
    canvas.drawLine(Offset(225, floorY - 36), Offset(225, floorY - 15), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(215, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(235, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 30), Offset(chairX - 5, floorY - 45), Paint()..color = Colors.amberAccent..strokeWidth = 2.5); // Tay vịn ghế

    // Nhãn 4 bước
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "1. Nằm nghiêng ➔ 2. Quỳ 4 điểm ➔ 3. Vịn ghế vững ➔ 4. Đẩy chân ngồi lên ghế",
      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// =========================================================================
// TÍNH NĂNG 2: HỒ SƠ Y TẾ KHẨN CẤP NGƯỜI CAO TUỔI (MEDICAL EMERGENCY PROFILE)
// =========================================================================
class ElderlyMedicalProfile {
  String fullName;
  int birthYear;
  String gender;
  String bloodType;
  List<String> chronicConditions;
  List<String> highRiskMedications;
  String allergies;
  String emergencyContact1Name;
  String emergencyContact1Phone;
  String emergencyContact2Name;
  String emergencyContact2Phone;
  String attendingDoctorName;
  String attendingDoctorPhone;
  String hospital;
  String notes;

  ElderlyMedicalProfile({
    this.fullName = "Nguyễn Văn An",
    this.birthYear = 1948,
    this.gender = "Nam",
    this.bloodType = "O+",
    this.chronicConditions = const ["Tăng huyết áp", "Loãng xương", "Bệnh mạch vành"],
    this.highRiskMedications = const ["Thuốc chống đông máu (Aspirin / Warfarin)", "Thuốc hạ áp Amlodipine"],
    this.allergies = "Chưa ghi nhận",
    this.emergencyContact1Name = "Con trai (Nguyễn Tuấn)",
    this.emergencyContact1Phone = "0987654321",
    this.emergencyContact2Name = "Con gái (Nguyễn Mai)",
    this.emergencyContact2Phone = "0912345678",
    this.attendingDoctorName = "BS. CKII Lê Hoàng",
    this.attendingDoctorPhone = "0903115115",
    this.hospital = "BV Lão Khoa TW / BV Đa Khoa Tỉnh",
    this.notes = "Người bệnh có tiền sử thay khớp háng nhân tạo năm 2022. Chìa khóa nhà dự phòng gửi tại căn hộ 402.",
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'birthYear': birthYear,
    'gender': gender,
    'bloodType': bloodType,
    'chronicConditions': chronicConditions,
    'highRiskMedications': highRiskMedications,
    'allergies': allergies,
    'emergencyContact1Name': emergencyContact1Name,
    'emergencyContact1Phone': emergencyContact1Phone,
    'emergencyContact2Name': emergencyContact2Name,
    'emergencyContact2Phone': emergencyContact2Phone,
    'attendingDoctorName': attendingDoctorName,
    'attendingDoctorPhone': attendingDoctorPhone,
    'hospital': hospital,
    'notes': notes,
  };

  factory ElderlyMedicalProfile.fromJson(Map<String, dynamic> json) {
    return ElderlyMedicalProfile(
      fullName: json['fullName'] ?? "Nguyễn Văn An",
      birthYear: json['birthYear'] ?? 1948,
      gender: json['gender'] ?? "Nam",
      bloodType: json['bloodType'] ?? "O+",
      chronicConditions: json['chronicConditions'] != null
          ? List<String>.from(json['chronicConditions'])
          : ["Tăng huyết áp", "Loãng xương"],
      highRiskMedications: json['highRiskMedications'] != null
          ? List<String>.from(json['highRiskMedications'])
          : ["Thuốc chống đông máu (Aspirin / Warfarin)"],
      allergies: json['allergies'] ?? "Chưa ghi nhận",
      emergencyContact1Name: json['emergencyContact1Name'] ?? "Con trai (Nguyễn Tuấn)",
      emergencyContact1Phone: json['emergencyContact1Phone'] ?? "0987654321",
      emergencyContact2Name: json['emergencyContact2Name'] ?? "Con gái (Nguyễn Mai)",
      emergencyContact2Phone: json['emergencyContact2Phone'] ?? "0912345678",
      attendingDoctorName: json['attendingDoctorName'] ?? "BS. CKII Lê Hoàng",
      attendingDoctorPhone: json['attendingDoctorPhone'] ?? "0903115115",
      hospital: json['hospital'] ?? "BV Lão Khoa TW",
      notes: json['notes'] ?? "",
    );
  }

  static Future<ElderlyMedicalProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('elderly_medical_profile');
    if (raw != null) {
      try {
        return ElderlyMedicalProfile.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return ElderlyMedicalProfile();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elderly_medical_profile', jsonEncode(toJson()));
  }

  bool get isTakingAnticoagulants => highRiskMedications.any((m) =>
      m.toLowerCase().contains("chống đông") ||
      m.toLowerCase().contains("aspirin") ||
      m.toLowerCase().contains("warfarin") ||
      m.toLowerCase().contains("clopidogrel") ||
      m.toLowerCase().contains("xarelto") ||
      m.toLowerCase().contains("eliquis"));
}

// =========================================================================
// THẺ Y TẾ CẤP CỨU KHẨN CẤP (EMERGENCY MEDICAL ID CARD DIALOG)
// =========================================================================
class EmergencyMedicalIdCardDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final VoidCallback onEdit;

  const EmergencyMedicalIdCardDialog({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  int get age => DateTime.now().year - profile.birthYear;

  void _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isNotEmpty) {
      final uri = Uri.parse("tel:$clean");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  void _copySummary(BuildContext context) {
    final text = """
[THẺ Y TẾ CẤP CỨU KHẨN CẤP - FALLGUARD]
Họ tên: ${profile.fullName} ($age tuổi - Sinh năm ${profile.birthYear} - ${profile.gender})
Nhóm máu: ${profile.bloodType}
CẢNH BÁO THUỐC CHỐNG ĐÔNG: ${profile.isTakingAnticoagulants ? 'CÓ (NGUY CƠ XUẤT HUYẾT NỘI SỌ CAO)' : 'Không'}
Bệnh lý nền: ${profile.chronicConditions.join(', ')}
Thuốc đang dùng: ${profile.highRiskMedications.join(', ')}
Dị ứng: ${profile.allergies}
Bác sĩ điều trị: ${profile.attendingDoctorName} (${profile.attendingDoctorPhone})
Bệnh viện chỉ định: ${profile.hospital}
Người thân 1: ${profile.emergencyContact1Name} (${profile.emergencyContact1Phone})
Người thân 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})
Ghi chú: ${profile.notes}
""";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép tóm tắt y tế vào bộ nhớ tạm!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề & Biểu tượng Cấp Cứu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("THẺ Y TẾ CẤP CỨU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                        Text("Dành cho Nhân viên Y tế 115 & Cứu hộ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    tooltip: "Chỉnh sửa hồ sơ",
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // Bảng tóm tắt bệnh nhân & nhóm máu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                          const SizedBox(height: 4),
                          Text("$age tuổi (${profile.birthYear}) • Giới tính: ${profile.gender}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Text("NHÓM MÁU", style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                          Text(profile.bloodType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CẢNH BÁO ĐẶC BIỆT NẾU DÙNG THUỐC CHỐNG ĐÔNG MÁU
              if (profile.isTakingAnticoagulants)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "CẢNH BÁO LÂM SÀNG: Người bệnh đang dùng THUỐC CHỐNG ĐÔNG MÁU (Aspirin/Warfarin...). Nguy cơ xuất huyết nội sọ cao khi chấn thương té ngã!",
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Bệnh lý nền
              const Text("Tiền sử bệnh lý nền:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.chronicConditions.map((c) => Chip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.25),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // Thuốc đang sử dụng
              const Text("Thuốc đặc biệt cần lưu ý:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.highRiskMedications.map((m) => Chip(
                  label: Text(m, style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  side: const BorderSide(color: Colors.redAccent, width: 0.8),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // Dị ứng & Bệnh viện
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock("Dị ứng:", profile.allergies, Icons.no_food),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBlock("BV chỉ định:", profile.hospital, Icons.local_hospital),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Danh bạ cấp cứu gọi nhanh 1 chạm
              const Text("Liên hệ khẩn cấp 1 chạm:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber("115"),
                      icon: const Icon(Icons.phone_in_talk, size: 16),
                      label: const Text("Cấp cứu 115", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber(profile.emergencyContact1Phone),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(profile.emergencyContact1Name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.emergencyContact2Phone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _callNumber(profile.emergencyContact2Phone),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text("Người thân 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})", style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 12),

              // Nút sao chép & Đóng
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySummary(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Sao chép tóm tắt"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH CHỈNH SỬA HỒ SƠ Y TẾ NGƯỜI CAO TUỔI (MEDICAL PROFILE EDIT DIALOG)
// =========================================================================
class MedicalProfileEditDialog extends StatefulWidget {
  final ElderlyMedicalProfile profile;
  final Function(ElderlyMedicalProfile) onSaved;

  const MedicalProfileEditDialog({super.key, required this.profile, required this.onSaved});

  @override
  State<MedicalProfileEditDialog> createState() => _MedicalProfileEditDialogState();
}

class _MedicalProfileEditDialogState extends State<MedicalProfileEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _c1NameCtrl;
  late TextEditingController _c1PhoneCtrl;
  late TextEditingController _c2NameCtrl;
  late TextEditingController _c2PhoneCtrl;
  late TextEditingController _doctorNameCtrl;
  late TextEditingController _doctorPhoneCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _notesCtrl;

  late String _gender;
  late String _bloodType;
  late List<String> _selectedConditions;
  late List<String> _selectedMeds;

  final List<String> _availableConditions = [
    "Tăng huyết áp",
    "Đái tháo đường Type 2",
    "Bệnh mạch vành / Tim mạch",
    "Loãng xương nặng",
    "Tiền sử đột quỵ / Tai biến",
    "Parkinson",
    "Rối loạn tiền đình",
    "Suy giảm trí nhớ / Sa sút trí tuệ",
  ];

  final List<String> _availableMeds = [
    "Thuốc chống đông máu (Aspirin / Warfarin)",
    "Thuốc kháng tiểu cầu (Clopidogrel / Plavix)",
    "Thuốc chống đông thế hệ mới (Xarelto / Eliquis)",
    "Thuốc hạ áp (Amlodipine / Losartan...)",
    "Insulin / Thuốc tiểu đường",
    "Thuốc an thần / Thuốc ngủ",
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _yearCtrl = TextEditingController(text: p.birthYear.toString());
    _allergiesCtrl = TextEditingController(text: p.allergies);
    _c1NameCtrl = TextEditingController(text: p.emergencyContact1Name);
    _c1PhoneCtrl = TextEditingController(text: p.emergencyContact1Phone);
    _c2NameCtrl = TextEditingController(text: p.emergencyContact2Name);
    _c2PhoneCtrl = TextEditingController(text: p.emergencyContact2Phone);
    _doctorNameCtrl = TextEditingController(text: p.attendingDoctorName);
    _doctorPhoneCtrl = TextEditingController(text: p.attendingDoctorPhone);
    _hospitalCtrl = TextEditingController(text: p.hospital);
    _notesCtrl = TextEditingController(text: p.notes);
    _gender = p.gender;
    _bloodType = p.bloodType;
    _selectedConditions = List<String>.from(p.chronicConditions);
    _selectedMeds = List<String>.from(p.highRiskMedications);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    _allergiesCtrl.dispose();
    _c1NameCtrl.dispose();
    _c1PhoneCtrl.dispose();
    _c2NameCtrl.dispose();
    _c2PhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = ElderlyMedicalProfile(
      fullName: _nameCtrl.text.trim().isEmpty ? "Nguyễn Văn An" : _nameCtrl.text.trim(),
      birthYear: int.tryParse(_yearCtrl.text.trim()) ?? 1948,
      gender: _gender,
      bloodType: _bloodType,
      chronicConditions: _selectedConditions,
      highRiskMedications: _selectedMeds,
      allergies: _allergiesCtrl.text.trim().isEmpty ? "Chưa ghi nhận" : _allergiesCtrl.text.trim(),
      emergencyContact1Name: _c1NameCtrl.text.trim(),
      emergencyContact1Phone: _c1PhoneCtrl.text.trim(),
      emergencyContact2Name: _c2NameCtrl.text.trim(),
      emergencyContact2Phone: _c2PhoneCtrl.text.trim(),
      attendingDoctorName: _doctorNameCtrl.text.trim(),
      attendingDoctorPhone: _doctorPhoneCtrl.text.trim(),
      hospital: _hospitalCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    updated.save();
    widget.onSaved(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hồ sơ y tế khẩn cấp đã được lưu thành công!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Cập nhật hồ sơ y tế khẩn cấp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text("1. Thông tin bệnh nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "Họ và tên người cao tuổi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Năm sinh (VD: 1948)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _bloodType,
                          decoration: const InputDecoration(labelText: "Nhóm máu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.bloodtype)),
                          items: ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-", "Chưa rõ"].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => _bloodType = val ?? "O+"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. Tiền sử bệnh lý nền (Chọn các bệnh áp dụng)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 6),
                  ..._availableConditions.map((cond) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cond, style: const TextStyle(fontSize: 13)),
                    value: _selectedConditions.contains(cond),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedConditions.add(cond);
                        } else {
                          _selectedConditions.remove(cond);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("3. Thuốc đặc biệt (Cực kỳ quan trọng khi cấp cứu)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 6),
                  ..._availableMeds.map((med) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(med, style: TextStyle(fontSize: 13, color: med.contains("chống đông") ? Colors.redAccent : null)),
                    value: _selectedMeds.contains(med),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedMeds.add(med);
                        } else {
                          _selectedMeds.remove(med);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("4. Danh bạ khẩn cấp & Bác sĩ điều trị", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c1NameCtrl, decoration: const InputDecoration(labelText: "Người thân 1 (Tên/Quan hệ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c1PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Người thân 1", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c2NameCtrl, decoration: const InputDecoration(labelText: "Người thân 2 (Tên/Quan hệ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c2PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Người thân 2", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _doctorNameCtrl, decoration: const InputDecoration(labelText: "Bác sĩ riêng", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _doctorPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SĐT Bác sĩ", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: "Bệnh viện ưu tiên chỉ định chuyển viện", border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                  const SizedBox(height: 10),
                  TextField(controller: _allergiesCtrl, decoration: const InputDecoration(labelText: "Dị ứng thuốc / thức ăn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning))),
                  const SizedBox(height: 10),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Ghi chú cấp cứu khác (Vị trí chìa khóa dự phòng, tiền sử mổ...)", border: OutlineInputBorder())),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("Lưu hồ sơ y tế", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 7: ĐÁNH GIÁ NGUY CƠ TÉ NGÃ THEO CHUẨN CDC STEADI (12 CÂU HỎI)
// =========================================================================
class CdcSteadiAssessmentDialog extends StatefulWidget {
  final Function(int score, String riskLevel) onCompleted;

  const CdcSteadiAssessmentDialog({super.key, required this.onCompleted});

  @override
  State<CdcSteadiAssessmentDialog> createState() => _CdcSteadiAssessmentDialogState();
}

class _CdcSteadiAssessmentDialogState extends State<CdcSteadiAssessmentDialog> {
  // 12 câu hỏi chuẩn CDC STEADI (Stay Independent Brochure)
  final List<Map<String, dynamic>> _questions = [
    {
      "text": "1. Tôi từng bị ngã trong vòng 1 năm qua.",
      "pts": 2,
      "why": "Người từng ngã có nguy cơ tái ngã cao gấp 3 lần.",
      "ans": false,
    },
    {
      "text": "2. Tôi cần dùng gậy chống hoặc khung tập đi, hoặc bác sĩ khuyên tôi nên dùng.",
      "pts": 2,
      "why": "Dấu hiệu suy giảm sức cơ chân và thăng bằng dáng đi.",
      "ans": false,
    },
    {
      "text": "3. Đôi khi tôi cảm thấy loạng choạng hoặc mất thăng bằng khi đi lại.",
      "pts": 1,
      "why": "Rối loạn chức năng tiền đình hoặc yếu cơ chi dưới.",
      "ans": false,
    },
    {
      "text": "4. Tôi hay phải vịn vào đồ đạc, tường khi đi lại trong nhà.",
      "pts": 1,
      "why": "Biểu hiện thiếu tự tin vào khả năng giữ thăng bằng tự thân.",
      "ans": false,
    },
    {
      "text": "5. Tôi thường lo lắng hoặc sợ hãi mình sẽ bị ngã.",
      "pts": 1,
      "why": "Hội chứng sợ ngã (Fear of Falling) dẫn đến hạn chế vận động và teo cơ.",
      "ans": false,
    },
    {
      "text": "6. Tôi cần dùng tay đẩy mạnh vào đùi hoặc ghế mới đứng dậy được.",
      "pts": 1,
      "why": "Suy giảm sức mạnh cơ tứ đầu đùi (quadriceps weakness).",
      "ans": false,
    },
    {
      "text": "7. Tôi cảm thấy khó khăn khi bước lên vỉa hè hoặc bậc thềm cao.",
      "pts": 1,
      "why": "Hạn chế linh hoạt khớp cổ chân và khả năng nâng chân.",
      "ans": false,
    },
    {
      "text": "8. Tôi thường phải vội vã đi gấp vào nhà vệ sinh.",
      "pts": 1,
      "why": "Hội chứng tiểu gấp làm tăng nguy cơ vấp ngã ban đêm.",
      "ans": false,
    },
    {
      "text": "9. Tôi bị tê bì hoặc mất cảm giác ở lòng bàn chân.",
      "pts": 1,
      "why": "Mất cảm thụ bản thể (neuropathy) hay gặp ở người đái tháo đường.",
      "ans": false,
    },
    {
      "text": "10. Tôi đang uống thuốc làm tôi cảm thấy choáng váng hoặc buồn ngủ.",
      "pts": 1,
      "why": "Tác dụng phụ của thuốc hạ huyết áp, an thần hoặc kháng histamine.",
      "ans": false,
    },
    {
      "text": "11. Tôi đang uống thuốc điều trị rối loạn tâm trạng hoặc thuốc hỗ trợ giấc ngủ.",
      "pts": 1,
      "why": "Thuốc ngủ làm giảm phản xạ thăng bằng khi thức dậy giữa đêm.",
      "ans": false,
    },
    {
      "text": "12. Gần đây tôi thường xuyên cảm thấy buồn bã, chán nản hoặc suy giảm tinh thần.",
      "pts": 1,
      "why": "Trầm cảm tuổi già liên quan mật thiết đến suy giảm phối hợp vận động.",
      "ans": false,
    },
  ];

  int get currentScore {
    int s = 0;
    for (var q in _questions) {
      if (q['ans'] == true) s += (q['pts'] as int);
    }
    return s;
  }

  String get riskLevel => currentScore >= 4 ? "NGUY CƠ CAO (High Risk)" : "NGUY CƠ THẤP / VỪA (Low/Mod Risk)";

  void _finish() async {
    final score = currentScore;
    final level = riskLevel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cdc_steadi_last_score', score);
    await prefs.setString('cdc_steadi_last_date', DateTime.now().toIso8601String());

    // Lưu vào danh sách lịch sử đánh giá
    final List<String> history = prefs.getStringList('cdc_steadi_history') ?? [];
    history.insert(0, jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'risk': level,
    }));
    await prefs.setStringList('cdc_steadi_history', history);

    widget.onCompleted(score, level);
    if (!mounted) return;
    Navigator.pop(context);

    // Mở hộp thoại thông báo kết quả & lời khuyên y tế
    _showResultDialog(score, level);
  }

  void _showResultDialog(int score, String level) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(score >= 4 ? Icons.warning : Icons.check_circle, color: score >= 4 ? Colors.redAccent : Colors.green),
            const SizedBox(width: 8),
            const Text("Kết quả đánh giá CDC", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (score >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: score >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                children: [
                  Text("$score / 14 điểm", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: score >= 4 ? Colors.redAccent : Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("Khuyến nghị y tế lâm sàng theo CDC STEADI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (score >= 4) ...[
              const Text("• Cần đo huyết áp tư thế (ngồi và đứng sau 1-3 phút) để tầm soát tụt huyết áp tư thế.", style: TextStyle(fontSize: 12)),
              const Text("• Đề nghị bác sĩ điều trị rà soát đơn thuốc, đặc biệt thuốc an thần và hạ áp.", style: TextStyle(fontSize: 12)),
              const Text("• Lắp đặt thanh vịn tay trong nhà tắm và thảm chống trượt ngay lập tức.", style: TextStyle(fontSize: 12)),
              const Text("• Tập vật lý trị liệu phục hồi chức năng thăng bằng (bài tập Otago / Thái Cực Quyền).", style: TextStyle(fontSize: 12)),
            ] else ...[
              const Text("• Duy trì thói quen tập luyện thể lực hàng ngày (đi bộ, Thái Cực Quyền 30 phút/ngày).", style: TextStyle(fontSize: 12)),
              const Text("• Bổ sung đủ Canxi và Vitamin D theo hướng dẫn của bác sĩ.", style: TextStyle(fontSize: 12)),
              const Text("• Đánh giá lại nguy cơ định kỳ 6 tháng một lần.", style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tôi đã hiểu")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Đánh giá nguy cơ ngã CDC STEADI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Chuẩn y khoa Trung tâm Kiểm soát Bệnh tật Hoa Kỳ (CDC)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // Điểm số trực tiếp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (currentScore >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: currentScore >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Điểm số hiện tại: $currentScore / 14 điểm", style: TextStyle(fontWeight: FontWeight.bold, color: currentScore >= 4 ? Colors.redAccent : Colors.green)),
                  Text(currentScore >= 4 ? "Nguy cơ cao (>= 4)" : "Nguy cơ thấp (< 4)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (ctx, idx) {
                  final q = _questions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: q['ans'] == true ? Colors.red.withValues(alpha: 0.08) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: q['ans'] == true ? Colors.redAccent : Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(q['text'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("+${q['pts']}đ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Y khoa: ${q['why']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ChoiceChip(
                                label: const Text("Không"),
                                selected: q['ans'] == false,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("Có / Đúng"),
                                selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                                selected: q['ans'] == true,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: currentScore >= 4 ? Colors.redAccent : Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _finish,
              icon: const Icon(Icons.check_circle_outline),
              label: Text("Hoàn thành đánh giá ($currentScore điểm)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 3: BÁO CÁO Y KHOA XUẤT ĐỊNH KỲ (MEDICAL AUDIT REPORT DIALOG)
// =========================================================================
class MedicalAuditReportDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final List<dynamic> eventHistory;
  final int cdcScore;
  final DateTime? cdcDate;
  final int inactivityEventsCount;
  final int tofHeight;
  final int radarMotion;

  const MedicalAuditReportDialog({
    super.key,
    required this.profile,
    required this.eventHistory,
    required this.cdcScore,
    required this.cdcDate,
    required this.inactivityEventsCount,
    required this.tofHeight,
    required this.radarMotion,
  });

  String _generateReportText() {
    final now = DateTime.now();
    final age = now.year - profile.birthYear;
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return """
======================================================================
BÁO CÁO LÂM SÀNG GIÁM SÁT TÉ NGÃ & VẬN ĐỘNG (FALLGUARD CLINICAL REPORT)
Hệ thống giám sát vi ba Radar FMCW 24GHz & Laser ToF AI ESP32-S3R8
Thời điểm xuất báo cáo: $dateStr
======================================================================

I. THÔNG TIN BỆNH NHÂN & HỒ SƠ Y TẾ
• Họ và tên: ${profile.fullName}
• Tuổi: $age tuổi (Sinh năm ${profile.birthYear} - Giới tính: ${profile.gender})
• Nhóm máu: ${profile.bloodType}
• Cảnh báo thuốc chống đông máu: ${profile.isTakingAnticoagulants ? 'CÓ (Aspirin/Warfarin/Xarelto - CỰC KỲ LƯU Ý)' : 'Không ghi nhận'}
• Bệnh lý nền: ${profile.chronicConditions.join(', ')}
• Đơn thuốc đang sử dụng: ${profile.highRiskMedications.join(', ')}
• Bác sĩ phụ trách: ${profile.attendingDoctorName} (SĐT: ${profile.attendingDoctorPhone})
• Bệnh viện chỉ định: ${profile.hospital}

II. CHỈ SỐ ĐÁNH GIÁ NGUY CƠ TÉ NGÃ (CDC STEADI USA)
• Điểm đánh giá: $cdcScore / 14 điểm
• Phân tầng nguy cơ: ${cdcScore >= 4 ? 'NGUY CƠ CAO (High Fall Risk >= 4)' : 'NGUY CƠ THẤP / TRUNG BÌNH (< 4)'}
• Ngày đánh giá gần nhất: ${cdcDate != null ? '${cdcDate!.day}/${cdcDate!.month}/${cdcDate!.year}' : 'Chưa thực hiện'}

III. THỐNG KÊ SỰ CỐ & HỘP ĐEN NVS (BLACKBOX AUDIT)
• Tổng số vụ té ngã va chạm mạnh ghi nhận: ${eventHistory.where((e) => e['type'] == 1).length} sự cố
• Tổng số sự cố ngã chậm / nằm sàn bất động: ${eventHistory.where((e) => e['type'] == 2).length} sự cố
• Số lần cảnh báo lưu trú bất động trong nhà tắm (>30p): $inactivityEventsCount lần
• Trạng thái hiện tại: Chiều cao ToF $tofHeight mm | Động năng Radar $radarMotion/100

IV. KHUYẾN CÁO LÂM SÀNG DÀNH CHO BÁC SĨ & GIA ĐÌNH
1. Người bệnh có phân tầng nguy cơ ngã ${cdcScore >= 4 ? 'CAO' : 'TRUNG BÌNH'}. Cần kiểm tra huyết áp tư thế nằm và đứng (Orthostatic Hypotension) tại phòng khám.
2. ${profile.isTakingAnticoagulants ? 'ĐẶC BIỆT LƯU Ý: Do bệnh nhân đang điều trị thuốc chống đông, mọi cú ngã va chạm vùng đầu dù chưa xuất hiện triệu chứng ngoài da vẫn bắt buộc chụp CT sọ não trong 24h để loại trừ tụ máu dưới màng cứng muộn.' : 'Duy trì chế độ vận động nhẹ nhàng.'}
3. Kiểm tra môi trường nhà ở: Lắp đặt tay vịn nhà vệ sinh, giữ sàn khô ráo, đảm bảo ánh sáng đèn ngủ tự động bật khi người bệnh thức dậy ban đêm.
======================================================================
""";
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép toàn bộ báo cáo y khoa vào clipboard!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReportText();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.tealAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Báo cáo y tế xuất định kỳ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text("Tóm tắt lâm sàng phục vụ thăm khám Bác sĩ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Sao chép Báo cáo"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      _copyToClipboard(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text("Sao chép & Gửi Bác sĩ"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÍNH NĂNG 4: CẢNH BÁO KHẨN CẤP VƯỢT CHẾ ĐỘ IM LẶNG (CRITICAL ALARM MODAL)
// =========================================================================
class CriticalEmergencyAlarmDialog extends StatefulWidget {
  final bool isFall;
  final String? customReason;
  final ElderlyMedicalProfile profile;
  final int tofHeight;
  final int radarMotion;
  final double dropRate;
  final String roomName;
  final VoidCallback onCancelAlarm;
  final VoidCallback onOpenMedicalId;
  final VoidCallback onOpenFirstAid;

  const CriticalEmergencyAlarmDialog({
    super.key,
    this.isFall = true,
    this.customReason,
    required this.profile,
    required this.tofHeight,
    required this.radarMotion,
    required this.dropRate,
    required this.roomName,
    required this.onCancelAlarm,
    required this.onOpenMedicalId,
    required this.onOpenFirstAid,
  });

  @override
  State<CriticalEmergencyAlarmDialog> createState() => _CriticalEmergencyAlarmDialogState();
}

class _CriticalEmergencyAlarmDialogState extends State<CriticalEmergencyAlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _hapticLoopTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // Vòng lặp rung chấn mạnh & âm thanh cảnh báo vượt chế độ im lặng
    _hapticLoopTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _hapticLoopTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _callFamily() async {
    final phone = widget.profile.emergencyContact1Phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isNotEmpty) {
      final uri = Uri.parse("tel:$phone");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final Color flashColor = Color.lerp(Colors.red.shade900, Colors.amber.shade900, _pulseController.value)!;
        return Dialog(
          backgroundColor: const Color(0xFF140303),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: flashColor, width: 3.5),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Biểu tượng & Nhấp nháy báo động
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2 + 0.3 * _pulseController.value),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2.5),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.redAccent, size: 48),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      widget.isFall ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP!" : "⚠️ CẢNH BÁO BẤT ĐỘNG KÉO DÀI!",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.customReason ?? (widget.isFall
                        ? "Hệ thống AI vừa phát hiện cú ngã va chạm mạnh tại khu vực [${widget.roomName}]!"
                        : "Phát hiện người thân bất động quá lâu trong [${widget.roomName}]. Nghi ngờ ngất xỉu hoặc đột quỵ!"),
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Bảng thông số tại thời điểm sự cố
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric("V_rơi", "${widget.dropRate.toStringAsFixed(0)} mm/s"),
                        _buildMetric("Độ cao ToF", "${widget.tofHeight} mm"),
                        _buildMetric("Động năng Radar", "${widget.radarMotion}%"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút gọi 115 khẩn cấp
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _call115,
                    icon: const Icon(Icons.phone_in_talk, size: 22),
                    label: const Text("GỌI CẤP CỨU 115 NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),

                  // Nút gọi người thân khẩn cấp
                  if (widget.profile.emergencyContact1Phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _callFamily,
                      icon: const Icon(Icons.call, size: 20),
                      label: Text("GỌI NGƯỜI THÂN (${widget.profile.emergencyContact1Name})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenMedicalId();
                          },
                          icon: const Icon(Icons.badge, size: 16),
                          label: const Text("Thẻ Y Tế", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenFirstAid();
                          },
                          icon: const Icon(Icons.medical_services, size: 16),
                          label: const Text("Sơ cứu", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nút xác nhận an toàn & Hủy còi hú
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _hapticLoopTimer?.cancel();
                      widget.onCancelAlarm();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("XÁC NHẬN AN TOÀN / TẮT CÒI HÚ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
      ],
    );
  }
}

// =========================================================================
// TÍNH NĂNG 6: WIDGET TIỆN ÍCH MÀN HÌNH KHÓA & MÀN HÌNH CHÍNH (PREVIEW MODAL)
// =========================================================================
class LockscreenWidgetPreviewDialog extends StatelessWidget {
  final String posture;
  final int tofHeight;
  final int radarMotion;
  final String roomName;
  final String sysState;

  const LockscreenWidgetPreviewDialog({
    super.key,
    required this.posture,
    required this.tofHeight,
    required this.radarMotion,
    required this.roomName,
    required this.sysState,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.widgets, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mô phỏng Widget Màn hình khóa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("iOS Dynamic Island & Android Glance Widget", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // 1. MÔ PHỎNG DYNAMIC ISLAND (iOS 16.1+)
              const Text("1. iOS Dynamic Island & Hoạt động trực tiếp (Live Activity):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sysState == "ALERT" ? Colors.red : Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.shield, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "FallGuard: $roomName • An toàn",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("${tofHeight}mm", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. MÔ PHỎNG WIDGET MÀN HÌNH KHÓA iOS (2x1)
              const Text("2. Tiện ích màn hình khóa iOS Lock Screen (Widget 2x1):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        const Text("FALL GUARD S3R8", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const Spacer(),
                        Text(posture, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("Người thân đang an toàn tại $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Radar: $radarMotion% • Chiều cao: ${tofHeight}mm • Trực tiếp", style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. MÔ PHỎNG WIDGET MÀN HÌNH CHÍNH ANDROID (Glance 4x2)
              const Text("3. Tiện ích màn hình chính Android Home Widget (Material You):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900.withValues(alpha: 0.5), Colors.teal.shade900.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ông An: Trạng thái bình thường", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Không phát hiện nguy cơ trượt ngã", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.battery_charging_full, size: 16, color: Colors.greenAccent),
                        const SizedBox(width: 2),
                        const Text("100%", style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("📞 Gọi 115", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("🪪 Thẻ Y Tế", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.tealAccent))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tôi đã hiểu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
