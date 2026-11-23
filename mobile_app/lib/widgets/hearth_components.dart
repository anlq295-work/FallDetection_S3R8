import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/app_strings.dart';
import 'liquid_glass.dart';

/// Focus-ring wrapper giving every interactive control a crisp 3px accent focus ring + 2px offset.
class HearthFocusRing extends StatefulWidget {
  final Widget child;
  final double borderRadius;

  const HearthFocusRing({
    super.key,
    required this.child,
    this.borderRadius = HearthTokens.buttonRadius,
  });

  @override
  State<HearthFocusRing> createState() => _HearthFocusRingState();
}

class _HearthFocusRingState extends State<HearthFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Focus(
      canRequestFocus: false,
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(_focused ? 2 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius + 4),
          border: _focused ? Border.all(color: p.accent, width: 3) : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Primary button (ONLY ONE per screen, filled with color.accent).
class HearthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final IconData? icon;
  final double minHeight;
  final bool expand;

  const HearthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.icon,
    this.minHeight = HearthTokens.minTarget + 2,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFF071529) : Colors.white;

    final btn = SizedBox(
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: fg,
          disabledBackgroundColor: p.accent.withValues(alpha: 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.85),
          minimumSize: Size(HearthTokens.minTarget, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HearthTokens.buttonRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.3, color: fg),
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                loading ? (loadingLabel ?? label) : label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
    return HearthFocusRing(child: btn);
  }
}

/// Secondary button (outline, frosted glass backdrop).
class HearthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minHeight;
  final bool expand;

  const HearthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minHeight = HearthTokens.minTarget + 2,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final btn = SizedBox(
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          backgroundColor: isDark ? const Color(0x55182433) : const Color(0xB3FFFFFF),
          side: BorderSide(color: p.border, width: 1.4),
          minimumSize: Size(HearthTokens.minTarget, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HearthTokens.buttonRadius),
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: p.accent),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
    return HearthFocusRing(child: btn);
  }
}

/// Destructive & Emergency outline button in color.critical (per UX Spec Section 2).
class HearthCriticalOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minHeight;
  final bool expand;

  const HearthCriticalOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minHeight = HearthTokens.minTarget + 2,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final btn = SizedBox(
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: p.critical,
          backgroundColor: p.critical.withValues(alpha: 0.08),
          side: BorderSide(color: p.critical, width: 1.8),
          minimumSize: Size(HearthTokens.minTarget, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HearthTokens.buttonRadius),
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: p.critical),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.critical),
              ),
            ),
          ],
        ),
      ),
    );
    return HearthFocusRing(child: btn);
  }
}

/// Tertiary text link with >= 48px accessible hit target.
class HearthTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool critical;
  final IconData? icon;

  const HearthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.critical = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final color = critical ? p.critical : p.accent;
    return HearthFocusRing(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(HearthTokens.minTarget, HearthTokens.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pill that ALWAYS pairs icon + text + color (never color alone).
class HearthStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const HearthStatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top bar for S2–S5 setup flow with Back button, "Step X of 4", and 4-segment Liquid Glass progress bar.
class HearthStepTopBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String? customStepText;
  final VoidCallback? onBack;
  final Widget? trailing;

  const HearthStepTopBar({
    super.key,
    required this.step,
    this.totalSteps = 4,
    this.customStepText,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.arrow_back_rounded, color: p.text),
              )
            else
              const SizedBox(width: 8),
            Expanded(
              child: Text(
                customStepText ?? 'Step $step of $totalSteps',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textMuted),
              ),
            ),
            ?trailing,
          ],
        ),
        if (totalSteps > 0) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(totalSteps, (index) {
                final active = index < step;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: active ? p.accent : p.border.withValues(alpha: 0.55),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

enum HearthBannerTone { info, ok, warning, critical }

class HearthBanner extends StatelessWidget {
  final HearthBannerTone tone;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const HearthBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final Color color;
    switch (tone) {
      case HearthBannerTone.info:
        color = p.accent;
        break;
      case HearthBannerTone.ok:
        color = p.ok;
        break;
      case HearthBannerTone.warning:
        color = p.warning;
        break;
      case HearthBannerTone.critical:
        color = p.critical;
        break;
    }

    return Semantics(
      liveRegion: tone == HearthBannerTone.critical || tone == HearthBannerTone.warning,
      child: LiquidGlassCard(
        borderRadius: 16,
        borderColor: color.withValues(alpha: 0.55),
        borderWidth: tone == HearthBannerTone.critical ? 1.8 : 1.3,
        tintColor: Color.alphaBlend(color.withValues(alpha: 0.08), p.glassFill),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 15, color: p.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Signal strength indicator with visual bars + explicit word (Strong/Weak) for accessibility.
class HearthSignalIndicator extends StatelessWidget {
  final int rssi;
  final AppStrings s;

  const HearthSignalIndicator({
    super.key,
    required this.rssi,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final strong = rssi >= -72;
    final bars = rssi >= -60 ? 3 : (rssi >= -75 ? 2 : 1);
    final color = strong ? p.ok : p.warning;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final filled = i < bars;
            return Container(
              width: 4,
              height: 7.0 + i * 4.5,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: filled ? color : p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          strong ? s.s2SignalStrong : s.s2SignalWeak,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

/// Subtle pulsing skeleton placeholder for loading states.
class HearthSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const HearthSkeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 10,
  });

  @override
  State<HearthSkeleton> createState() => _HearthSkeletonState();
}

class _HearthSkeletonState extends State<HearthSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: p.border.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: p.border.withValues(alpha: 0.25 + 0.30 * _ctrl.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Language switcher pill supporting VI (default) / EN / FR at any moment.
class HearthLanguagePill extends StatelessWidget {
  final AppLanguage current;
  final ValueChanged<AppLanguage> onSelected;

  const HearthLanguagePill({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return PopupMenuButton<AppLanguage>(
      initialValue: current,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => AppLanguage.values.map((lang) {
        final selected = lang == current;
        return PopupMenuItem<AppLanguage>(
          value: lang,
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: selected ? Icon(Icons.check_rounded, size: 18, color: p.accent) : null,
              ),
              Text(
                '${lang.shortCode} · ${lang.nativeName}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: LiquidGlassPill(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 17, color: p.accent),
            const SizedBox(width: 6),
            Text(
              current.shortCode,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Brand mark for Hearth
class HearthBrandMark extends StatelessWidget {
  final double size;
  const HearthBrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.accent,
            Color.lerp(p.accent, const Color(0xFF2FA8A2), 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: p.accent.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.home_rounded, color: Colors.white, size: size * 0.56),
    );
  }
}

void showHearthToast(BuildContext context, String message, {bool critical = false}) {
  final p = HearthPalette.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: critical ? p.critical : const Color(0xFF1A2636),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 3),
      ),
    );
}
