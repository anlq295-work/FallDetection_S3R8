import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S2FindSensorScreen extends StatefulWidget {
  final HearthController ctrl;
  final bool showIntroBanner;
  final VoidCallback? onBack;
  final ValueChanged<DiscoveredSensor> onSensorConnected;

  const S2FindSensorScreen({
    super.key,
    required this.ctrl,
    this.showIntroBanner = false,
    this.onBack,
    required this.onSensorConnected,
  });

  @override
  State<S2FindSensorScreen> createState() => _S2FindSensorScreenState();
}

class _S2FindSensorScreenState extends State<S2FindSensorScreen> {
  bool _btPermissionGranted = false;
  bool _scanning = false;
  bool _connecting = false;
  bool _connectedSuccess = false;
  String? _errorText;
  List<DiscoveredSensor> _sensors = [];
  String? _selectedId;

  Future<void> _grantPermissionAndScan() async {
    setState(() {
      _btPermissionGranted = true;
      _errorText = null;
    });
    await _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _errorText = null;
      _sensors = [];
      _selectedId = null;
    });

    final hw = widget.ctrl.hardware;
    final found = await hw.scanNearbySensors(timeout: const Duration(seconds: 4));

    if (!mounted) return;
    setState(() {
      _scanning = false;
      _sensors = found;
      if (_sensors.length == 1) {
        _selectedId = _sensors.first.id;
      }
    });
  }

  Future<void> _connectSelected() async {
    if (_selectedId == null) return;
    final sensor = _sensors.firstWhere((e) => e.id == _selectedId);

    setState(() {
      _connecting = true;
      _errorText = null;
    });

    final ok = await widget.ctrl.hardware.connectBleSensor(sensor);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _connecting = false;
        _errorText = widget.ctrl.s.s2BtOffError;
      });
      return;
    }

    setState(() {
      _connecting = false;
      _connectedSuccess = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    widget.onSensorConnected(sensor);
  }

  void _selectDemoSensor() {
    const demo = DiscoveredSensor(
      id: 'DEMO-4F2A',
      shortCode: '4F2A',
      name: 'FallDetector_S3R8',
      rssi: -52,
      isSimulated: true,
    );
    setState(() {
      _btPermissionGranted = true;
      _sensors = [demo];
      _selectedId = demo.id;
      _errorText = null;
    });
  }

  void _openNotShowingHelp() {
    final idCtrl = TextEditingController();
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s2HelpTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(s.s2HelpBody, style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextField(
              controller: idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: s.s2ManualIdLabel,
                hintText: '4F2A',
              ),
            ),
            const SizedBox(height: 14),
            HearthPrimaryButton(
              label: s.s2UseManualId,
              onPressed: () {
                final code = idCtrl.text.trim().isEmpty ? '4F2A' : idCtrl.text.trim().toUpperCase();
                final manual = DiscoveredSensor(
                  id: 'MANUAL-$code',
                  shortCode: code.length > 4 ? code.substring(code.length - 4) : code,
                  name: 'FallDetector_S3R8',
                  rssi: -58,
                  isSimulated: true,
                );
                Navigator.pop(ctx);
                setState(() {
                  _btPermissionGranted = true;
                  _sensors = [manual];
                  _selectedId = manual.id;
                });
              },
            ),
            const SizedBox(height: 8),
            HearthSecondaryButton(
              label: s.s2UseDemoSensor,
              onPressed: () {
                Navigator.pop(ctx);
                _selectDemoSensor();
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

    final checklistPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showIntroBanner) ...[
          HearthBanner(
            tone: HearthBannerTone.info,
            icon: Icons.tips_and_updates_rounded,
            title: s.s1SetupIntro,
          ),
          const SizedBox(height: 14),
        ],
        LiquidGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.sensors_rounded, size: 32, color: p.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'HEARTH',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CheckItem(number: '1', text: s.s2Step1),
              const SizedBox(height: 10),
              _CheckItem(number: '2', text: s.s2Step2),
              const SizedBox(height: 10),
              _CheckItem(number: '3', text: s.s2Step3),
            ],
          ),
        ),
      ],
    );

    final discoveryPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorText != null) ...[
          HearthBanner(
            tone: HearthBannerTone.critical,
            icon: Icons.bluetooth_disabled_rounded,
            title: _errorText!,
            action: HearthSecondaryButton(
              label: s.retry,
              onPressed: _scan,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_connectedSuccess && _selectedId != null) ...[
          HearthBanner(
            tone: HearthBannerTone.ok,
            icon: Icons.check_circle_rounded,
            title: s.s2ConnectedTitle(
              _sensors.firstWhere((e) => e.id == _selectedId).shortCode,
            ),
            subtitle: s.s2ConnectedLightCopy,
          ),
        ] else if (!_btPermissionGranted) ...[
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.bluetooth_searching_rounded, size: 38, color: p.accent),
                const SizedBox(height: 12),
                Text(
                  s.s2PermissionTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                HearthPrimaryButton(
                  label: s.s2AllowBluetooth,
                  icon: Icons.bluetooth_rounded,
                  onPressed: _grantPermissionAndScan,
                ),
                const SizedBox(height: 8),
                Center(
                  child: HearthTextLink(
                    label: s.s2UseDemoSensor,
                    onPressed: _selectDemoSensor,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(s.s2SensorsNearby, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_scanning) ...[
            Semantics(
              liveRegion: true,
              child: Text(s.s2Searching, style: TextStyle(fontSize: 15, color: p.textMuted)),
            ),
            const SizedBox(height: 10),
            const LiquidGlassCard(child: HearthSkeleton(height: 44)),
            const SizedBox(height: 10),
            const LiquidGlassCard(child: HearthSkeleton(height: 44)),
          ] else if (_sensors.isEmpty) ...[
            LiquidGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.bluetooth_searching_rounded, size: 40, color: p.textMuted),
                  const SizedBox(height: 10),
                  Text(s.s2NotFound, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  HearthPrimaryButton(
                    label: s.s2SearchAgain,
                    icon: Icons.refresh_rounded,
                    onPressed: _scan,
                  ),
                  const SizedBox(height: 8),
                  HearthSecondaryButton(
                    label: s.s2UseDemoSensor,
                    onPressed: _selectDemoSensor,
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._sensors.map((sensor) {
              final selected = sensor.id == _selectedId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LiquidGlassCard(
                  selected: selected,
                  onTap: _connecting ? null : () => setState(() => _selectedId = sensor.id),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: selected ? p.accent : p.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.s2SensorRowTitle(sensor.shortCode),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                            ),
                            const SizedBox(height: 4),
                            HearthSignalIndicator(rssi: sensor.rssi, s: s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            HearthPrimaryButton(
              label: s.s2ConnectBtn,
              loadingLabel: s.s2Connecting,
              loading: _connecting,
              onPressed: _selectedId == null ? null : _connectSelected,
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: HearthTextLink(
              label: s.s2NotShowingLink,
              onPressed: _openNotShowingHelp,
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              HearthStepTopBar(
                step: 1,
                totalSteps: 4,
                customStepText: s.stepOf(1, 4),
                onBack: widget.onBack,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HearthLanguagePill(
                    current: widget.ctrl.language,
                    onSelected: widget.ctrl.setLanguage,
                  ),
                ),
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
                          Text(s.s2Title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (layout.isTwoPane)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: checklistPanel),
                                SizedBox(width: layout.hingeGap + 12),
                                Expanded(child: discoveryPanel),
                              ],
                            )
                          else ...[
                            checklistPanel,
                            const SizedBox(height: 18),
                            discoveryPanel,
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

class _CheckItem extends StatelessWidget {
  final String number;
  final String text;
  const _CheckItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.accent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}
