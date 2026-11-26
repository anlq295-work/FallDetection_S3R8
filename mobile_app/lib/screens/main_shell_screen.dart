import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/medical_dialogs.dart';
import 's8_room_detail_screen.dart';
import 's9_contacts_screen.dart';

class MainShellScreen extends StatefulWidget {
  final HearthController ctrl;
  final VoidCallback onAddRoom;
  final ValueChanged<HearthRoom> onReconnectRoom;
  final ValueChanged<HearthRoom> onTestRoom;
  final VoidCallback onSignedOut;

  const MainShellScreen({
    super.key,
    required this.ctrl,
    required this.onAddRoom,
    required this.onReconnectRoom,
    required this.onTestRoom,
    required this.onSignedOut,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _tabIndex = 0; // 0=Home, 1=Activity, 2=Settings
  String? _selectedRoomId;
  String? _activityRoomFilter;
  bool _loadingHome = false;

  Future<void> _refreshHome() async {
    setState(() => _loadingHome = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (mounted) setState(() => _loadingHome = false);
  }

  void _openRoom(HearthRoom room, HearthLayout layout) {
    setState(() => _selectedRoomId = room.id);
    if (layout.isPhone || layout.isDesktop) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ListenableBuilder(
            listenable: widget.ctrl,
            builder: (ctx, _) => S8RoomDetailScreen(
              ctrl: widget.ctrl,
              roomId: room.id,
              onBack: () => Navigator.of(ctx).pop(),
              onReconnectSensor: () {
                Navigator.of(ctx).pop();
                widget.onReconnectRoom(room);
              },
              onTestSensor: () => widget.onTestRoom(room),
              onSeeEarlierDays: (rId) {
                Navigator.of(ctx).pop();
                setState(() {
                  _activityRoomFilter = rId;
                  _tabIndex = 1;
                });
              },
            ),
          ),
        ),
      );
    }
  }

  void _openQuickCareProfileModal() {
    final carerCtrl = TextEditingController(text: widget.ctrl.carerName);
    final personCtrl = TextEditingController(text: widget.ctrl.personName);
    final phoneCtrl = TextEditingController(text: widget.ctrl.medicalProfile.personPhone);
    String? personErr;
    String? carerErr;

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s6CompleteProfileBtn, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: carerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.s1CarerNameLabel,
                  errorText: carerErr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: personCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.s4PersonLabel,
                  errorText: personErr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s.s1PersonPhoneLabel),
              ),
              const SizedBox(height: 16),
              HearthPrimaryButton(
                label: s.save,
                onPressed: () async {
                  final cn = carerCtrl.text.trim();
                  final pn = personCtrl.text.trim();
                  setModalState(() {
                    carerErr = cn.isEmpty ? s.requiredFieldError : null;
                    personErr = pn.isEmpty ? s.s4PersonRequiredError : null;
                  });
                  if (cn.isEmpty || pn.isEmpty) return;
                  await widget.ctrl.updateCareIdentity(
                    carerName: cn,
                    personName: pn,
                    personPhone: phoneCtrl.text.trim(),
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

  Future<void> _checkUpdatesModal() async {
    final pkg = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) {
        return FutureBuilder(
          future: widget.ctrl.hardware.fetchLatestGitHubRelease(),
          builder: (c, snap) {
            final s = widget.ctrl.s;
            final p = HearthPalette.of(c);
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [HearthSkeleton(height: 22), SizedBox(height: 12), HearthSkeleton(height: 44)],
                ),
              );
            }
            final rel = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.appUpdatesTitle, style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Release: $kAppReleaseLabel\nInstalled version: ${pkg.version} · Build ${pkg.buildNumber}',
                  style: TextStyle(fontSize: 15, color: p.textMuted),
                ),
                const SizedBox(height: 12),
                if (rel == null)
                  HearthBanner(
                    tone: HearthBannerTone.warning,
                    icon: Icons.cloud_off_rounded,
                    title: s.s1NetworkError,
                  )
                else ...[
                  HearthBanner(
                    tone: HearthBannerTone.ok,
                    icon: Icons.new_releases_rounded,
                    title: 'Latest GitHub Release: ${rel.tagName}',
                  ),
                  const SizedBox(height: 14),
                  HearthPrimaryButton(
                    label: 'Open Release Page',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () async {
                      final uri = Uri.parse(rel.htmlUrl);
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                  const SizedBox(height: 10),
                  HearthSecondaryButton(
                    label: 'Trigger ESP32 OTA Latest',
                    icon: Icons.system_update_alt_rounded,
                    onPressed: () async {
                      await widget.ctrl.hardware.sendCommand('OTA_LATEST');
                      if (c.mounted) {
                        Navigator.pop(c);
                      }
                      if (mounted) {
                        showHearthToast(context, 'OTA_LATEST sent');
                      }
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoomCard(HearthRoom room, HearthLayout layout, {bool selected = false}) {
    final s = widget.ctrl.s;
    final p = HearthPalette.of(context);

    final IconData statusIcon;
    final String statusWord;
    final Color statusColor;
    final String contextLine;
    final telemetry = room.latestTelemetry;

    switch (room.status) {
      case RoomStatus.occupied:
        statusIcon = Icons.circle;
        statusWord = s.s6StatusOccupied;
        statusColor = p.ok;
        contextLine = s.s6MovementAgo(s.formatRelativeTime(room.lastMovementAt));
        break;
      case RoomStatus.empty:
        statusIcon = Icons.radio_button_unchecked_rounded;
        statusWord = s.s6StatusEmpty;
        statusColor = p.textMuted;
        contextLine = s.s6LastPresence(s.formatClock(room.lastMovementAt));
        break;
      case RoomStatus.offline:
        statusIcon = Icons.warning_amber_rounded;
        statusWord = s.s6StatusOffline;
        statusColor = p.critical;
        contextLine = s.s6OfflineContext(s.formatClock(room.offlineSince ?? room.lastCheckedAt));
        break;
    }

    return LiquidGlassCard(
      selected: selected,
      borderColor: room.status == RoomStatus.offline ? p.critical.withValues(alpha: 0.55) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _openRoom(room, layout),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(room.type.icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        room.name,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      HearthStatusBadge(icon: statusIcon, label: statusWord, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contextLine,
                    style: TextStyle(fontSize: 15, color: p.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sensor ${room.sensorId}',
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (telemetry != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _RoomMetric(label: 'ToF', value: '${telemetry.tofHeightMm} mm'),
                        _RoomMetric(label: 'Motion', value: '${telemetry.radarMotion}/100'),
                        _RoomMetric(label: 'Static', value: '${telemetry.radarStatic}/100'),
                        _RoomMetric(label: 'PIR', value: telemetry.pirActive ? 'ON' : 'OFF'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }



  Widget _buildHomeContent(HearthLayout layout) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final rooms = ctrl.rooms;
    final offline = ctrl.offlineRoom;
    final recent = ctrl.mostRecentOccupiedRoom;

    final headerBar = LiquidGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          const HearthBrandMark(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: () => ctrl.triggerFallAlert(simulated: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.s6HomeTitle(ctrl.personName),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        ctrl.guestModeActive || rooms.isEmpty || offline != null
                            ? Icons.shield_outlined
                            : Icons.verified_user_rounded,
                        size: 15,
                        color: ctrl.guestModeActive || rooms.isEmpty || offline != null ? p.warning : p.ok,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ctrl.guestModeActive
                              ? s.s6MonitoringPaused
                              : rooms.isEmpty
                                  ? s.s6SetupNeeded
                                  : offline != null
                                      ? s.s6AttentionNeeded
                                      : s.s6MonitoringActive,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: s.tabActivity,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => setState(() => _tabIndex = 1),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'sim_fall') ctrl.triggerFallAlert(simulated: true);
              if (v == 'first_aid') showFirstAidGuideModal(context, ctrl);
              if (v == 'med_id') showMedicalIdModal(context, ctrl);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'sim_fall',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: p.critical, size: 20),
                    const SizedBox(width: 10),
                    Text(s.s6SimulateFall),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'first_aid',
                child: Row(
                  children: [
                    Icon(Icons.medical_services_outlined, color: p.accent, size: 20),
                    const SizedBox(width: 10),
                    Text(s.firstAidTitle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'med_id',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: p.accent, size: 20),
                    const SizedBox(width: 10),
                    Text(s.medicalIdTitle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_loadingHome) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding, vertical: 16),
        children: [
          headerBar,
          const SizedBox(height: 16),
          const LiquidGlassCard(child: HearthSkeleton(height: 26)),
          const SizedBox(height: 14),
          const LiquidGlassCard(child: HearthSkeleton(height: 70)),
          const SizedBox(height: 10),
          const LiquidGlassCard(child: HearthSkeleton(height: 70)),
          const SizedBox(height: 10),
          const LiquidGlassCard(child: HearthSkeleton(height: 70)),
        ],
      );
    }

    final summaryBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!ctrl.hasRequiredCareProfile) ...[
          HearthBanner(
            tone: HearthBannerTone.warning,
            icon: Icons.person_outline_rounded,
            title: s.s6IncompleteProfileTitle,
            subtitle: s.s6IncompleteProfileBody,
            action: HearthSecondaryButton(
              label: s.s6CompleteProfileBtn,
              expand: false,
              icon: Icons.edit_rounded,
              onPressed: _openQuickCareProfileModal,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ctrl.guestModeActive) ...[
          HearthBanner(
            tone: HearthBannerTone.info,
            icon: Icons.pause_circle_outline_rounded,
            title: s.s6GuestModeActive,
            action: HearthSecondaryButton(
              label: s.s6GuestModeResume,
              expand: false,
              onPressed: () => ctrl.setGuestMode(false),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ctrl.phoneOfflineSimulation) ...[
          HearthBanner(
            tone: HearthBannerTone.warning,
            icon: Icons.cloud_off_rounded,
            title: s.s6OfflinePhoneBanner,
            action: HearthSecondaryButton(label: s.retry, expand: false, onPressed: _refreshHome),
          ),
          const SizedBox(height: 12),
        ],
        if (rooms.isNotEmpty) ...[
          HearthBanner(
            tone: offline != null ? HearthBannerTone.critical : HearthBannerTone.ok,
            icon: offline != null ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            title: offline != null
                ? s.s6IssueSummary(offline.name)
                : s.s6AllGoodSummary(
                    rooms.length,
                    ctrl.personName,
                    recent?.name ?? rooms.first.name,
                    s.formatRelativeTime(recent?.lastMovementAt ?? DateTime.now()),
                  ),
            subtitle: offline != null
                ? s.s6OfflineSince(
                    offline.name,
                    s.formatClock(offline.offlineSince ?? offline.lastCheckedAt),
                  )
                : (ctrl.lastSafeCheckIn != null
                    ? s.s6LastCheckIn(s.formatClock(ctrl.lastSafeCheckIn!))
                    : null),
            action: offline != null
                ? HearthPrimaryButton(
                    label: s.s6ReconnectSensor,
                    icon: Icons.bluetooth_searching_rounded,
                    onPressed: () => widget.onReconnectRoom(offline),
                  )
                : HearthSecondaryButton(
                    label: s.s6CheckInBtn,
                    expand: false,
                    icon: Icons.favorite_border_rounded,
                    onPressed: () async {
                      await ctrl.logSafeCheckIn();
                      if (mounted) {
                        showHearthToast(context, s.s6LastCheckIn(s.formatClock(DateTime.now())));
                      }
                    },
                  ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );

    if (rooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshHome,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding, vertical: 16),
          children: [
            headerBar,
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LiquidGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.home_outlined, size: 52, color: p.accent),
                      const SizedBox(height: 14),
                      Text(s.s6EmptyTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(s.s6EmptyBody(ctrl.personName), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 20),
                      HearthPrimaryButton(
                        label: s.s6AddRoom,
                        icon: Icons.add_rounded,
                        onPressed: widget.onAddRoom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Desktop layout (>= 1024dp): full-width issue banner + 3-col room grid + today's activity column
    if (layout.isDesktop) {
      return RefreshIndicator(
        onRefresh: _refreshHome,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerBar,
              const SizedBox(height: 16),
              summaryBlock,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (_, box) {
                            final cols = box.maxWidth >= 820 ? 3 : 2;
                            final cardWidth = (box.maxWidth - (cols - 1) * 12) / cols;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: rooms
                                  .map((r) => SizedBox(width: cardWidth, child: _buildRoomCard(r, layout)))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: offline != null
                              ? HearthSecondaryButton(
                                  label: s.s6AddRoom,
                                  expand: false,
                                  icon: Icons.add_rounded,
                                  onPressed: widget.onAddRoom,
                                )
                              : HearthPrimaryButton(
                                  label: s.s6AddRoom,
                                  expand: false,
                                  icon: Icons.add_rounded,
                                  onPressed: widget.onAddRoom,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: _TodayActivitySidebar(ctrl: ctrl),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Tablet & Foldable 2-pane (600–1023dp, hinge-aware!)
    if (layout.isTabletOrFoldable) {
      final activeId = _selectedRoomId ?? rooms.first.id;
      final effectiveId = rooms.any((r) => r.id == activeId) ? activeId : rooms.first.id;
      final selectedRoom = rooms.firstWhere((r) => r.id == effectiveId);

      return Row(
        children: [
          SizedBox(
            width: layout.masterPaneWidth,
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 90),
                children: [
                  headerBar,
                  const SizedBox(height: 12),
                  summaryBlock,
                  ...rooms.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildRoomCard(r, layout, selected: r.id == effectiveId),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (offline != null)
                    HearthSecondaryButton(label: s.s6AddRoom, icon: Icons.add_rounded, onPressed: widget.onAddRoom)
                  else
                    HearthPrimaryButton(label: s.s6AddRoom, icon: Icons.add_rounded, onPressed: widget.onAddRoom),
                ],
              ),
            ),
          ),
          SizedBox(width: layout.hingeGap),
          Expanded(
            child: S8RoomDetailScreen(
              ctrl: ctrl,
              roomId: effectiveId,
              embedded: true,
              onReconnectSensor: () => widget.onReconnectRoom(selectedRoom),
              onTestSensor: () => widget.onTestRoom(selectedRoom),
              onSeeEarlierDays: (rId) => setState(() {
                _activityRoomFilter = rId;
                _tabIndex = 1;
              }),
            ),
          ),
        ],
      );
    }

    // Mobile single-column layout (< 600dp)
    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: ListView(
        padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 14, layout.horizontalPadding, 110),
        children: [
          headerBar,
          const SizedBox(height: 14),
          summaryBlock,
          ...rooms.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRoomCard(r, layout),
            ),
          ),
          const SizedBox(height: 10),
          // Rule: ONLY ONE primary accent button per screen. When issue banner has "Reconnect sensor", "Add a room" drops to secondary outline.
          if (offline != null)
            HearthSecondaryButton(
              label: s.s6AddRoom,
              icon: Icons.add_rounded,
              onPressed: widget.onAddRoom,
            )
          else
            HearthPrimaryButton(
              label: s.s6AddRoom,
              icon: Icons.add_rounded,
              onPressed: widget.onAddRoom,
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(HearthLayout layout) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final events = _activityRoomFilter == null
        ? ctrl.events
        : ctrl.events.where((e) => e.roomId == _activityRoomFilter).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 16, layout.horizontalPadding, 110),
          children: [
            Text(s.tabActivity, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(s.tabHome),
                    selected: _activityRoomFilter == null,
                    onSelected: (_) => setState(() => _activityRoomFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...ctrl.rooms.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(r.name),
                        selected: _activityRoomFilter == r.id,
                        onSelected: (_) => setState(() => _activityRoomFilter = r.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (events.isEmpty)
              LiquidGlassCard(child: Text(s.s8NoEventsToday, style: Theme.of(context).textTheme.bodyLarge))
            else
              ...events.map((ev) {
                final critical =
                    ev.type == HearthEventType.fallDetected || ev.type == HearthEventType.sensorOffline;
                final ok = ev.type == HearthEventType.fallResolved || ev.type == HearthEventType.testPassed;
                final color = critical ? p.critical : (ok ? p.ok : p.accent);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LiquidGlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 7, right: 12),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ev.roomName} · ${s.eventTitle(ev, ctrl.personName)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${s.formatClock(ev.at)} · ${s.formatRelativeTime(ev.at)}',
                                style: TextStyle(fontSize: 14, color: p.textMuted),
                              ),
                              if (ev.outcome != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: HearthStatusBadge(
                                    icon: Icons.check_rounded,
                                    label: s.outcomeLabel(ev.outcome!, ctrl.personName),
                                    color: p.ok,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(HearthLayout layout) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 16, layout.horizontalPadding, 110),
          children: [
            Text(s.tabSettings, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // S9 Alert contacts entry
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(Icons.group_rounded, color: p.accent),
                title: Text(s.s9Title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${ctrl.contacts.length} · ${ctrl.dispatchMode == AlertDispatchMode.simultaneous ? s.s9ModeSimultaneous : s.s9Minutes(ctrl.escalationMinutes)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ListenableBuilder(
                      listenable: ctrl,
                      builder: (ctx, _) => S9ContactsScreen(
                        ctrl: ctrl,
                        onBack: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Language (VI default, EN, FR) & Theme Mode
            LiquidGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.language, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppLanguage.values.map((language) => ChoiceChip(
                      label: Text(language.nativeName),
                      selected: ctrl.language == language,
                      onSelected: (_) => ctrl.setLanguage(language),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(s.appearance, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      (ThemeMode.system, s.themeSystem),
                      (ThemeMode.light, s.themeLight),
                      (ThemeMode.dark, s.themeDark),
                    ].map((option) => ChoiceChip(
                      label: Text(option.$2),
                      selected: ctrl.themeMode == option.$1,
                      onSelected: (_) => ctrl.setThemeMode(option.$1),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Preserved Elderly Care & Medical Kit
            Text(s.medicalSuiteTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.medical_services_rounded, color: p.critical),
                    title: Text(s.firstAidTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.firstAidSub),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showFirstAidGuideModal(context, ctrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.badge_rounded, color: p.accent),
                    title: Text(s.medicalIdTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      ctrl.medicalProfile.fullName.isEmpty
                          ? s.medicalIdSub
                          : '${ctrl.medicalProfile.fullName}${ctrl.medicalProfile.bloodType.isNotEmpty ? " · ${ctrl.medicalProfile.bloodType}" : ""}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showMedicalIdModal(context, ctrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.medication_rounded, color: p.accent),
                    title: Text(s.medicationTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${s.medicationSub} (${ctrl.medications.length})'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showMedicationScheduleModal(context, ctrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.fact_check_rounded, color: p.accent),
                    title: Text(s.steadiTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${s.steadiSub} (${ctrl.steadiScore}/14)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showCdcSteadiModal(context, ctrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.assessment_rounded, color: p.ok),
                    title: Text(s.auditReportTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.auditReportSub),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showMedicalAuditReportModal(context, ctrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Regional emergency number, updates, and QA/test helpers
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.emergency_rounded, color: p.critical),
                    title: Text(s.emergencyNumberLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(ctrl.emergencyServiceNumber),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () {
                      final numCtrl = TextEditingController(text: ctrl.emergencyServiceNumber);
                      showLiquidGlassAdaptiveModal(
                        context: context,
                        builder: (ctx) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(s.emergencyNumberLabel, style: Theme.of(ctx).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            TextField(
                              controller: numCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(hintText: '115 / 112 / 911'),
                            ),
                            const SizedBox(height: 16),
                            HearthPrimaryButton(
                              label: s.save,
                              onPressed: () async {
                                await ctrl.updateEmergencyNumber(numCtrl.text);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.pause_circle_outline_rounded, color: p.accent),
                    title: Text(s.guestModeTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.guestModeSub),
                    value: ctrl.guestModeActive,
                    onChanged: ctrl.setGuestMode,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minTileHeight: 60,
                    leading: Icon(Icons.system_update_rounded, color: p.accent),
                    title: Text(s.appUpdatesTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Release $kAppReleaseLabel · GitHub Releases OTA'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _checkUpdatesModal,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(s.s6SimulateFall),
                    subtitle: const Text('Test S7 offline acknowledge error'),
                    value: ctrl.phoneOfflineSimulation,
                    onChanged: ctrl.setPhoneOfflineSimulation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HearthSecondaryButton(
              label: '${ctrl.userEmail.isEmpty ? "Hearth" : ctrl.userEmail} · Sign out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ctrl.signOut();
                widget.onSignedOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);

    final activePage = _tabIndex == 0
        ? _buildHomeContent(layout)
        : (_tabIndex == 1 ? _buildActivityTab(layout) : _buildSettingsTab(layout));

    if (layout.isDesktop) {
      return Scaffold(
        body: LiquidGlassBackdrop(
          child: SafeArea(
            child: Row(
              children: [
                // Left Liquid Glass Navigation Rail
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: LiquidGlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: SizedBox(
                      width: 112,
                      child: Column(
                        children: [
                          const HearthBrandMark(size: 46),
                          const SizedBox(height: 24),
                          _RailNavItem(
                            icon: Icons.home_rounded,
                            label: s.tabHome,
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                          const SizedBox(height: 10),
                          _RailNavItem(
                            icon: Icons.timeline_rounded,
                            label: s.tabActivity,
                            selected: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                          const SizedBox(height: 10),
                          _RailNavItem(
                            icon: Icons.settings_rounded,
                            label: s.tabSettings,
                            selected: _tabIndex == 2,
                            onTap: () => setState(() => _tabIndex = 2),
                          ),
                          const Spacer(),
                          HearthLanguagePill(
                            current: ctrl.language,
                            onSelected: ctrl.setLanguage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: activePage),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: LiquidGlassBackdrop(
        child: SafeArea(bottom: false, child: activePage),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: p.glassFill,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: p.glassHighlight, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: p.glassShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _BottomGlassTab(
                      icon: Icons.home_rounded,
                      label: s.tabHome,
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    _BottomGlassTab(
                      icon: Icons.timeline_rounded,
                      label: s.tabActivity,
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                    _BottomGlassTab(
                      icon: Icons.settings_rounded,
                      label: s.tabSettings,
                      selected: _tabIndex == 2,
                      onTap: () => setState(() => _tabIndex = 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomGlassTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomGlassTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? p.accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: selected ? p.accent : p.textMuted),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? p.accent : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? p.accent : p.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? p.accent : p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RoomMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Text(
      '$label $value',
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textMuted),
    );
  }
}

class _TodayActivitySidebar extends StatelessWidget {
  final HearthController ctrl;
  const _TodayActivitySidebar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final items = ctrl.events.take(8).toList();

    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.s6TodayActivity, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(s.s8NoEventsToday, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.formatClock(e.at)} · ${e.roomName}',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textMuted),
                    ),
                    Text(
                      s.eventTitle(e, ctrl.personName),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
