part of 'main.dart';

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
  final List<Map<String, double>> telemetryHistory;

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

  // Giám sát trực tiếp qua Wi-Fi LAN
  final String deviceIp;
  final bool isWifiConnected;
  final int wifiDelayMs;
  final Future<void> Function(String)? onSendWifiCommand;
  final Future<void> Function()? onFetchWifiHistory;

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
    this.telemetryHistory = const [],
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
    this.deviceIp = "",
    this.isWifiConnected = false,
    this.wifiDelayMs = 0,
    this.onSendWifiCommand,
    this.onFetchWifiHistory,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _deviceTabController;
  bool _obscurePass = true;
  late double _currentFloorThreshold;
  int _selectedEventIndex = 0;
  int _blackBoxSubTab = 0; // 0: Trực tiếp thời gian thực, 1: Hộp đen NVS

  // Xử lý gửi lệnh qua kênh khả dụng (BLE hoặc Wi-Fi)
  Future<void> _handleDeviceCommand(String cmd) async {
    if (widget.isConnected) {
      await widget.onSendCommand(cmd);
    } else if (widget.onSendWifiCommand != null && widget.deviceIp.isNotEmpty) {
      await widget.onSendWifiCommand!(cmd);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa kết nối thiết bị qua Bluetooth hoặc Wi-Fi!"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(TimeOfDay value) {
    return "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickNightTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _nightStart : _nightEnd,
      helpText: isStart ? "Giờ bắt đầu bật đèn" : "Giờ kết thúc đèn",
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (isStart) {
        _nightStart = picked;
      } else {
        _nightEnd = picked;
      }
    });
  }

  void _saveNightlightSchedule() {
    final command = "NIGHTLIGHT_SCHEDULE:${_nightScheduleEnabled ? 1 : 0},"
        "${_nightStart.hour},${_nightStart.minute},"
        "${_nightEnd.hour},${_nightEnd.minute}";
    _handleDeviceCommand(command);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã gửi lịch night light ${_formatTime(_nightStart)}–${_formatTime(_nightEnd)}")),
    );
  }

  // Cấu hình thông minh cho thiết bị
  int _alarmGracePeriod = 15; // 15 giây trễ trước khi hú còi lớn
  String _nightlightMode = "AUTO_MOTION"; // "AUTO_MOTION", "ALWAYS_ON", "OFF"
  double _nightlightBrightness = 40.0;
  String _nightlightColor = "WARM_YELLOW";
  bool _nightScheduleEnabled = true;
  TimeOfDay _nightStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _nightEnd = const TimeOfDay(hour: 6, minute: 0);

  Future<void> _confirmDeviceReset(String command, String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _handleDeviceCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lệnh. Thiết bị sẽ khởi động lại.')),
        );
      }
    }
  }
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

  Widget _constrainedTab(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String devName = widget.device.platformName.isEmpty ? "FallDetector_S3R8" : widget.device.platformName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(devName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text("ID: ${widget.device.remoteId}", style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
        bottom: TabBar(
          controller: _deviceTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart), text: "Giám sát"),
            Tab(icon: Icon(Icons.timeline), text: "Hộp đen NVS"),
            Tab(icon: Icon(Icons.settings), text: "Cài đặt"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _deviceTabController,
        children: [
          _constrainedTab(_buildMonitorTab()),
          _constrainedTab(_buildBlackBoxTab()),
          _constrainedTab(_buildSettingsTab()),
        ],
      ),
    );
  }

  // TAB 1: GIÁM SÁT THỜI GIAN THỰC & ĐIỀU KHIỂN TỪ XA
  Widget _buildMonitorTab() {
    final bool canControl = widget.isConnected || widget.isWifiConnected;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Huy hiệu nguồn kết nối (BLE & Wi-Fi)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isConnected ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isConnected ? Colors.green : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                         size: 14, color: widget.isConnected ? Colors.green : Colors.grey),
                    const SizedBox(width: 4),
                    Text(widget.isConnected ? "Bluetooth: Đã kết nối" : "Bluetooth: Ngắt",
                         style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                          color: widget.isConnected ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isWifiConnected ? Colors.teal.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isWifiConnected ? Icons.wifi : Icons.wifi_off,
                         size: 14, color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.isWifiConnected
                          ? "Wi-Fi: Trực tiếp (${widget.wifiDelayMs}ms)"
                          : (widget.deviceIp.isNotEmpty ? "Wi-Fi: ${widget.deviceIp}" : "Wi-Fi: Chưa bật"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thẻ trạng thái khẩn cấp
          Card(
            color: _getStateColor(widget.sysState).withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _getStateColor(widget.sysState).withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: _getStateColor(widget.sysState), size: 30),
                      const SizedBox(width: 10),
                      Text(
                        widget.sysState,
                        style: TextStyle(
                          color: _getStateColor(widget.sysState),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.sysState == "ALERT" ? "CẢNH BÁO TÉ NGÃ KHẨN CẤP!" :
                    widget.sysState == "PRE_ALARM" ? "ĐANG ĐẾM NGƯỢC PRE-ALARM (30s)" :
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
            childAspectRatio: compact ? 1.28 : 1.55,
            children: [
              _buildMetricCard("Tư thế AI", widget.aiPosture, "Tin cậy: ${(widget.aiConfidence * 100).toStringAsFixed(0)}%", Icons.accessibility_new, const Color(0xFF477B72)),
              _buildMetricCard("Độ cao ToF", "${widget.tofHeight} mm", "V_drop: ${widget.dropRate.toStringAsFixed(0)} mm/s", Icons.height, const Color(0xFF3D6F8E)),
              _buildMetricCard("Động năng Radar", "${widget.radarMotion} / 100", "LD2410 Peak Move", Icons.directions_run, const Color(0xFF9A6B35)),
              _buildMetricCard("Tĩnh học Hô hấp", "${widget.radarStatic} / 100", "LD2410 Static Gate", Icons.air, const Color(0xFF3F7C73)),
            ],
          ),
          const SizedBox(height: 14),

          // Nút bấm khẩn cấp SOS từ xa
          ElevatedButton.icon(
            onPressed: canControl ? () => _handleDeviceCommand("PANIC_SOS") : null,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CANCEL_ALARM") : null,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Tắt còi / Hủy"),
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CALIBRATE_FLOOR") : null,
                  icon: const Icon(Icons.straighten),
                  label: const Text("Hiệu chuẩn sàn"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("TEST_ALARM") : null,
                  icon: const Icon(Icons.speaker),
                  label: const Text("Test chuông/đèn"),
                ),
              ),
              // Nút xem hộp đen: Chuyển thẳng sang Tab 2 và fetch dữ liệu
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (widget.isConnected) {
                      widget.onFetchHistory();
                    } else if (widget.onFetchWifiHistory != null) {
                      widget.onFetchWifiHistory!();
                    }
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

  // TAB 2: HỘP ĐEN & PHÂN TÍCH ĐỘNG HỌC KHÔNG GIAN (TRỰC TIẾP & LỊCH SỬ)
  Widget _buildBlackBoxTab() {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    // Dữ liệu mô phỏng trực tiếp từ cảm biến thời gian thực
    final Map<String, dynamic> liveEvent = {
      "type": (widget.aiPosture == "FALL") ? 1 : 0,
      "sec": 0,
      "vel": widget.dropRate > 0 ? widget.dropRate : 0.0,
      "mot": widget.radarMotion,
      "dst": widget.tofHeight > 0 ? (widget.tofHeight / 10).round() : 160,
    };

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
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. THANH CHUYỂN ĐỘNG CHẾ ĐỘ: TRỰC TIẾP (LIVE) vs LỊCH SỬ HỘP ĐEN (NVS)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _blackBoxSubTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _blackBoxSubTab == 0 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors, size: 18, color: _blackBoxSubTab == 0 ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                           Flexible(
                             child: Text(
                               "Trực tiếp thời gian thực",
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _blackBoxSubTab == 0 ? Colors.white : Colors.grey,
                            ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _blackBoxSubTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _blackBoxSubTab == 1 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 18, color: _blackBoxSubTab == 1 ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                           Flexible(
                             child: Text(
                               "Hộp đen NVS (${widget.eventHistory.length})",
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _blackBoxSubTab == 1 ? Colors.white : Colors.grey,
                            ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===================================================================
          // PHÂN ĐOẠN 1: THEO DÕI TRỰC TIẾP THỜI GIAN THỰC (LIVE TELEMETRY)
          // ===================================================================
          if (_blackBoxSubTab == 0) ...[
            // Thẻ hiển thị nhanh tình trạng cảm biến thực tế
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (widget.isConnected || widget.isWifiConnected) ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Cảm biến & Tư thế trực tiếp:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.aiPosture == "FALL"
                                ? Colors.redAccent
                                : (widget.aiPosture == "LIE" ? Colors.purpleAccent : (widget.aiPosture == "SIT" ? Colors.orangeAccent : Colors.green)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${widget.aiPosture} • ${(widget.aiConfidence * 100).toInt()}%",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("Độ cao ToF", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.tofHeight} mm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.cyanAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("Động năng Radar", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.radarMotion}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("Hô hấp / Tĩnh", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.radarStatic}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.tealAccent)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Chỉ hiển thị đồ thị từ mẫu telemetry thật nhận được.
            LiveTelemetryChart(samples: widget.telemetryHistory),
          ] else ...[
            // ===================================================================
            // PHÂN ĐOẠN 2: LỊCH SỬ HỘP ĐEN NVS (FLASH BLACK BOX AUDIT)
            // ===================================================================
            // Thanh công cụ Hộp đen
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: compact ? double.infinity : 180,
                  child: ElevatedButton.icon(
                    onPressed: widget.isLoadingHistory
                        ? null
                        : () {
                            if (widget.isConnected) {
                              widget.onFetchHistory();
                            } else if (widget.onFetchWifiHistory != null && widget.deviceIp.isNotEmpty) {
                              widget.onFetchWifiHistory!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Chưa kết nối Bluetooth hoặc Wi-Fi để tải lịch sử!"), backgroundColor: Colors.orange),
                              );
                            }
                          },
                    icon: widget.isLoadingHistory
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: const Text("Tải lại từ ESP32"),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 100,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("CLEAR_HISTORY"),
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 130,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("ADD_TEST_EVENT"),
                    icon: const Icon(Icons.add_alert, color: Colors.orangeAccent),
                    label: const Text("Tạo Test"),
                  ),
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
                        "Hộp đen NVS hiện chưa có vụ ngã thật. Đang hiển thị sự cố mẫu minh họa!",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 8),

            // Danh sách các sự kiện ghi nhận trong hộp đen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Danh sách sự kiện ghi nhận trong NVS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            _buildSelfTestItem(Icons.motion_photos_on, "Cảm biến PIR (AM312)", "Đang hoạt động | Phát hiện chuyển động thân nhiệt hồng ngoại (GPIO 4)", Colors.green),
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
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
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

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(children: [
                    Icon(Icons.restart_alt, color: Colors.orangeAccent),
                    SizedBox(width: 8),
                    Text('Khôi phục hệ thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Xóa cấu hình mạng hoặc đưa thiết bị về trạng thái mặc định.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeviceReset('RESET_NETWORK', 'Đặt lại Wi-Fi?', 'Thiết bị sẽ xóa SSID/mật khẩu Wi-Fi và khởi động lại.'),
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('Xóa cấu hình mạng'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: () => _confirmDeviceReset('FACTORY_RESET', 'Khôi phục toàn bộ?', 'Xóa toàn bộ cấu hình, Wi-Fi, danh bạ và lịch sử hộp đen.'),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Khôi phục mặc định toàn bộ'),
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

          // 4. CHẾ ĐỘ ĐỘ NGỦ THÔNG MINH (SMART NIGHTLIGHT)
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "AUTO_MOTION", label: Text("Tự động (Radar)", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "ALWAYS_ON", label: Text("Luôn sáng", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "OFF", label: Text("Tắt", style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_nightlightMode},
                      onSelectionChanged: (val) => setState(() => _nightlightMode = val.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Chỉ bật trong khung giờ ban đêm", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _nightScheduleEnabled ? "Mặc định: 18:00 – 06:00" : "Night light hoạt động cả ngày",
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _nightScheduleEnabled,
                    onChanged: (value) => setState(() => _nightScheduleEnabled = value),
                  ),
                  if (_nightScheduleEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNightTime(true),
                            icon: const Icon(Icons.login, size: 18),
                            label: Text("Bật ${_formatTime(_nightStart)}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNightTime(false),
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text("Tắt ${_formatTime(_nightEnd)}"),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _saveNightlightSchedule,
                    icon: const Icon(Icons.schedule),
                    label: const Text("Lưu lịch night light vào thiết bị"),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Màu ánh sáng:", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "WARM_YELLOW", label: Text("Vàng ấm", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "SOFT_WHITE", label: Text("Trắng dịu", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "CYAN", label: Text("Xanh ngọc", style: TextStyle(fontSize: 10))),
                        ],
                        selected: {_nightlightColor},
                        onSelectionChanged: (val) => setState(() => _nightlightColor = val.first),
                        ),
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
                    "Kiểm tra tình trạng hoạt động của Cụm cảm biến đa phương thức (PIR AM312 + Radar 24GHz + Laser ToF + Còi & Pin UPS):",
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
                              child: const Text("v1.2.0 (Mới nhất)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purpleAccent)),
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
                    "Phiên bản: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)\nTự động tải và cập nhật trực tiếp phiên bản mới nhất từ GitHub qua mạng không cần cắm cáp máy tính.",
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
      builder: (ctx) {
        bool isLoading = true;
        Map<String, dynamic>? releaseInfo;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (isLoading && releaseInfo == null) {
              () async {
                try {
                  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
                  final request = await client.getUrl(
                    Uri.parse('https://api.github.com/repos/anlq295-work/FallDetection_S3R8/releases/latest'),
                  );
                  request.headers.set('User-Agent', 'FallGuardApp');
                  request.headers.set('Accept', 'application/vnd.github.v3+json');
                  final response = await request.close();
                  if (response.statusCode == 200) {
                    final body = await response.transform(utf8.decoder).join();
                    final data = jsonDecode(body) as Map<String, dynamic>;
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        releaseInfo = data;
                        isLoading = false;
                      });
                    }
                  } else {
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        isLoading = false;
                      });
                    }
                  }
                } catch (_) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              }();
            }

            int? apkSize;
            if (releaseInfo != null && releaseInfo!['assets'] is List) {
              for (var asset in (releaseInfo!['assets'] as List)) {
                if (asset is Map && asset['name'] == 'app-release.apk') {
                  apkSize = asset['size'] as int?;
                  break;
                }
              }
            }

            return AlertDialog(
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("Cập nhật ứng dụng OTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: SizedBox(
                width: _dialogContentWidth(context),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done, color: Colors.blueAccent, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("GitHub Releases (Trực tiếp)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                                  Text(
                                    Platform.isIOS ? "Apple In-House OTA (FallGuard_iOS_unsigned.ipa)" : "Android APK Release (app-release.apk)",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Phiên bản hiện tại:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                FutureBuilder<PackageInfo>(
                                  future: _appPackageInfo,
                                  builder: (context, snapshot) => Text(
                                    snapshot.hasData ? _appVersionLabel(snapshot.data!) : "Loading...",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Bản mới trên GitHub:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  releaseInfo?['name']?.toString() ?? (isLoading ? "Đang kết nối..." : "Fall Guard Latest Release"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            if (apkSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Dung lượng file APK:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    "${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Platform.isIOS
                            ? "Hệ thống sẽ mở đường dẫn cài đặt trực tiếp từ GitHub Releases. Nhấn [Cài đặt] để nâng cấp."
                            : "Hệ thống kết nối trực tiếp tới bản APK mới nhất trên GitHub Releases và mở trình cài đặt Android để nâng cấp đè giữ nguyên dữ liệu.",
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Đóng"),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final releasesPage = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest");
                    try {
                      await launchUrl(releasesPage, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text("Xem Release GitHub"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (Platform.isIOS) {
                      const otaUrl = "itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/ios_ota/manifest.plist";
                      final uri = Uri.parse(otaUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        final ipaUrl = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/FallGuard_iOS_unsigned.ipa");
                        await launchUrl(ipaUrl, mode: LaunchMode.externalApplication);
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
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Cài đặt cập nhật ngay"),
                ),
              ],
            );
          },
        );
      },
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
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
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
                width: _dialogContentWidth(context),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                urlController.text = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/firmware.bin";
                              },
                              child: const Text("GitHub Releases", style: TextStyle(fontSize: 10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                urlController.text = "https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/firmware.bin";
                              },
                              child: const Text("GitHub Raw", style: TextStyle(fontSize: 10)),
                            ),
                          ),
                        ],
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
                      if (widget.deviceIp.isNotEmpty) ...[
                        const Divider(height: 28),
                        const Text(
                          "2. Nạp trực tiếp qua Web OTA nội bộ (Siêu nhanh)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Mở trang nạp http://${widget.deviceIp}/update trực tiếp trong mạng Wi-Fi để nạp file firmware.bin không cần Internet.",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.greenAccent),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse("http://${widget.deviceIp}/update");
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lỗi mở Web OTA: $e")),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.language, size: 18, color: Colors.greenAccent),
                          label: Text("Mở Web OTA (http://${widget.deviceIp}/update)", style: const TextStyle(color: Colors.greenAccent)),
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        widget.deviceIp.isNotEmpty ? "3. Nạp qua Bluetooth Low Energy (BLE OTA)" : "2. Nạp qua Bluetooth Low Energy (BLE OTA)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
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
                            req.followRedirects = true;
                            req.maxRedirects = 5;
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
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

