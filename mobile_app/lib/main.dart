import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// =========================================================================
// CÁC UUID TRÙNG KHỚP 100% VỚI FIRMWARE ESP32-S3 N16R8
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
  final Map<String, int> _rssiMap = {};

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
    // 2 Tab: Kết nối (Thiết bị) và Giám sát
    _tabController = TabController(length: 2, vsync: this);
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

  // Kết nối tới ESP32-S3
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _statusMessage = "Đang kết nối tới ${device.platformName.isEmpty ? 'FallDetector_S3R8' : device.platformName}...";
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

  // Mở màn hình Cài đặt riêng cho thiết bị
  void _openDeviceSettings(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DeviceSettingsScreen(
          device: device,
          isConnected: _isConnected,
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
          onSaveWifi: _sendWifiConfig,
          onSaveContacts: _sendContactsConfig,
          onDisconnect: () {
            _disconnect();
            Navigator.pop(ctx);
          },
          onCalibrateFloor: () => _sendCommand("CALIBRATE_FLOOR"),
          onRefreshContacts: _readCurrentContacts,
        ),
      ),
    );
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
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: _isConnected ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: _isConnected ? "Đã kết nối" : "Chưa kết nối",
            onPressed: () => _tabController.animateTo(0),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth_searching), text: 'Kết nối'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'Giám sát'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
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

  // TAB 1: KẾT NỐI BLUETOOTH (ĐÃ TINH CHỈNH THEO YÊU CẦU)
  Widget _buildConnectionTab() {
    // Tập hợp danh sách thiết bị hiển thị (đưa thiết bị đã kết nối lên đầu)
    List<BluetoothDevice> displayedDevices = [];
    if (_connectedDevice != null && _isConnected) {
      displayedDevices.add(_connectedDevice!);
    }
    for (var r in _scanResults) {
      if (_connectedDevice == null || r.device.remoteId != _connectedDevice!.remoteId) {
        displayedDevices.add(r.device);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nút quét thiết bị đưa lên trên cùng (đã bỏ khối Đang trực tuyến riêng lẻ)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Thiết bị tìm thấy:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey.shade400),
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

                      // Trường hợp thiết bị đã kết nối thành công: Hiển thị xanh, nút Ngắt, chạm vào để mở Cài đặt
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
                            onTap: () => _openDeviceSettings(device),
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
                                        const SizedBox(height: 3),
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              "Đã kết nối",
                                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            SizedBox(width: 6),
                                            Text("•", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            SizedBox(width: 6),
                                            Text(
                                              "Chạm để cài đặt",
                                              style: TextStyle(color: Colors.blueAccent, fontSize: 12, decoration: TextDecoration.underline),
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
                                  // Nút ngắt kết nối trực tiếp trên thiết bị
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

                      // Trường hợp thiết bị chưa kết nối: Card tiêu chuẩn với nút Kết nối
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
    );
  }

  // TAB 2: GIÁM SÁT THỜI GIAN THỰC & ĐIỀU KHIỂN TỪ XA
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

// =========================================================================
// MÀN HÌNH CÀI ĐẶT THIẾT BỊ (MỞ RA KHI CHẠM VÀO THIẾT BỊ ĐÃ KẾT NỐI)
// =========================================================================
class DeviceSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final TextEditingController ssidController;
  final TextEditingController passController;
  final TextEditingController phoneController;
  final TextEditingController chatIdController;
  final TextEditingController botTokenController;
  final double floorThreshold;
  final ValueChanged<double> onFloorThresholdChanged;
  final Future<void> Function() onSaveWifi;
  final Future<void> Function() onSaveContacts;
  final VoidCallback onDisconnect;
  final VoidCallback onCalibrateFloor;
  final Future<void> Function() onRefreshContacts;

  const DeviceSettingsScreen({
    super.key,
    required this.device,
    required this.isConnected,
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
    required this.onCalibrateFloor,
    required this.onRefreshContacts,
  });

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  bool _obscurePass = true;
  late double _currentFloorThreshold;

  @override
  void initState() {
    super.initState();
    _currentFloorThreshold = widget.floorThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final String devName = widget.device.platformName.isEmpty ? "FallDetector_S3R8" : widget.device.platformName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cài đặt: $devName",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              "ID: ${widget.device.remoteId}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Đọc lại cấu hình từ ESP32",
            onPressed: () async {
              await widget.onRefreshContacts();
              if (!context.mounted) return;
              setState(() {
                _currentFloorThreshold = widget.floorThreshold;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã làm mới dữ liệu cấu hình từ ESP32!"), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ tóm tắt trạng thái kết nối
            Card(
              color: widget.isConnected ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: widget.isConnected ? Colors.green : Colors.red, width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      widget.isConnected ? Icons.check_circle : Icons.error,
                      color: widget.isConnected ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isConnected ? "Thiết bị đang kết nối Bluetooth Low Energy" : "Thiết bị đã ngắt kết nối",
                        style: TextStyle(
                          color: widget.isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

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
                    TextField(
                      controller: widget.phoneController,
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
                      controller: widget.chatIdController,
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

            // 3. Công cụ & Ngắt kết nối
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
                      onPressed: widget.isConnected ? widget.onCalibrateFloor : null,
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
          ],
        ),
      ),
    );
  }
}
