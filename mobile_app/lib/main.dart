import 'package:flutter/material.dart';
import 'core/models.dart';
import 'core/responsive.dart';
import 'core/theme.dart';
import 'screens/main_shell_screen.dart';
import 'screens/s1_welcome_screen.dart';
import 'screens/s5_test_sensor_screen.dart';
import 'screens/s7_fall_alert_screen.dart';
import 'screens/setup_flow_coordinator.dart';
import 'services/hearth_controller.dart';
import 'widgets/liquid_glass.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HearthApp());
}

class HearthApp extends StatefulWidget {
  final HearthController? controller;
  const HearthApp({super.key, this.controller});

  @override
  State<HearthApp> createState() => _HearthAppState();
}

class _HearthAppState extends State<HearthApp> {
  late final HearthController _ctrl;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ctrl = widget.controller ?? HearthController();
    if (!_ctrl.initialized) {
      _ctrl.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hearth',
          debugShowCheckedModeBanner: false,
          theme: HearthTheme.build(Brightness.light),
          darkTheme: HearthTheme.build(Brightness.dark),
          themeMode: _ctrl.themeMode,
          builder: (ctx, child) => ResponsiveTextScaleGuard(
            maxScale: 2.0,
            child: child ?? const SizedBox.shrink(),
          ),
          home: _HearthRootNavigator(ctrl: _ctrl),
        );
      },
    );
  }
}

class _HearthRootNavigator extends StatefulWidget {
  final HearthController ctrl;
  const _HearthRootNavigator({required this.ctrl});

  @override
  State<_HearthRootNavigator> createState() => _HearthRootNavigatorState();
}

class _HearthRootNavigatorState extends State<_HearthRootNavigator> {
  bool _inFirstTimeSetup = false;

  void _openAddRoomFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, _) => SensorSetupFlow(
            ctrl: widget.ctrl,
            isFirstTimeOnboarding: false,
            onCancel: () => Navigator.of(ctx).pop(),
            onComplete: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  void _openReconnectFlow(HearthRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, _) => SensorSetupFlow(
            ctrl: widget.ctrl,
            isFirstTimeOnboarding: false,
            reconnectTargetRoom: room,
            onCancel: () => Navigator.of(ctx).pop(),
            onComplete: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  void _openTestSensorFlow(HearthRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, _) => S5TestSensorScreen(
            ctrl: widget.ctrl,
            room: room,
            onBack: () => Navigator.of(ctx).pop(),
            onFinish: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final layout = HearthLayout.of(context);

    if (!ctrl.initialized) {
      return const Scaffold(
        body: LiquidGlassBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    Widget baseScreen;
    if (!ctrl.signedIn) {
      baseScreen = S1WelcomeScreen(
        ctrl: ctrl,
        onSignedInNewUser: () => setState(() => _inFirstTimeSetup = true),
        onSignedInReturningUser: () => setState(() => _inFirstTimeSetup = false),
      );
    } else if (_inFirstTimeSetup || !ctrl.setupCompleted) {
      baseScreen = SensorSetupFlow(
        ctrl: ctrl,
        isFirstTimeOnboarding: true,
        onComplete: () => setState(() => _inFirstTimeSetup = false),
      );
    } else {
      baseScreen = MainShellScreen(
        ctrl: ctrl,
        onAddRoom: _openAddRoomFlow,
        onReconnectRoom: _openReconnectFlow,
        onTestRoom: _openTestSensorFlow,
        onSignedOut: () => setState(() => _inFirstTimeSetup = false),
      );
    }

    // S7 Fall Alert can open instantaneously from ANY screen (full-screen on phone, non-dismissible modal on tablet/desktop)
    final alert = ctrl.activeAlert;
    if (alert == null) return baseScreen;

    return Stack(
      fit: StackFit.expand,
      children: [
        baseScreen,
        S7FallAlertView(
          ctrl: ctrl,
          alert: alert,
          asDialog: layout.isTwoPane,
        ),
      ],
    );
  }
}
