import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/material.dart';

enum DeviceFormFactor {
  compactPhone, // < 380dp
  phone, // 380 - 599dp
  foldableOrTablet, // 600 - 1023dp (includes unfolded phones & tablets)
  desktopOrLargeTablet, // >= 1024dp
}

class HearthLayout {
  final Size size;
  final Orientation orientation;
  final List<DisplayFeature> displayFeatures;

  const HearthLayout({
    required this.size,
    required this.orientation,
    required this.displayFeatures,
  });

  factory HearthLayout.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return HearthLayout(
      size: mq.size,
      orientation: mq.orientation,
      displayFeatures: mq.displayFeatures,
    );
  }

  double get width => size.width;
  double get height => size.height;

  DeviceFormFactor get formFactor {
    if (width >= 1024) return DeviceFormFactor.desktopOrLargeTablet;
    if (width >= 600) return DeviceFormFactor.foldableOrTablet;
    if (width < 380) return DeviceFormFactor.compactPhone;
    return DeviceFormFactor.phone;
  }

  bool get isPhone => width < 600;
  bool get isTabletOrFoldable => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
  bool get isTwoPane => width >= 600;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Detects a vertical hinge on folding phones (Galaxy Z Fold, Pixel Fold, Surface Duo)
  Rect? get verticalHingeBounds {
    for (final feature in displayFeatures) {
      if ((feature.type == DisplayFeatureType.hinge || feature.type == DisplayFeatureType.fold) &&
          feature.bounds.height > feature.bounds.width &&
          feature.bounds.left > 0) {
        return feature.bounds;
      }
    }
    return null;
  }

  bool get hasVerticalHinge => verticalHingeBounds != null;

  /// Smooth scale factor for spacing and subtle typography adjustments across phone sizes
  double get scale {
    if (width < 360) return 0.90;
    if (width < 410) return 0.96;
    if (width < 600) return 1.0;
    if (width < 1024) return 1.04;
    return 1.06;
  }

  double get horizontalPadding {
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 1024) return 24;
    return 32;
  }

  double get sectionGap => (20 * scale).roundToDouble();
  double get cardGap => (12 * scale).roundToDouble();

  /// Left master-pane width on tablets & foldables (respects hinge if present)
  double get masterPaneWidth {
    final hinge = verticalHingeBounds;
    if (hinge != null && hinge.left >= 280) {
      return hinge.left;
    }
    return math.min(380.0, math.max(320.0, width * 0.40));
  }

  double get hingeGap => verticalHingeBounds?.width ?? 16.0;

  double maxModalWidth({double preferred = 560}) {
    return math.min(preferred, math.max(280, width - 32));
  }
}

/// Keeps text readable up to 200% Dynamic Type without breaking layouts
class ResponsiveTextScaleGuard extends StatelessWidget {
  final Widget child;
  final double maxScale;

  const ResponsiveTextScaleGuard({
    super.key,
    required this.child,
    this.maxScale = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final clamped = mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: maxScale);
    return MediaQuery(
      data: mq.copyWith(textScaler: clamped),
      child: child,
    );
  }
}
