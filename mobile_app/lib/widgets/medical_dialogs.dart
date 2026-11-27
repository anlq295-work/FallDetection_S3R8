import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import 'hearth_components.dart';
import 'liquid_glass.dart';

/// 1. Illustrated 4-step Clinical First Aid Guide for Elderly Falls (VI / EN / FR).
Future<void> showFirstAidGuideModal(
  BuildContext context,
  HearthController ctrl,
) {
  final s = ctrl.s;
  final lang = ctrl.language;
  final steps = _firstAidSteps(lang);

  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 580,
    builder: (ctx) {
      final p = HearthPalette.of(ctx);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: p.critical, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.firstAidTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LiquidGlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.icon, color: step.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. ${step.title}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.body,
                            style: TextStyle(fontSize: 15, color: p.textMuted),
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
      );
    },
  );
}

class _FirstAidStep {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const _FirstAidStep(this.title, this.body, this.icon, this.color);
}

List<_FirstAidStep> _firstAidSteps(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.vi:
      return const [
        _FirstAidStep(
          'Giữ bình tĩnh — KHÔNG kéo dựng dậy ngay',
          'Kiểm tra xem người thân có đau cổ, lưng, hông hay đập đầu không. Di chuyển vội có thể làm nặng vết gãy xương.',
          Icons.pan_tool_rounded,
          Color(0xFFB42318),
        ),
        _FirstAidStep(
          'Kiểm tra ý thức & nhịp thở',
          'Gọi tên nhẹ nhàng, kiểm tra xem người thân có tỉnh táo, thở đều và không chảy máu nhiều.',
          Icons.monitor_heart_rounded,
          Color(0xFF1F5FBF),
        ),
        _FirstAidStep(
          'Tư thế nằm nghiêng an toàn nếu chóng mặt/nôn',
          'Nếu bất tỉnh nhưng còn thở, nhẹ nhàng xoay nghiêng sang một bên, giữ ấm bằng chăn và gọi 115 ngay.',
          Icons.airline_seat_flat_rounded,
          Color(0xFF9A5B00),
        ),
        _FirstAidStep(
          'Đỡ dậy từng bước bằng ghế (nếu hoàn toàn không đau)',
          'Cho người thân xoay sấp, chống tay gối bò lại gần ghế vững, nghỉ 5 phút rồi mới đứng lên từ từ.',
          Icons.chair_rounded,
          Color(0xFF1E7A3E),
        ),
      ];
    case AppLanguage.en:
      return const [
        _FirstAidStep(
          'Stay calm — Do NOT pull them up immediately',
          'Check for head impact, hip, neck or back pain first. Moving too fast can worsen a fracture.',
          Icons.pan_tool_rounded,
          Color(0xFFB42318),
        ),
        _FirstAidStep(
          'Check consciousness and breathing',
          'Speak calmly, confirm they are alert, breathing normally, and not bleeding heavily.',
          Icons.monitor_heart_rounded,
          Color(0xFF1F5FBF),
        ),
        _FirstAidStep(
          'Recovery position if dizzy or unresponsive',
          'If unconscious but breathing, place gently on their side, keep warm with a blanket and call emergency services.',
          Icons.airline_seat_flat_rounded,
          Color(0xFF9A5B00),
        ),
        _FirstAidStep(
          'Two-chair rise (only if completely uninjured)',
          'Help them roll onto hands and knees near a sturdy chair, rest before standing slowly.',
          Icons.chair_rounded,
          Color(0xFF1E7A3E),
        ),
      ];
    case AppLanguage.fr:
      return const [
        _FirstAidStep(
          'Restez calme — Ne relevez pas brusquement',
          'Vérifiez l’absence de douleur à la tête, à la hanche ou au dos avant tout déplacement.',
          Icons.pan_tool_rounded,
          Color(0xFFB42318),
        ),
        _FirstAidStep(
          'Vérifiez la conscience et la respiration',
          'Parlez doucement, assurez-vous que la personne répond et respire normalement.',
          Icons.monitor_heart_rounded,
          Color(0xFF1F5FBF),
        ),
        _FirstAidStep(
          'Position latérale de sécurité si malaise',
          'En cas de perte de connaissance avec respiration, placez sur le côté, couvrez et appelez le 112.',
          Icons.airline_seat_flat_rounded,
          Color(0xFF9A5B00),
        ),
        _FirstAidStep(
          'Se relever avec une chaise (si aucune douleur)',
          'Aidez la personne à passer à quatre pattes près d’une chaise solide, puis à s’asseoir doucement.',
          Icons.chair_rounded,
          Color(0xFF1E7A3E),
        ),
      ];
  }
}

/// 2. Emergency Medical ID Card & Editor.
Future<void> showMedicalIdModal(BuildContext context, HearthController ctrl) {
  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 560,
    builder: (ctx) {
      final p = HearthPalette.of(ctx);
      final s = ctrl.s;
      final prof = ctrl.medicalProfile;

      Widget row(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: p.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                val.isEmpty ? '—' : val,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
          ],
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.badge_rounded, color: p.critical, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.medicalIdTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LiquidGlassCard(
            borderColor: p.critical.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    prof.fullName.isEmpty
                        ? s.personOrGeneric('')
                        : prof.fullName,
                    if (prof.age != null) '${prof.age}',
                    if (prof.bloodType.isNotEmpty) prof.bloodType,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: p.critical,
                  ),
                ),
                const Divider(height: 20),
                row(
                  _lbl(ctrl.language, 'SĐT người thân', 'Phone', 'Téléphone'),
                  prof.personPhone,
                ),
                row(
                  _lbl(
                    ctrl.language,
                    'Mã khóa cửa / PIN',
                    'Door lockbox code',
                    'Code porte',
                  ),
                  prof.doorLockboxCode,
                ),
                row(
                  _lbl(ctrl.language, 'Địa chỉ nhà', 'Home address', 'Adresse'),
                  prof.homeAddress,
                ),
                row(
                  _lbl(ctrl.language, 'Bệnh nền', 'Conditions', 'Antécédents'),
                  prof.conditions,
                ),
                row(
                  _lbl(
                    ctrl.language,
                    'Thuốc đang dùng',
                    'Medications',
                    'Traitements',
                  ),
                  prof.medications,
                ),
                row(
                  _lbl(ctrl.language, 'Dị ứng', 'Allergies', 'Allergies'),
                  prof.allergies,
                ),
                row(
                  _lbl(ctrl.language, 'Bác sĩ điều trị', 'Doctor', 'Médecin'),
                  prof.primaryDoctor,
                ),
                row(
                  _lbl(
                    ctrl.language,
                    'SĐT bác sĩ',
                    'Doctor phone',
                    'Tél. médecin',
                  ),
                  prof.doctorPhone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HearthPrimaryButton(
            label: _lbl(
              ctrl.language,
              'Chỉnh sửa hồ sơ y tế',
              'Edit medical profile',
              'Modifier la fiche',
            ),
            icon: Icons.edit_rounded,
            onPressed: () {
              Navigator.pop(ctx);
              showMedicalProfileEditorModal(context, ctrl);
            },
          ),
        ],
      );
    },
  );
}

Future<void> showMedicalProfileEditorModal(
  BuildContext context,
  HearthController ctrl,
) {
  final prof = ctrl.medicalProfile;
  final nameCtrl = TextEditingController(text: prof.fullName);
  final ageCtrl = TextEditingController(text: prof.age?.toString() ?? '');
  final bloodCtrl = TextEditingController(text: prof.bloodType);
  final phoneCtrl = TextEditingController(text: prof.personPhone);
  final lockboxCtrl = TextEditingController(text: prof.doorLockboxCode);
  final condCtrl = TextEditingController(text: prof.conditions);
  final medCtrl = TextEditingController(text: prof.medications);
  final allergyCtrl = TextEditingController(text: prof.allergies);
  final docCtrl = TextEditingController(text: prof.primaryDoctor);
  final docPhoneCtrl = TextEditingController(text: prof.doctorPhone);
  final addrCtrl = TextEditingController(text: prof.homeAddress);

  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 560,
    builder: (ctx) {
      final s = ctrl.s;
      final lang = ctrl.language;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.medicalIdTitle, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: s.s4PersonLabel),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _lbl(lang, 'Tuổi', 'Age', 'Âge'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: bloodCtrl,
                  decoration: InputDecoration(
                    labelText: _lbl(
                      lang,
                      'Nhóm máu',
                      'Blood type',
                      'Groupe sanguin',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _lbl(
                lang,
                'SĐT của người thân',
                'Relative phone',
                'Téléphone',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: condCtrl,
            decoration: InputDecoration(
              labelText: _lbl(lang, 'Bệnh nền', 'Conditions', 'Antécédents'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: medCtrl,
            decoration: InputDecoration(
              labelText: _lbl(
                lang,
                'Thuốc đang dùng',
                'Medications',
                'Traitements',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: allergyCtrl,
            decoration: InputDecoration(
              labelText: _lbl(lang, 'Dị ứng', 'Allergies', 'Allergies'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: docCtrl,
            decoration: InputDecoration(
              labelText: _lbl(lang, 'Bác sĩ điều trị', 'Doctor', 'Médecin'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: docPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _lbl(
                lang,
                'SĐT bác sĩ',
                'Doctor phone',
                'Tél. médecin',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: addrCtrl,
            decoration: InputDecoration(
              labelText: _lbl(lang, 'Địa chỉ nhà', 'Home address', 'Adresse'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lockboxCtrl,
            decoration: InputDecoration(
              labelText: _lbl(
                lang,
                'Mã khóa cửa / Hộp chìa khóa khẩn cấp',
                'Emergency door / lockbox code',
                'Code porte / boîte à clés',
              ),
            ),
          ),
          const SizedBox(height: 16),
          HearthPrimaryButton(
            label: s.save,
            onPressed: () async {
              await ctrl.saveMedicalProfile(
                prof.copyWith(
                  fullName: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text.trim()),
                  bloodType: bloodCtrl.text.trim(),
                  personPhone: phoneCtrl.text.trim(),
                  conditions: condCtrl.text.trim(),
                  medications: medCtrl.text.trim(),
                  allergies: allergyCtrl.text.trim(),
                  primaryDoctor: docCtrl.text.trim(),
                  doctorPhone: docPhoneCtrl.text.trim(),
                  homeAddress: addrCtrl.text.trim(),
                  doorLockboxCode: lockboxCtrl.text.trim(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      );
    },
  );
}

/// 3. CDC STEADI 12-question clinical fall risk assessment.
Future<void> showCdcSteadiModal(BuildContext context, HearthController ctrl) {
  final questions = _steadiQuestions(ctrl.language);
  final answers = List<bool>.filled(questions.length, false);

  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 600,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (c, setModalState) {
          final p = HearthPalette.of(c);
          final s = ctrl.s;
          int score = 0;
          for (int i = 0; i < questions.length; i++) {
            if (answers[i]) score += (i < 2 ? 2 : 1);
          }
          final highRisk = score >= 4;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.fact_check_rounded, color: p.accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.steadiTitle,
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HearthBanner(
                tone: highRisk
                    ? HearthBannerTone.critical
                    : HearthBannerTone.ok,
                icon: highRisk
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_rounded,
                title: _lbl(
                  ctrl.language,
                  'Điểm hiện tại: $score / 14 · ${highRisk ? "Nguy cơ té ngã CAO (>=4)" : "Nguy cơ thấp (<4)"}',
                  'Current score: $score / 14 · ${highRisk ? "ELEVATED fall risk (≥4)" : "Low risk (<4)"}',
                  'Score : $score / 14 · ${highRisk ? "Risque ÉLEVÉ (≥4)" : "Risque faible (<4)"}',
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(questions.length, (i) {
                return CheckboxListTile(
                  value: answers[i],
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    questions[i],
                    style: TextStyle(fontSize: 15, color: p.text),
                  ),
                  onChanged: (v) =>
                      setModalState(() => answers[i] = v ?? false),
                );
              }),
              const SizedBox(height: 14),
              HearthPrimaryButton(
                label: _lbl(
                  ctrl.language,
                  'Lưu kết quả đánh giá',
                  'Save assessment',
                  'Enregistrer le bilan',
                ),
                onPressed: () async {
                  await ctrl.saveSteadiResult(score);
                  if (c.mounted) {
                    Navigator.pop(c);
                    showHearthToast(context, 'CDC STEADI: $score/14');
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

List<String> _steadiQuestions(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.vi:
      return const [
        'Đã từng bị té ngã trong vòng 12 tháng qua (+2 điểm)',
        'Phải dùng gậy hoặc khung tập đi (+2 điểm)',
        'Đôi khi cảm thấy loạng choạng khi đi bộ',
        'Phải bám vào đồ đạc khi di chuyển trong nhà',
        'Lo lắng sợ bị té ngã',
        'Cần chống tay mới đứng dậy được khỏi ghế',
        'Gặp khó khăn khi bước lên bậc thềm',
        'Thường xuyên phải đi vệ sinh gấp vào ban đêm',
        'Bị tê bì bàn chân',
        'Đang uống thuốc gây chóng mặt/buồn ngủ',
        'Đang dùng thuốc ngủ hoặc thuốc an thần',
        'Thường xuyên cảm thấy buồn bã hoặc mệt mỏi',
      ];
    case AppLanguage.en:
      return const [
        'Has fallen in the past 12 months (+2 pts)',
        'Uses a cane or walker to get around safely (+2 pts)',
        'Sometimes feels unsteady when walking',
        'Steadies self by holding onto furniture at home',
        'Worries about falling',
        'Needs to push with hands to stand up from a chair',
        'Has trouble stepping up onto a curb',
        'Often has to rush to the toilet',
        'Has lost some feeling in feet',
        'Takes medicine that causes light-headedness or tiredness',
        'Takes medicine to help sleep or improve mood',
        'Often feels sad or depressed',
      ];
    case AppLanguage.fr:
      return const [
        'A déjà chuté au cours des 12 derniers mois (+2 pts)',
        'Utilise une canne ou un déambulateur (+2 pts)',
        'Se sent parfois instable en marchant',
        'Se tient aux meubles pour se déplacer',
        'Craint de tomber',
        'Doit s’appuyer avec les mains pour se lever d’une chaise',
        'A du mal à monter une marche',
        'Doit souvent se presser pour aller aux toilettes',
        'Perte de sensibilité dans les pieds',
        'Prend un traitement donnant des vertiges',
        'Prend un somnifère ou anxiolytique',
        'Se sent souvent triste ou fatigué(e)',
      ];
  }
}

/// 4. Medical Safety Audit Report combining STEADI score, rooms health, and incident log.
Future<void> showMedicalAuditReportModal(
  BuildContext context,
  HearthController ctrl,
) {
  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 600,
    builder: (ctx) {
      final p = HearthPalette.of(ctx);
      final s = ctrl.s;
      final lang = ctrl.language;
      final onlineCount = ctrl.rooms
          .where((r) => r.status != RoomStatus.offline)
          .length;
      final fallCount = ctrl.events
          .where((e) => e.type == HearthEventType.fallDetected)
          .length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.assessment_rounded, color: p.accent, size: 25),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.auditReportTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    ctrl.medicalProfile.fullName.isEmpty
                        ? s.personOrGeneric(ctrl.personName)
                        : ctrl.medicalProfile.fullName,
                    if (ctrl.medicalProfile.age != null)
                      '${ctrl.medicalProfile.age}',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lbl(
                    lang,
                    '• Điểm CDC STEADI: ${ctrl.steadiScore}/14 (${ctrl.steadiScore >= 4 ? "Nguy cơ cao" : "Nguy cơ thấp"})\n'
                        '• Cảm biến hoạt động: $onlineCount / ${ctrl.rooms.length} phòng\n'
                        '• Sự kiện té ngã ghi nhận: $fallCount\n'
                        '• Người nhận cảnh báo dự phòng: ${ctrl.contacts.length - 1}',
                    '• CDC STEADI Score: ${ctrl.steadiScore}/14 (${ctrl.steadiScore >= 4 ? "Elevated risk" : "Low risk"})\n'
                        '• Active sensors: $onlineCount / ${ctrl.rooms.length} rooms\n'
                        '• Recorded fall alerts: $fallCount\n'
                        '• Backup alert contacts: ${ctrl.contacts.length - 1}',
                    '• Score CDC STEADI : ${ctrl.steadiScore}/14 (${ctrl.steadiScore >= 4 ? "Risque élevé" : "Risque faible"})\n'
                        '• Capteurs actifs : $onlineCount / ${ctrl.rooms.length} pièces\n'
                        '• Alertes de chute enregistrées : $fallCount\n'
                        '• Contacts de secours : ${ctrl.contacts.length - 1}',
                  ),
                  style: TextStyle(fontSize: 15, height: 1.6, color: p.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HearthPrimaryButton(
            label: s.close,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      );
    },
  );
}

/// 5. Daily Medication Schedule Tracker (linked with room presence awareness).
Future<void> showMedicationScheduleModal(
  BuildContext context,
  HearthController ctrl,
) {
  final nameCtrl = TextEditingController();
  final doseCtrl = TextEditingController();
  int hour = 8;
  int minute = 0;

  return showLiquidGlassAdaptiveModal(
    context: context,
    maxDialogWidth: 580,
    builder: (ctx) => ListenableBuilder(
      listenable: ctrl,
      builder: (c, _) {
        final s = ctrl.s;
        final p = HearthPalette.of(c);
        final lang = ctrl.language;
        final meds = ctrl.medications;

        return StatefulBuilder(
          builder: (sc, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.medication_rounded, color: p.accent, size: 25),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.medicationTitle,
                      style: Theme.of(sc).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sc),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _lbl(
                      lang,
                      'Chưa có lịch uống thuốc nào. Thêm cữ thuốc bên dưới để theo dõi mỗi ngày.',
                      'No medication reminders yet. Add a daily dose below.',
                      'Aucun rappel configuré. Ajoutez une prise ci-dessous.',
                    ),
                    style: Theme.of(sc).textTheme.bodyMedium,
                  ),
                )
              else
                ...meds.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LiquidGlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: m.takenToday,
                            onChanged: (_) => ctrl.toggleMedicationTaken(m.id),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.formattedTime} · ${m.name}',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.text,
                                    decoration: m.takenToday
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (m.dosage.isNotEmpty)
                                  Text(
                                    m.dosage,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: p.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: p.critical,
                              size: 20,
                            ),
                            onPressed: () => ctrl.removeMedication(m.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(height: 22),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: _lbl(
                    lang,
                    'Tên thuốc *',
                    'Medication name *',
                    'Nom du médicament *',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final timeField = DropdownButtonFormField<int>(
                    initialValue: hour,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _lbl(lang, 'Giờ', 'Hour', 'Heure'),
                    ),
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => hour = v ?? hour),
                  );
                  final doseField = TextField(
                    controller: doseCtrl,
                    decoration: InputDecoration(
                      labelText: _lbl(lang, 'Liều dùng', 'Dosage', 'Dosage'),
                      hintText: '1 viên',
                    ),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        doseField,
                        const SizedBox(height: 10),
                        timeField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: doseField),
                      const SizedBox(width: 10),
                      Expanded(child: timeField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              HearthPrimaryButton(
                label: _lbl(
                  lang,
                  'Thêm lịch nhắc thuốc',
                  'Add medication',
                  'Ajouter',
                ),
                icon: Icons.add_rounded,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await ctrl.addMedication(
                    nameCtrl.text,
                    doseCtrl.text,
                    hour,
                    minute,
                  );
                  nameCtrl.clear();
                  doseCtrl.clear();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _lbl(AppLanguage lang, String vi, String en, String fr) {
  switch (lang) {
    case AppLanguage.vi:
      return vi;
    case AppLanguage.en:
      return en;
    case AppLanguage.fr:
      return fr;
  }
}
