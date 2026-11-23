import 'package:flutter/material.dart';
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
  void _openAddContactModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? phoneError;

    showLiquidGlassAdaptiveModal(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = widget.ctrl.s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.s9AddContact, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: s.s9ContactName),
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
              const SizedBox(height: 18),
              HearthPrimaryButton(
                label: s.s9SendInvite,
                onPressed: () async {
                  final digits = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 9) {
                    setModalState(() => phoneError = s.s9PhoneError);
                    return;
                  }
                  final name = nameCtrl.text.trim().isEmpty ? phoneCtrl.text.trim() : nameCtrl.text.trim();
                  await widget.ctrl.addContact(name, phoneCtrl.text.trim());
                  if (c.mounted) {
                    Navigator.pop(c);
                  }
                  if (mounted) {
                    showHearthToast(context, '${s.s9BadgeInvited}: $name');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);
    final contacts = ctrl.contacts;

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
              Text(s.s9Explainer(ctrl.escalationMinutes), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),

              if (contacts.length <= 1) ...[
                HearthBanner(
                  tone: HearthBannerTone.info,
                  icon: Icons.group_add_rounded,
                  title: s.s9EmptyHint,
                ),
                const SizedBox(height: 14),
              ],

              // Reorderable contact list with BOTH drag handle (48px) and accessible Move Up/Down buttons
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
                                if (!c.isPrimaryUser) ...[
                                  const SizedBox(height: 4),
                                  HearthStatusBadge(
                                    icon: c.joined ? Icons.check_circle_rounded : Icons.mail_outline_rounded,
                                    label: c.joined ? s.s9BadgeJoined : s.s9BadgeInvited,
                                    color: c.joined ? p.ok : p.accent,
                                  ),
                                ],
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

              const SizedBox(height: 12),
              LiquidGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.s9WaitBeforeNext, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
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
                ),
              ),

              const SizedBox(height: 20),
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
