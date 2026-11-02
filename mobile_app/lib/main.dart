import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// =========================================================================
// CÁC UUID TRÙNG KHỚP 100% VỚI FIRMWARE ESP32-S3R8
// =========================================================================
const String serviceUuid       = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String charWifiUuid      = "0beb5483-e18e-4f36-9e1b-b4d6b63c7b28";
const String charContactUuid   = "1c6f8742-9a6d-4785-b9e1-e63f9b8c0011";
const String charStatusUuid    = "2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344";
const String charTelemetryUuid = "3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455";
const String charCmdUuid       = "4fa0b044-9b3e-4d75-af4c-b70e901c5566";

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
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Trạng thái kết nối BLE
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = "Chưa kết nối thiết bị";
  List<ScanResult> _scanResults = [];

  // Các Characteristic được tìm thấy
  BluetoothCharacteristic? _wifiChar;
  BluetoothCharacteristic? _contactChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _cmdChar;

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
  bool _obscurePass = true;

  // Dữ liệu Telemetry thời gian thực
  String _sysState = "DISCONNECTED";
  String _aiPosture = "UNKNOWN";
  double _aiConfidence = 0.0;
  int _tofHeight = 0;
  int _radarMotion = 0;
  int _radarStatic = 0;
  double _dropRate = 0.0;
  List<dynamic> _eventHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkBluetoothState();
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
    _tabController.dispose();
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
            return name.contains("FallDetector") || r.advertisementData.serviceUuids.any((u) => u.str128.toLowerCase().contains(serviceUuid.toLowerCase()));
          }).toList();
        });
      });

      await Future.delayed(const Duration(seconds: 6));
      setState(() {
        _isScanning = false;
        if (_scanResults.isEmpty) {
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

  // Kết nối tới ESP32-S3R8
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _statusMessage = "Đang kết nối tới ${device.platformName}...";
    });

    try {
      await device.connect(license: License.nonprofit, autoConnect: false, timeout: const Duration(seconds: 10));
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _statusMessage = "Đã kết nối thành công!";
      });

      // Lắng nghe trạng thái mất kết nối
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

      // Khám phá dịch vụ
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
          }
        }
      }

      // Đọc danh bạ hiện có trên chip
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

      // Đăng ký nhận Telemetry thời gian thực
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
              });
            }
          } catch (_) {}
        });
      }

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
      _showSnackbar("ESP32 đã kết nối Wi-Fi! Địa chỉ IP: $ip", Colors.green);
    } else if (msg == "WIFI_CONNECT_FAILED") {
      _showSnackbar("ESP32 kết nối Wi-Fi thất bại! Kiểm tra mật khẩu.", Colors.red);
    } else if (msg == "CONFIG_UPDATED_OK") {
      _showSnackbar("Cấu hình danh bạ đã lưu thành công!", Colors.green);
    } else if (msg == "EMERGENCY_DISPATCHED") {
      _showEmergencyDialog();
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            icon: const Icon(Icons.check_circle),
            label: const Text("TẮT BÁO ĐỘNG TỪ XA"),
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

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
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
            icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: _isConnected ? Colors.greenAccent : Colors.grey),
            tooltip: _isConnected ? "Đã kết nối" : "Chưa kết nối",
            onPressed: () => _tabController.animateTo(0),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth_searching), text: 'Kết nối'),
            Tab(icon: Icon(Icons.settings), text: 'Cài đặt'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'Giám sát'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildSettingsTab(),
          _buildMonitorTab(),
        ],
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

  // TAB 1: KẾT NỐI BLUETOOTH
  Widget _buildConnectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(
                          _isConnected ? Icons.sensors : Icons.sensors_off,
                          color: _isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _connectedDevice != null ? _connectedDevice!.platformName : "Chưa có thiết bị",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _isConnected ? "Đang trực tuyến (BLE Connected)" : "Hãy quét và chọn thiết bị",
                              style: TextStyle(color: _isConnected ? Colors.green : Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_isConnected)
                        OutlinedButton(
                          onPressed: _disconnect,
                          child: const Text("Ngắt"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: _isScanning
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: Text(_isScanning ? "Đang quét xung quanh..." : "Quét thiết bị FallDetector_S3R8"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text("Thiết bị tìm thấy:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? "Đang tìm kiếm sóng Bluetooth..." : "Nhấn 'Quét' để tìm thiết bị ESP32",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (ctx, idx) {
                      final r = _scanResults[idx];
                      String name = r.device.platformName.isEmpty ? "FallDetector_S3R8" : r.device.platformName;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.devices, color: Colors.blue),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("RSSI: ${r.rssi} dBm | ID: ${r.device.remoteId}"),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(r.device),
                            child: const Text("Kết nối"),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 2: CÀI ĐẶT WI-FI & DANH BẠ KHẨN CẤP
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
                      Icon(Icons.wifi, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Cấu hình Wi-Fi cho ESP32", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ssidController,
                    decoration: const InputDecoration(
                      labelText: "Tên mạng Wi-Fi (SSID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.router),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
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
                    onPressed: _isConnected ? _sendWifiConfig : null,
                    icon: const Icon(Icons.save),
                    label: const Text("Lưu Wi-Fi & Khởi động lại ESP32"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
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
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại người thân (SMS)",
                      hintText: "0901234567",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chatIdController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "Telegram Chat ID (Người thân / Nhóm)",
                      hintText: "123456789",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.send),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _botTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Telegram Bot Token (Tùy chọn)",
                      hintText: "Để trống nếu dùng mặc định",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Ngưỡng chiều cao sàn: ${_floorThreshold.toInt()} mm", style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(
                    value: _floorThreshold,
                    min: 200,
                    max: 800,
                    divisions: 12,
                    label: "${_floorThreshold.toInt()} mm",
                    onChanged: (val) => setState(() => _floorThreshold = val),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isConnected ? _sendContactsConfig : null,
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
        ],
      ),
    );
  }

  // TAB 3: GIÁM SÁT THỜI GIAN THỰC & ĐIỀU KHIỂN TỪ XA
  Widget _buildMonitorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ trạng thái khẩn cấp
          Card(
            color: _getStateColor(_sysState).withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _getStateColor(_sysState), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: _getStateColor(_sysState), size: 36),
                      const SizedBox(width: 10),
                      Text(
                        _sysState,
                        style: TextStyle(
                          color: _getStateColor(_sysState),
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sysState == "ALERT" ? "🚨 CẢNH BÁO TÉ NGÃ KHẨN CẤP!" :
                    _sysState == "PRE_ALARM" ? "⚠️ ĐANG ĐẾM NGƯỢC PRE-ALARM (30s)" :
                    _sysState == "SUSPECTED" ? "Xác thực va chạm tiếp đất..." :
                    _sysState == "NORMAL" ? "Môi trường bình thường & An toàn" : "Chưa kết nối",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lưới các thông số thời gian thực
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildMetricCard("Tư thế AI", _aiPosture, "Tin cậy: ${(_aiConfidence * 100).toStringAsFixed(0)}%", Icons.accessibility_new, Colors.indigo),
              _buildMetricCard("Độ cao ToF", "$_tofHeight mm", "V_drop: ${_dropRate.toStringAsFixed(0)} mm/s", Icons.height, Colors.blue),
              _buildMetricCard("Động năng Radar", "$_radarMotion / 100", "LD2410 Peak Move", Icons.directions_run, Colors.orange),
              _buildMetricCard("Tĩnh học Hô hấp", "$_radarStatic / 100", "LD2410 Static Gate", Icons.air, Colors.teal),
            ],
          ),
          const SizedBox(height: 16),

          // Nút bấm khẩn cấp SOS từ xa
          ElevatedButton.icon(
            onPressed: _isConnected ? () => _sendCommand("PANIC_SOS") : null,
            icon: const Icon(Icons.emergency, size: 28),
            label: const Text("KÍCH HOẠT SOS CẤP CỨU TỪ XA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Các nút lệnh nhanh
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isConnected ? () => _sendCommand("CANCEL_ALARM") : null,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Tắt còi / Hủy"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isConnected ? () => _sendCommand("CALIBRATE_FLOOR") : null,
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
                  onPressed: _isConnected ? () => _sendCommand("TEST_ALARM") : null,
                  icon: const Icon(Icons.speaker),
                  label: const Text("Test chuông/đèn"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isConnected ? () => _sendCommand("GET_HISTORY") : null,
                  icon: const Icon(Icons.history),
                  label: const Text("Xem hộp đen"),
                ),
              ),
            ],
          ),

          // Danh sách lịch sử sự cố
          if (_eventHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Nhật ký sự kiện (Hộp đen NVS):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            for (var e in _eventHistory) ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    (e["type"] ?? 0) == 3 ? Icons.touch_app : Icons.personal_injury,
                    color: Colors.red,
                  ),
                  title: Text(
                    (e["type"] ?? 0) == 3 ? "SOS Thủ công" : (((e["type"] ?? 0) == 2) ? "Ngã chậm (15s)" : "Ngã va chạm"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Vận tốc: ${e['vel']} mm/s | Động năng: ${e['mot']}/100"),
                  trailing: Text("${e['sec']}s", style: const TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ],
        ],
      ),
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
