part of 'main.dart';

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
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
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
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
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
// MÀN HÌNH CHÍNH (HOME SCREEN)
// =========================================================================
