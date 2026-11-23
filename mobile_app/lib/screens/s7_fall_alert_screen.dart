import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/medical_dialogs.dart';

class S7FallAlertView extends StatefulWidget {
  final HearthController ctrl;
  final ActiveFallAlert alert;
  final bool asDialog;
  final ValueChanged<String>? onResolvedNavigateToRoom;

  const S7FallAlertView({
    super.key,
    required this.ctrl,
    required this.alert,
    this.asDialog = false,
    this.onResolvedNavigateToRoom,
  });

  @override
  State<S7FallAlertView> createState() => _S7FallAlertViewState();
}

class _S7FallAlertViewState extends State<S7FallAlertView> {
  final _titleFocus = FocusNode();
  bool _ackFailed = false;
  bool _acknowledging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _dial(String rawNumber) async {
    final clean = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      showHearthToast(context, clean);
    }
  }

  Future<void> _handleRespond() async {
    setState(() {
      _acknowledging = true;
      _ackFailed = false;
    });
    final ok = await widget.ctrl.acknowledgeActiveAlert();
    if (!mounted) return;
    setState(() {
      _acknowledging = false;
      _ackFailed = !ok;
    });
  }

  void _confirmFalseAlarm() {
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s7FalseAlarmTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(s.s7FalseAlarmBody(widget.alert.roomName), style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 18),
            HearthPrimaryButton(
              label: s.s7KeepAlertOpen,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            HearthCriticalOutlineButton(
              label: s.s7OutcomeFalse,
              onPressed: () async {
                Navigator.pop(ctx);
                final roomId = widget.alert.roomId;
                await widget.ctrl.resolveActiveAlert(outcome: FallResolutionOutcome.falseAlarm);
                widget.onResolvedNavigateToRoom?.call(roomId);
              },
            ),
          ],
        );
      },
    );
  }

  void _openResolveSheet() {
    FallResolutionOutcome selected = FallResolutionOutcome.personOk;
    final noteCtrl = TextEditingController();

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (c, setModalState) {
            final s = widget.ctrl.s;
            final p = HearthPalette.of(c);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.s7ResolveTitle, style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 14),
                ...FallResolutionOutcome.values.map((o) {
                  final active = selected == o;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LiquidGlassCard(
                      selected: active,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => setModalState(() => selected = o),
                      child: Row(
                        children: [
                          Icon(
                            active ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: active ? p.accent : p.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.outcomeLabel(o, widget.alert.personName),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: s.s7OptionalNote),
                ),
                const SizedBox(height: 16),
                HearthPrimaryButton(
                  label: s.s7MarkResolved,
                  onPressed: () async {
                    Navigator.pop(c);
                    final roomId = widget.alert.roomId;
                    await widget.ctrl.resolveActiveAlert(
                      outcome: selected,
                      note: noteCtrl.text,
                    );
                    widget.onResolvedNavigateToRoom?.call(roomId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCountdown(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final alert = widget.alert;
    final backup = ctrl.nextEscalationContact;
    final secLeft = ctrl.escalationSecondsLeft;
    final announceEscalation = secLeft % 30 == 0;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Critical header band
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: p.critical,
            borderRadius: widget.asDialog
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            top: !widget.asDialog,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Focus(
                        focusNode: _titleFocus,
                        child: Text(
                          s.s7Title(alert.personName),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${alert.roomName} · ${s.formatClock(alert.detectedAt)} · ${s.formatRelativeTime(alert.detectedAt)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main actionable body
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_ackFailed && backup != null) ...[
                HearthBanner(
                  tone: HearthBannerTone.critical,
                  icon: Icons.wifi_off_rounded,
                  title: s.s7AckError(backup.name),
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      HearthSecondaryButton(
                        label: s.retry,
                        expand: false,
                        onPressed: _handleRespond,
                      ),
                      HearthCriticalOutlineButton(
                        label: s.s7CallPerson(backup.name),
                        expand: false,
                        onPressed: () => _dial(backup.phone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Context block
              LiquidGlassCard(
                borderColor: p.critical.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContextLine(
                      icon: alert.movementDetectedAt != null
                          ? Icons.directions_walk_rounded
                          : Icons.accessibility_new_rounded,
                      color: alert.movementDetectedAt != null ? p.warning : p.critical,
                      text: alert.movementDetectedAt != null
                          ? s.s7MovementAt(s.formatClock(alert.movementDetectedAt!))
                          : s.s7NoMovementSince(s.formatClock(alert.detectedAt)),
                    ),
                    const SizedBox(height: 10),
                    _ContextLine(
                      icon: alert.roomAlarmActive
                          ? Icons.notifications_active_rounded
                          : Icons.lightbulb_rounded,
                      color: p.accent,
                      text: alert.roomAlarmActive
                          ? s.s7LightAlarmOn(alert.roomName)
                          : s.s7LightOnlyOn(alert.roomName),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: announceEscalation,
                      child: _ContextLine(
                        icon: alert.isAcknowledged ? Icons.check_circle_rounded : Icons.timer_rounded,
                        color: alert.isAcknowledged ? p.ok : p.warning,
                        text: alert.isAcknowledged
                            ? s.s7RespondingStatus(backup?.name)
                            : (backup != null
                                ? s.s7EscalationCountdown(backup.name, _formatCountdown(secLeft))
                                : s.s7EscalationNoBackup),
                      ),
                    ),
                    if (alert.telemetry != null) ...[
                      const Divider(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          HearthStatusBadge(
                            icon: Icons.speed_rounded,
                            label: 'Drop: ${alert.telemetry!.dropRateMmS.toStringAsFixed(0)} mm/s',
                            color: p.critical,
                          ),
                          HearthStatusBadge(
                            icon: Icons.radar_rounded,
                            label: 'Radar: ${alert.telemetry!.radarMotion}/100',
                            color: p.warning,
                          ),
                          HearthStatusBadge(
                            icon: Icons.favorite_rounded,
                            label: 'Static: ${alert.telemetry!.radarStatic}/100',
                            color: p.ok,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary 56px action (ONLY ONE primary accent button)
              if (!alert.isAcknowledged)
                HearthPrimaryButton(
                  label: s.s7PrimaryRespond,
                  loading: _acknowledging,
                  minHeight: HearthTokens.alertTarget,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _handleRespond,
                )
              else ...[
                HearthPrimaryButton(
                  label: s.s7MarkResolved,
                  minHeight: HearthTokens.alertTarget,
                  icon: Icons.task_alt_rounded,
                  onPressed: _openResolveSheet,
                ),
                if (alert.roomAlarmActive) ...[
                  const SizedBox(height: 10),
                  HearthSecondaryButton(
                    label: s.s7TurnOffRoomAlarm,
                    minHeight: HearthTokens.alertTarget,
                    icon: Icons.volume_off_rounded,
                    onPressed: ctrl.turnOffRoomAlarmOnly,
                  ),
                ],
              ],

              const SizedBox(height: 12),

              // Secondary call row (56px each)
              Row(
                children: [
                  Expanded(
                    child: HearthSecondaryButton(
                      label: s.s7CallPerson(alert.personName),
                      minHeight: HearthTokens.alertTarget,
                      icon: Icons.call_rounded,
                      onPressed: () => _dial(ctrl.medicalProfile.personPhone),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HearthCriticalOutlineButton(
                      label: s.s7CallEmergency(ctrl.emergencyServiceNumber),
                      minHeight: HearthTokens.alertTarget,
                      icon: Icons.emergency_rounded,
                      onPressed: () => _dial(ctrl.emergencyServiceNumber),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 1-tap clinical helpers (First Aid + Medical ID from existing Fall Guard app)
              Row(
                children: [
                  Expanded(
                    child: HearthSecondaryButton(
                      label: s.firstAidTitle,
                      icon: Icons.medical_services_outlined,
                      onPressed: () => showFirstAidGuideModal(context, ctrl),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HearthSecondaryButton(
                      label: s.medicalIdTitle,
                      icon: Icons.badge_outlined,
                      onPressed: () => showMedicalIdModal(context, ctrl),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Center(
                child: HearthTextLink(
                  label: s.s7FalseAlarmLink,
                  critical: true,
                  onPressed: _confirmFalseAlarm,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.asDialog) {
      final layout = HearthLayout.of(context);
      return PopScope(
        canPop: false,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: layout.maxModalWidth(preferred: 600),
                maxHeight: layout.height * 0.90,
              ),
              child: LiquidGlassCard(
                borderRadius: 24,
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(child: body),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: LiquidGlassBackdrop(
          criticalTint: true,
          child: SingleChildScrollView(child: body),
        ),
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ContextLine({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text),
          ),
        ),
      ],
    );
  }
}
