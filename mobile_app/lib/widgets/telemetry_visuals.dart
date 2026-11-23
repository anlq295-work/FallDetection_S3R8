import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/app_strings.dart';
import 'liquid_glass.dart';

/// Compact, scalable real-time telemetry sparkline chart for ToF Height, Radar Motion & Static Energy.
class HearthLiveTelemetryChart extends StatelessWidget {
  final List<TelemetrySnapshot> samples;
  final AppStrings s;

  const HearthLiveTelemetryChart({
    super.key,
    required this.samples,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(color: p.accent, label: 'ToF (mm)'),
              _LegendDot(color: p.warning, label: 'Radar Motion'),
              _LegendDot(color: p.ok, label: 'Radar Static'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _TelemetryPainter(
                samples: samples,
                tofColor: p.accent,
                motionColor: p.warning,
                staticColor: p.ok,
                gridColor: p.border.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textMuted)),
      ],
    );
  }
}

class _TelemetryPainter extends CustomPainter {
  final List<TelemetrySnapshot> samples;
  final Color tofColor;
  final Color motionColor;
  final Color staticColor;
  final Color gridColor;

  _TelemetryPainter({
    required this.samples,
    required this.tofColor,
    required this.motionColor,
    required this.staticColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (samples.length < 2) return;

    void drawSeries(List<double> values, double maxVal, Color color) {
      final path = Path();
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final dx = size.width / math.max(1, values.length - 1);
      for (int i = 0; i < values.length; i++) {
        final norm = (values[i] / maxVal).clamp(0.0, 1.0);
        final x = i * dx;
        final y = size.height - norm * (size.height - 10) - 5;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawSeries(samples.map((e) => e.tofHeightMm.toDouble()).toList(), 2200, tofColor);
    drawSeries(samples.map((e) => e.radarMotion.toDouble()).toList(), 100, motionColor);
    drawSeries(samples.map((e) => e.radarStatic.toDouble()).toList(), 100, staticColor);
  }

  @override
  bool shouldRepaint(covariant _TelemetryPainter oldDelegate) => true;
}

/// Clean non-invasive AI posture illustration (STAND / SIT / LIE / FALL) for advanced sensor view in S8.
class HearthPostureCard extends StatelessWidget {
  final TelemetrySnapshot telemetry;
  final AppStrings s;

  const HearthPostureCard({
    super.key,
    required this.telemetry,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final isFall = telemetry.postureClass == 'FALL' || telemetry.isFallAlert;
    final accent = isFall ? p.critical : p.accent;
    final pct = (telemetry.confidence * 100).round().clamp(0, 100);

    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: CustomPaint(
              painter: _PostureFigurePainter(posture: telemetry.postureClass, color: accent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI: ${telemetry.postureClass} · $pct%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _MiniMetric('ToF', '${telemetry.tofHeightMm} mm'),
                    _MiniMetric('Drop', '${telemetry.dropRateMmS.toStringAsFixed(0)} mm/s'),
                    _MiniMetric('Motion', '${telemetry.radarMotion}/100'),
                    _MiniMetric('Static', '${telemetry.radarStatic}/100'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String k;
  final String v;
  const _MiniMetric(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Text(
      '$k: $v',
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textMuted),
    );
  }
}

class _PostureFigurePainter extends CustomPainter {
  final String posture;
  final Color color;

  _PostureFigurePainter({required this.posture, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;

    final floorY = size.height * 0.82;
    canvas.drawLine(
      Offset(10, floorY),
      Offset(size.width - 10, floorY),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );

    if (posture == 'FALL' || posture == 'LIE') {
      canvas.drawCircle(Offset(size.width * 0.24, floorY - 12), 7, fill);
      canvas.drawLine(Offset(size.width * 0.34, floorY - 10), Offset(size.width * 0.62, floorY - 9), stroke);
      canvas.drawLine(Offset(size.width * 0.62, floorY - 9), Offset(size.width * 0.82, floorY - 6), stroke);
    } else if (posture == 'SIT') {
      canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.28), 7, fill);
      canvas.drawLine(Offset(size.width * 0.42, size.height * 0.38), Offset(size.width * 0.42, size.height * 0.60), stroke);
      canvas.drawLine(Offset(size.width * 0.42, size.height * 0.60), Offset(size.width * 0.64, size.height * 0.60), stroke);
      canvas.drawLine(Offset(size.width * 0.64, size.height * 0.60), Offset(size.width * 0.64, floorY - 3), stroke);
    } else {
      // STAND
      canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.22), 7, fill);
      canvas.drawLine(Offset(size.width * 0.50, size.height * 0.32), Offset(size.width * 0.50, size.height * 0.58), stroke);
      canvas.drawLine(Offset(size.width * 0.50, size.height * 0.40), Offset(size.width * 0.34, size.height * 0.52), stroke);
      canvas.drawLine(Offset(size.width * 0.50, size.height * 0.40), Offset(size.width * 0.66, size.height * 0.52), stroke);
      canvas.drawLine(Offset(size.width * 0.50, size.height * 0.58), Offset(size.width * 0.40, floorY - 3), stroke);
      canvas.drawLine(Offset(size.width * 0.50, size.height * 0.58), Offset(size.width * 0.60, floorY - 3), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _PostureFigurePainter old) => old.posture != posture || old.color != color;
}
