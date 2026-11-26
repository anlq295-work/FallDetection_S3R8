import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S3WifiSetupScreen extends StatefulWidget {
  final HearthController ctrl;
  final DiscoveredSensor sensor;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final void Function(String ssid, String? lanIp) onWifiConnected;

  const S3WifiSetupScreen({
    super.key,
    required this.ctrl,
    required this.sensor,
    required this.onBack,
    required this.onCancel,
    required this.onWifiConnected,
  });

  @override
  State<S3WifiSetupScreen> createState() => _S3WifiSetupScreenState();
}

class _S3WifiSetupScreenState extends State<S3WifiSetupScreen> {
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _obscurePass = true;
  bool _connecting = false;
  int _progressStage = 0; // 1=joining, 2=reaching, 3=done
  bool _success = false;
  String? _errorText;
  String? _assignedIp;

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _connectWifi() async {
    if (_connecting) return;
    final s = widget.ctrl.s;
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text;

    if (ssid.isEmpty) {
      setState(() => _errorText = s.s3SsidRequiredError);
      return;
    }

    setState(() {
      _connecting = true;
      _progressStage = 1;
      _errorText = null;
    });

    final ok = await widget.ctrl.hardware.provisionWifi(
      ssid,
      pass,
      sensor: widget.sensor,
    );
    if (!mounted) return;
    if (!ok) {
      final detail = widget.ctrl.hardware.lastBleError;
      setState(() {
        _connecting = false;
        _progressStage = 0;
        _errorText = detail != null && detail.isNotEmpty
            ? '${s.s3WrongPassword(ssid)} ($detail)'
            : s.s3WrongPassword(ssid);
      });
      _passFocus.requestFocus();
      return;
    }

    setState(() => _progressStage = 2);
    final verified = await widget.ctrl.hardware.waitForWifiConnection(widget.sensor);
    if (!mounted) return;
    if (!verified) {
      setState(() {
        _connecting = false;
        _progressStage = 0;
        _errorText = s.s3WifiNotVerified(ssid);
      });
      return;
    }
    setState(() {
      _progressStage = 3;
      _connecting = false;
      _success = true;
      _assignedIp = widget.ctrl.hardware.activeLanIp;
    });
  }

  void _showNoWifiHelp() {
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s3NoWifiLink, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(s.s3NoWifiBody, style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.close,
              onPressed: () => Navigator.pop(ctx),
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
    final activeSsid = _ssidCtrl.text.trim();

    final infoCard = LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_2_bar_rounded, color: p.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.sensor.name} · ${widget.sensor.shortCode}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.s3Helper, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );

    final credentialsCard = LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorText != null) ...[
            HearthBanner(
              tone: HearthBannerTone.critical,
              icon: Icons.error_outline_rounded,
              title: _errorText!,
            ),
            const SizedBox(height: 14),
          ],
          if (_success) ...[
            HearthBanner(
              tone: HearthBannerTone.ok,
              icon: Icons.wifi_rounded,
              title: s.s3SuccessBanner(activeSsid),
            ),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.continueBtn,
              onPressed: () => widget.onWifiConnected(activeSsid, _assignedIp),
            ),
          ] else ...[
            TextField(
              controller: _ssidCtrl,
              enabled: !_connecting,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: s.s3SsidLabel,
                hintText: s.s3SsidHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              focusNode: _passFocus,
              enabled: !_connecting,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _connectWifi(),
              decoration: InputDecoration(
                labelText: s.s3PasswordLabel,
                helperText: s.s3PasswordHelper,
                suffixIcon: IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(_obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            if (_connecting) ...[
              const SizedBox(height: 16),
              _StageRow(label: s.s3ProgressJoining(activeSsid), done: _progressStage > 1, active: _progressStage == 1),
              const SizedBox(height: 6),
              _StageRow(label: s.s3ProgressReaching, done: _progressStage > 2, active: _progressStage == 2),
              const SizedBox(height: 6),
              _StageRow(label: s.s3ProgressDone, done: _progressStage >= 3, active: false),
            ],
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.s3ConnectBtn,
              loading: _connecting,
              onPressed: _connectWifi,
            ),
            const SizedBox(height: 8),
            Center(
              child: HearthTextLink(
                label: s.s3NoWifiLink,
                onPressed: _showNoWifiHelp,
              ),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              HearthStepTopBar(
                step: 2,
                totalSteps: 4,
                customStepText: s.stepOf(2, 4),
                onBack: widget.onBack,
                trailing: HearthTextLink(label: s.cancel, onPressed: widget.onCancel),
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
                          Text(s.s3Title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (layout.isTwoPane)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: infoCard),
                                SizedBox(width: layout.hingeGap + 12),
                                Expanded(child: credentialsCard),
                              ],
                            )
                          else ...[
                            infoCard,
                            const SizedBox(height: 14),
                            credentialsCard,
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

class _StageRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StageRow({required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Row(
      children: [
        if (done)
          Icon(Icons.check_circle_rounded, color: p.ok, size: 20)
        else if (active)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: p.accent),
          )
        else
          Icon(Icons.radio_button_unchecked_rounded, color: p.border, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active || done ? FontWeight.w700 : FontWeight.w400,
              color: done ? p.ok : (active ? p.text : p.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}
