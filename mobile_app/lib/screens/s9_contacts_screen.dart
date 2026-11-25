import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S9ContactsScreen extends StatefulWidget {
  final HearthController ctrl;
  final bool isOnboarding;
  final VoidCallback? onBack;
  final VoidCallback? onFinishOnboarding;

  const S9ContactsScreen({
    super.key,
    required this.ctrl,
    this.isOnboarding = false,
    this.onBack,
    this.onFinishOnboarding,
  });

  @override
  State<S9ContactsScreen> createState() => _S9ContactsScreenState();
}

class _S9ContactsScreenState extends State<S9ContactsScreen> {
  String? _testingChannel;

  Future<void> _runTestChannel({
    required String label,
    List<String>? channels,
    String? targetContactId,
  }) async {
    if (_testingChannel != null) return;
    setState(() => _testingChannel = label);
    final res = await widget.ctrl.sendTestAlertBot(
      channels: channels,
      targetContactId: targetContactId,
    );
    if (!mounted) return;
    setState(() => _testingChannel = null);
    showHearthToast(
      context,
      res.ok
          ? '$label thành công (${res.summary})'
          : '$label chưa gửi được (${res.summary})',
      critical: !res.ok,
    );
  }

  void _openContactModal({AlertContact? contact}) {
    final isEditing = contact != null;
    final nameCtrl = TextEditingController(text: contact?.name ?? '');
    final phoneCtrl = TextEditingController(text: contact?.phone ?? '');
    final telegramCtrl = TextEditingController(text: contact?.telegramPhone ?? '');
    final chatIdCtrl = TextEditingController(text: contact?.telegramChatId ?? '');
    final usernameCtrl = TextEditingController(text: contact?.telegramUsername ?? '');
    bool sameTelegramPhone = contact != null &&
        contact.telegramPhone.trim().isNotEmpty &&
        contact.telegramPhone.trim() == contact.phone.trim();
    bool notifyTelegram = contact?.notifyTelegram ?? true;
    bool notifyCall = contact?.notifyCall ?? true;
    String? nameError;
    String? phoneError;

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEditing ? s.s9EditContact : s.s9AddContact, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.s9ContactName,
                  errorText: nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s.s9ContactPhone,
                  helperText: s.s9InviteHelper,
                  helperMaxLines: 2,
                  errorText: phoneError,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telegramCtrl,
                keyboardType: TextInputType.phone,
                enabled: !sameTelegramPhone,
                decoration: InputDecoration(
                  labelText: s.s9TelegramPhone,
                  hintText: '+84 xxx xxx xxx',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: sameTelegramPhone,
                title: Text(s.s9TelegramSamePhone),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setModalState(() {
                    sameTelegramPhone = value ?? false;
                    if (sameTelegramPhone) telegramCtrl.text = phoneCtrl.text;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: chatIdCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: s.s9TelegramChatId,
                  hintText: '512345678 (nhắn /start cho bot để lấy)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  labelText: s.s9TelegramUsername,
                  hintText: '@username_telegram',
                ),
              ),
              const SizedBox(height: 12),
              Text(s.s9ContactChannels, style: Theme.of(c).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Telegram'),
                    avatar: const Icon(Icons.send_rounded, size: 16),
                    selected: notifyTelegram,
                    onSelected: (v) => setModalState(() => notifyTelegram = v),
                  ),
                  FilterChip(
                    label: const Text('Call'),
                    avatar: const Icon(Icons.call_rounded, size: 16),
                    selected: notifyCall,
                    onSelected: (v) => setModalState(() => notifyCall = v),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              HearthPrimaryButton(
                label: isEditing ? s.s9EditContact : s.s9SendInvite,
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final digits = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final hasTelegram = chatIdCtrl.text.trim().isNotEmpty || usernameCtrl.text.trim().isNotEmpty;
                  setModalState(() {
                    nameError = name.isEmpty ? s.requiredFieldError : null;
                    phoneError = (digits.length < 9 && !hasTelegram) ? s.s9PhoneError : null;
                  });
                  if (name.isEmpty || (digits.length < 9 && !hasTelegram)) return;

                  final telegramPhone = sameTelegramPhone ? phoneCtrl.text.trim() : telegramCtrl.text.trim();
                  if (contact != null) {
                    await widget.ctrl.updateContact(
                      contact.id,
                      name,
                      phoneCtrl.text.trim(),
                      telegramPhone: telegramPhone,
                      telegramChatId: chatIdCtrl.text.trim(),
                      telegramUsername: usernameCtrl.text.trim(),
                      notifyTelegram: notifyTelegram,
                      notifySms: false,
                      notifyCall: notifyCall,
                    );
                  } else {
                    await widget.ctrl.addContact(
                      name,
                      phoneCtrl.text.trim(),
                      telegramPhone: telegramPhone,
                      telegramChatId: chatIdCtrl.text.trim(),
                      telegramUsername: usernameCtrl.text.trim(),
                      notifyTelegram: notifyTelegram,
                      notifySms: false,
                      notifyCall: notifyCall,
                    );
                  }
                  if (c.mounted) {
                    Navigator.pop(c);
                  }
                  if (mounted) {
                    showHearthToast(context, isEditing ? '${s.s9EditContact}: $name' : '${s.s9BadgeInvited}: $name');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAddContactModal() => _openContactModal();

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);
    final contacts = ctrl.contacts;
    final isSimultaneous = ctrl.dispatchMode == AlertDispatchMode.simultaneous;

    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: layout.horizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s9Title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                isSimultaneous ? s.s9SimultaneousExplainer : s.s9SequentialExplainer(ctrl.escalationMinutes),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Dispatch Mode Card (Simultaneous DEFAULT vs Sequential)
              LiquidGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.s9ModeTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = 8.0;
                        final itemWidth = constraints.maxWidth >= 420
                            ? (constraints.maxWidth - gap) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _AlertModeButton(
                              width: itemWidth,
                              icon: Icons.campaign_rounded,
                              label: s.s9ModeSimultaneous,
                              selected: isSimultaneous,
                              onPressed: () => ctrl.setDispatchMode(AlertDispatchMode.simultaneous),
                            ),
                            _AlertModeButton(
                              width: itemWidth,
                              icon: Icons.format_list_numbered_rounded,
                              label: s.s9ModeSequential,
                              selected: !isSimultaneous,
                              onPressed: () => ctrl.setDispatchMode(AlertDispatchMode.sequential),
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final columns = constraints.maxWidth >= 300 ? 2 : 1;
                        final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _AlertChannelButton(
                              width: itemWidth,
                              icon: Icons.send_rounded,
                              label: 'Telegram',
                              selected: ctrl.channelTelegramEnabled,
                              onPressed: (v) => ctrl.setChannelPreferences(telegram: v),
                            ),
                            _AlertChannelButton(
                              width: itemWidth,
                              icon: Icons.call_rounded,
                              label: 'Call',
                              selected: ctrl.channelCallEnabled,
                              onPressed: (v) => ctrl.setChannelPreferences(call: v),
                            ),
                          ],
                        );
                      },
                    ),
                    if (!isSimultaneous) ...[
                      const SizedBox(height: 14),
                      Text(s.s9WaitBeforeNext, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: [
                          ButtonSegment(value: 1, label: Text(s.s9Minutes(1))),
                          ButtonSegment(value: 2, label: Text(s.s9Minutes(2))),
                          ButtonSegment(value: 5, label: Text(s.s9Minutes(5))),
                        ],
                        selected: {ctrl.escalationMinutes},
                        onSelectionChanged: (set) => ctrl.setEscalationMinutes(set.first),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Automated Alert Bot Status Card (zero technical setup needed for end-users)
              LiquidGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: p.ok, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.s9BotConfigTitle, style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ctrl.lastBotSyncStatus.isNotEmpty
                          ? 'Hệ thống đã tự động kết nối (${ctrl.lastBotSyncStatus})'
                          : 'Tự động nhắn Telegram & gọi điện thoại tiếng Việt ngay khi phát hiện té ngã',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        HearthSecondaryButton(
                          label: _testingChannel == s.s9TestTelegramBtn ? '...' : s.s9TestTelegramBtn,
                          expand: false,
                          icon: Icons.send_rounded,
                          onPressed: _testingChannel != null
                              ? null
                              : () => _runTestChannel(
                                    label: s.s9TestTelegramBtn,
                                    channels: const ['telegram'],
                                  ),
                        ),
                        HearthSecondaryButton(
                          label: _testingChannel == s.s9TestCallBtn ? '...' : s.s9TestCallBtn,
                          expand: false,
                          icon: Icons.call_rounded,
                          onPressed: _testingChannel != null
                              ? null
                              : () => _runTestChannel(
                                    label: s.s9TestCallBtn,
                                    channels: const ['call'],
                                  ),
                        ),
                        HearthSecondaryButton(
                          label: _testingChannel == s.s9BotTestBtn ? '...' : s.s9BotTestBtn,
                          expand: false,
                          icon: Icons.notifications_active_outlined,
                          onPressed: _testingChannel != null
                              ? null
                              : () => _runTestChannel(
                                    label: s.s9BotTestBtn,
                                    channels: const ['telegram', 'call'],
                                  ),
                        ),
                        HearthSecondaryButton(
                          label: s.s9BotPullBtn,
                          expand: false,
                          icon: Icons.sync_rounded,
                          onPressed: _testingChannel != null
                              ? null
                              : () async {
                                  final count = await ctrl.pullContactsFromBot();
                                  if (!context.mounted) return;
                                  if (count < 0) {
                                    showHearthToast(context, 'Không kết nối được máy chủ cảnh báo', critical: true);
                                  } else {
                                    showHearthToast(context, 'Đã đồng bộ $count người nhận từ Telegram');
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (contacts.length <= 1) ...[
                HearthBanner(
                  tone: HearthBannerTone.warning,
                  icon: Icons.group_add_rounded,
                  title: s.s9EmptyHint,
                ),
                const SizedBox(height: 14),
              ],

              // Real contact list (drag handle + accessible Up/Down buttons)
              ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                // ignore: deprecated_member_use
                onReorder: ctrl.reorderContacts,
                itemBuilder: (ctx, idx) {
                  final c = contacts[idx];
                  return Padding(
                    key: ValueKey(c.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: idx,
                            child: SizedBox(
                              width: 44,
                              height: 48,
                              child: Icon(Icons.drag_indicator_rounded, color: p.textMuted),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.isPrimaryUser ? '${c.name} (${s.s9YouThisPhone})' : c.name,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                                ),
                                if (c.phone.isNotEmpty)
                                  Text(c.phone, style: TextStyle(fontSize: 14, color: p.textMuted)),
                                if (c.telegramChatId.isNotEmpty || c.telegramUsername.isNotEmpty)
                                  Text(
                                    [
                                      if (c.telegramChatId.isNotEmpty) 'TG: ${c.telegramChatId}',
                                      if (c.telegramUsername.isNotEmpty) c.telegramUsername,
                                    ].join(' · '),
                                    style: TextStyle(fontSize: 12.5, color: p.accent),
                                  ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (!c.isPrimaryUser)
                                      HearthStatusBadge(
                                        icon: c.joined ? Icons.check_circle_rounded : Icons.sync_rounded,
                                        label: c.joined ? s.s9BadgeJoined : s.s9BadgeInvited,
                                        color: c.joined ? p.ok : p.accent,
                                      ),
                                    if (c.notifyTelegram && c.telegramChatId.isNotEmpty)
                                      HearthStatusBadge(icon: Icons.send_rounded, label: 'TG', color: p.ok),
                                    if (c.notifyCall && (c.telegramUsername.isNotEmpty || c.phone.isNotEmpty))
                                      HearthStatusBadge(icon: Icons.call_rounded, label: 'Call', color: p.warning),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: s.s9MoveUp,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                            onPressed: idx == 0 ? null : () => ctrl.moveContactByDelta(idx, -1),
                          ),
                          IconButton(
                            tooltip: s.s9MoveDown,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                            icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                            onPressed: idx == contacts.length - 1 ? null : () => ctrl.moveContactByDelta(idx, 1),
                          ),
                          IconButton(
                            tooltip: s.s9BotTestBtn,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                            icon: Icon(Icons.notifications_active_outlined, color: p.ok, size: 20),
                            onPressed: _testingChannel != null
                                ? null
                                : () => _runTestChannel(
                                      label: 'Test ${c.name}',
                                      targetContactId: c.id,
                                    ),
                          ),
                          IconButton(
                            tooltip: s.s9EditContact,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _openContactModal(contact: c),
                          ),
                          if (!c.isPrimaryUser)
                            IconButton(
                              tooltip: s.cancel,
                              constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                              icon: Icon(Icons.delete_outline_rounded, color: p.critical, size: 20),
                              onPressed: () => ctrl.removeContact(c.id),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),
              if (widget.isOnboarding) ...[
                HearthPrimaryButton(
                  label: s.continueBtn,
                  onPressed: widget.onFinishOnboarding,
                ),
                const SizedBox(height: 10),
                HearthSecondaryButton(
                  label: s.s9AddContact,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _openAddContactModal,
                ),
                const SizedBox(height: 8),
                Center(
                  child: HearthTextLink(
                    label: s.s9AddLater,
                    onPressed: widget.onFinishOnboarding,
                  ),
                ),
              ] else
                HearthPrimaryButton(
                  label: s.s9AddContact,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _openAddContactModal,
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.isOnboarding && widget.onBack == null) {
      return body;
    }

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              HearthStepTopBar(
                step: 4,
                totalSteps: widget.isOnboarding ? 4 : 0,
                customStepText: widget.isOnboarding ? s.s9AlmostDone : s.s9Title,
                onBack: widget.onBack,
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertModeButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _AlertModeButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, textAlign: TextAlign.center, softWrap: true),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          foregroundColor: selected ? p.accent : p.text,
          backgroundColor: selected ? p.accent.withValues(alpha: 0.12) : null,
          side: BorderSide(color: selected ? p.accent : p.border, width: selected ? 1.8 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HearthTokens.buttonRadius)),
        ),
      ),
    );
  }
}

class _AlertChannelButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onPressed;

  const _AlertChannelButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: () => onPressed(!selected),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          foregroundColor: selected ? p.accent : p.text,
          backgroundColor: selected ? p.accent.withValues(alpha: 0.10) : null,
          side: BorderSide(color: selected ? p.accent : p.border, width: selected ? 1.6 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HearthTokens.buttonRadius)),
        ),
      ),
    );
  }
}
