import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/telemetry_visuals.dart';

class S8RoomDetailScreen extends StatefulWidget {
  final HearthController ctrl;
  final String roomId;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback onReconnectSensor;
  final VoidCallback onTestSensor;
  final ValueChanged<String> onSeeEarlierDays;

  const S8RoomDetailScreen({
    super.key,
    required this.ctrl,
    required this.roomId,
    this.embedded = false,
    this.onBack,
    required this.onReconnectSensor,
    required this.onTestSensor,
    required this.onSeeEarlierDays,
  });

  @override
  State<S8RoomDetailScreen> createState() => _S8RoomDetailScreenState();
}

class _S8RoomDetailScreenState extends State<S8RoomDetailScreen> {
  bool _showLiveHardware = false;

  HearthRoom? get _room {
    for (final r in widget.ctrl.rooms) {
      if (r.id == widget.roomId) return r;
    }
    return null;
  }

  void _openRenameModal(HearthRoom room) {
    final nameCtrl = TextEditingController(text: room.name);
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s8RenameRoom, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: s.s4RoomNameLabel),
            ),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.save,
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await widget.ctrl.renameRoom(room.id, nameCtrl.text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _openAlarmSoundModal(HearthRoom room) {
    AlarmSoundLevel vol = room.alarmVolume;
    bool activeHigh = room.buzzerActiveHigh;

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          final p = HearthPalette.of(c);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s8AlarmVolume, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...AlarmSoundLevel.values.map((lv) {
                final selected = vol == lv;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LiquidGlassCard(
                    selected: selected,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onTap: () => setModalState(() => vol = lv),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selected ? p.accent : p.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Text(s.soundLevelLabel(lv), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Buzzer Active-HIGH (GPIO5)'),
                subtitle: Text(
                  activeHigh ? 'Active-HIGH (3.3V = Beep)' : 'Active-LOW (0V = Beep, default 3-pin module)',
                ),
                value: activeHigh,
                onChanged: (v) => setModalState(() => activeHigh = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: HearthSecondaryButton(
                      label: 'Test Beep',
                      icon: Icons.volume_up_rounded,
                      onPressed: () => widget.ctrl.hardware.sendCommand('TEST_BEEP', overrideLanIp: room.lanIp),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HearthPrimaryButton(
                      label: s.save,
                      onPressed: () async {
                        await widget.ctrl.updateRoomSettings(
                          room.id,
                          alarmVolume: vol,
                          buzzerActiveHigh: activeHigh,
                        );
                        if (c.mounted) Navigator.pop(c);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _openNightlightModal(HearthRoom room) {
    bool enabled = room.nightlightEnabled;
    int startH = room.nightStartHour;
    int endH = room.nightEndHour;

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s8NightLight, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.s8NightLight),
                value: enabled,
                onChanged: (v) => setModalState(() => enabled = v),
              ),
              if (enabled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: startH,
                        decoration: const InputDecoration(labelText: 'Start (h)'),
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')),
                        ),
                        onChanged: (v) => setModalState(() => startH = v ?? startH),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: endH,
                        decoration: const InputDecoration(labelText: 'End (h)'),
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')),
                        ),
                        onChanged: (v) => setModalState(() => endH = v ?? endH),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              HearthPrimaryButton(
                label: s.save,
                onPressed: () async {
                  await widget.ctrl.updateRoomSettings(
                    room.id,
                    nightlightEnabled: enabled,
                    nightStartHour: startH,
                    nightStartMinute: 0,
                    nightEndHour: endH,
                    nightEndMinute: 0,
                  );
                  if (c.mounted) Navigator.pop(c);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openInactivityModal(HearthRoom room) {
    int mins = room.inactivityLimitMinutes;
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s8InactivityAlert, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('Off')),
                  ButtonSegment(value: 15, label: Text(s.s9Minutes(15))),
                  ButtonSegment(value: 30, label: Text(s.s9Minutes(30))),
                  ButtonSegment(value: 60, label: Text(s.s9Minutes(60))),
                ],
                selected: {mins},
                onSelectionChanged: (set) => setModalState(() => mins = set.first),
              ),
              const SizedBox(height: 18),
              HearthPrimaryButton(
                label: s.save,
                onPressed: () async {
                  await widget.ctrl.updateRoomSettings(room.id, inactivityLimitMinutes: mins);
                  if (c.mounted) Navigator.pop(c);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAdjustDetectionModal(HearthRoom room) {
    double floorMm = room.floorThresholdMm.toDouble().clamp(200, 800);
    final ipCtrl = TextEditingController(text: room.lanIp ?? '');

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s8AdjustDetection, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(s.s8AdjustDetectionSub, style: Theme.of(c).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text('Floor height threshold: ${floorMm.round()} mm', style: Theme.of(c).textTheme.titleMedium),
              Slider(
                min: 200,
                max: 800,
                divisions: 24,
                value: floorMm,
                label: '${floorMm.round()} mm',
                onChanged: (v) => setModalState(() => floorMm = v),
              ),
              const SizedBox(height: 8),
              HearthSecondaryButton(
                label: s.s8CalibrateFloor,
                icon: Icons.straighten_rounded,
                onPressed: () async {
                  await widget.ctrl.hardware.sendCommand('CALIBRATE_FLOOR', overrideLanIp: room.lanIp);
                  if (mounted) showHearthToast(context, 'CALIBRATE_FLOOR sent');
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'ESP32 Wi-Fi LAN IP (Port 80)',
                  hintText: '192.168.1.48',
                ),
              ),
              const SizedBox(height: 16),
              HearthPrimaryButton(
                label: s.save,
                onPressed: () async {
                  final ip = ipCtrl.text.trim();
                  if (ip.isNotEmpty) {
                    widget.ctrl.hardware.startLanPolling(ip);
                    await widget.ctrl.markRoomOnlineAfterReconnect(room.id, lanIp: ip);
                  }
                  await widget.ctrl.updateRoomSettings(room.id, floorThresholdMm: floorMm.round());
                  if (c.mounted) Navigator.pop(c);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openRemoteChannelsModal() {
    final tokenCtrl = TextEditingController(text: widget.ctrl.telegramBotToken);
    final chatCtrl = TextEditingController(text: widget.ctrl.telegramChatId);

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s8RemoteChannels, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Telegram Bot Token',
                hintText: '123456:ABC-DEF...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chatCtrl,
              decoration: const InputDecoration(
                labelText: 'Telegram Chat / Group IDs',
                helperText: 'Comma-separated (e.g. -100192837465, 512345678)',
              ),
            ),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.save,
              onPressed: () async {
                await widget.ctrl.updateRemoteChannels(
                  telegramBotToken: tokenCtrl.text,
                  telegramChatId: chatCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  showHearthToast(context, 'Synced to ESP32-S3');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openOtaModal(HearthRoom room) {
    final urlCtrl = TextEditingController();
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s8FirmwareOta, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Current firmware: ${room.firmwareVersion}', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 14),
            HearthPrimaryButton(
              label: 'OTA Latest (GitHub Releases)',
              icon: Icons.system_update_alt_rounded,
              onPressed: () async {
                await widget.ctrl.hardware.sendCommand('OTA_LATEST', overrideLanIp: room.lanIp);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  showHearthToast(context, 'OTA_LATEST triggered on ESP32-S3');
                }
              },
            ),
            const SizedBox(height: 12),
            if (room.lanIp != null && room.lanIp!.isNotEmpty) ...[
              HearthSecondaryButton(
                label: 'Web OTA (http://${room.lanIp}/update)',
                icon: Icons.open_in_browser_rounded,
                onPressed: () async {
                  final uri = Uri.parse('http://${room.lanIp}/update');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Custom Firmware URL (.bin)',
                hintText: 'https://.../firmware.bin',
              ),
            ),
            const SizedBox(height: 10),
            HearthSecondaryButton(
              label: 'Flash from URL',
              onPressed: () async {
                final u = urlCtrl.text.trim();
                if (u.isNotEmpty) {
                  await widget.ctrl.hardware.sendCommand('OTA_HTTP:$u', overrideLanIp: room.lanIp);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openBlackboxModal(HearthRoom room) async {
    await widget.ctrl.hardware.sendCommand('GET_HISTORY', overrideLanIp: room.lanIp);
    if (!mounted) return;
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        final events = widget.ctrl.blackboxEvents;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s8BlackboxHistory, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Text(s.s8NoEventsToday, style: Theme.of(ctx).textTheme.bodyMedium)
            else
              ...events.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded),
                  title: Text('Type #${e.type} · ${e.velocityMmS.toStringAsFixed(0)} mm/s'),
                  subtitle: Text('Motion: ${e.motionPeak}/100 · Dist: ${e.targetDistCm} cm · @${e.uptimeSec}s'),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HearthSecondaryButton(
                    label: 'Add Test Event',
                    onPressed: () => widget.ctrl.hardware.sendCommand('ADD_TEST_EVENT', overrideLanIp: room.lanIp),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HearthCriticalOutlineButton(
                    label: 'Clear Flash',
                    onPressed: () => widget.ctrl.hardware.sendCommand('CLEAR_HISTORY', overrideLanIp: room.lanIp),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openMaintenanceModal(HearthRoom room) {
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        final s = widget.ctrl.s;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.s8Maintenance, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            HearthSecondaryButton(
              label: 'Reboot ESP32-S3',
              icon: Icons.restart_alt_rounded,
              onPressed: () async {
                await widget.ctrl.hardware.sendCommand('REBOOT', overrideLanIp: room.lanIp);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            HearthSecondaryButton(
              label: 'Reset Wi-Fi Credentials',
              icon: Icons.wifi_off_rounded,
              onPressed: () async {
                await widget.ctrl.hardware.sendCommand('RESET_NETWORK', overrideLanIp: room.lanIp);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            HearthCriticalOutlineButton(
              label: 'Factory Reset NVS Flash',
              icon: Icons.delete_forever_rounded,
              onPressed: () async {
                await widget.ctrl.hardware.sendCommand('FACTORY_RESET', overrideLanIp: room.lanIp);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);
    final room = _room;

    if (room == null) {
      return Center(child: Text(s.s6EmptyTitle));
    }

    final isOffline = room.status == RoomStatus.offline;
    final roomEvents = ctrl.events.where((e) => e.roomId == room.id).toList();
    final wifiQuality = room.wifiRssi >= -67 ? s.s8WifiGood : s.s8WifiFair;
    final nightRange =
        '${room.nightStartHour.toString().padLeft(2, '0')}:${room.nightStartMinute.toString().padLeft(2, '0')}–${room.nightEndHour.toString().padLeft(2, '0')}:${room.nightEndMinute.toString().padLeft(2, '0')}';

    final statusAndSettings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOffline) ...[
          HearthBanner(
            tone: HearthBannerTone.critical,
            icon: Icons.wifi_off_rounded,
            title: s.s6OfflineSince(room.name, s.formatClock(room.offlineSince ?? room.lastCheckedAt)),
            subtitle: s.s6IssueSummary(room.name),
            action: HearthPrimaryButton(
              label: s.s6ReconnectSensor,
              icon: Icons.bluetooth_searching_rounded,
              onPressed: widget.onReconnectSensor,
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(room.type.icon, color: p.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HearthStatusBadge(
                        icon: room.status == RoomStatus.occupied
                            ? Icons.person_rounded
                            : Icons.radio_button_unchecked_rounded,
                        label: room.status == RoomStatus.occupied
                            ? '${s.s6StatusOccupied} · ${s.formatRelativeTime(room.lastMovementAt)}'
                            : '${s.s6StatusEmpty} · ${s.s6LastPresence(s.formatClock(room.lastMovementAt))}',
                        color: room.status == RoomStatus.occupied ? p.ok : p.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  s.s8OnlineHealth(wifiQuality, s.formatClock(room.lastCheckedAt)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${room.sensorId} · FW ${room.firmwareVersion}${room.lanIp != null ? " · LAN ${room.lanIp}" : ""}',
                  style: TextStyle(fontSize: 13.5, color: p.textMuted),
                ),
                const SizedBox(height: 16),
                HearthPrimaryButton(
                  label: s.s8TestSensor,
                  icon: Icons.verified_user_outlined,
                  onPressed: widget.onTestSensor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Optional Live ESP32-S3 Telemetry & Posture panel (preserves all advanced features without cluttering everyday carers)
        LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () => setState(() => _showLiveHardware = !_showLiveHardware),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors_rounded, color: p.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.s8LiveHardwareTitle, style: Theme.of(context).textTheme.titleMedium),
                        Text(s.s8LiveHardwareSub, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(_showLiveHardware ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                ],
              ),
              if (_showLiveHardware) ...[
                const SizedBox(height: 12),
                if (room.latestTelemetry != null) ...[
                  HearthPostureCard(telemetry: room.latestTelemetry!, s: s),
                  const SizedBox(height: 10),
                ],
                HearthLiveTelemetryChart(
                  samples: ctrl.telemetryHistory.isNotEmpty
                      ? ctrl.telemetryHistory
                      : (room.latestTelemetry != null ? [room.latestTelemetry!, room.latestTelemetry!] : []),
                  s: s,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HearthCriticalOutlineButton(
                      label: s.s8TriggerSos,
                      expand: false,
                      icon: Icons.sos_rounded,
                      onPressed: () {
                        ctrl.hardware.sendCommand('PANIC_SOS', overrideLanIp: room.lanIp);
                        ctrl.triggerFallAlert(roomId: room.id, simulated: true);
                      },
                    ),
                    HearthSecondaryButton(
                      label: s.s8CalibrateFloor,
                      expand: false,
                      icon: Icons.straighten_rounded,
                      onPressed: () {
                        ctrl.hardware.sendCommand('CALIBRATE_FLOOR', overrideLanIp: room.lanIp);
                        showHearthToast(context, 'CALIBRATE_FLOOR');
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Settings section (56px rows)
        Text(s.s8RoomSettings, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LiquidGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.volume_up_rounded,
                title: s.s8AlarmVolume,
                subtitle: s.soundLevelLabel(room.alarmVolume),
                onTap: () => _openAlarmSoundModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.nightlight_round,
                title: s.s8NightLight,
                subtitle: room.nightlightEnabled ? 'On ($nightRange)' : 'Off',
                onTap: () => _openNightlightModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.hourglass_bottom_rounded,
                title: s.s8InactivityAlert,
                subtitle: room.inactivityLimitMinutes == 0
                    ? 'Off'
                    : s.s9Minutes(room.inactivityLimitMinutes),
                onTap: () => _openInactivityModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.tune_rounded,
                title: s.s8AdjustDetection,
                subtitle: '${room.floorThresholdMm} mm · ${s.s8AdjustDetectionSub}',
                onTap: () => _openAdjustDetectionModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.send_rounded,
                title: s.s8RemoteChannels,
                subtitle: ctrl.telegramChatId.isEmpty ? 'Telegram / SMS' : 'Telegram: ${ctrl.telegramChatId}',
                onTap: _openRemoteChannelsModal,
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.history_rounded,
                title: s.s8BlackboxHistory,
                subtitle: '${ctrl.blackboxEvents.length} / 5',
                onTap: () => _openBlackboxModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.system_update_alt_rounded,
                title: s.s8FirmwareOta,
                subtitle: room.firmwareVersion,
                onTap: () => _openOtaModal(room),
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.build_circle_outlined,
                title: s.s8Maintenance,
                subtitle: 'Reboot / Reset Wi-Fi / Factory Reset',
                onTap: () => _openMaintenanceModal(room),
              ),
            ],
          ),
        ),
      ],
    );

    final timelineColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.s8TodayTimeline, style: Theme.of(context).textTheme.titleMedium)),
            HearthTextLink(
              label: s.s8SeeEarlierDays,
              onPressed: () => widget.onSeeEarlierDays(room.id),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (roomEvents.isEmpty)
          LiquidGlassCard(
            child: Text(s.s8NoEventsToday, style: Theme.of(context).textTheme.bodyLarge),
          )
        else
          LiquidGlassCard(
            child: Column(
              children: List.generate(roomEvents.length, (i) {
                final ev = roomEvents[i];
                final isCritical =
                    ev.type == HearthEventType.fallDetected || ev.type == HearthEventType.sensorOffline;
                final isOk = ev.type == HearthEventType.fallResolved || ev.type == HearthEventType.testPassed;
                final dotColor = isCritical ? p.critical : (isOk ? p.ok : p.accent);

                return Padding(
                  padding: EdgeInsets.only(bottom: i == roomEvents.length - 1 ? 0 : 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          s.formatClock(ev.at),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textMuted),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5, right: 12),
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.eventTitle(ev, ctrl.personName),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                            ),
                            if (ev.outcome != null)
                              Text(
                                s.outcomeLabel(ev.outcome!, ctrl.personName),
                                style: TextStyle(fontSize: 14.5, color: p.textMuted),
                              ),
                            if (ev.note != null && ev.note!.isNotEmpty)
                              Text(ev.note!, style: TextStyle(fontSize: 14, color: p.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );

    final header = Row(
      children: [
        if (!widget.embedded && widget.onBack != null)
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        Expanded(
          child: Text(
            room.name,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) async {
            if (v == 'rename') _openRenameModal(room);
            if (v == 'remove') {
              await ctrl.removeRoom(room.id);
              if (!widget.embedded) widget.onBack?.call();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'rename', child: Text(s.s8RenameRoom)),
            PopupMenuItem(
              value: 'remove',
              child: Text(s.s8RemoveRoom, style: TextStyle(color: p.critical)),
            ),
          ],
        ),
      ],
    );

    final content = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 16 : layout.horizontalPadding,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          if (!widget.embedded && layout.isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: statusAndSettings),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: timelineColumn),
              ],
            )
          else ...[
            statusAndSettings,
            const SizedBox(height: 18),
            timelineColumn,
          ],
          const SizedBox(height: 32),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(child: content),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: p.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: p.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
