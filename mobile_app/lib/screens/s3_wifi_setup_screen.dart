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
  final _manualSsidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _loadingList = true;
  bool _manualMode = false;
  bool _obscurePass = true;
  bool _connecting = false;
  int _progressStage = 0; // 1=joining, 2=reaching, 3=done
  bool _success = false;
  String? _errorText;
  String? _selectedSsid;
  String? _assignedIp;

  List<WifiNetworkCandidate> _networks = const [];

  @override
  void initState() {
    super.initState();
    _loadNetworks();
  }

  @override
  void dispose() {
    _manualSsidCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _loadNetworks() async {
    setState(() {
      _loadingList = true;
      _errorText = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      _loadingList = false;
      _networks = const [
        WifiNetworkCandidate(ssid: 'Home_2.4G', rssi: -52),
        WifiNetworkCandidate(ssid: 'VNPT_2.4GHz', rssi: -63),
        WifiNetworkCandidate(ssid: 'FPT_LivingRoom', rssi: -76),
      ];
      _selectedSsid = _networks.first.ssid;
    });
  }

  Future<void> _connectWifi() async {
    final s = widget.ctrl.s;
    final ssid = _manualMode ? _manualSsidCtrl.text.trim() : (_selectedSsid ?? '').trim();
    final pass = _passCtrl.text;

    if (ssid.isEmpty) {
      setState(() => _errorText = s.s3NoNetworksError);
      return;
    }

    setState(() {
      _connecting = true;
      _progressStage = 1;
      _errorText = null;
    });

    final ok = await widget.ctrl.hardware.provisionWifi(ssid, pass);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _progressStage = 0;
        _errorText = s.s3WrongPassword(ssid);
      });
      _passFocus.requestFocus();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _progressStage = 2);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _progressStage = 3;
      _connecting = false;
      _success = true;
      _assignedIp = widget.ctrl.hardware.activeLanIp ?? '192.168.1.48';
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
    final activeSsid = _manualMode ? _manualSsidCtrl.text.trim() : (_selectedSsid ?? '');

    final networksPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.s3NetworksTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (_loadingList) ...[
          Text(s.s3ScanningNetworks, style: TextStyle(fontSize: 15, color: p.textMuted)),
          const SizedBox(height: 10),
          const LiquidGlassCard(child: HearthSkeleton(height: 36)),
          const SizedBox(height: 8),
          const LiquidGlassCard(child: HearthSkeleton(height: 36)),
          const SizedBox(height: 8),
          const LiquidGlassCard(child: HearthSkeleton(height: 36)),
        ] else ...[
          ..._networks.map((net) {
            final selected = !_manualMode && _selectedSsid == net.ssid;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LiquidGlassCard(
                selected: selected,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: _connecting
                    ? null
                    : () => setState(() {
                          _manualMode = false;
                          _selectedSsid = net.ssid;
                          _errorText = null;
                        }),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: selected ? p.accent : p.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        net.ssid,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                      ),
                    ),
                    HearthSignalIndicator(rssi: net.rssi, s: s),
                  ],
                ),
              ),
            );
          }),
          LiquidGlassCard(
            selected: _manualMode,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: _connecting ? null : () => setState(() => _manualMode = true),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: p.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.s3ManualNetwork,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    final credentialsPanel = LiquidGlassCard(
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
              title: s.s3SuccessBanner(activeSsid.isEmpty ? 'Wi-Fi' : activeSsid),
            ),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.continueBtn,
              onPressed: () => widget.onWifiConnected(
                activeSsid.isEmpty ? 'Home_2.4G' : activeSsid,
                _assignedIp,
              ),
            ),
          ] else ...[
            if (_manualMode) ...[
              TextField(
                controller: _manualSsidCtrl,
                enabled: !_connecting,
                decoration: InputDecoration(labelText: s.s3SsidLabel),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _passCtrl,
              focusNode: _passFocus,
              enabled: !_connecting,
              obscureText: _obscurePass,
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
                          const SizedBox(height: 8),
                          Text(s.s3Helper, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          if (layout.isTwoPane)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: networksPanel),
                                SizedBox(width: layout.hingeGap + 12),
                                Expanded(child: credentialsPanel),
                              ],
                            )
                          else ...[
                            networksPanel,
                            const SizedBox(height: 16),
                            credentialsPanel,
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
