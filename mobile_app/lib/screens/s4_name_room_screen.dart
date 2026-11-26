import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S4NameRoomScreen extends StatefulWidget {
  final HearthController ctrl;
  final DiscoveredSensor sensor;
  final String wifiSsid;
  final String? lanIp;
  final VoidCallback onBack;
  final ValueChanged<HearthRoom> onRoomSaved;

  const S4NameRoomScreen({
    super.key,
    required this.ctrl,
    required this.sensor,
    required this.wifiSsid,
    this.lanIp,
    required this.onBack,
    required this.onRoomSaved,
  });

  @override
  State<S4NameRoomScreen> createState() => _S4NameRoomScreenState();
}

class _S4NameRoomScreenState extends State<S4NameRoomScreen> {
  RoomType? _selectedType;
  final _roomNameCtrl = TextEditingController();
  late final TextEditingController _personCtrl;
  bool _saving = false;
  String? _errorText;
  String? _personError;

  @override
  void initState() {
    super.initState();
    _personCtrl = TextEditingController(text: widget.ctrl.personName);
  }

  @override
  void dispose() {
    _roomNameCtrl.dispose();
    _personCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    final s = widget.ctrl.s;
    final roomName = _roomNameCtrl.text.trim();
    final personName = _personCtrl.text.trim();
    setState(() {
      _errorText = null;
      _personError = null;
    });

    if (_selectedType == null && roomName.isEmpty) {
      setState(() => _errorText = s.s4MissingError);
      return;
    }

    // Strict required field: never allow blank personName or invent a generic name!
    if (personName.isEmpty) {
      setState(() => _personError = s.s4PersonRequiredError);
      return;
    }

    final finalName = roomName.isNotEmpty ? roomName : s.roomTypeName(_selectedType!);
    final duplicate = widget.ctrl.rooms.any(
      (r) => r.name.toLowerCase() == finalName.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _errorText = s.s4DuplicateError(finalName));
      return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await widget.ctrl.setPersonName(personName);
    final liveSensor = widget.lanIp != null
        ? await widget.ctrl.hardware.fetchLanTelemetry(widget.lanIp!)
        : null;
    if (!mounted) return;

    final now = DateTime.now();
    final room = HearthRoom(
      id: 'room_${now.millisecondsSinceEpoch}',
      name: finalName,
      type: _selectedType ?? RoomType.other,
      status: RoomStatus.empty,
      lastMovementAt: now,
      sensorId: liveSensor?.deviceId.isNotEmpty == true ? liveSensor!.deviceId : widget.sensor.shortCode,
      bleDeviceId: widget.sensor.id,
      lanIp: widget.lanIp,
      wifiSsid: widget.wifiSsid,
      wifiRssi: widget.sensor.rssi,
      lastCheckedAt: now,
    );

    await widget.ctrl.addOrUpdateRoom(room);
    if (!mounted) return;
    setState(() => _saving = false);
    showHearthToast(context, s.s4SavedToast(finalName));
    widget.onRoomSaved(room);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              HearthStepTopBar(
                step: 3,
                totalSteps: 4,
                customStepText: s.stepOf(3, 4),
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
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.s4Title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            const gap = 10.0;
                            final columns = constraints.maxWidth >= 420 ? 3 : (constraints.maxWidth >= 260 ? 2 : 1);
                            final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
                            return Wrap(spacing: gap, runSpacing: gap, children: RoomType.values.map((type) {
                              final selected = _selectedType == type;
                              return SizedBox(width: itemWidth, child: LiquidGlassCard(
                                selected: selected,
                                borderRadius: 14,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                onTap: _saving
                                    ? null
                                    : () => setState(() {
                                          _selectedType = type;
                                          _roomNameCtrl.text = s.roomTypeName(type);
                                          _errorText = null;
                                        }),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(type.icon, size: 22, color: selected ? p.accent : p.textMuted),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        s.roomTypeName(type),
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                          color: selected ? p.accent : p.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                            }).toList());
                          }),
                          const SizedBox(height: 18),
                          LiquidGlassCard(
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
                                TextField(
                                  controller: _roomNameCtrl,
                                  enabled: !_saving,
                                  decoration: InputDecoration(
                                    labelText: s.s4RoomNameLabel,
                                    helperText: s.s4RoomNameHelper,
                                    helperMaxLines: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _personCtrl,
                                  enabled: !_saving,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: s.s4PersonLabel,
                                    hintText: s.s4PersonPlaceholder,
                                    helperText: s.s4PersonHelper,
                                    helperMaxLines: 2,
                                    errorText: _personError,
                                    errorMaxLines: 2,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                HearthPrimaryButton(
                                  label: s.s4SaveBtn,
                                  loadingLabel: s.s4Saving,
                                  loading: _saving,
                                  onPressed: _saveRoom,
                                ),
                              ],
                            ),
                          ),
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
