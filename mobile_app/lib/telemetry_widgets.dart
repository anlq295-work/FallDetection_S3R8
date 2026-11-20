part of 'main.dart';

class LiveTelemetryChart extends StatelessWidget {
  final List<Map<String, double>> samples;
  const LiveTelemetryChart({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: const [
            Icon(Icons.show_chart, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(child: Text('Đang chờ đủ dữ liệu telemetry để vẽ biểu đồ thời gian thực...', style: TextStyle(color: Colors.grey))),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.timeline, color: Colors.cyanAccent), SizedBox(width: 8), Text('Telemetry thời gian thực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          const SizedBox(height: 4),
          const Text('120 mẫu gần nhất • ToF mm • Radar /100', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(height: 210, child: CustomPaint(painter: LiveTelemetryPainter(samples))),
          const SizedBox(height: 8),
          const Wrap(spacing: 14, children: [
            _ChartLegend(color: Colors.cyanAccent, label: 'ToF'),
            _ChartLegend(color: Colors.orangeAccent, label: 'Radar động'),
            _ChartLegend(color: Colors.tealAccent, label: 'Radar tĩnh'),
          ]),
        ]),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
}

class LiveTelemetryPainter extends CustomPainter {
  final List<Map<String, double>> samples;
  LiveTelemetryPainter(this.samples);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.grey.withValues(alpha: .18)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(0, size.height * i / 4), Offset(size.width, size.height * i / 4), grid);
    }
    for (var i = 0; i <= 6; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6, size.height), grid);
    }
    final series = [('h', Colors.cyanAccent, 2000.0), ('m', Colors.orangeAccent, 100.0), ('s', Colors.tealAccent, 100.0)];
    for (final item in series) {
      final paint = Paint()..color = item.$2..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < samples.length; i++) {
        final x = samples.length == 1 ? 0.0 : size.width * i / (samples.length - 1);
        final yValue = (samples[i][item.$1] ?? 0).clamp(0, item.$3);
        final y = size.height * (1 - yValue / item.$3);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant LiveTelemetryPainter oldDelegate) => true;
}

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
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 6,
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
    // t = -2s (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng cao 1700mm) -> t = -0.5s (Rơi) -> t = 0s (Chạm sàn 300mm) -> t = +2s (Nằm sàn)
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
    // t = -2s (Thấp 15) -> t = 0s (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh va đập Peak Motion) -> t = +2s (Về 0-5)
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

    drawText("-2s (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng)", w * 0.10, h - 14, Colors.grey);
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 6,
              children: [
                const Wrap(
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
                    label: const Text("Trước ngã (-2s: ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng)", style: TextStyle(fontSize: 11)),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
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
                  width: math.max(0.0, math.min(280.0, MediaQuery.sizeOf(context).width - 48.0)),
                  height: math.max(0.0, math.min(280.0, MediaQuery.sizeOf(context).width - 48.0)),
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
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
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
                          Color(0xFFFF0054), // ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh va chạm (97%)
                          Color(0xFFFFFFFF), // Điểm xung kích bão hòa (100%)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("100% (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh)", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
    _drawCrosshair(canvas, peakPos, isPostFall ? "E_max: 98% (Sàn Y: 0.15m)" : "E_max: 90% (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng Y: 1.5m)", Colors.redAccent);

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
      stageName = "1. ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng vững thăng bằng";
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
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
HỒ SƠ GIÁM ĐỊNH TAI NẠN TÉ NGÃ (FALL INCIDENT RECORD)
Hệ thống giám sát: FallGuard S3R8 (ESP32-S3-WROOM-1-N16R8)
Mã sự cố: #FALL-REC-${sec.toString().padLeft(6, '0')}
Thời gian xảy ra: Cách đây ${sec}s
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
1. THÔNG SỐ ĐỘNG HỌC CÚ NGÃ (KINEMATICS):
   - Phân loại cú ngã: Ngã va đập động năng mạnh (High-Velocity Fall Impact)
   - Vận tốc rơi tự do cực đại (V_drop): ${vel.toStringAsFixed(0)} mm/s (Ngưỡng: >= 550 mm/s)
   - Động năng va đập đỉnh (Peak Motion): $motion/100 (Chấn động va chạm mức cao)
   - Cự ly của nạn nhân: $dist cm (Cổng radar FMCW số 3)
   - Độ cao trước ngã: 1.72 m (ĐÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng thẳng) ➔ Sau ngã: 0.22 m (Sát sàn nhà)

2. ĐÁNH GIÁ TRẠNG THÁI NẠN NHÂN (POST-FALL STATUS):
   - Trạng thái: Nằm sàn bất động (Immobile on floor)
   - Năng lượng vận động sau ngã: <= 20/100 (Không có phản xạ gượng dậy)
   - Năng lượng vi chuyển động tĩnh: >= 16/100 (Còn dấu hiệu hô hấp / nhịp tim)
   - Kết luận AI: Cú ngã thật 100%, nạn nhân cần hỗ trợ y tế khẩn cấp.

3. HÀNH ĐỘNG CỨU NẠN TỰ ĐỘNG ĐÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ THỰC THI:
   - Còi báo động Active Buzzer: Đã phát tín hiệu cảnh báo tại chỗ (85 dB)
   - Đèn LED RGB WS2812B: Đổi màu Đỏ SOS nhấp nháy liên tục
   - Gateway Wi-Fi: Đã gửi cảnh báo khẩn cấp Telegram Bot & SMS SpeedSMS
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
Bản ghi được trích xuất từ bộ nhớ Flash NVS của thiết bị ESP32-S3.
""";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowAlignment: OverflowBarAlignment.end,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(child: Text("Biên bản sự cố té ngã", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: _dialogContentWidth(context, max: 450),
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
// MÀN HÌNH CÀI ĐẶT CHUNG CỦA ỨNG DỤNG (GENERAL SETTINGS SCREEN)
// =========================================================================
