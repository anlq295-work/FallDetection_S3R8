import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S5TestSensorScreen extends StatefulWidget {
  final HearthController ctrl;
  final HearthRoom room;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const S5TestSensorScreen({
    super.key,
    required this.ctrl,
    required this.room,
    required this.onBack,
    required this.onFinish,
  });

  @override
  State<S5TestSensorScreen> createState() => _S5TestSensorScreenState();
}

class _S5TestSensorScreenState extends State<S5TestSensorScreen> {
  bool _waitingPresence = true;
  bool _presencePassed = false;
  bool _presenceTimedOut = false;
  bool _sendingAlert = false;
  bool _alertPassed = false;
  DateTime? _alertTime;
  Timer? _presenceTimer;
  StreamSubscription<TelemetrySnapshot>? _telemSub;

  @override
  void initState() {
    super.initState();
    _startPresenceCheck();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _telemSub?.cancel();
    super.dispose();
  }

  void _startPresenceCheck() {
    _presenceTimer?.cancel();
    _telemSub?.cancel();
    setState(() {
      _waitingPresence = true;
      _presenceTimedOut = false;
      _presencePassed = false;
    });

    // Listen for real ESP32 presence (PIR / Radar / ToF)
    _telemSub = widget.ctrl.hardware.telemetryStream.listen((snap) {
      if (snap.isPersonPresent && mounted && !_presencePassed) {
        _markPresencePassed();
      }
    });

    // If using simulated sensor, auto-detect presence smoothly after 2.5s; otherwise 60s timeout
    if (!widget.ctrl.hardware.isBleConnected && !widget.ctrl.hardware.isLanConnected) {
      _presenceTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted && !_presencePassed) _markPresencePassed();
      });
    } else {
      _presenceTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && !_presencePassed) {
          setState(() {
            _waitingPresence = false;
            _presenceTimedOut = true;
          });
        }
      });
    }
  }

  void _markPresencePassed() {
    _presenceTimer?.cancel();
    setState(() {
      _waitingPresence = false;
      _presenceTimedOut = false;
      _presencePassed = true;
    });
  }

  Future<void> _sendTestAlert() async {
    setState(() => _sendingAlert = true);
    await widget.ctrl.hardware.sendCommand('TEST_ALARM', overrideLanIp: widget.room.lanIp);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final now = DateTime.now();
    await widget.ctrl.logEvent(
      HearthEvent(
        id: 'ev_test_${now.millisecondsSinceEpoch}',
        roomId: widget.room.id,
        roomName: widget.room.name,
        type: HearthEventType.testPassed,
        at: now,
      ),
    );
    setState(() {
      _sendingAlert = false;
      _alertPassed = true;
      _alertTime = now;
    });
  }

  void _confirmSkip() {
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s5SkipConfirmTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(s.s5SkipConfirmBody, style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 18),
            HearthPrimaryButton(
              label: s.s5GoBackToTest,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            HearthSecondaryButton(
              label: s.s5SkipLink,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onFinish();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);
    final bothPassed = _presencePassed && _alertPassed;

    final check1Card = LiquidGlassCard(
      borderColor: _presencePassed ? p.ok.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _presencePassed ? Icons.check_circle_rounded : Icons.directions_walk_rounded,
                color: _presencePassed ? p.ok : p.accent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.s5Check1Title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.s5Check1Desc(widget.room.name), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: _presencePassed
                ? HearthStatusBadge(icon: Icons.check_rounded, label: s.s5PresenceOk, color: p.ok)
                : _presenceTimedOut
                    ? HearthBanner(
                        tone: HearthBannerTone.warning,
                        icon: Icons.warning_amber_rounded,
                        title: s.s5PresenceTimeout,
                        action: HearthSecondaryButton(label: s.retry, onPressed: _startPresenceCheck),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: p.accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _waitingPresence ? s.s5WaitingMovement : s.s5PresenceNotDone,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.accent),
                            ),
                          ),
                        ],
                      ),
          ),
          if (!_presencePassed) ...[
            const SizedBox(height: 12),
            HearthSecondaryButton(
              label: s.s5SimulatePresence,
              onPressed: _markPresencePassed,
            ),
          ],
        ],
      ),
    );

    final check2Card = LiquidGlassCard(
      borderColor: _alertPassed ? p.ok.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _alertPassed ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                color: _alertPassed ? p.ok : p.accent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.s5Check2Title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.s5Check2Desc, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(s.s5SoundMedium, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (_alertPassed && _alertTime != null)
            HearthStatusBadge(
              icon: Icons.check_rounded,
              label: s.s5ReadyBanner(s.formatClock(_alertTime!), widget.room.name),
              color: p.ok,
            )
          else
            HearthStatusBadge(
              icon: Icons.schedule_rounded,
              label: s.s5PresenceNotDone,
              color: p.textMuted,
            ),
        ],
      ),
    );

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              HearthStepTopBar(
                step: 4,
                totalSteps: 4,
                customStepText: s.stepOf(4, 4),
                onBack: widget.onBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: layout.isTwoPane ? 960 : 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.s5Title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (layout.isTwoPane)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: check1Card),
                                SizedBox(width: layout.hingeGap + 12),
                                Expanded(child: check2Card),
                              ],
                            )
                          else ...[
                            check1Card,
                            const SizedBox(height: 14),
                            check2Card,
                          ],
                          const SizedBox(height: 22),
                          HearthPrimaryButton(
                            label: bothPassed ? s.s5StartMonitoring : s.s5SendTestBtn,
                            loadingLabel: s.s5SendingTest,
                            loading: _sendingAlert,
                            icon: bothPassed ? Icons.verified_user_rounded : Icons.campaign_rounded,
                            onPressed: bothPassed ? widget.onFinish : _sendTestAlert,
                          ),
                          if (!bothPassed) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: HearthTextLink(
                                label: s.s5SkipLink,
                                onPressed: _confirmSkip,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
