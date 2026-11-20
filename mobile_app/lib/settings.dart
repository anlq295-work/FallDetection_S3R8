part of 'main.dart';

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
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
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

          // 3. HIỂN THỊ & ĐÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â N VỊ ĐO
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Đơn vị khoảng cách:", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Đơn vị năng lượng Radar:", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
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
                  Text("Phiên bản: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Vi điều khiển: ESP32-S3-WROOM-1-N16R8 (16MB Flash / 8MB PSRAM)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Cảm biến kết hợp: PIR AM312 (Hồng ngoại) + ToF Laser (Độ cao) + Radar 24GHz FMCW (Động năng & Cự ly)", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

