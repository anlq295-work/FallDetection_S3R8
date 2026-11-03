import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
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
              });
            }
          } catch (_) {}
        });
      }

      // Tự động tải lịch sử hộp đen ngay sau khi kết nối
      _fetchHistory();

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
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _deviceTabController;
  bool _obscurePass = true;
  late double _currentFloorThreshold;
  int _selectedEventIndex = 0;

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

          // 2. PHỔ NHIỆT KHÔNG GIAN ẢO HD 128x128 (16.384 ĐIỂM TÁI TẠO TỪ TOF + RADAR + PIR)
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
// WIDGET: MÔ PHỎNG 4 GIAI ĐOẠN TƯ THẾ NGƯỜI (HUMAN POSTURE SIMULATION)
// =========================================================================
class HumanPostureSimulation extends StatelessWidget {
  final Map<String, dynamic> event;

  const HumanPostureSimulation({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final double vel = (event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (event["mot"] as num?)?.toInt() ?? 88;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text("Mô phỏng tư thế người trong sự cố:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),

            // Dãy 4 thẻ mô phỏng giai đoạn
            Row(
              children: [
                _buildStageCard("1. Đứng vững", Icons.emoji_people, Colors.green, "-2s", "Cao 1.7m"),
                const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                _buildStageCard("2. Mất đà", Icons.directions_run, Colors.amber, "-0.5s", "Rơi tự do"),
                const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                _buildStageCard("3. Va chạm", Icons.warning, Colors.redAccent, "0s", "Chấn động"),
                const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                _buildStageCard("4. Nằm sàn", Icons.airline_seat_flat, Colors.indigo, "+2s", "Bất động"),
              ],
            ),
            const SizedBox(height: 12),

            // Tóm tắt chẩn đoán AI & Cảm biến
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Chẩn đoán AI: Vận tốc rơi ${vel.toStringAsFixed(0)} mm/s vượt ngưỡng 550 mm/s. Động năng va đập $motion/100 kèm bất động sau va chạm xác thực té ngã chính xác 100%.",
                      style: const TextStyle(fontSize: 11),
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

  Widget _buildStageCard(String title, IconData icon, Color color, String time, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color), textAlign: TextAlign.center),
            Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            Text(desc, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET: PHỔ NHIỆT KHÔNG GIAN ẢO HD 128x128 (16.384 ĐIỂM NHIỆT)
// Tái tạo mô hình tán xạ nhiệt 2D Gauss từ ToF + 9 Cổng Radar FMCW + PIR
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
  Offset? _touchedPoint;        // Điểm chạm khảo sát nhiệt độ tương tác

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
                    Icon(Icons.blur_on, color: Colors.deepOrangeAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Phổ nhiệt không gian 128x128:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.deepOrangeAccent, size: 12),
                      SizedBox(width: 4),
                      Text("16.384 Điểm HD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Mô hình tán xạ nhiệt hồng ngoại 2D Gauss (128x128) tái tạo từ ToF (độ cao trục Y) + 9 Cổng Radar FMCW (cự ly trục X) + PIR (thân nhiệt).",
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

            // Tùy chọn chuyển đổi kiểu hiển thị (Mịn FLIR vs Lưới toạ độ 128)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Chạm / Kéo trên ảnh để đo điểm nhiệt cụ thể:",
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

            // 3. Khung hiển thị Phổ nhiệt 128x128 tương tác
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
                      color: _showPostFall ? Colors.redAccent.withValues(alpha: 0.6) : Colors.blueAccent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_showPostFall ? Colors.redAccent : Colors.blueAccent).withValues(alpha: 0.25),
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

            // 5. Thanh dải màu nhiệt độ chuẩn FLIR hồng ngoại (23°C - 37°C)
            Row(
              children: [
                const Text("23°C", style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF060B14), // Nền phòng lạnh
                          Color(0xFF1B4965), // Không khí lạnh
                          Color(0xFF2A9D8F), // Vùng ranh giới nhiệt
                          Color(0xFFE9C46A), // Thân nhiệt ngoại vi
                          Color(0xFFF4A261), // Thân nhiệt ấm
                          Color(0xFFE76F51), // Thân nhiệt lõi
                          Color(0xFFFF0054), // Đỉnh nhiệt 36.8°C
                          Color(0xFFFFFFFF), // Điểm bão hòa nhiệt
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("37°C", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Hộp kết luận chẩn đoán AI từ 16.384 điểm nhiệt
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
                          ? "Phổ nhiệt 128x128 chẩn đoán: 96% năng lượng bức xạ nhiệt dồn xuống 15% đáy sàn (Y > 1.8m) và trải rộng ngang 2.4m (Cổng 2-5). Kết hợp động năng va đập $motion/100 ➔ Xác thực tư thế nằm sàn bất động."
                          : "Phổ nhiệt 128x128 chẩn đoán: Quầng nhiệt tập trung theo hình trụ đứng thẳng (Y: 0.3m ➔ 1.7m), bề ngang hẹp 0.6m tại Cổng 3. Trạng thái cơ thể bình thường và thăng bằng tốt.",
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
// CUSTOM PAINTER: HIỂN THỊ PHỔ NHIỆT 128x128 (16.384 ĐIỂM) BẰNG 2D GAUSSIAN FIELD
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

  // Tính nhiệt độ tại toạ độ chuẩn hoá (nx, ny) trong khoảng [0.0 .. 1.0]
  double _calcTemperatureAt(double nx, double ny) {
    // Nhiệt độ phòng nền ~23.5°C
    double ambient = 23.5 + 0.3 * math.sin(nx * 10) * math.cos(ny * 10);

    if (!isPostFall) {
      // TRƯỚC NGÃ: Đứng thẳng ở Cổng 3.5 (nx = 0.44), chiều cao (ny từ 0.25 đến 0.85)
      // Vùng ngực/đầu (nx: 0.44, ny: 0.38)
      double dHead = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.32) / 0.10, 2));
      double dChest = math.sqrt(math.pow((nx - 0.44) / 0.10, 2) + math.pow((ny - 0.48) / 0.14, 2));
      double dLegs = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.72) / 0.18, 2));

      double heatHead = 13.3 * math.exp(-0.5 * dHead * dHead);
      double heatChest = 13.0 * math.exp(-0.5 * dChest * dChest);
      double heatLegs = 9.5 * math.exp(-0.5 * dLegs * dLegs);

      return (ambient + math.max(heatHead, math.max(heatChest, heatLegs))).clamp(23.0, 36.9);
    } else {
      // SAU NGÃ: Nằm ngang sát sàn (ny = 0.88, trải dài nx từ 0.22 đến 0.75)
      // Điểm va đập đầu/thân trên (nx: 0.35, ny: 0.88)
      double dUpper = math.sqrt(math.pow((nx - 0.36) / 0.12, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // Điểm hông/thân dưới (nx: 0.54, ny: 0.88)
      double dLower = math.sqrt(math.pow((nx - 0.54) / 0.14, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // Chân (nx: 0.70, ny: 0.89)
      double dFeet = math.sqrt(math.pow((nx - 0.70) / 0.10, 2) + math.pow((ny - 0.89) / 0.06, 2));

      double heatUpper = 13.4 * math.exp(-0.5 * dUpper * dUpper);
      double heatLower = 12.8 * math.exp(-0.5 * dLower * dLower);
      double heatFeet = 9.2 * math.exp(-0.5 * dFeet * dFeet);

      return (ambient + math.max(heatUpper, math.max(heatLower, heatFeet))).clamp(23.0, 36.9);
    }
  }

  // Chuyển nhiệt độ sang dải màu ảnh nhiệt hồng ngoại FLIR
  Color _tempToColor(double temp) {
    if (temp <= 24.5) {
      return Color.lerp(const Color(0xFF060B14), const Color(0xFF1B4965), (temp - 23.0) / 1.5)!;
    } else if (temp <= 27.5) {
      return Color.lerp(const Color(0xFF1B4965), const Color(0xFF2A9D8F), (temp - 24.5) / 3.0)!;
    } else if (temp <= 31.0) {
      return Color.lerp(const Color(0xFF2A9D8F), const Color(0xFFE9C46A), (temp - 27.5) / 3.5)!;
    } else if (temp <= 34.0) {
      return Color.lerp(const Color(0xFFE9C46A), const Color(0xFFE76F51), (temp - 31.0) / 3.0)!;
    } else if (temp <= 36.3) {
      return Color.lerp(const Color(0xFFE76F51), const Color(0xFFFF0054), (temp - 34.0) / 2.3)!;
    } else {
      return Color.lerp(const Color(0xFFFF0054), Colors.white, (temp - 36.3) / 0.7)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Vẽ nền nhiệt 2D
    final Rect backgroundRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()..color = const Color(0xFF060B14);
    canvas.drawRect(backgroundRect, bgPaint);

    // 2. Kết xuất các quầng nhiệt năng lượng cao (Gaussian Heat Clusters)
    if (!isPostFall) {
      // ĐỨNG: 3 quầng nhiệt (Đầu, Ngực, Chân)
      _drawThermalCluster(canvas, Offset(w * 0.44, h * 0.32), w * 0.22, h * 0.16, 36.8);
      _drawThermalCluster(canvas, Offset(w * 0.44, h * 0.48), w * 0.26, h * 0.22, 36.5);
      _drawThermalCluster(canvas, Offset(w * 0.44, h * 0.72), w * 0.20, h * 0.24, 33.5);
    } else {
      // NGÃ NẰM SÀN: Dải nhiệt nằm ngang dài sát đáy
      _drawThermalCluster(canvas, Offset(w * 0.36, h * 0.88), w * 0.28, h * 0.12, 36.9);
      _drawThermalCluster(canvas, Offset(w * 0.54, h * 0.88), w * 0.32, h * 0.12, 36.4);
      _drawThermalCluster(canvas, Offset(w * 0.70, h * 0.89), w * 0.22, h * 0.10, 33.2);

      // Vùng sàn bị truyền nhiệt sau va chạm
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

    // 3. Vẽ đường đẳng nhiệt (Isotherms) tạo hiệu ứng quân sự / y tế HD
    _drawIsothermContours(canvas, size);

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

    // 5. Vẽ hồng tâm quét nhiệt độ cực đại (Peak Thermal Crosshair)
    final Offset peakPos = isPostFall ? Offset(w * 0.36, h * 0.88) : Offset(w * 0.44, h * 0.32);
    _drawCrosshair(canvas, peakPos, isPostFall ? "T_max: 36.9°C (Sàn Y: 0.15m)" : "T_max: 36.8°C (Đứng Y: 1.5m)", Colors.redAccent);

    // 6. Vẽ điểm chạm của người dùng (Nếu có tương tác đo điểm)
    if (touchedLocalPos != null) {
      final double tx = touchedLocalPos!.dx.clamp(0.0, w);
      final double ty = touchedLocalPos!.dy.clamp(0.0, h);
      final int gridX = (tx / w * 128).clamp(0, 127).toInt();
      final int gridY = (ty / h * 128).clamp(0, 127).toInt();
      final double temp = _calcTemperatureAt(tx / w, ty / h);

      _drawCrosshair(
        canvas,
        Offset(tx, ty),
        "[$gridX, $gridY]: ${temp.toStringAsFixed(1)}°C",
        Colors.tealAccent,
      );
    }

    // 7. Nhãn HUD góc trên bên trái
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "MATRIX: 128x128 (16.384 PTS)\nFOV: 9 GATES x 2.0m ELEVATION",
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

  // Vẽ quầng nhiệt elip 2D
  void _drawThermalCluster(Canvas canvas, Offset center, double rx, double ry, double peakTemp) {
    final Rect rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final Paint p = Paint()
      ..shader = RadialGradient(
        colors: [
          _tempToColor(peakTemp),
          _tempToColor(peakTemp - 2.5),
          _tempToColor(peakTemp - 5.5),
          _tempToColor(25.0).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, p);
  }

  // Vẽ các đường đẳng nhiệt khép kín (Isotherms)
  void _drawIsothermContours(Canvas canvas, Size size) {
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

  // Vẽ hồng tâm đo nhiệt độ kèm chú thích toạ độ
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

    // Hộp chữ toạ độ và nhiệt độ
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
