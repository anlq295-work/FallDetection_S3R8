import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

/// Atmospheric Liquid Glass backdrop that gives frosted panels genuine depth and specular refraction
/// while preserving crisp high-contrast readability (WCAG AA/AAA).
class LiquidGlassBackdrop extends StatelessWidget {
  final Widget child;
  final bool criticalTint;

  const LiquidGlassBackdrop({
    super.key,
    required this.child,
    this.criticalTint = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColors = criticalTint
        ? (isDark
            ? const [Color(0xFF1A0B0D), Color(0xFF130D14), Color(0xFF0B1018)]
            : const [Color(0xFFFFF4F3), Color(0xFFFDF7F8), Color(0xFFF3F6FB)])
        : (isDark
            ? const [Color(0xFF08101A), Color(0xFF0D1724), Color(0xFF09121C)]
            : const [Color(0xFFF2F6FC), Color(0xFFF9FBFE), Color(0xFFEEF4FA)]);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: baseColors,
            ),
          ),
        ),
        // Soft ambient refraction orbs (non-distracting, subtle glass depth)
        Positioned(
          top: -90,
          left: -70,
          child: _AmbientOrb(
            size: 280,
            color: criticalTint
                ? const Color(0xFFB42318).withValues(alpha: isDark ? 0.24 : 0.10)
                : const Color(0xFF1F5FBF).withValues(alpha: isDark ? 0.22 : 0.11),
          ),
        ),
        Positioned(
          top: 140,
          right: -100,
          child: _AmbientOrb(
            size: 260,
            color: criticalTint
                ? const Color(0xFFFF7A59).withValues(alpha: isDark ? 0.14 : 0.08)
                : const Color(0xFF2FA8A2).withValues(alpha: isDark ? 0.15 : 0.09),
          ),
        ),
        Positioned(
          bottom: -110,
          left: 40,
          child: _AmbientOrb(
            size: 300,
            color: const Color(0xFF5D8BF4).withValues(alpha: isDark ? 0.13 : 0.08),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Core Liquid Glass panel with frosted backdrop blur, top-left specular sheen,
/// crisp luminous border, and optional accessible focus ring.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticsLabel;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = HearthTokens.cardRadius,
    this.blurSigma = 20,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1.25,
    this.onTap,
    this.selected = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final effectiveTint = tintColor ?? p.glassFill;
    final effectiveBorder = selected
        ? p.accent
        : (borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.85)));

    Widget glassBody = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
                  effectiveTint,
                ),
                effectiveTint,
                Color.alphaBlend(
                  (selected ? p.accent : p.surface).withValues(alpha: isDark ? 0.12 : 0.20),
                  effectiveTint,
                ),
              ],
            ),
            border: Border.all(
              color: effectiveBorder,
              width: selected ? 2.2 : borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: p.glassShadow,
                blurRadius: 22,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Specular top-edge liquid light reflection
              Positioned(
                top: 0,
                left: 14,
                right: 14,
                height: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: isDark ? 0.32 : 0.95),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      glassBody = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          focusColor: p.accent.withValues(alpha: 0.18),
          highlightColor: p.accent.withValues(alpha: 0.08),
          child: glassBody,
        ),
      );
    }

    if (semanticsLabel != null) {
      return Semantics(
        label: semanticsLabel,
        button: onTap != null,
        selected: selected,
        child: glassBody,
      );
    }
    return glassBody;
  }
}

/// Floating Liquid Glass pill container (used for language selector, live chips, navigation capsule)
class LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tintColor;
  final Color? borderColor;

  const LiquidGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.onTap,
    this.tintColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(999);

    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: tintColor ?? (isDark ? const Color(0xB8182535) : const Color(0xD9FFFFFF)),
            border: Border.all(
              color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.9)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: p.glassShadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HearthTokens.minTarget),
          child: Center(widthFactor: 1, child: content),
        ),
      ),
    );
  }
}

/// Adaptive Liquid Glass modal: bottom sheet on phones, centered frosted dialog on tablets/foldables/desktops.
Future<T?> showLiquidGlassAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  double maxDialogWidth = 540,
}) {
  final layout = HearthLayout.of(context);
  final p = HearthPalette.of(context);

  if (layout.isTwoPane) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxModalWidth(preferred: maxDialogWidth)),
          child: LiquidGlassCard(
            borderRadius: 24,
            blurSigma: 26,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: builder(ctx)),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(10, 24, 10, bottomInset + 10),
        child: LiquidGlassCard(
          borderRadius: 26,
          blurSigma: 26,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  builder(ctx),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
