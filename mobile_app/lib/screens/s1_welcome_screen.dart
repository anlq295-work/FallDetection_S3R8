import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/hearth_controller.dart';
import '../widgets/hearth_components.dart';
import '../widgets/liquid_glass.dart';

class S1WelcomeScreen extends StatefulWidget {
  final HearthController ctrl;
  final VoidCallback onSignedInNewUser;
  final VoidCallback onSignedInReturningUser;

  const S1WelcomeScreen({
    super.key,
    required this.ctrl,
    required this.onSignedInNewUser,
    required this.onSignedInReturningUser,
  });

  @override
  State<S1WelcomeScreen> createState() => _S1WelcomeScreenState();
}

class _S1WelcomeScreenState extends State<S1WelcomeScreen> {
  final _emailCtrl = TextEditingController();
  final _carerNameCtrl = TextEditingController();
  final _personPhoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  bool _stepTwo = false;
  bool _loading = false;
  String? _emailError;
  String? _carerNameError;
  String? _codeError;
  String? _networkError;
  String? _otpProviderNotice;
  int _resendSec = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.ctrl.userEmail;
    _carerNameCtrl.text = widget.ctrl.carerName;
    _personPhoneCtrl.text = widget.ctrl.medicalProfile.personPhone;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _carerNameCtrl.dispose();
    _personPhoneCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    final at = s.indexOf('@');
    if (at <= 0 || at == s.length - 1) return false;
    final domain = s.substring(at + 1);
    return domain.contains('.') && !domain.startsWith('.') && !domain.endsWith('.');
  }

  bool _validateStepOneFields() {
    final s = widget.ctrl.s;
    String? emailErr;
    String? carerErr;

    if (!_isValidEmail(_emailCtrl.text)) {
      emailErr = s.s1EmailError;
    }
    if (_carerNameCtrl.text.trim().isEmpty) {
      carerErr = s.requiredFieldError;
    }
    setState(() {
      _emailError = emailErr;
      _carerNameError = carerErr;
      _networkError = null;
    });
    return emailErr == null && carerErr == null;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSec = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSec <= 1) {
        t.cancel();
        setState(() => _resendSec = 0);
      } else {
        setState(() => _resendSec -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    final s = widget.ctrl.s;
    if (!_validateStepOneFields()) return;

    if (widget.ctrl.phoneOfflineSimulation) {
      setState(() => _networkError = s.s1NetworkError);
      return;
    }

    setState(() {
      _loading = true;
      _networkError = null;
      _codeError = null;
    });

    if (widget.ctrl.alertBotUrl.trim().isNotEmpty) {
      final res = await widget.ctrl.requestLoginEmailOtp(
        email: _emailCtrl.text.trim(),
        phone: _personPhoneCtrl.text.trim(),
        carerName: _carerNameCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!res.ok) {
        setState(() {
          _loading = false;
          _networkError = res.message.isNotEmpty ? res.message : s.s1NetworkError;
        });
        return;
      }
      setState(() {
        _loading = false;
        _stepTwo = true;
        _otpProviderNotice = res.provider.isNotEmpty ? res.provider : null;
      });
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stepTwo = true;
        _otpProviderNotice = null;
      });
    }

    _startResendCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  Future<void> _verifyCode({bool skipDirectToHome = false}) async {
    final s = widget.ctrl.s;
    setState(() {
      _codeError = null;
      _networkError = null;
    });

    if (!_validateStepOneFields()) {
      setState(() => _stepTwo = false);
      return;
    }

    final code = _codeCtrl.text.trim();
    if (!skipDirectToHome && (code.length != 6 || int.tryParse(code) == null)) {
      setState(() => _codeError = s.s1CodeError);
      return;
    }
    if (widget.ctrl.phoneOfflineSimulation) {
      setState(() => _networkError = s.s1NetworkError);
      return;
    }

    setState(() => _loading = true);

    if (!skipDirectToHome && widget.ctrl.alertBotUrl.trim().isNotEmpty) {
      final res = await widget.ctrl.verifyLoginEmailOtp(
        email: _emailCtrl.text.trim(),
        phone: _personPhoneCtrl.text.trim(),
        code: code,
      );
      if (!mounted) return;
      if (!res.ok) {
        setState(() {
          _loading = false;
          _codeError = res.message.isNotEmpty ? res.message : s.s1CodeError;
        });
        return;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    await widget.ctrl.signIn(
      email: _emailCtrl.text.trim(),
      carerName: _carerNameCtrl.text.trim(),
      // The monitored person's name is configured later in S4, after the
      // sensor has been paired. Keep the initial sign-in form focused on the
      // account and caregiver details.
      personName: widget.ctrl.personName,
      personPhone: _personPhoneCtrl.text.trim(),
      skipDirectToHome: skipDirectToHome || widget.ctrl.rooms.isNotEmpty,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (skipDirectToHome || widget.ctrl.setupCompleted) {
      widget.onSignedInReturningUser();
    } else {
      widget.onSignedInNewUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final s = ctrl.s;
    final p = HearthPalette.of(context);
    final layout = HearthLayout.of(context);

    final heroSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const HearthBrandMark(size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    kAppReleaseLabel,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.accent),
                  ),
                ],
              ),
            ),
            HearthLanguagePill(
              current: ctrl.language,
              onSelected: ctrl.setLanguage,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(s.s1Headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        _FactRow(icon: Icons.videocam_off_rounded, text: s.s1Fact1),
        const SizedBox(height: 10),
        _FactRow(icon: Icons.campaign_rounded, text: s.s1Fact2),
        const SizedBox(height: 10),
        _FactRow(icon: Icons.wifi_rounded, text: s.s1Fact3),
        if (layout.isDesktop) ...[
          const SizedBox(height: 18),
          HearthBanner(
            tone: HearthBannerTone.info,
            icon: Icons.phonelink_setup_rounded,
            title: s.s1DesktopHint,
          ),
        ],
      ],
    );

    final formCard = LiquidGlassCard(
      borderRadius: 24,
      padding: EdgeInsets.all(layout.isPhone ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_networkError != null) ...[
            HearthBanner(
              tone: HearthBannerTone.critical,
              icon: Icons.wifi_off_rounded,
              title: _networkError!,
            ),
            const SizedBox(height: 14),
          ],
          if (!_stepTwo) ...[
            TextField(
              controller: _emailCtrl,
              readOnly: _loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: s.s1EmailLabel,
                hintText: s.s1EmailPlaceholder,
                helperText: s.s1EmailHelper,
                errorText: _emailError,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carerNameCtrl,
              readOnly: _loading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: s.s1CarerNameLabel,
                hintText: s.s1CarerNameHint,
                errorText: _carerNameError,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _personPhoneCtrl,
              readOnly: _loading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendCode(),
              decoration: InputDecoration(
                labelText: s.s1PersonPhoneLabel,
                hintText: '09xx xxx xxx',
              ),
            ),
            const SizedBox(height: 18),
            HearthPrimaryButton(
              label: s.s1SendCode,
              loadingLabel: s.s1SendingCode,
              loading: _loading,
              onPressed: _sendCode,
            ),
            const SizedBox(height: 8),
            Center(
              child: HearthTextLink(
                label: s.s1AlreadyHaveCode,
                onPressed: _loading
                    ? null
                    : () {
                        if (_validateStepOneFields()) {
                          setState(() => _stepTwo = true);
                        }
                      },
              ),
            ),
            Center(
              child: HearthTextLink(
                label: s.s1SkipToHome,
                onPressed: _loading ? null : () => _verifyCode(skipDirectToHome: true),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.s1Legal,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: p.textMuted),
            ),
          ] else ...[
            HearthBanner(
              tone: HearthBannerTone.ok,
              icon: Icons.mark_email_read_rounded,
              title: s.s1CodeSentTo(_emailCtrl.text.trim()),
              subtitle: _otpProviderNotice,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              readOnly: _loading,
              maxLength: 6,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
              onSubmitted: (_) => _verifyCode(),
              decoration: InputDecoration(
                labelText: s.s1CodeLabel,
                hintText: '123456',
                counterText: '',
                errorText: _codeError,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            HearthPrimaryButton(
              label: s.s1SignIn,
              loadingLabel: s.s1SigningIn,
              loading: _loading,
              onPressed: () => _verifyCode(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HearthTextLink(
                  label: s.back,
                  onPressed: _loading ? null : () => setState(() => _stepTwo = false),
                ),
                HearthTextLink(
                  label: _resendSec > 0 ? s.s1ResendCountdown(_resendSec) : s.s1ResendNow,
                  onPressed: (_resendSec > 0 || _loading) ? null : _sendCode,
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: LiquidGlassBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: layout.horizontalPadding,
                vertical: 20,
              ),
              child: layout.isTwoPane && layout.isLandscape
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: heroSection),
                          SizedBox(width: layout.hingeGap + 16),
                          Expanded(
                            flex: 5,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: formCard,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heroSection,
                          const SizedBox(height: 22),
                          formCard,
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

class _FactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = HearthPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: p.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: p.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
