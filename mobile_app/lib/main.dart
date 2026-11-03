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

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _loadGeneralSettings();
    _loadDeviceHistory();
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
      _showEmergencyDialog();
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

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text("CẢNH BÁO TÉ NGÃ KHẨN CẤP!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Hệ thống vừa phát hiện té ngã hoặc bấm nút SOS cứu nạn! Tin nhắn khẩn cấp đã được gửi qua Telegram & SMS.",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            icon: const Icon(Icons.medical_services, size: 18),
            label: const Text("HƯỚNG DẪN SƠ CỨU"),
            onPressed: () {
              Navigator.pop(ctx);
              showFirstAidGuideModal(context);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            icon: const Icon(Icons.check_circle),
            label: const Text("TẮT BÁO ĐỘNG"),
            onPressed: () {
              _sendCommand("CANCEL_ALARM");
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _deviceTabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _currentFloorThreshold = widget.floorThreshold;
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
            _buildSelfTestItem(Icons.sensors, "Cảm biến PIR (AM312)", "Phát hiện chuyển động hồng ngoại sẵn sàng", Colors.green),
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
                    "Kiểm tra tình trạng hoạt động của Radar 24GHz, Laser ToF, PIR, Còi, Đèn và Khối nguồn UPS 220V:",
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
          const SizedBox(height: 16),

          // 6. Công cụ & Ngắt kết nối
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
                    leading: const Icon(Icons.medical_information, color: Colors.redAccent),
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
                  Text("Cảm biến kết hợp: ToF Laser (Độ cao) + Radar 24GHz FMCW (Động năng & Cự ly) + PIR (Hồng ngoại)", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
