import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================================
// CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂC UUID TRÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â™NG KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂšP 100% VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂšI FIRMWARE ESP32-S3 N16R8
// =========================================================================
const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String charWifiUuid = "0beb5483-e18e-4f36-9e1b-b4d6b63c7b28";
const String charContactUuid = "1c6f8742-9a6d-4785-b9e1-e63f9b8c0011";
const String charStatusUuid = "2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344";
const String charTelemetryUuid = "3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455";
const String charCmdUuid = "4fa0b044-9b3e-4d75-af4c-b70e901c5566";
const String charOtaUuid = "5fa0b055-9b3e-4d75-af4c-b70e901c5566";

void main() {
  runApp(const FallGuardApp());
}

class FallGuardApp extends StatelessWidget {
  const FallGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Guard S3R8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF236B63),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(width: 1.5, color: Color(0xFF236B63))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size(0, 46))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size(0, 46))),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F6),
          foregroundColor: Color(0xFF17302D),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF69A89E),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(width: 1.5, color: Color(0xFF69A89E))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size(0, 46))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size(0, 46))),
        scaffoldBackgroundColor: const Color(0xFF101817),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101817),
          foregroundColor: Color(0xFFE6F0ED),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AppStartupGate(),
    );
  }
}

// =========================================================================
// CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â”NG KIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚M TRA KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂžI ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG (STARTUP PERMISSION GATE CHO IOS & ANDROID)
// BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t buÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™c xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n cho phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ xung quanh trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o app lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u
// =========================================================================
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _isLoading = true;
  bool _hasConsented = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConsent();
  }

  Future<void> _checkInitialConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consented = prefs.getBool('has_consented_nearby_devices') ?? false;
      setState(() {
        _hasConsented = consented;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onConsentGranted() {
    setState(() {
      _hasConsented = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF060B14),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (!_hasConsented) {
      return IosNearbyDeviceConsentScreen(
        onConsentGranted: _onConsentGranted,
      );
    }

    return const MainDashboardScreen();
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂC NHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬N CHO PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰P QUÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰T THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ XUNG QUANH (CHUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N APPLE HIG)
// =========================================================================
class IosNearbyDeviceConsentScreen extends StatefulWidget {
  final VoidCallback onConsentGranted;

  const IosNearbyDeviceConsentScreen({super.key, required this.onConsentGranted});

  @override
  State<IosNearbyDeviceConsentScreen> createState() => _IosNearbyDeviceConsentScreenState();
}

class _IosNearbyDeviceConsentScreenState extends State<IosNearbyDeviceConsentScreen> {
  bool _isRequesting = false;

  Future<void> _requestNearbyPermission() async {
    setState(() => _isRequesting = true);

    try {
      // 1. KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t CBCentralManager trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn iOS bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch truy vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i adapter
      BluetoothAdapterState state;
      try {
        state = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 4),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
      } catch (_) {
        state = BluetoothAdapterState.unknown;
      }

      // 2. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn Android mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  Bluetooth chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t
      if (Platform.isAndroid && state == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 3. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i rÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµ rÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn iOS
      if (state == BluetoothAdapterState.unauthorized) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 4. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u Bluetooth ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn iOS
      if (state == BluetoothAdapterState.off && Platform.isIOS) {
        if (!mounted) return;
        _showBluetoothOffDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 5. LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› vÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o Dashboard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_nearby_devices', true);

      if (!mounted) return;
      widget.onConsentGranted();
    } catch (e) {
      // DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ ngoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o cÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©ng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹t ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_nearby_devices', true);
      if (!mounted) return;
      widget.onConsentGranted();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân Bluetooth", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân Bluetooth trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ESP32-S3, vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t iPhone > FallGuard > BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân Bluetooth.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse("app-settings:"));
            },
            child: const Text("MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t iPhone"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.setBool('has_consented_nearby_devices', true));
              widget.onConsentGranted();
            },
            child: const Text("TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o App"),
          ),
        ],
      ),
    );
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text("Bluetooth ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "Bluetooth trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn iPhone cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t. Vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng vuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘t Trung tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn (Control Center) vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Bluetooth ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ FallGuard.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.setBool('has_consented_nearby_devices', true));
              widget.onConsentGranted();
            },
            child: const Text("TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo & BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyan.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.bluetooth_searching, size: 40, color: Colors.cyanAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh
              const Text(
                "Cho phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ xung quanh",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "YÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn iOS ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿m vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ FallGuard S3R8.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 3 ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân
              _buildFeatureItem(
                Icons.radar,
                Colors.cyanAccent,
                "QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t & KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n",
                "TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n ESP32-S3 trong phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng qua Bluetooth Low Energy (BLE) vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c tiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ pin tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.health_and_safety,
                Colors.redAccent,
                "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬",
                "NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng khi ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cao tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£, sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥t giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.verified_user,
                Colors.greenAccent,
                "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân riÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° (ChuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n Apple)",
                "KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng thu thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ GPS, khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng ghi ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m hay theo dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµi cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n. ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ giao tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ UUID FallGuard.",
              ),

              const Spacer(),

              // ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o hÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i iOS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Khi hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i iOS hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ra, vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân [Cho phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p] (Allow) ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿m thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade300, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p quyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.shade700,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isRequesting ? null : _requestNearbyPermission,
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n & Cho phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH (HOME SCREEN): KHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â’N TAB BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŠN NGOÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I, QUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢N LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ
// =========================================================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final ValueNotifier<int> _telemetryRevision = ValueNotifier<int>(0);
  // TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i BLE
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹";
  List<ScanResult> _scanResults = [];
  final Map<String, int> _rssiMap = {};

  // CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c Characteristic ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y
  BluetoothCharacteristic? _wifiChar;
  BluetoothCharacteristic? _contactChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _otaChar;
  final ValueNotifier<String> _otaStatusNotifier = ValueNotifier<String>("");

  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _telemetrySub;
  Timer? _telemetryPollTimer;
  String _telemetryBuffer = '';

  // Controllers cho form cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  double _floorThreshold = 450;

  // GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng Wi-Fi LAN (Direct Wi-Fi Telemetry)
  String _deviceIp = "";
  final TextEditingController _deviceIpController = TextEditingController();
  bool _isWifiMonitoringEnabled = false;
  bool _isWifiConnected = false;
  int _wifiDelayMs = 0;
  Timer? _wifiPollTimer;
  int _wifiFailureCount = 0;

  // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u Telemetry thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c
  String _sysState = "DISCONNECTED";
  String _aiPosture = "UNKNOWN";
  double _aiConfidence = 0.0;
  int _tofHeight = 0;
  int _radarMotion = 0;
  int _radarStatic = 0;
  double _dropRate = 0.0;
  String _deviceFirmwareVersion = "v1.2.0";
  List<dynamic> _eventHistory = [];
  final List<Map<String, double>> _telemetryHistory = <Map<String, double>>[];
  bool _isLoadingHistory = false;

  void _consumeTelemetryBytes(List<int> value, {String source = 'BLE'}) {
    final chunk = utf8.decode(value, allowMalformed: true);
    if (chunk.isEmpty) return;
    // Android cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ chia notify thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh khi MTU chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§.
    // ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ parse khi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ghÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t JSON hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh.
    _telemetryBuffer += chunk;
    if (_telemetryBuffer.length > 4096) {
      final start = _telemetryBuffer.lastIndexOf('{');
      _telemetryBuffer = start >= 0 ? _telemetryBuffer.substring(start) : '';
    }
    try {
      final parsed = jsonDecode(_telemetryBuffer);
      if (parsed is! Map<String, dynamic>) return;
      final complete = _telemetryBuffer;
      _telemetryBuffer = '';
      _applyTelemetryData(parsed, complete.length, source);
    } catch (_) {
      // ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh JSON, chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â notify tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p theo.
    }
  }

  void _applyTelemetryData(Map<String, dynamic> data, int byteCount, String source) {
    try {
      debugPrint('[$source] Telemetry $byteCount bytes: ${jsonEncode(data)}');
      if (!mounted) return;
      setState(() {
        if (data.containsKey('events')) {
          _eventHistory = data['events'] as List<dynamic>? ?? [];
          _isLoadingHistory = false;
        } else if (data.containsKey('st')) {
          _sysState = data['st']?.toString() ?? 'NORMAL';
          _aiPosture = data['cls']?.toString() ?? 'STAND';
          _aiConfidence = (data['cf'] as num?)?.toDouble() ?? 0.0;
          _tofHeight = (data['h'] as num?)?.toInt() ?? 0;
          _radarMotion = (data['m'] as num?)?.toInt() ?? 0;
          _radarStatic = (data['s'] as num?)?.toInt() ?? 0;
          _dropRate = (data['dr'] as num?)?.toDouble() ?? 0.0;
          if (data['ver'] != null) _deviceFirmwareVersion = data['ver'].toString();
          _telemetryHistory.add({
            'h': _tofHeight.toDouble(),
            'm': _radarMotion.toDouble(),
            's': _radarStatic.toDouble(),
            'cf': _aiConfidence,
          });
          if (_telemetryHistory.length > 120) _telemetryHistory.removeAt(0);
        }
      });
      _telemetryRevision.value++;
    } catch (e) {
      debugPrint('[$source] Invalid telemetry payload ($byteCount bytes): $e');
    }
  }

  // LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i & CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a App
  List<Map<String, dynamic>> _deviceHistory = [];
  bool _alarmSoundEnabled = true;
  bool _alarmVibrateEnabled = true;
  double _alarmVolume = 0.8;
  bool _autoEmergency115 = false;
  bool _autoReconnect = true;
  String _heightUnit = "mm";
  String _tempUnit = "ÃƒÂƒÃ‚Â‚ÃƒÂ‚Ã‚Â°C";

  // TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng 1, 2, 3, 4, 6, 7 (Y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿, CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p, CDC STEADI, BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o & Widget)
  ElderlyMedicalProfile _medicalProfile = ElderlyMedicalProfile();
  int _cdcSteadiScore = 0;
  DateTime? _cdcSteadiDate;
  bool _inactivityAlertEnabled = true;
  int _inactivityThresholdMinutes = 30;
  String _monitoredRoomName = "NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m / Toilet";
  DateTime? _roomPresenceStartTime;
  int _roomPresenceSeconds = 0;
  Timer? _inactivityTicker;
  bool _isInactivityAlertShowing = false;
  int _inactivityIncidentsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _loadGeneralSettings();
    _loadDeviceHistory();
    _loadMedicalProfile();
    _loadCdcData();
    _loadInactivitySettings();
    _startInactivityTicker();
  }

  Future<void> _loadMedicalProfile() async {
    final p = await ElderlyMedicalProfile.load();
    setState(() => _medicalProfile = p);
  }

  Future<void> _loadCdcData() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('cdc_steadi_last_score') ?? 0;
    final dateStr = prefs.getString('cdc_steadi_last_date');
    DateTime? dt;
    if (dateStr != null) dt = DateTime.tryParse(dateStr);
    setState(() {
      _cdcSteadiScore = score;
      _cdcSteadiDate = dt;
    });
  }

  Future<void> _loadInactivitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inactivityAlertEnabled = prefs.getBool('inactivity_enabled') ?? true;
      _inactivityThresholdMinutes = prefs.getInt('inactivity_threshold_min') ?? 30;
      _monitoredRoomName = prefs.getString('inactivity_room_name') ?? "NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m / Toilet";
      _inactivityIncidentsCount = prefs.getInt('inactivity_incidents_count') ?? 0;
    });
  }

  Future<void> _saveInactivitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('inactivity_enabled', _inactivityAlertEnabled);
    await prefs.setInt('inactivity_threshold_min', _inactivityThresholdMinutes);
    await prefs.setString('inactivity_room_name', _monitoredRoomName);
  }

  void _startInactivityTicker() {
    _inactivityTicker?.cancel();
    _inactivityTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isConnected && !_isWifiConnected) {
        if (_roomPresenceStartTime != null) {
          setState(() {
            _roomPresenceStartTime = null;
            _roomPresenceSeconds = 0;
          });
        }
        return;
      }

      // NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u radar phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi (motion hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c static) hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ToF cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly
      final bool hasPresence = (_radarMotion > 5 || _radarStatic > 10 || (_tofHeight > 100 && _tofHeight < 3000));
      if (hasPresence) {
        _roomPresenceStartTime ??= DateTime.now();
        final elapsed = DateTime.now().difference(_roomPresenceStartTime!).inSeconds;
        setState(() {
          _roomPresenceSeconds = elapsed;
        });

        // KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra vÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£t ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng
        if (_inactivityAlertEnabled && !_isInactivityAlertShowing && elapsed >= (_inactivityThresholdMinutes * 60)) {
          _triggerInactivityAlarm();
        }
      } else {
        // NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ 45 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ reset bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿m
        if (_roomPresenceStartTime != null && DateTime.now().difference(_roomPresenceStartTime!).inSeconds > 45) {
          setState(() {
            _roomPresenceStartTime = null;
            _roomPresenceSeconds = 0;
          });
        }
      }
    });
  }

  void _triggerInactivityAlarm() async {
    setState(() {
      _isInactivityAlertShowing = true;
      _inactivityIncidentsCount++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('inactivity_incidents_count', _inactivityIncidentsCount);

    if (!mounted) return;
    _showCriticalEmergencyDialog(
      isFall: false,
      reason: "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤T ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG: NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ trong [$_monitoredRoomName] liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c $_inactivityThresholdMinutes phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›n! Nghi ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âµ hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰u.",
    );
  }

  void _showCriticalEmergencyDialog({bool isFall = true, String? reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CriticalEmergencyAlarmDialog(
        isFall: isFall,
        customReason: reason,
        profile: _medicalProfile,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
        dropRate: _dropRate,
        roomName: _monitoredRoomName,
        onCancelAlarm: () {
          _sendCommand("CANCEL_ALARM");
          setState(() {
            _isInactivityAlertShowing = false;
            _roomPresenceStartTime = DateTime.now(); // reset timer
            _roomPresenceSeconds = 0;
          });
        },
        onOpenMedicalId: _openMedicalIdCard,
        onOpenFirstAid: () => showFirstAidGuideModal(context),
      ),
    );
  }

  void _openMedicalIdCard() {
    showDialog(
      context: context,
      builder: (ctx) => EmergencyMedicalIdCardDialog(
        profile: _medicalProfile,
        onEdit: _openMedicalProfileEdit,
      ),
    );
  }

  void _openMedicalProfileEdit() {
    showDialog(
      context: context,
      builder: (ctx) => MedicalProfileEditDialog(
        profile: _medicalProfile,
        onSaved: (p) => setState(() => _medicalProfile = p),
      ),
    );
  }

  void _openCdcSteadiAssessment() {
    showDialog(
      context: context,
      builder: (ctx) => CdcSteadiAssessmentDialog(
        onCompleted: (score, risk) {
          setState(() {
            _cdcSteadiScore = score;
            _cdcSteadiDate = DateTime.now();
          });
        },
      ),
    );
  }

  void _openMedicalAuditReport() {
    showDialog(
      context: context,
      builder: (ctx) => MedicalAuditReportDialog(
        profile: _medicalProfile,
        eventHistory: _eventHistory,
        cdcScore: _cdcSteadiScore,
        cdcDate: _cdcSteadiDate,
        inactivityEventsCount: _inactivityIncidentsCount,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
      ),
    );
  }

  void _openLockscreenWidgetPreview() {
    showDialog(
      context: context,
      builder: (ctx) => LockscreenWidgetPreviewDialog(
        posture: _aiPosture,
        tofHeight: _tofHeight,
        radarMotion: _radarMotion,
        roomName: _monitoredRoomName,
        sysState: _sysState,
      ),
    );
  }

  void _openInactivitySettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº & NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰u nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng / ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰u", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i khi lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢u khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _inactivityAlertEnabled,
                onChanged: (val) {
                  setSheetState(() => _inactivityAlertEnabled = val);
                  setState(() => _inactivityAlertEnabled = val);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 10),
              const Text("NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text("15 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt")),
                  ButtonSegment(value: 30, label: Text("30 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt")),
                  ButtonSegment(value: 45, label: Text("45 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt")),
                  ButtonSegment(value: 60, label: Text("60 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt")),
                ],
                selected: {_inactivityThresholdMinutes},
                onSelectionChanged: (val) {
                  setSheetState(() => _inactivityThresholdMinutes = val.first);
                  setState(() => _inactivityThresholdMinutes = val.first);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 14),
              const Text("VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ khu vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m / Toilet", label: Text("NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m")),
                  ButtonSegment(value: "PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§", label: Text("PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§")),
                  ButtonSegment(value: "PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch", label: Text("PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch")),
                ],
                selected: {_monitoredRoomName},
                onSelectionChanged: (val) {
                  setSheetState(() => _monitoredRoomName = val.first);
                  setState(() => _monitoredRoomName = val.first);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›
  Future<void> _loadGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('saved_device_ip') ?? "";
    final wifiMon = prefs.getBool('wifi_monitoring_enabled') ?? false;

    setState(() {
      _alarmSoundEnabled = prefs.getBool('alarm_sound') ?? true;
      _alarmVibrateEnabled = prefs.getBool('alarm_vibrate') ?? true;
      _alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      _autoEmergency115 = prefs.getBool('auto_emergency_115') ?? false;
      _autoReconnect = prefs.getBool('auto_reconnect') ?? true;
      _heightUnit = prefs.getString('height_unit') ?? "mm";
      _tempUnit = prefs.getString('temp_unit') ?? "ÃƒÂƒÃ‚Â‚ÃƒÂ‚Ã‚Â°C";
      _deviceIp = savedIp;
      _deviceIpController.text = savedIp;
      _isWifiMonitoringEnabled = wifiMon;
    });

    if (_isWifiMonitoringEnabled && _deviceIp.isNotEmpty) {
      _startWifiPolling();
    }
  }

  // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Wi-Fi
  Future<void> _saveWifiMonitoringSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_device_ip', _deviceIp);
    await prefs.setBool('wifi_monitoring_enabled', _isWifiMonitoringEnabled);
  }

  // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›
  Future<void> _saveGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_sound', _alarmSoundEnabled);
    await prefs.setBool('alarm_vibrate', _alarmVibrateEnabled);
    await prefs.setDouble('alarm_volume', _alarmVolume);
    await prefs.setBool('auto_emergency_115', _autoEmergency115);
    await prefs.setBool('auto_reconnect', _autoReconnect);
    await prefs.setString('height_unit', _heightUnit);
    await prefs.setString('temp_unit', _tempUnit);
  }

  // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
  Future<void> _loadDeviceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('saved_devices_history');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _deviceHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } catch (_) {}
    }

    // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Auto-Reconnect
    if (_autoReconnect && !_isConnected && _deviceHistory.isNotEmpty) {
      final mostRecentId = _deviceHistory.first['id'];
      if (mostRecentId != null && mostRecentId.toString().isNotEmpty) {
        _connectToDevice(BluetoothDevice.fromId(mostRecentId.toString()));
      }
    }
  }

  // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
  Future<void> _saveDeviceToHistory(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final String id = device.remoteId.str;
    final String devName = device.platformName.isEmpty ? "FallDetector_S3R8" : device.platformName;

    int existingIdx = _deviceHistory.indexWhere((d) => d['id'] == id);
    String customName = devName;
    if (existingIdx >= 0 && _deviceHistory[existingIdx]['customName'] != null) {
      customName = _deviceHistory[existingIdx]['customName'];
    }

    final record = {
      'id': id,
      'name': devName,
      'customName': customName,
      'lastConnected': DateTime.now().toIso8601String(),
      'rssi': _rssiMap[id] ?? -60,
    };

    if (existingIdx >= 0) {
      _deviceHistory.removeAt(existingIdx);
    }
    _deviceHistory.insert(0, record);

    await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
    setState(() {});
  }

  // XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­
  Future<void> _removeDeviceFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _deviceHistory.removeWhere((d) => d['id'] == id);
    await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
    setState(() {});
  }

  // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trong lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ (VD: PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§, NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ sinh)
  Future<void> _renameDeviceInHistory(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    int idx = _deviceHistory.indexWhere((d) => d['id'] == id);
    if (idx >= 0) {
      _deviceHistory[idx]['customName'] = newName.trim().isEmpty ? _deviceHistory[idx]['name'] : newName.trim();
      await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
      setState(() {});
    }
  }

  @override
  void dispose() {
    _wifiPollTimer?.cancel();
    _deviceIpController.dispose();
    _inactivityTicker?.cancel();
    _scanSub?.cancel();
    _statusSub?.cancel();
    _telemetrySub?.cancel();
    _telemetryPollTimer?.cancel();
    _telemetryRevision.dispose();
    _ssidController.dispose();
    _passController.dispose();
    _phoneController.dispose();
    _chatIdController.dispose();
    _botTokenController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
    }
  }

  // QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ BLE
  void _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _statusMessage = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ FallDetector_S3R8...";
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results.where((r) {
            String name = r.device.platformName;
            return name.contains("FallDetector") ||
                   r.advertisementData.serviceUuids.any((u) => u.str128.toLowerCase().contains(serviceUuid.toLowerCase()));
          }).toList();

          for (var r in results) {
            _rssiMap[r.device.remoteId.str] = r.rssi;
          }
        });
      });

      await Future.delayed(const Duration(seconds: 6));
      setState(() {
        _isScanning = false;
        if (_scanResults.isEmpty && !_isConnected) {
          _statusMessage = "KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯n ESP32-S3 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t!";
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i khi quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t BLE: $e";
      });
    }
  }

  // KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i ESP32-S3 N16R8
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _statusMessage = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i ${device.platformName.isEmpty ? 'FallDetector_S3R8' : device.platformName}...";
    });

    try {
      await device.connect(license: License.nonprofit, autoConnect: false, timeout: const Duration(seconds: 10));

      // YÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u MTU 512 bytes ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i JSON HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n
      if (Platform.isAndroid) {
        try {
          final mtu = await device.requestMtu(512);
          debugPrint('[BLE] Negotiated MTU: $mtu (payload max ${mtu - 3} bytes)');
        } catch (_) {}
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _statusMessage = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng!";
      });

      // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ ghÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng
      _saveDeviceToHistory(device);

      // LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯ng nghe trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _sysState = "DISCONNECTED";
            _statusMessage = "ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i";
          });
        }
      });

      // KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ BLE
      List<BluetoothService> services = await device.discoverServices();
      _wifiChar = null;
      _contactChar = null;
      _statusChar = null;
      _telemetryChar = null;
      _cmdChar = null;
      _otaChar = null;
      for (var s in services) {
        for (var c in s.characteristics) {
          String u = c.uuid.str128.toLowerCase();
          debugPrint('[BLE] Char $u read=${c.properties.read} notify=${c.properties.notify} write=${c.properties.write}');
          if (u == charWifiUuid.toLowerCase()) _wifiChar = c;
          if (u == charContactUuid.toLowerCase()) _contactChar = c;
          if (u == charStatusUuid.toLowerCase()) _statusChar = c;
          if (u == charTelemetryUuid.toLowerCase()) _telemetryChar = c;
          if (u == charCmdUuid.toLowerCase()) _cmdChar = c;
          if (u == charOtaUuid.toLowerCase()) _otaChar = c;
        }
      }

      // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng cho Android/GATT cache: nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n diÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n telemetry bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng payload JSON,
      // khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™c hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o UUID.
      if (_telemetryChar == null) {
        for (final service in services) {
          for (final candidate in service.characteristics) {
            if (!candidate.properties.read || !candidate.properties.notify) continue;
            try {
              final probe = await candidate.read();
              final text = utf8.decode(probe, allowMalformed: true);
              final parsed = jsonDecode(text);
              if (parsed is Map<String, dynamic> &&
                  (parsed.containsKey('st') || parsed.containsKey('events'))) {
                _telemetryChar = candidate;
                debugPrint('[BLE] Telemetry fallback selected: ${candidate.uuid.str128}');
                break;
              }
            } catch (_) {
              // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  status/contact characteristic; tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªnh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c.
            }
          }
          if (_telemetryChar != null) break;
        }
      }

      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ & ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« chip
      final discovered = [_wifiChar, _contactChar, _statusChar, _telemetryChar, _cmdChar, _otaChar].whereType<BluetoothCharacteristic>().length;
      debugPrint('[BLE] Discovered $discovered/6 characteristics');
      if (_cmdChar == null) {
        _showSnackbar('BLE command channel not found. Please reflash firmware and reconnect.', Colors.red);
        debugPrint('[BLE] Missing command characteristic: $charCmdUuid');
      }
      await _readCurrentContacts();

      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o Status Notify
      if (_statusChar != null) {
        await _statusChar!.setNotifyValue(true);
        _statusSub?.cancel();
        _statusSub = _statusChar!.onValueReceived.listen((value) {
          String msg = utf8.decode(value);
          setState(() {
            _statusMessage = msg;
          });
          _handleStatusNotification(msg);
        });
      }

      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n Telemetry thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c & DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en
      if (_telemetryChar != null) {
        try {
          await _telemetryChar!.setNotifyValue(true);
        } catch (e) {
          debugPrint('[BLE] Enable telemetry notify failed: $e');
        }
        _telemetrySub?.cancel();
        _telemetryBuffer = '';
        _telemetrySub = _telemetryChar!.onValueReceived.listen((value) => _consumeTelemetryBytes(value));
        try {
          final initial = await _telemetryChar!.read();
          if (initial.isNotEmpty) _consumeTelemetryBytes(initial, source: 'BLE-READ');
        } catch (e) {
          debugPrint('[BLE] Initial telemetry read failed: $e');
        }
        _telemetryPollTimer?.cancel();
        _telemetryPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
          try {
            final value = await _telemetryChar?.read();
            if (value != null && value.isNotEmpty) _consumeTelemetryBytes(value, source: 'BLE-READ');
          } catch (e) {
            debugPrint('[BLE-READ] Poll failed: $e');
          }
        });
      }

      // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en ngay sau khi kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
      _fetchHistory();
      _sendCommand("GET_VERSION");

    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _statusMessage = "KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: $e";
      });
    }
  }

  void _disconnect() async {
    await _connectedDevice?.disconnect();
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
      _sysState = "DISCONNECTED";
      _statusMessage = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i";
    });
  }

  Future<void> _readCurrentContacts() async {
    if (_contactChar == null) return;
    try {
      List<int> bytes = await _contactChar!.read();
      if (bytes.isNotEmpty) {
        String jsonStr = utf8.decode(bytes);
        Map<String, dynamic> data = jsonDecode(jsonStr);
        setState(() {
          _phoneController.text = data["phone"] ?? "";
          _chatIdController.text = data["chat_id"] ?? "";
          if (data.containsKey("floor_mm")) {
            _floorThreshold = (data["floor_mm"] as num).toDouble();
          }
        });
      }
    } catch (_) {}
  }

  void _handleStatusNotification(String msg) {
    if (msg.startsWith("CONNECTED_IP:")) {
      String ip = msg.replaceAll("CONNECTED_IP:", "").trim();
      setState(() {
        _deviceIp = ip;
        _deviceIpController.text = ip;
      });
      _saveWifiMonitoringSettings();
      _showSnackbar("ESP32 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Wi-Fi! IP: $ip (TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u)", Colors.green);
      if (!_isWifiMonitoringEnabled) {
        _toggleWifiMonitoring(true);
      }
    } else if (msg == "WIFI_CONNECT_FAILED") {
      _showSnackbar("ESP32 kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Wi-Fi thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i! KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©u.", Colors.red);
    } else if (msg == "CONFIG_UPDATED_OK") {
      _showSnackbar("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng!", Colors.green);
    } else if (msg == "NETWORK_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh Wi-Fi. ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i.", Colors.orange);
    } else if (msg == "FACTORY_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh. ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i.", Colors.orange);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_SAVED") {
      _showSnackbar("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch night light ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o ESP32!", Colors.green);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_ERROR") {
      _showSnackbar("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch night light khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡.", Colors.red);
    } else if (msg == "EMERGENCY_DISPATCHED") {
      _showCriticalEmergencyDialog(isFall: true);
    } else if (msg == "HISTORY_SENT") {
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS!", Colors.blueAccent);
    } else if (msg == "HISTORY_CLEARED_OK") {
      setState(() {
        _eventHistory.clear();
      });
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en!", Colors.orange);
    } else if (msg == "TEST_EVENT_ADDED") {
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS!", Colors.green);
    } else if (msg.startsWith("FIRMWARE_VERSION:")) {
      setState(() {
        _deviceFirmwareVersion = msg.replaceFirst("FIRMWARE_VERSION:", "").trim();
      });
    } else if (msg.startsWith("OTA_")) {
      _otaStatusNotifier.value = msg;
      if (msg == "OTA_SUCCESS_REBOOTING") {
        _showSnackbar("NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p firmware ESP32 thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng 100%! ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i...", Colors.green);
      } else if (msg.startsWith("OTA_ERROR:")) {
        _showSnackbar("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t firmware: ${msg.replaceFirst('OTA_ERROR:', '')}", Colors.red);
      }
    }
  }

  // GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh Wi-Fi
  Future<void> _sendWifiConfig() async {
    if (_wifiChar == null) {
      _showSnackbar("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i BLE vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹!", Colors.red);
      return;
    }
    String ssid = _ssidController.text.trim();
    String pass = _passController.text.trim();
    if (ssid.isEmpty) {
      _showSnackbar("Vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn Wi-Fi (SSID)!", Colors.orange);
      return;
    }

    Map<String, String> payload = {"ssid": ssid, "pass": pass};
    String jsonStr = jsonEncode(payload);

    try {
      await _wifiChar!.write(utf8.encode(jsonStr), withoutResponse: false);
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i Wi-Fi. ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i...", Colors.blue);
    } catch (e) {
      _showSnackbar("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i Wi-Fi thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: $e", Colors.red);
    }
  }

  // GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
  Future<void> _sendContactsConfig() async {
    if (_contactChar == null) {
      _showSnackbar("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i BLE vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹!", Colors.red);
      return;
    }

    Map<String, dynamic> payload = {
      "phone": _phoneController.text.trim(),
      "chat_id": _chatIdController.text.trim(),
      "floor_mm": _floorThreshold.toInt(),
    };
    if (_botTokenController.text.trim().isNotEmpty) {
      payload["bot_token"] = _botTokenController.text.trim();
    }

    String jsonStr = jsonEncode(payload);
    try {
      await _contactChar!.write(utf8.encode(jsonStr), withoutResponse: false);
      _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh...", Colors.blue);
    } catch (e) {
      _showSnackbar("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: $e", Colors.red);
    }
  }

  // GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn
  Future<void> _sendCommand(String cmd) async {
    if (_cmdChar == null) {
      _showSnackbar("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i BLE!", Colors.red);
      return;
    }
    try {
      await _cmdChar!.write(utf8.encode(cmd), withoutResponse: false);
    } catch (e) {
      _showSnackbar("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh $cmd: $e", Colors.red);
    }
  }

  // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en
  Future<void> _fetchHistory() async {
    if (!_isConnected) return;
    setState(() {
      _isLoadingHistory = true;
    });
    await _sendCommand("GET_HISTORY");
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  // =========================================================================
  // GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾P QUA MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â NG WI-FI NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜I BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜ (DIRECT WI-FI LAN TELEMETRY)
  // =========================================================================
  void _toggleWifiMonitoring(bool enabled) {
    setState(() {
      _isWifiMonitoringEnabled = enabled;
      if (!enabled) {
        _isWifiConnected = false;
        _wifiDelayMs = 0;
      }
    });
    _saveWifiMonitoringSettings();
    if (enabled) {
      _startWifiPolling();
    } else {
      _stopWifiPolling();
    }
  }

  void _startWifiPolling() {
    _wifiPollTimer?.cancel();
    _pollWifiTelemetry();
    // ThÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â² dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i 700ms qua HTTP LAN
    _wifiPollTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _pollWifiTelemetry();
    });
  }

  void _stopWifiPolling() {
    _wifiPollTimer?.cancel();
    _wifiPollTimer = null;
  }

  Future<void> _pollWifiTelemetry() async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty || !_isWifiMonitoringEnabled) return;

    final stopwatch = Stopwatch()..start();
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);

    try {
      final uri = Uri.parse('http://$ip/api/telemetry');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 1500));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);

        if (!mounted) return;
        setState(() {
          _isWifiConnected = true;
          _wifiDelayMs = stopwatch.elapsedMilliseconds;
          _wifiFailureCount = 0;

          if (data.containsKey("st")) {
            final oldState = _sysState;
            _sysState = data["st"] ?? "NORMAL";
            _aiPosture = data["cls"] ?? "STAND";
            _aiConfidence = (data["cf"] as num?)?.toDouble() ?? 0.0;
            _tofHeight = (data["h"] as num?)?.toInt() ?? 0;
            _radarMotion = (data["m"] as num?)?.toInt() ?? 0;
            _radarStatic = (data["s"] as num?)?.toInt() ?? 0;
            _dropRate = (data["dr"] as num?)?.toDouble() ?? 0.0;
            if (data.containsKey("ver") && data["ver"] != null) {
              _deviceFirmwareVersion = data["ver"].toString();
            }
            _telemetryHistory.add({
              'h': _tofHeight.toDouble(),
              'm': _radarMotion.toDouble(),
              's': _radarStatic.toDouble(),
              'cf': _aiConfidence,
            });
            if (_telemetryHistory.length > 120) _telemetryHistory.removeAt(0);

            if (oldState != "ALERT" && _sysState == "ALERT") {
              _showCriticalEmergencyDialog(isFall: true);
            }
            _telemetryRevision.value++;
          }
        });
      } else {
        _handleWifiPollFailure();
      }
    } catch (_) {
      _handleWifiPollFailure();
    } finally {
      client.close();
    }
  }

  void _handleWifiPollFailure() {
    if (!mounted) return;
    _wifiFailureCount++;
    if (_wifiFailureCount >= 3 && _isWifiConnected) {
      setState(() {
        _isWifiConnected = false;
      });
    }
  }

  Future<void> _sendWifiCommand(String cmd) async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty) {
      _showSnackbar("Vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c!", Colors.orange);
      return;
    }

    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2000);
    try {
      final uri = Uri.parse('http://$ip/api/command?cmd=$cmd');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh qua Wi-Fi: $cmd", Colors.green);
        _pollWifiTelemetry();
      } else {
        _showSnackbar("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh qua Wi-Fi thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i (HTTP ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      _showSnackbar("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Wi-Fi tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i $ip: $e", Colors.red);
    } finally {
      client.close();
    }
  }

  Future<void> _fetchHistoryOverWifi() async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty) {
      _showSnackbar("Vui lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c!", Colors.orange);
      return;
    }

    setState(() => _isLoadingHistory = true);
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 3000);
    try {
      final uri = Uri.parse('http://$ip/api/events');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 3500));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        if (data.containsKey("events")) {
          setState(() {
            _eventHistory = data["events"];
            _isLoadingHistory = false;
          });
          _showSnackbar("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en qua Wi-Fi (${_eventHistory.length} sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘)", Colors.blueAccent);
          return;
        }
      }
    } catch (_) {}
    finally {
      client.close();
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showWifiIpDialog() {
    _deviceIpController.text = _deviceIp;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh IP Wi-Fi"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ESP32 (hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ khi ESP32 kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Wi-Fi):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceIpController,
              decoration: const InputDecoration(
                labelText: "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP",
                hintText: "192.168.1.xxx",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹o: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP cÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u khi thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Wi-Fi qua Bluetooth.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y"),
          ),
          FilledButton(
            onPressed: () {
              final newIp = _deviceIpController.text.trim();
              if (newIp.isNotEmpty) {
                setState(() {
                  _deviceIp = newIp;
                });
                _saveWifiMonitoringSettings();
                _toggleWifiMonitoring(true);
              }
              Navigator.pop(ctx);
            },
            child: const Text("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u & KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i"),
          ),
        ],
      ),
    );
  }

  // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ chi tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ (GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“m GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t, HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t)
  void _openDeviceDetail(BluetoothDevice device, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ValueListenableBuilder<int>(
          valueListenable: _telemetryRevision,
          builder: (context, _, _) => DeviceDetailScreen(
          device: device,
          isConnected: _isConnected,
          initialTabIndex: initialTab,
          // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c
          sysState: _sysState,
          aiPosture: _aiPosture,
          aiConfidence: _aiConfidence,
          tofHeight: _tofHeight,
          radarMotion: _radarMotion,
          radarStatic: _radarStatic,
          dropRate: _dropRate,
          eventHistory: _eventHistory,
          isLoadingHistory: _isLoadingHistory,
          telemetryHistory: _telemetryHistory,
          // Controllers
          ssidController: _ssidController,
          passController: _passController,
          phoneController: _phoneController,
          chatIdController: _chatIdController,
          botTokenController: _botTokenController,
          floorThreshold: _floorThreshold,
          onFloorThresholdChanged: (val) {
            setState(() {
              _floorThreshold = val;
            });
          },
          // Callbacks
          onSaveWifi: _sendWifiConfig,
          onSaveContacts: _sendContactsConfig,
          onDisconnect: () {
            _disconnect();
            Navigator.pop(ctx);
          },
          onSendCommand: _sendCommand,
          onFetchHistory: _fetchHistory,
          onRefreshContacts: _readCurrentContacts,
          otaChar: _otaChar,
          otaStatusNotifier: _otaStatusNotifier,
          firmwareVersion: _deviceFirmwareVersion,
          // Wi-Fi Telemetry & Commands
          deviceIp: _deviceIp,
          isWifiConnected: _isWifiConnected,
          wifiDelayMs: _wifiDelayMs,
          onSendWifiCommand: _sendWifiCommand,
          onFetchWifiHistory: _fetchHistoryOverWifi,
          ),
        ),
      ),
    );
  }

  // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t
  String _formatLastSeen(DateTime? dt) {
    if (dt == null) return "GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y";
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«a xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c";
    if (diff.inHours < 24) return "${diff.inHours} giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c";
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trong lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­
  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn theo phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â… theo dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµi (VD: PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”ng BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â , NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng 2, PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _renameDeviceInHistory(id, controller.text);
            },
            child: const Text("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn"),
          ),
        ],
      ),
    );
  }

  // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng
  void _openGeneralSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => GeneralSettingsScreen(
          alarmSound: _alarmSoundEnabled,
          alarmVibrate: _alarmVibrateEnabled,
          alarmVolume: _alarmVolume,
          autoEmergency115: _autoEmergency115,
          autoReconnect: _autoReconnect,
          heightUnit: _heightUnit,
          tempUnit: _tempUnit,
          deviceHistoryCount: _deviceHistory.length,
          onSettingsChanged: (sound, vib, vol, em115, autoRec, hUnit, tUnit) {
            setState(() {
              _alarmSoundEnabled = sound;
              _alarmVibrateEnabled = vib;
              _alarmVolume = vol;
              _autoEmergency115 = em115;
              _autoReconnect = autoRec;
              _heightUnit = hUnit;
              _tempUnit = tUnit;
            });
            _saveGeneralSettings();
          },
          onClearHistory: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_devices_history');
            setState(() {
              _deviceHistory.clear();
            });
          },
        ),
      ),
    );
  }

  // Widget hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
  Widget _buildDeviceHistoryList() {
    return Column(
      children: _deviceHistory.map((item) {
        final String id = item['id'] ?? '';
        final String customName = item['customName'] ?? item['name'] ?? 'FallDetector_S3R8';
        final String rawName = item['name'] ?? 'FallDetector_S3R8';
        final String lastTime = item['lastConnected'] != null
            ? _formatLastSeen(DateTime.tryParse(item['lastConnected']))
            : "GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y";
        final bool isCurrent = _isConnected && _connectedDevice?.remoteId.str == id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isCurrent ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isCurrent ? Colors.green : Colors.grey.withValues(alpha: 0.25),
              width: isCurrent ? 1.6 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isCurrent ? Colors.green.withValues(alpha: 0.2) : Colors.blueGrey.withValues(alpha: 0.15),
              child: Icon(
                isCurrent ? Icons.sensors : Icons.history,
                color: isCurrent ? Colors.green : Colors.blueGrey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    customName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  "$rawName | ID: $id",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i cuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i: $lastTime",
                  style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrent)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _connectToDevice(BluetoothDevice.fromId(id)),
                    child: const Text("KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i", style: TextStyle(fontSize: 12)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.green),
                    tooltip: "VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o chi tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹",
                    onPressed: () {
                      if (_connectedDevice != null) _openDeviceDetail(_connectedDevice!);
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'rename') {
                      _showRenameDialog(id, customName);
                    } else if (val == 'delete') {
                      _removeDeviceFromHistory(id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng / vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text("QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y", style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              if (isCurrent && _connectedDevice != null) {
                _openDeviceDetail(_connectedDevice!);
              } else {
                _connectToDevice(BluetoothDevice.fromId(id));
              }
            },
          ),
        );
      }).toList(),
    );
  }

  // Widget hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a & trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p (Feature 6 & 1)
  Widget _buildGlanceableLiveStatusCard() {
    final bool isActivelyMonitored = _isConnected || _isWifiConnected;
    final Color badgeColor = _sysState == "ALERT"
        ? Colors.redAccent
        : (_sysState == "PRE_ALARM" ? Colors.orangeAccent : (isActivelyMonitored ? Colors.greenAccent : Colors.grey));
    final int minutes = _roomPresenceSeconds ~/ 60;
    final int seconds = _roomPresenceSeconds % 60;
    final double progress = (_inactivityThresholdMinutes > 0)
        ? (_roomPresenceSeconds / (_inactivityThresholdMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: badgeColor.withValues(alpha: 0.06),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sysState == "ALERT" ? Icons.emergency : (isActivelyMonitored ? Icons.shield : Icons.shield_outlined),
                    color: badgeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActivelyMonitored
                            ? (_sysState == "ALERT"
                                ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Â¨ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P"
                                : (_isWifiConnected && !_isConnected
                                    ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂŒÃƒÂ‚Ã‚Â GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾P QUA WI-FI"
                                    : (_isWifiConnected && _isConnected
                                        ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚Â¢ GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰P (BLE + WI-FI)"
                                        : "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚Â¢ AN TOÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N - ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂANG GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT BLE 24/7")))
                            : "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Âª CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âœ KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂI (BLUETOOTH HOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶C WI-FI)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: badgeColor),
                      ),
                      Text(
                        "Khu vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c: $_monitoredRoomName ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ${_medicalProfile.fullName}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.widgets_outlined, size: 20),
                  tooltip: "MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng Widget MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a",
                  onPressed: _openLockscreenWidgetPreview,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m & bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng
            if (isActivelyMonitored) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Text("HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n diÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n: ${minutes}p ${seconds}s", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n: < ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.85 ? Colors.redAccent : (progress > 0.6 ? Colors.orangeAccent : Colors.tealAccent),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3 thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ mini
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatusChip("TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatusChip("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatusChip("Radar 24GHz", "$_radarMotion%", Icons.radar, Colors.orangeAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Wi-Fi LAN
  Widget _buildWifiMonitoringCard() {
    final bool isOnline = _isWifiConnected;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;
    final Color statusColor = !_isWifiMonitoringEnabled
        ? Colors.grey
        : (isOnline ? Colors.tealAccent : Colors.orangeAccent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t/tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t Wi-Fi
            Row(
              children: [
                Icon(
                  _isWifiMonitoringEnabled ? Icons.wifi : Icons.wifi_off,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Wi-Fi (LAN)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _isWifiMonitoringEnabled
                            ? (_deviceIp.isEmpty
                                ? "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹"
                                : "IP: $_deviceIp ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ${isOnline ? 'ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…: ${_wifiDelayMs}ms' : 'ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i...'}")
                            : "Theo dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµi tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« xa xuyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n Bluetooth",
                        style: TextStyle(fontSize: 11, color: isOnline ? Colors.tealAccent : Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isWifiMonitoringEnabled,
                  activeThumbColor: Colors.tealAccent,
                  onChanged: (val) {
                    if (val && _deviceIp.isEmpty) {
                      _showWifiIpDialog();
                    } else {
                      _toggleWifiMonitoring(val);
                    }
                  },
                ),
              ],
            ),

            if (_isWifiMonitoringEnabled) ...[
              const Divider(height: 16),
              // Thanh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ IP vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOnline ? Colors.green : Colors.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.sensors : Icons.sync,
                          size: 13,
                          color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang truyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân (${_wifiDelayMs}ms)" : "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i...",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i IP", style: TextStyle(fontSize: 11)),
                        onPressed: _showWifiIpDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.cyanAccent),
                        tooltip: "LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u Wi-Fi ngay",
                        onPressed: _pollWifiTelemetry,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n qua Wi-Fi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  runAlignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng", "$_radarMotion/100", Icons.directions_run, Colors.orangeAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ", "$_radarStatic/100", Icons.air, Colors.tealAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nhanh Wi-Fi
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: compact ? screenWidth - 60 : (screenWidth - 68) / 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.emergency, size: 16),
                      label: const Text("SOS Wi-Fi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _sendWifiCommand("PANIC_SOS"),
                    ),
                  ),
                  SizedBox(
                    width: compact ? screenWidth - 60 : (screenWidth - 68) / 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.volume_off, size: 16),
                      label: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i Wi-Fi", style: TextStyle(fontSize: 12)),
                      onPressed: () => _sendWifiCommand("CANCEL_ALARM"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.blueAccent),
                    tooltip: "TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS qua Wi-Fi",
                    onPressed: _fetchHistoryOverWifi,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWifiMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMiniStatusChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // Thanh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nhanh 1 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (Feature 2, 7, 3, 1)
  Widget _buildQuickHealthActionBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.badge, size: 16, color: Colors.redAccent),
              label: const Text("ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalIdCard,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.quiz, size: 16, color: Colors.blueAccent),
              label: Text("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m CDC: $_cdcSteadiScoreÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.4)),
              onPressed: _openCdcSteadiAssessment,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.description, size: 16, color: Colors.tealAccent),
              label: const Text("BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o Y Khoa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalAuditReport,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.bathtub, size: 16, color: Colors.amberAccent),
              label: Text("GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t: ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.amber.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
              onPressed: _openInactivitySettingsSheet,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u)
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    List<BluetoothDevice> displayedDevices = [];
    if (_connectedDevice != null && _isConnected) {
      displayedDevices.add(_connectedDevice!);
    }
    for (var r in _scanResults) {
      if (_connectedDevice == null || r.device.remoteId != _connectedDevice!.remoteId) {
        displayedDevices.add(r.device);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Fall Guard S3R8', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (compact)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'medical') {
                  _openMedicalIdCard();
                } else if (value == 'report') {
                  _openMedicalAuditReport();
                } else if (value == 'device') {
                  if (_isConnected && _connectedDevice != null) _openDeviceDetail(_connectedDevice!);
                } else if (value == 'settings') {
                  _openGeneralSettings();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'medical', child: Text('ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» Y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p')),
                PopupMenuItem(value: 'report', child: Text('BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o y khoa')),
                PopupMenuItem(value: 'device', child: Text('ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i')),
                PopupMenuItem(value: 'settings', child: Text('CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung')),
              ],
            ),
          if (!compact) ...[
            IconButton(
              icon: const Icon(Icons.badge, color: Colors.redAccent),
              tooltip: "ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ KhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p",
              onPressed: _openMedicalIdCard,
            ),
            IconButton(
              icon: const Icon(Icons.description, color: Colors.tealAccent),
              tooltip: "BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o Y Khoa ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³",
              onPressed: _openMedicalAuditReport,
            ),
            IconButton(
              icon: Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: _isConnected ? Colors.greenAccent : Colors.grey,
              ),
              tooltip: _isConnected ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i" : "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i",
              onPressed: () {
                if (_isConnected && _connectedDevice != null) {
                  _openDeviceDetail(_connectedDevice!);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung",
              onPressed: _openGeneralSettings,
            ),
          ],
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i Glanceable Live Status Card (Feature 6 & 1)
            _buildGlanceableLiveStatusCard(),

            // ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Wi-Fi LAN
            _buildWifiMonitoringCard(),

            // Thanh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nhanh 1 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (Feature 2, 7, 3, 1)
            _buildQuickHealthActionBar(),

            // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isScanning ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t xung quanh..." : "QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ FallDetector_S3R8"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¦N 1: LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠCH SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¬ THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂªNG KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂI (PAIRED / HISTORY DEVICES)
            if (_deviceHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text("ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Text("${_deviceHistory.length} thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              _buildDeviceHistoryList(),
              const SizedBox(height: 14),
            ],

            // PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¦N 2: THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒM THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤Y QUA QUÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰T BLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y xung quanh:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (displayedDevices.isNotEmpty)
                  Text("${displayedDevices.length} thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: displayedDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_searching, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _isScanning ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng Bluetooth..." : "NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n 'QuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t' ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ FallDetector_S3R8",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedDevices.length,
                      itemBuilder: (ctx, idx) {
                        final device = displayedDevices[idx];
                        final bool isThisConnected = _isConnected && _connectedDevice?.remoteId == device.remoteId;
                        final String devName = device.platformName.isEmpty ? "FallDetector_S3R8" : device.platformName;
                        final int? rssi = _rssiMap[device.remoteId.str];

                        // ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i: ViÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân xanh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡, hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ xanh "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i", cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t")
                        if (isThisConnected) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.green.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.green, width: 1.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openDeviceDetail(device),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.sensors, color: Colors.green, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            devName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 15),
                                              SizedBox(width: 5),
                                              Text(
                                                "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i",
                                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "RSSI: ${rssi != null ? '$rssi dBm' : 'TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘t'} | ID: ${device.remoteId}",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _disconnect,
                                      child: const Text("NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right, color: Colors.green),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _connectToDevice(device),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.devices, color: Colors.blueAccent, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          devName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "RSSI: ${rssi != null ? '$rssi dBm' : '--'} | ID: ${device.remoteId}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text("KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH QUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢N TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ: GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â’M 3 TAB (GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT, HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂEN & GRAPH, CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶T)
// =========================================================================
class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final int initialTabIndex;

  // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u Telemetry
  final String sysState;
  final String aiPosture;
  final double aiConfidence;
  final int tofHeight;
  final int radarMotion;
  final int radarStatic;
  final double dropRate;
  final List<dynamic> eventHistory;
  final bool isLoadingHistory;
  final List<Map<String, double>> telemetryHistory;

  // Controllers cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh
  final TextEditingController ssidController;
  final TextEditingController passController;
  final TextEditingController phoneController;
  final TextEditingController chatIdController;
  final TextEditingController botTokenController;
  final double floorThreshold;
  final ValueChanged<double> onFloorThresholdChanged;

  // Callbacks
  final Future<void> Function() onSaveWifi;
  final Future<void> Function() onSaveContacts;
  final VoidCallback onDisconnect;
  final Future<void> Function(String) onSendCommand;
  final Future<void> Function() onFetchHistory;
  final Future<void> Function() onRefreshContacts;
  final BluetoothCharacteristic? otaChar;
  final ValueNotifier<String> otaStatusNotifier;
  final String firmwareVersion;

  // GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Wi-Fi LAN
  final String deviceIp;
  final bool isWifiConnected;
  final int wifiDelayMs;
  final Future<void> Function(String)? onSendWifiCommand;
  final Future<void> Function()? onFetchWifiHistory;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.isConnected,
    this.initialTabIndex = 0,
    required this.sysState,
    required this.aiPosture,
    required this.aiConfidence,
    required this.tofHeight,
    required this.radarMotion,
    required this.radarStatic,
    required this.dropRate,
    required this.eventHistory,
    required this.isLoadingHistory,
    this.telemetryHistory = const [],
    required this.ssidController,
    required this.passController,
    required this.phoneController,
    required this.chatIdController,
    required this.botTokenController,
    required this.floorThreshold,
    required this.onFloorThresholdChanged,
    required this.onSaveWifi,
    required this.onSaveContacts,
    required this.onDisconnect,
    required this.onSendCommand,
    required this.onFetchHistory,
    required this.onRefreshContacts,
    this.otaChar,
    required this.otaStatusNotifier,
    required this.firmwareVersion,
    this.deviceIp = "",
    this.isWifiConnected = false,
    this.wifiDelayMs = 0,
    this.onSendWifiCommand,
    this.onFetchWifiHistory,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _deviceTabController;
  bool _obscurePass = true;
  late double _currentFloorThreshold;
  int _selectedEventIndex = 0;
  int _blackBoxSubTab = 0; // 0: TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c, 1: HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS

  // XÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh qua kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªnh khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng (BLE hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c Wi-Fi)
  Future<void> _handleDeviceCommand(String cmd) async {
    if (widget.isConnected) {
      await widget.onSendCommand(cmd);
    } else if (widget.onSendWifiCommand != null && widget.deviceIp.isNotEmpty) {
      await widget.onSendWifiCommand!(cmd);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ qua Bluetooth hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c Wi-Fi!"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(TimeOfDay value) {
    return "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickNightTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _nightStart : _nightEnd,
      helpText: isStart ? "GiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n" : "GiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºc ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n",
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (isStart) {
        _nightStart = picked;
      } else {
        _nightEnd = picked;
      }
    });
  }

  void _saveNightlightSchedule() {
    final command = "NIGHTLIGHT_SCHEDULE:${_nightScheduleEnabled ? 1 : 0},"
        "${_nightStart.hour},${_nightStart.minute},"
        "${_nightEnd.hour},${_nightEnd.minute}";
    _handleDeviceCommand(command);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch night light ${_formatTime(_nightStart)}ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â“${_formatTime(_nightEnd)}")),
    );
  }

  // CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng minh cho thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹
  int _alarmGracePeriod = 15; // 15 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â… trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›n
  String _nightlightMode = "AUTO_MOTION"; // "AUTO_MOTION", "ALWAYS_ON", "OFF"
  double _nightlightBrightness = 40.0;
  String _nightlightColor = "WARM_YELLOW";
  bool _nightScheduleEnabled = true;
  TimeOfDay _nightStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _nightEnd = const TimeOfDay(hour: 6, minute: 0);

  Future<void> _confirmDeviceReset(String command, String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _handleDeviceCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh. ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i.')),
        );
      }
    }
  }
  bool _buzzerActiveHigh = false; // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›p vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i module cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i 3 chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n: Active-LOW (High-Z im lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·ng, 0V bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng)
  bool _buzzerMuted = false;

  @override
  void initState() {
    super.initState();
    _deviceTabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _currentFloorThreshold = widget.floorThreshold;
    _loadBuzzerPolarity();
  }

  Future<void> _loadBuzzerPolarity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _buzzerActiveHigh = prefs.getBool('dev_buzzer_active_high_${widget.device.remoteId.str}') ?? false;
      _buzzerMuted = prefs.getBool('dev_buzzer_muted_${widget.device.remoteId.str}') ?? false;
    });
  }

  @override
  void dispose() {
    _deviceTabController.dispose();
    super.dispose();
  }

  Color _getStateColor(String state) {
    switch (state) {
      case "NORMAL": return Colors.green;
      case "SUSPECTED": return Colors.amber.shade700;
      case "PRE_ALARM": return Colors.orange.shade800;
      case "ALERT": return Colors.red;
      case "ACK": return Colors.red.shade400;
      case "FAULT": return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _constrainedTab(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String devName = widget.device.platformName.isEmpty ? "FallDetector_S3R8" : widget.device.platformName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(devName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text("ID: ${widget.device.remoteId}", style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
        bottom: TabBar(
          controller: _deviceTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart), text: "GiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t"),
            Tab(icon: Icon(Icons.timeline), text: "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS"),
            Tab(icon: Icon(Icons.settings), text: "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _deviceTabController,
        children: [
          _constrainedTab(_buildMonitorTab()),
          _constrainedTab(_buildBlackBoxTab()),
          _constrainedTab(_buildSettingsTab()),
        ],
      ),
    );
  }

  // TAB 1: GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI GIAN THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â€U KHIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚N TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âª XA
  Widget _buildMonitorTab() {
    final bool canControl = widget.isConnected || widget.isWifiConnected;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Huy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u nguÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i (BLE & Wi-Fi)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isConnected ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isConnected ? Colors.green : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                         size: 14, color: widget.isConnected ? Colors.green : Colors.grey),
                    const SizedBox(width: 4),
                    Text(widget.isConnected ? "Bluetooth: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i" : "Bluetooth: NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t",
                         style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                          color: widget.isConnected ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isWifiConnected ? Colors.teal.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isWifiConnected ? Icons.wifi : Icons.wifi_off,
                         size: 14, color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.isWifiConnected
                          ? "Wi-Fi: TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p (${widget.wifiDelayMs}ms)"
                          : (widget.deviceIp.isNotEmpty ? "Wi-Fi: ${widget.deviceIp}" : "Wi-Fi: ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t"),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isWifiConnected ? Colors.tealAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
          Card(
            color: _getStateColor(widget.sysState).withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _getStateColor(widget.sysState).withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: _getStateColor(widget.sysState), size: 30),
                      const SizedBox(width: 10),
                      Text(
                        widget.sysState,
                        style: TextStyle(
                          color: _getStateColor(widget.sysState),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.sysState == "ALERT" ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Â¨ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P!" :
                    widget.sysState == "PRE_ALARM" ? "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â¯ÃƒÂ‚Ã‚Â¸ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂANG ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾M NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¢C PRE-ALARM (30s)" :
                    widget.sysState == "SUSPECTED" ? "XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t..." :
                    widget.sysState == "NORMAL" ? "MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng & An toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n" : "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 1.28 : 1.55,
            children: [
              _buildMetricCard("TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ AI", widget.aiPosture, "Tin cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y: ${(widget.aiConfidence * 100).toStringAsFixed(0)}%", Icons.accessibility_new, const Color(0xFF477B72)),
              _buildMetricCard("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", "${widget.tofHeight} mm", "V_drop: ${widget.dropRate.toStringAsFixed(0)} mm/s", Icons.height, const Color(0xFF3D6F8E)),
              _buildMetricCard("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar", "${widget.radarMotion} / 100", "LD2410 Peak Move", Icons.directions_run, const Color(0xFF9A6B35)),
              _buildMetricCard("TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p", "${widget.radarStatic} / 100", "LD2410 Static Gate", Icons.air, const Color(0xFF3F7C73)),
            ],
          ),
          const SizedBox(height: 14),

          // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p SOS tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« xa
          ElevatedButton.icon(
            onPressed: canControl ? () => _handleDeviceCommand("PANIC_SOS") : null,
            icon: const Icon(Icons.emergency, size: 28),
            label: const Text("KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂCH HOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â T SOS CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âª XA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh nhanh
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CANCEL_ALARM") : null,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i / HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y"),
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CALIBRATE_FLOOR") : null,
                  icon: const Icon(Icons.straighten),
                  label: const Text("HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("TEST_ALARM") : null,
                  icon: const Icon(Icons.speaker),
                  label: const Text("Test chuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng/ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n"),
                ),
              ),
              // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt xem hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en: ChuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng sang Tab 2 vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  fetch dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (widget.isConnected) {
                      widget.onFetchHistory();
                    } else if (widget.onFetchWifiHistory != null) {
                      widget.onFetchWifiHistory!();
                    }
                    _deviceTabController.animateTo(1);
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text("Xem HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âen"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂEN & PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂCH ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŒC KHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG GIAN (TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾P & LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠCH SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¬)
  Widget _buildBlackBoxTab() {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c
    final Map<String, dynamic> liveEvent = {
      "type": (widget.aiPosture == "FALL") ? 1 : 0,
      "sec": 0,
      "vel": widget.dropRate > 0 ? widget.dropRate : 0.0,
      "mot": widget.radarMotion,
      "dst": widget.tofHeight > 0 ? (widget.tofHeight / 10).round() : 160,
    };

    // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    final Map<String, dynamic> demoEvent = {
      "type": 1,
      "sec": 128,
      "vel": 680.0,
      "mot": 88,
      "dst": 165,
    };

    final List<dynamic> events = widget.eventHistory.isNotEmpty ? widget.eventHistory : [demoEvent];
    final bool isDemo = widget.eventHistory.isEmpty;

    final currentEvent = (_selectedEventIndex >= 0 && _selectedEventIndex < events.length)
        ? events[_selectedEventIndex]
        : events[0];

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. THANH CHUYÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â”I CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜: TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾P (LIVE) vs LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠCH SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¬ HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂEN (NVS)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _blackBoxSubTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _blackBoxSubTab == 0 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors, size: 18, color: _blackBoxSubTab == 0 ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                           Flexible(
                             child: Text(
                               "TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c",
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _blackBoxSubTab == 0 ? Colors.white : Colors.grey,
                            ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _blackBoxSubTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _blackBoxSubTab == 1 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 18, color: _blackBoxSubTab == 1 ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                           Flexible(
                             child: Text(
                               "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS (${widget.eventHistory.length})",
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _blackBoxSubTab == 1 ? Colors.white : Colors.grey,
                            ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===================================================================
          // PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â N 1: THEO DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â•I TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾P THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI GIAN THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C (LIVE TELEMETRY)
          // ===================================================================
          if (_blackBoxSubTab == 0) ...[
            // ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nhanh tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (widget.isConnected || widget.isWifiConnected) ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n & TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.aiPosture == "FALL"
                                ? Colors.redAccent
                                : (widget.aiPosture == "LIE" ? Colors.purpleAccent : (widget.aiPosture == "SIT" ? Colors.orangeAccent : Colors.green)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${widget.aiPosture} ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ${(widget.aiConfidence * 100).toInt()}%",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.tofHeight} mm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.cyanAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.radarMotion}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text("HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p / TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text("${widget.radarStatic}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.tealAccent)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u telemetry thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c.
            LiveTelemetryChart(samples: widget.telemetryHistory),
          ] else ...[
            // ===================================================================
            // PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â N 2: LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠCH SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¬ HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂEN NVS (FLASH BLACK BOX AUDIT)
            // ===================================================================
            // Thanh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: compact ? double.infinity : 180,
                  child: ElevatedButton.icon(
                    onPressed: widget.isLoadingHistory
                        ? null
                        : () {
                            if (widget.isConnected) {
                              widget.onFetchHistory();
                            } else if (widget.onFetchWifiHistory != null && widget.deviceIp.isNotEmpty) {
                              widget.onFetchWifiHistory!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Bluetooth hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c Wi-Fi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­!"), backgroundColor: Colors.orange),
                              );
                            }
                          },
                    icon: widget.isLoadingHistory
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« ESP32"),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 100,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("CLEAR_HISTORY"),
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 130,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("ADD_TEST_EVENT"),
                    icon: const Icon(Icons.add_alert, color: Colors.orangeAccent),
                    label: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o Test"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isDemo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en NVS hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u minh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa!",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 8),

            // Danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n trong hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n trong NVS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${widget.eventHistory.length} sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.eventHistory.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user, size: 40, color: Colors.green.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n. ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y ra!",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n 'TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o Test' ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› Flash NVS.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < widget.eventHistory.length; i++) ...[
                _buildEventListItem(widget.eventHistory[i], i),
              ],
          ],
        ],
      ),
    );
  }

    Widget _buildEventListItem(Map<String, dynamic> e, int index) {
    final bool isSelected = _selectedEventIndex == index;
    final int type = (e["type"] ?? 0) as int;
    final String typeTitle = (type == 3) ? "SOS ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng" : (type == 2 ? "NgÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­m (15s)" : "NgÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh");
    final IconData icon = (type == 3) ? Icons.touch_app : Icons.personal_injury;
    final double vel = (e["vel"] as num?)?.toDouble() ?? 0.0;
    final int mot = (e["mot"] as num?)?.toInt() ?? 0;
    final int sec = (e["sec"] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.blue.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedEventIndex = index;
          });
        },
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(typeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("V_drop: ${vel.toStringAsFixed(0)} mm/s | ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng: $mot/100 | LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºc: ${sec}s"),
        trailing: isSelected
            ? const Chip(
                label: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang xem Graph", style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                padding: EdgeInsets.zero,
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng
  void _showHardwareSelfTestModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹n phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ESP32-S3R8:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSelfTestItem(Icons.radar, "Radar FMCW 24GHz (LD2410B)", "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t 9 cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly | SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng vi ba ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh", Colors.green),
            _buildSelfTestItem(Icons.height, "Laser ToF (VL53L1X)", "KhoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â : ${widget.tofHeight} mm | ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c", Colors.green),
            _buildSelfTestItem(Icons.motion_photos_on, "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n PIR (AM312)", "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng | PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng ngoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i (GPIO 4)", Colors.green),
            _buildSelfTestItem(Icons.volume_up, "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng Active Buzzer", "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i | MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n 85dB", Colors.teal),
            _buildSelfTestItem(Icons.lightbulb, "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ LED RGB WS2812B", "ChuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i LED ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng", Colors.teal),
            _buildSelfTestItem(Icons.battery_charging_full, "KhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i nguÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n 220V AC & Pin UPS", "HLK-5M05 cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n | Pin 18650 dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Âµn sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng", Colors.blueAccent),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () {
                widget.onSendCommand("TEST_BEEP");
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra chuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹!")),
                );
              },
              child: const Text("KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t Test ChuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngay"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfTestItem(IconData icon, String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(status, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }

  // TAB 3: CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶T THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ
  Widget _buildSettingsTab() {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh Wi-Fi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh Wi-Fi cho ESP32", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.ssidController,
                    decoration: const InputDecoration(
                      labelText: "TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng Wi-Fi (SSID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.router),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©u Wi-Fi",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: widget.isConnected ? widget.onSaveWifi : null,
                    icon: const Icon(Icons.save),
                    label: const Text("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u Wi-Fi & KhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ESP32"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(children: [
                    Icon(Icons.restart_alt, color: Colors.orangeAccent),
                    SizedBox(width: 8),
                    Text('KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeviceReset('RESET_NETWORK', 'ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i Wi-Fi?', 'ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a SSID/mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©u Wi-Fi vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i.'),
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: () => _confirmDeviceReset('FACTORY_RESET', 'KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™?', 'XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh, Wi-Fi, danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘en.'),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("Danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // HÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘a kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªnh
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.blueAccent, size: 18),
                            SizedBox(width: 6),
                            Text("BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘a kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªnh & NhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ NhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ SMS: NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂT cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch nhau bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y (VD: 0901234567, 0988776655).\n"
                          "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m Telegram: ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm Bot vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m gia ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh rÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân Group ID (cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u -, VD: -100192837465) ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n chuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi.\n"
                          "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ NhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu Telegram cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n: NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c ID cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch nhau dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y (VD: 123456789, 987654321).",
                          style: TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n (SMS)",
                      hintText: "0901234567, 0912345678",
                      helperText: "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i, phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y (,)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.chatIdController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "Telegram Chat ID / Group ID",
                      hintText: "-100192837465, 123456789",
                      helperText: "Group ID gia ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh (cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u -) hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu ID cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n (,)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.send),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.botTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Telegram Bot Token (TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân)",
                      hintText: "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng chiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu cao sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n: ${_currentFloorThreshold.toInt()} mm",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _currentFloorThreshold,
                    min: 200,
                    max: 800,
                    divisions: 12,
                    label: "${_currentFloorThreshold.toInt()} mm",
                    onChanged: (val) {
                      setState(() {
                        _currentFloorThreshold = val;
                      });
                      widget.onFloorThresholdChanged(val);
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: widget.isConnected ? widget.onSaveContacts : null,
                    icon: const Icon(Icons.save_as),
                    label: const Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ & NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI GIAN CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âœ HOÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂƒN BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG (GRACE PERIOD)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.amber),
                      SizedBox(width: 8),
                      Text("ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (Grace Period)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i tin nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯n/Telegram khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [5, 10, 15, 30].map((sec) {
                      final bool isSelected = _alarmGracePeriod == sec;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.amber.withValues(alpha: 0.25) : Colors.transparent,
                              side: BorderSide(color: isSelected ? Colors.amber : Colors.grey.shade800),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => setState(() => _alarmGracePeriod = sec),
                            child: Text(
                              "${sec}s",
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.amber : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂˆN NGÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¦ THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG MINH (SMART NIGHTLIGHT)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.indigoAccent),
                      SizedBox(width: 8),
                      Text("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng minh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ WS2812B trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cao tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥c ban ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "AUTO_MOTION", label: Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (Radar)", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "ALWAYS_ON", label: Text("LuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "OFF", label: Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t", style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_nightlightMode},
                      onSelectionChanged: (val) => setState(() => _nightlightMode = val.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t trong khung giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ban ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _nightScheduleEnabled ? "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh: 18:00 ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â“ 06:00" : "Night light hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y",
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _nightScheduleEnabled,
                    onChanged: (value) => setState(() => _nightScheduleEnabled = value),
                  ),
                  if (_nightScheduleEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNightTime(true),
                            icon: const Icon(Icons.login, size: 18),
                            label: Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ${_formatTime(_nightStart)}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNightTime(false),
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t ${_formatTime(_nightEnd)}"),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _saveNightlightSchedule,
                    icon: const Icon(Icons.schedule),
                    label: const Text("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch night light vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§:", style: TextStyle(fontSize: 12)),
                      Text("${_nightlightBrightness.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigoAccent)),
                    ],
                  ),
                  Slider(
                    value: _nightlightBrightness,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    onChanged: (val) => setState(() => _nightlightBrightness = val),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng:", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "WARM_YELLOW", label: Text("VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "SOFT_WHITE", label: Text("TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹u", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "CYAN", label: Text("Xanh ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc", style: TextStyle(fontSize: 10))),
                        ],
                        selected: {_nightlightColor},
                        onSelectionChanged: (val) => setState(() => _nightlightColor = val.first),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â° KIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚M TRA PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¦N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨NG (HARDWARE DIAGNOSTIC SELF-TEST)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fact_check, color: Colors.teal),
                      SizedBox(width: 8),
                      Text("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥m cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘a phÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c (PIR AM312 + Radar 24GHz + Laser ToF + CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i & Pin UPS):",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.teal),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: _showHardwareSelfTestModal,
                    icon: const Icon(Icons.speed, color: Colors.teal),
                    label: const Text("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n & nguÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n", style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),
          // CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (Active HIGH / Active LOW)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (Buzzer)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n: KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c Cao (Active-HIGH, chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n GPIO 5 ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ 0V tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i). NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu khi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n, thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân 'MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p' hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t 'TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i' ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ test yÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text("MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c Cao (HIGH)", style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: false, label: Text("MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p (LOW)", style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_buzzerActiveHigh},
                        onSelectionChanged: (val) async {
                          final isHigh = val.first;
                          setState(() => _buzzerActiveHigh = isHigh);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('dev_buzzer_active_high_${widget.device.remoteId.str}', isHigh);
                          widget.onSendCommand(isHigh ? "BUZZER_ACTIVE_HIGH" : "BUZZER_ACTIVE_LOW");
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isHigh ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh: CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c Cao (Active-HIGH, 0V TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t)" : "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh: CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p (Active-LOW, 3.3V TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t)"),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i (Mute khi test)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text("VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½, chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng qua LED vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _buzzerMuted,
                    onChanged: (val) async {
                      setState(() => _buzzerMuted = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('dev_buzzer_muted_${widget.device.remoteId.str}', val);
                      widget.onSendCommand(val ? "BUZZER_MUTE" : "BUZZER_UNMUTE");
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i (Muted)" : "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i (Unmuted)"),
                          backgroundColor: val ? Colors.deepOrange : Colors.teal,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                    onPressed: widget.isConnected ? () => widget.onSendCommand("TEST_BEEP") : null,
                    icon: const Icon(Icons.speaker, size: 18),
                    label: const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i (Test Beep 200ms)", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.isConnected ? () => widget.onSendCommand("CALIBRATE_FLOOR") : null,
                    icon: const Icon(Icons.straighten),
                    label: const Text("HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (ToF)"),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onDisconnect,
                    icon: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent),
                    label: const Text("NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y", style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬P NHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬T FIRMWARE THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ (ESP32-S3 FIRMWARE OTA)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.memory, color: Colors.purpleAccent),
                      SizedBox(width: 8),
                      Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Firmware ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ (ESP32 OTA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh & thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n diÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ cho vi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ESP32-S3-N16R8 mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Firmware hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn chip:", style: TextStyle(fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(widget.firmwareVersion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn Cloud:", style: TextStyle(fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("v1.2.0 (MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purpleAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: widget.isConnected ? _showEsp32OtaDialog : null,
                    icon: const Icon(Icons.cloud_sync),
                    label: const Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t Firmware cho thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ (1-ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m)"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.shade700,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬P NHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬T ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨NG DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¤NG KHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚Y (OTA UPDATE CHO ANDROID & IPHONE)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.system_update_alt, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm (OTA Update)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PhiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)\nTÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p phiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub qua mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _triggerOtaUpdate,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text("KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t phiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerOtaUpdate() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = true;
        Map<String, dynamic>? releaseInfo;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (isLoading && releaseInfo == null) {
              () async {
                try {
                  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
                  final request = await client.getUrl(
                    Uri.parse('https://api.github.com/repos/anlq295-work/FallDetection_S3R8/releases/latest'),
                  );
                  request.headers.set('User-Agent', 'FallGuardApp');
                  request.headers.set('Accept', 'application/vnd.github.v3+json');
                  final response = await request.close();
                  if (response.statusCode == 200) {
                    final body = await response.transform(utf8.decoder).join();
                    final data = jsonDecode(body) as Map<String, dynamic>;
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        releaseInfo = data;
                        isLoading = false;
                      });
                    }
                  } else {
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        isLoading = false;
                      });
                    }
                  }
                } catch (_) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              }();
            }

            int? apkSize;
            if (releaseInfo != null && releaseInfo!['assets'] is List) {
              for (var asset in (releaseInfo!['assets'] as List)) {
                if (asset is Map && asset['name'] == 'app-release.apk') {
                  apkSize = asset['size'] as int?;
                  break;
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng OTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done, color: Colors.blueAccent, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("GitHub Releases (TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                                  Text(
                                    Platform.isIOS ? "Apple In-House OTA (FallGuard_iOS_unsigned.ipa)" : "Android APK Release (app-release.apk)",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("PhiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("v1.2.0 (Build 2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn GitHub:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  releaseInfo?['name']?.toString() ?? (isLoading ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i..." : "Fall Guard Latest Release"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            if (apkSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Dung lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng file APK:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    "${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Platform.isIOS
                            ? "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub Releases. NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n [CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t] ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p."
                            : "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n APK mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn GitHub Releases vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t Android ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ nguyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u.",
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final releasesPage = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest");
                    try {
                      await launchUrl(releasesPage, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text("Xem Release GitHub"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (Platform.isIOS) {
                      const otaUrl = "itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/ios_ota/manifest.plist";
                      final uri = Uri.parse(otaUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        final ipaUrl = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/FallGuard_iOS_unsigned.ipa");
                        await launchUrl(ipaUrl, mode: LaunchMode.externalApplication);
                      }
                    } else {
                      const apkUrl = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/app-release.apk";
                      final uri = Uri.parse(apkUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t APK: $e")),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ngay"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEsp32OtaDialog() {
    final TextEditingController urlController = TextEditingController(
      text: "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/firmware.bin",
    );
    bool isBleFlashing = false;
    double bleProgress = 0.0;
    String bleStatusText = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_update_alt, color: Colors.purpleAccent, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Firmware ESP32",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purpleAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ A/B Dual-OTA trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn chip ESP32-S3 (16MB Flash). ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ luÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p nguÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n trong suÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘t quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t.",
                                style: TextStyle(fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "1. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng qua Wi-Fi (KhuyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purpleAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "ESP32 kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Internet qua Wi-Fi vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i file firmware.bin trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t 5-10 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: urlController,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          labelText: "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i Firmware (.bin)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                urlController.text = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/firmware.bin";
                              },
                              child: const Text("GitHub Releases", style: TextStyle(fontSize: 10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                urlController.text = "https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/firmware.bin";
                              },
                              child: const Text("GitHub Raw", style: TextStyle(fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: widget.otaStatusNotifier,
                        builder: (context, otaStatus, _) {
                          double? wifiPct;
                          String wifiText = "SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Âµn sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t";
                          if (otaStatus == "OTA_STARTING") {
                            wifiText = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Cloud vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i firmware...";
                            wifiPct = 0.1;
                          } else if (otaStatus.startsWith("OTA_PROGRESS:")) {
                            int p = int.tryParse(otaStatus.replaceFirst("OTA_PROGRESS:", "")) ?? 0;
                            wifiPct = p / 100.0;
                            wifiText = "TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o Flash: $p%";
                          } else if (otaStatus == "OTA_SUCCESS_REBOOTING") {
                            wifiPct = 1.0;
                            wifiText = "ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng 100%! ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i...";
                          } else if (otaStatus.startsWith("OTA_ERROR:")) {
                            wifiText = "LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i: ${otaStatus.replaceFirst('OTA_ERROR:', '')}";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (otaStatus.isNotEmpty) ...[
                                LinearProgressIndicator(
                                  value: wifiPct,
                                  color: otaStatus.startsWith("OTA_ERROR:") ? Colors.red : Colors.purpleAccent,
                                  backgroundColor: Colors.purple.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  wifiText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: otaStatus.startsWith("OTA_ERROR:") ? Colors.red : Colors.purpleAccent,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent.shade700,
                                  minimumSize: const Size.fromHeight(40),
                                ),
                                onPressed: () {
                                  final url = urlController.text.trim();
                                  if (url.isNotEmpty) {
                                    widget.onSendCommand("OTA_HTTP:$url");
                                  } else {
                                    widget.onSendCommand("OTA_LATEST");
                                  }
                                },
                                icon: const Icon(Icons.wifi, size: 18),
                                label: const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t qua Wi-Fi"),
                              ),
                            ],
                          );
                        },
                      ),
                      if (widget.deviceIp.isNotEmpty) ...[
                        const Divider(height: 28),
                        const Text(
                          "2. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p qua Web OTA nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ (SiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu nhanh)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ trang nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p http://${widget.deviceIp}/update trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p trong mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng Wi-Fi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p file firmware.bin khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n Internet.",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.greenAccent),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse("http://${widget.deviceIp}/update");
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ Web OTA: $e")),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.language, size: 18, color: Colors.greenAccent),
                          label: Text("MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ Web OTA (http://${widget.deviceIp}/update)", style: const TextStyle(color: Colors.greenAccent)),
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        widget.deviceIp.isNotEmpty ? "3. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p qua Bluetooth Low Energy (BLE OTA)" : "2. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p qua Bluetooth Low Energy (BLE OTA)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng cho trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ nÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ Wi-Fi hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ Internet.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      if (isBleFlashing) ...[
                        LinearProgressIndicator(
                          value: bleProgress,
                          color: Colors.blueAccent,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bleStatusText,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 10),
                      ],
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: isBleFlashing ? null : () async {
                          if (widget.otaChar == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng OTA Bluetooth trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setDialogState(() {
                            isBleFlashing = true;
                            bleProgress = 0.05;
                            bleStatusText = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i firmware tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i...";
                          });

                          try {
                            final client = HttpClient();
                            client.badCertificateCallback = (cert, host, port) => true;
                            final req = await client.getUrl(Uri.parse(urlController.text.trim()));
                            req.followRedirects = true;
                            req.maxRedirects = 5;
                            final resp = await req.close();
                            if (resp.statusCode != 200) {
                              throw Exception("MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i HTTP ${resp.statusCode}");
                            }
                            final bytes = await consolidateHttpClientResponseBytes(resp);
                            if (bytes.length < 50000 || bytes[0] != 0xE9) {
                              throw Exception("File tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â (${bytes.length} bytes) khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i firmware ESP32 hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ (magic byte 0xE9 khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›p)!");
                            }

                            // XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©
                            widget.otaStatusNotifier.value = "";

                            setDialogState(() {
                              bleProgress = 0.05;
                              bleStatusText = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng Flash trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ESP32...";
                            });

                            // GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u OTA
                            await widget.otaChar!.write(utf8.encode("OTA_BEGIN:${bytes.length}"), withoutResponse: false);

                            // ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ESP32 thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n Flash sector erase (mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t khoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng 1-3 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y)
                            for (int i = 0; i < 40; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("ESP32 tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i OTA: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                              if (st == "OTA_READY") {
                                break;
                              }
                            }

                            const chunkSize = 256;
                            int sent = 0;
                            final total = bytes.length;
                            while (sent < total) {
                              final st = widget.otaStatusNotifier.value;
                              if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("ESP32 ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                              final end = (sent + chunkSize < total) ? sent + chunkSize : total;
                              final chunk = bytes.sublist(sent, end);
                              await widget.otaChar!.write(chunk, withoutResponse: false);
                              sent = end;
                              setDialogState(() {
                                bleProgress = 0.05 + (sent / total) * 0.90;
                                bleStatusText = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p qua BLE: ${(sent / 1024).toStringAsFixed(1)} / ${(total / 1024).toStringAsFixed(1)} KB (${(bleProgress * 100).toInt()}%)";
                              });
                              await Future.delayed(const Duration(milliseconds: 20));
                            }

                            setDialogState(() {
                              bleProgress = 0.96;
                              bleStatusText = "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹n (Checksum & Verify) trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn chip...";
                            });

                            await Future.delayed(const Duration(milliseconds: 500));
                            await widget.otaChar!.write(utf8.encode("OTA_END"), withoutResponse: false);

                            // ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ESP32 xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  reboot trong tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘a 10 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y
                            bool isRebooting = false;
                            for (int i = 0; i < 100; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st == "OTA_SUCCESS_REBOOTING") {
                                isRebooting = true;
                                break;
                              } else if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c firmware thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                            }

                            if (isRebooting) {
                              setDialogState(() {
                                bleProgress = 1.0;
                                bleStatusText = "ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng 100%! ESP32 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o firmware mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i...";
                              });
                            } else {
                              throw Exception("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« ESP32 sau khi gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u.");
                            }
                          } catch (e) {
                            setDialogState(() {
                              isBleFlashing = false;
                              bleStatusText = "LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p BLE: $e";
                            });
                          }
                        },
                        icon: const Icon(Icons.bluetooth, size: 18, color: Colors.blueAccent),
                        label: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i & NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p firmware qua BLE", style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBleFlashing ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class LiveTelemetryChart extends StatelessWidget {
  final List<Map<String, double>> samples;
  const LiveTelemetryChart({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: const [
            Icon(Icons.show_chart, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(child: Text('ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u telemetry ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c...', style: TextStyle(color: Colors.grey))),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.timeline, color: Colors.cyanAccent), SizedBox(width: 8), Text('Telemetry thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          const SizedBox(height: 4),
          const Text('120 mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ToF mm ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ Radar /100', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(height: 210, child: CustomPaint(painter: LiveTelemetryPainter(samples))),
          const SizedBox(height: 8),
          const Wrap(spacing: 14, children: [
            _ChartLegend(color: Colors.cyanAccent, label: 'ToF'),
            _ChartLegend(color: Colors.orangeAccent, label: 'Radar ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng'),
            _ChartLegend(color: Colors.tealAccent, label: 'Radar tÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh'),
          ]),
        ]),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
}

class LiveTelemetryPainter extends CustomPainter {
  final List<Map<String, double>> samples;
  LiveTelemetryPainter(this.samples);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.grey.withValues(alpha: .18)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(0, size.height * i / 4), Offset(size.width, size.height * i / 4), grid);
    }
    for (var i = 0; i <= 6; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6, size.height), grid);
    }
    final series = [('h', Colors.cyanAccent, 2000.0), ('m', Colors.orangeAccent, 100.0), ('s', Colors.tealAccent, 100.0)];
    for (final item in series) {
      final paint = Paint()..color = item.$2..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < samples.length; i++) {
        final x = samples.length == 1 ? 0.0 : size.width * i / (samples.length - 1);
        final yValue = (samples[i][item.$1] ?? 0).clamp(0, item.$3);
        final y = size.height * (1 - yValue / item.$3);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant LiveTelemetryPainter oldDelegate) => true;
}

class FallKinematicGraph extends StatelessWidget {
  final Map<String, dynamic> event;

  const FallKinematicGraph({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final int type = (event["type"] as num?)?.toInt() ?? 1;
    final double vel = (event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (event["mot"] as num?)?.toInt() ?? 88;
    final int dist = (event["dst"] as num?)?.toInt() ?? 165;
    final int sec = (event["sec"] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (Kinematic Graph)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly: ${dist}cm | VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c: ${vel.toStringAsFixed(0)} mm/s | ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng: $motion/100",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    "${sec}s",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Canvas vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ 2 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng cong
            SizedBox(
              height: 190,
              child: CustomPaint(
                painter: KinematicCurvePainter(
                  dropVelocity: vel,
                  peakMotion: motion,
                  fallType: type,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.cyanAccent, "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF (mm)"),
                _buildLegendItem(Colors.orangeAccent, "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar (/100)"),
                _buildLegendItem(Colors.redAccent, "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (Impact)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›p CustomPainter vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng
class KinematicCurvePainter extends CustomPainter {
  final double dropVelocity;
  final int peakMotion;
  final int fallType;

  KinematicCurvePainter({
    required this.dropVelocity,
    required this.peakMotion,
    required this.fallType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ khung lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      double y = h * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (int i = 0; i <= 5; i++) {
      double x = w * (i / 5.0);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // 2. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (Impact point) tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i x = 50%
    final double impactX = w * 0.50;
    final Paint impactLinePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(impactX, 0), Offset(impactX, h), impactLinePaint);

    // 3. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng cong 1: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF (MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u xanh Cyan)
    // t = -2s (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng cao 1700mm) -> t = -0.5s (RÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i) -> t = 0s (ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n 300mm) -> t = +2s (NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n)
    final Path heightPath = Path();
    final double hTop = h * 0.15;    // ~1700mm
    final double hFloor = h * 0.82;  // ~300mm

    heightPath.moveTo(0, hTop);
    heightPath.lineTo(w * 0.25, hTop + 5);
    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥t dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c rÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± do
    heightPath.cubicTo(
      w * 0.38, hTop + 10,
      w * 0.44, hFloor * 0.65,
      impactX, hFloor,
    );
    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m yÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    heightPath.lineTo(w, hFloor + 3);

    final Paint heightPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(heightPath, heightPaint);

    // 4. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng cong 2: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar (MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u cam)
    // t = -2s (ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p 15) -> t = 0s (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p Peak Motion) -> t = +2s (VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â 0-5)
    final Path motionPath = Path();
    final double mBase = h * 0.85; // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
    final double mPeak = h * (1.0 - (math.min(100, math.max(20, peakMotion)) / 100.0) * 0.85);

    motionPath.moveTo(0, mBase - 10);
    motionPath.lineTo(w * 0.25, mBase - 15);
    motionPath.cubicTo(
      w * 0.40, mBase - 25,
      w * 0.46, mPeak,
      impactX, mPeak,
    );
    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng sau ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n 0
    motionPath.cubicTo(
      w * 0.60, mBase - 20,
      w * 0.75, mBase - 5,
      w, mBase,
    );

    final Paint motionPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(motionPath, motionPaint);

    // 5. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t (Impact point pulse dot)
    final Paint pulseOuter = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 14, pulseOuter);

    final Paint pulseInner = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 6, pulseInner);

    // 6. NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c X
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, double x, double y, Color c) {
      tp.text = TextSpan(text: text, style: TextStyle(fontSize: 9, color: c));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }

    drawText("-2s (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng)", w * 0.10, h - 14, Colors.grey);
    drawText("-1s (MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â )", w * 0.32, h - 14, Colors.grey);
    drawText("0s (ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n)", impactX, h - 14, Colors.redAccent);
    drawText("+1s (NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m yÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn)", w * 0.72, h - 14, Colors.grey);
    drawText("+2s", w * 0.92, h - 14, Colors.grey);
  }

  @override
  bool shouldRepaint(covariant KinematicCurvePainter oldDelegate) {
    return oldDelegate.dropVelocity != dropVelocity ||
           oldDelegate.peakMotion != peakMotion ||
           oldDelegate.fallType != fallType;
  }
}

// =========================================================================
// WIDGET: BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢N GHI PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â I QUÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â TRÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ (FALL PLAYBACK & AUDIT RECORD)
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian 4 giai ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n (-2.0s -> 0s -> +2.0s) & XuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t biÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n
// =========================================================================

class VirtualThermalSpectrum extends StatefulWidget {
  final Map<String, dynamic> event;

  const VirtualThermalSpectrum({super.key, required this.event});

  @override
  State<VirtualThermalSpectrum> createState() => _VirtualThermalSpectrumState();
}

class _VirtualThermalSpectrumState extends State<VirtualThermalSpectrum> {
  bool _showPostFall = true;   // true: Sau khi ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t), false: TrÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng)
  bool _showGrid128 = true;     // HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ 128x128
  Offset? _touchedPoint;        // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c

  @override
  Widget build(BuildContext context) {
    final double vel = (widget.event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (widget.event["mot"] as num?)?.toInt() ?? 88;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng nghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ HD 128x128
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "PhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng gian 128x128:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 12),
                      SizedBox(width: 4),
                      Text("16.384 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm FMCW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar FMCW 24GHz (128x128) tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« ToF (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c Y) + 9 CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng khoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch Radar LD2410 (cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c X) + ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // 2. BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i (TrÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c / Sau ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£) vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i 128x128
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_showPostFall ? Colors.blue.withValues(alpha: 0.25) : Colors.transparent,
                      side: BorderSide(color: !_showPostFall ? Colors.blueAccent : Colors.grey.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.accessibility_new, size: 16),
                    label: const Text("TrÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (-2s: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng)", style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _showPostFall = false;
                      _touchedPoint = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showPostFall ? Colors.redAccent.withValues(alpha: 0.25) : Colors.transparent,
                      side: BorderSide(color: _showPostFall ? Colors.redAccent : Colors.grey.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.airline_seat_flat, size: 16),
                    label: const Text("Sau ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (+2s: SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n)", style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _showPostFall = true;
                      _touchedPoint = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m / KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©o trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng radar tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm:",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showGrid128 = !_showGrid128),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _showGrid128 ? Colors.teal.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _showGrid128 ? Colors.teal : Colors.grey.shade700),
                    ),
                    child: Text(
                      _showGrid128 ? "LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i 128: BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬T" : "LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i 128: TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â®T",
                      style: TextStyle(fontSize: 9, color: _showGrid128 ? Colors.tealAccent : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 3. Khung hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ PhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar 128x128 tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c
            Center(
              child: GestureDetector(
                onPanDown: (details) => setState(() => _touchedPoint = details.localPosition),
                onPanUpdate: (details) => setState(() => _touchedPoint = details.localPosition),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF060B14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showPostFall ? Colors.redAccent.withValues(alpha: 0.6) : Colors.cyanAccent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_showPostFall ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CustomPaint(
                      painter: ThermalSpectrumPainter128(
                        isPostFall: _showPostFall,
                        showGrid: _showGrid128,
                        touchedLocalPos: _touchedPoint,
                        dropVelocity: vel,
                        peakMotion: motion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i 2 trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng gian
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âc Y: TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n (0m) ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  (2.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c ngang X: CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng radar (0.75m ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 6.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Thanh dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ Radar FMCW (0% - 100%)
            Row(
              children: [
                const Text("0% (TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh)", style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF060B14), // NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân tÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh (0% RF)
                          Color(0xFF0F3854), // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân RF (15%)
                          Color(0xFF0077B6), // TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ (35%)
                          Color(0xFF00B4D8), // HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n diÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n vi chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (55%)
                          Color(0xFFFFB703), // ChuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ (75%)
                          Color(0xFFFB8500), // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng cao (90%)
                          Color(0xFFFF0054), // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (97%)
                          Color(0xFFFFFFFF), // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm xung kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£o hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²a (100%)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("100% (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh)", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 6. HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t luÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n AI tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« 16.384 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng radar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _showPostFall ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                    color: _showPostFall ? Colors.redAccent : Colors.tealAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _showPostFall
                          ? "PhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• radar 128x128 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n: 96% mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng 15% ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n (Y > 1.8m) vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i rÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng ngang 2.4m (CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng 2-5). KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p xung lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p $motion/100 ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng."
                          : "PhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• radar 128x128 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n: CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng radar tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p trung theo hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng (Y: 0.3m ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 1.7m), bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ngang hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹p 0.6m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng 3. TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘t.",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _showPostFall ? Colors.redAccent.shade100 : Colors.tealAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER: HIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚N THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â” NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¢NG RADAR 128x128 (16.384 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚M GAUSS)
// =========================================================================
class ThermalSpectrumPainter128 extends CustomPainter {
  final bool isPostFall;
  final bool showGrid;
  final Offset? touchedLocalPos;
  final double dropVelocity;
  final int peakMotion;

  ThermalSpectrumPainter128({
    required this.isPostFall,
    required this.showGrid,
    required this.touchedLocalPos,
    required this.dropVelocity,
    required this.peakMotion,
  });

  // TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ Radar FMCW tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n hoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ (nx, ny) [0.0 .. 1.0]
  double _calcRadarEnergyAt(double nx, double ny) {
    // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡p ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân RF mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng ~ 3.5%
    double ambient = 3.5 + 1.2 * math.sin(nx * 8) * math.cos(ny * 8);

    if (!isPostFall) {
      // TRÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂšC NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ: CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng 3.5 (nx = 0.44), chiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu cao (ny tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« 0.25 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n 0.85)
      // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c/ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u (nx: 0.44, ny: 0.38)
      double dHead = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.32) / 0.10, 2));
      double dChest = math.sqrt(math.pow((nx - 0.44) / 0.10, 2) + math.pow((ny - 0.48) / 0.14, 2));
      double dLegs = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.72) / 0.18, 2));

      double energyHead = 82.0 * math.exp(-0.5 * dHead * dHead);
      double energyChest = 88.0 * math.exp(-0.5 * dChest * dChest);
      double energyLegs = 65.0 * math.exp(-0.5 * dLegs * dLegs);

      return (ambient + math.max(energyHead, math.max(energyChest, energyLegs))).clamp(0.0, 100.0);
    } else {
      // SAU NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ: NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m ngang sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n (ny = 0.88, trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i nx tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« 0.22 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n 0.75)
      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn (nx: 0.36, ny: 0.88)
      double dUpper = math.sqrt(math.pow((nx - 0.36) / 0.12, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng/thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i (nx: 0.54, ny: 0.88)
      double dLower = math.sqrt(math.pow((nx - 0.54) / 0.14, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n (nx: 0.70, ny: 0.89)
      double dFeet = math.sqrt(math.pow((nx - 0.70) / 0.10, 2) + math.pow((ny - 0.89) / 0.06, 2));

      double energyUpper = 95.0 * math.exp(-0.5 * dUpper * dUpper);
      double energyLower = 88.0 * math.exp(-0.5 * dLower * dLower);
      double energyFeet = 60.0 * math.exp(-0.5 * dFeet * dFeet);

      return (ambient + math.max(energyUpper, math.max(energyLower, energyFeet))).clamp(0.0, 100.0);
    }
  }

  // ChuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ Radar sang dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ tuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n (Turbo/Jet Colormap)
  Color _energyToColor(double energy) {
    if (energy <= 15.0) {
      return Color.lerp(const Color(0xFF060B14), const Color(0xFF0F3854), energy / 15.0)!;
    } else if (energy <= 35.0) {
      return Color.lerp(const Color(0xFF0F3854), const Color(0xFF0077B6), (energy - 15.0) / 20.0)!;
    } else if (energy <= 55.0) {
      return Color.lerp(const Color(0xFF0077B6), const Color(0xFF00B4D8), (energy - 35.0) / 20.0)!;
    } else if (energy <= 75.0) {
      return Color.lerp(const Color(0xFF00B4D8), const Color(0xFFFFB703), (energy - 55.0) / 20.0)!;
    } else if (energy <= 90.0) {
      return Color.lerp(const Color(0xFFFFB703), const Color(0xFFFB8500), (energy - 75.0) / 15.0)!;
    } else if (energy <= 97.0) {
      return Color.lerp(const Color(0xFFFB8500), const Color(0xFFFF0054), (energy - 90.0) / 7.0)!;
    } else {
      return Color.lerp(const Color(0xFFFF0054), Colors.white, (energy - 97.0) / 3.0)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân RF 2D
    final Rect backgroundRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()..color = const Color(0xFF060B14);
    canvas.drawRect(backgroundRect, bgPaint);

    // 2. KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar (Radar Kinematic Clusters)
    if (!isPostFall) {
      // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨NG: 3 quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u, NgÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c, ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n)
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.32), w * 0.22, h * 0.16, 85.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.48), w * 0.26, h * 0.22, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.72), w * 0.20, h * 0.24, 65.0);
    } else {
      // NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â°M SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N: DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m ngang dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
      _drawRadarEnergyCluster(canvas, Offset(w * 0.36, h * 0.88), w * 0.28, h * 0.12, 98.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.54, h * 0.88), w * 0.32, h * 0.12, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.70, h * 0.89), w * 0.22, h * 0.10, 60.0);

      // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng lan tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p
      final Paint floorSpread = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.orange.withValues(alpha: 0.15),
            Colors.redAccent.withValues(alpha: 0.30),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.80, w, h * 0.20));
      canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), floorSpread);
    }

    // 3. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ (Iso-Energy Contours)
    _drawIsoEnergyContours(canvas, size);

    // 4. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ 128x128 (HiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch chia 16, 32, 64, 96, 128)
    if (showGrid) {
      final Paint gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5;

      for (int i = 0; i <= 128; i += 16) {
        double pos = (i / 128.0) * w;
        canvas.drawLine(Offset(pos, 0), Offset(pos, h), gridPaint);
        canvas.drawLine(Offset(0, pos), Offset(w, pos), gridPaint);
      }
    }

    // 5. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©t mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i
    final Offset peakPos = isPostFall ? Offset(w * 0.36, h * 0.88) : Offset(w * 0.44, h * 0.32);
    _drawCrosshair(canvas, peakPos, isPostFall ? "E_max: 98% (SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n Y: 0.15m)" : "E_max: 90% (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng Y: 1.5m)", Colors.redAccent);

    // 6. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng (NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm)
    if (touchedLocalPos != null) {
      final double tx = touchedLocalPos!.dx.clamp(0.0, w);
      final double ty = touchedLocalPos!.dy.clamp(0.0, h);
      final int gridX = (tx / w * 128).clamp(0, 127).toInt();
      final int gridY = (ty / h * 128).clamp(0, 127).toInt();
      final double energy = _calcRadarEnergyAt(tx / w, ty / h);

      _drawCrosshair(
        canvas,
        Offset(tx, ty),
        "[$gridX, $gridY]: E = ${energy.toStringAsFixed(0)}%",
        Colors.cyanAccent,
      );
    }

    // 7. NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n HUD gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³c trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "RADAR FMCW 24GHz SPATIAL SPECTRUM\nMATRIX: 128x128 (16.384 PTS)\nFOV: 9 GATES x 2.0m ELEVATION",
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.6),
        fontFamily: 'monospace',
      ),
    );
    tp.layout();
    tp.paint(canvas, const Offset(8, 8));
  }

  // VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar 2D
  void _drawRadarEnergyCluster(Canvas canvas, Offset center, double rx, double ry, double peakEnergy) {
    final Rect rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final Paint p = Paint()
      ..shader = RadialGradient(
        colors: [
          _energyToColor(peakEnergy),
          _energyToColor(peakEnergy * 0.75),
          _energyToColor(peakEnergy * 0.45),
          _energyToColor(10.0).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, p);
  }

  // VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­n (Iso-Energy Contours)
  void _drawIsoEnergyContours(Canvas canvas, Size size) {
    final Paint contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.15);

    if (!isPostFall) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.44, size.height * 0.44), width: size.width * 0.32, height: size.height * 0.54),
        contourPaint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.88), width: size.width * 0.65, height: size.height * 0.18),
        contourPaint,
      );
    }
  }

  // VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨m chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™
  void _drawCrosshair(Canvas canvas, Offset pos, String label, Color color) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    // VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p
    canvas.drawLine(Offset(pos.dx - 10, pos.dy), Offset(pos.dx + 10, pos.dy), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - 10), Offset(pos.dx, pos.dy + 10), p);

    // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹
    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(pos, 6, circlePaint);

    // HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ toÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: color,
        backgroundColor: Colors.black.withValues(alpha: 0.75),
      ),
    );
    tp.layout();

    double textX = pos.dx + 8;
    double textY = pos.dy - 16;
    if (textX + tp.width > 270) textX = pos.dx - tp.width - 8;
    if (textY < 10) textY = pos.dy + 8;

    tp.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant ThermalSpectrumPainter128 oldDelegate) {
    return oldDelegate.isPostFall != isPostFall ||
           oldDelegate.showGrid != showGrid ||
           oldDelegate.touchedLocalPos != touchedLocalPos;
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶T CHUNG CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¦A ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨NG DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¤NG (GENERAL SETTINGS SCREEN)
// =========================================================================

// =========================================================================
// WIDGET: BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢N GHI PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â I QUÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â TRÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ (FALL PLAYBACK & AUDIT RECORD)
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian 4 giai ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n (-2.0s -> 0s -> +2.0s) & XuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t biÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n
// =========================================================================
class HumanPostureSimulation extends StatefulWidget {
  final Map<String, dynamic> event;

  const HumanPostureSimulation({super.key, required this.event});

  @override
  State<HumanPostureSimulation> createState() => _HumanPostureSimulationState();
}

class _HumanPostureSimulationState extends State<HumanPostureSimulation> {
  double _currentTime = -2.0; // TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« -2.0 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n +2.0 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y
  bool _isPlaying = false;
  double _speed = 1.0;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_currentTime >= 2.0) {
        _currentTime = -2.0;
      }
      setState(() => _isPlaying = true);
      _playbackTimer?.cancel();
      const intervalMs = 50; // 20 FPS ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n 20Hz
      _playbackTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
        setState(() {
          _currentTime += (intervalMs / 1000.0) * _speed;
          if (_currentTime >= 2.0) {
            _currentTime = 2.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  void _resetPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _currentTime = -2.0;
      _isPlaying = false;
    });
  }

  Map<String, dynamic> _getFrameAt(double t, double maxVel, int peakMot) {
    double heightMm;
    double currentVel;
    int currentMot;
    String stageName;
    Color stageColor;
    double angleDeg;

    if (t < -0.8) {
      heightMm = 1720.0 + 15.0 * math.sin(t * 5);
      currentVel = 40.0;
      currentMot = 12;
      stageName = "1. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ng thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng";
      stageColor = Colors.greenAccent;
      angleDeg = 0.0;
    } else if (t < 0.0) {
      double progress = (t - (-0.8)) / 0.8;
      heightMm = 1720.0 - (1720.0 - 240.0) * (progress * progress);
      currentVel = maxVel * progress;
      currentMot = (15 + (peakMot - 15) * progress * 0.7).toInt();
      stageName = "2. MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  & RÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± do";
      stageColor = Colors.amberAccent;
      angleDeg = progress * 75.0;
    } else if (t < 0.4) {
      heightMm = 240.0;
      currentVel = maxVel * (1.0 - t / 0.4);
      currentMot = peakMot;
      stageName = "3. VA CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â M SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N (CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG)";
      stageColor = Colors.redAccent;
      angleDeg = 90.0;
    } else {
      double postProg = (t - 0.4) / 1.6;
      heightMm = 220.0 + 8.0 * math.sin(t * 3);
      currentVel = 0.0;
      currentMot = (peakMot * (1.0 - postProg * 0.85)).clamp(8, 25).toInt();
      stageName = "4. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­u ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£)";
      stageColor = Colors.indigoAccent;
      angleDeg = 90.0;
    }

    return {
      "height": heightMm,
      "vel": currentVel,
      "mot": currentMot,
      "stage": stageName,
      "color": stageColor,
      "angle": angleDeg,
    };
  }

  void _showExportRecordDialog(BuildContext context, double vel, int motion, int dist, int sec) {
    final recordText = """
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â’ SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠNH TAI NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â N TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ (FALL INCIDENT RECORD)
HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t: FallGuard S3R8 (ESP32-S3-WROOM-1-N16R8)
MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘: #FALL-REC-${sec.toString().padLeft(6, '0')}
ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y ra: CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y ${sec}s
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
1. THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŒC CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âš NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ (KINEMATICS):
   - PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£: NgÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh (High-Velocity Fall Impact)
   - VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c rÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± do cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i (V_drop): ${vel.toStringAsFixed(0)} mm/s (NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ng: >= 550 mm/s)
   - ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng va ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh (Peak Motion): $motion/100 (ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c cao)
   - CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n: $dist cm (CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng radar FMCW sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ 3)
   - ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£: 1.72 m (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng) ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” Sau ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£: 0.22 m (SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â )

2. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â TRÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â NG THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂI NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â N NHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N (POST-FALL STATUS):
   - TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i: NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng (Immobile on floor)
   - NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng sau ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£: <= 20/100 (KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ gÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y)
   - NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng vi chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng tÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©nh: >= 16/100 (CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²n dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p / nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p tim)
   - KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t luÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n AI: CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t 100%, nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p.

3. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€NH ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â N TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â° ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C THI:
   - CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng Active Buzzer: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— (85 dB)
   - ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n LED RGB WS2812B: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â u ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â SOS nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c
   - Gateway Wi-Fi: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p Telegram Bot & SMS SpeedSMS
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â•ÃƒÂ‚Ã‚Â
BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n ghi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› Flash NVS cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ESP32-S3.
""";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(child: Text("BiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    recordText,
                    style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p biÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recordText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p biÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m!"), backgroundColor: Colors.green),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double vel = (widget.event["vel"] as num?)?.toDouble() ?? 680.0;
    final int motion = (widget.event["mot"] as num?)?.toInt() ?? 88;
    final int dist = (widget.event["dst"] as num?)?.toInt() ?? 165;
    final int sec = (widget.event["sec"] as num?)?.toInt() ?? 0;

    final frame = _getFrameAt(_currentTime, vel, motion);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â & NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.slow_motion_video, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n ghi phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (Record Playback):",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 14, color: Colors.cyanAccent),
                  label: const Text("XuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t biÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n", style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                  onPressed: () => _showExportRecordDialog(context, vel, motion, dist, sec),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Tua lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ 4 giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y (-2s ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 0s ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” +2s) tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n Laser ToF vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  Radar FMCW.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // Khung hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi 2D
            Container(
              height: 125,
              decoration: BoxDecoration(
                color: const Color(0xFF060B14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (frame["color"] as Color).withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CustomPaint(
                  painter: HumanMotionPlaybackPainter(
                    angleDeg: frame["angle"] as double,
                    heightMm: frame["height"] as double,
                    currentTime: _currentTime,
                    stageColor: frame["color"] as Color,
                  ),
                  child: Stack(
                    children: [
                      // Badge mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³c trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn
                      Positioned(
                        top: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (frame["color"] as Color).withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            "t = ${_currentTime >= 0 ? "+" : ""}${_currentTime.toStringAsFixed(2)}s",
                            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: frame["color"] as Color),
                          ),
                        ),
                      ),
                      // Badge giai ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³c trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (frame["color"] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            frame["stage"] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: frame["color"] as Color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi
            Row(
              children: [
                _buildMetricChip("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", "${(frame["height"] as double).toInt()} mm", Icons.height, Colors.cyanAccent),
                const SizedBox(width: 8),
                _buildMetricChip("VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ToF", "${(frame["vel"] as double).toStringAsFixed(0)} mm/s", Icons.speed, Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildMetricChip("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar", "${frame["mot"]}/100", Icons.radar, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£t thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi gian (Timeline Slider)
            Row(
              children: [
                const Text("-2.0s", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _currentTime.clamp(-2.0, 2.0),
                    min: -2.0,
                    max: 2.0,
                    divisions: 40,
                    activeColor: frame["color"] as Color,
                    inactiveColor: Colors.grey.shade800,
                    onChanged: (val) {
                      _playbackTimer?.cancel();
                      setState(() {
                        _currentTime = val;
                        _isPlaying = false;
                      });
                    },
                  ),
                ),
                const Text("+2.0s", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),

            // HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn Play / Pause / Replay / Speed
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.replay),
                  tooltip: "Tua lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u (-2s)",
                  onPressed: _resetPlayback,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.amber.shade700 : Colors.cyanAccent.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? "TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng" : "PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£"),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    setState(() {
                      _speed = (_speed == 1.0) ? 0.5 : 1.0;
                    });
                  },
                  child: Text(
                    "${_speed}x",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER: VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¼ HOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â T ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI CHUYÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG TRONG PHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â I CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âš NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ
// =========================================================================
class HumanMotionPlaybackPainter extends CustomPainter {
  final double angleDeg;
  final double heightMm;
  final double currentTime;
  final Color stageColor;

  HumanMotionPlaybackPainter({
    required this.angleDeg,
    required this.heightMm,
    required this.currentTime,
    required this.stageColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n (Floor Line)
    final double floorY = h - 18;
    final Paint floorPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹m ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o laser ToF tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n chiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi
    final double humanX = w * 0.48;
    final double normH = (heightMm / 2000.0).clamp(0.1, 0.95);
    final double headY = floorY - (normH * (floorY - 25));

    final Paint tofBeam = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(humanX, 5), Offset(humanX, headY), tofBeam);

    // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n ToF trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â 
    final Paint ceilingSensor = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(humanX, 5), 4, ceilingSensor);

    // Xung chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n khi va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m (t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« -0.1s ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n +0.3s)
    if (currentTime >= -0.1 && currentTime <= 0.3) {
      final Paint shockwave = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(humanX, floorY), 22 * (currentTime + 0.1) * 3, shockwave);
    }

    // VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi (Stick Figure vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³c xoay ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£)
    canvas.save();
    canvas.translate(humanX, floorY);
    canvas.rotate(angleDeg * math.pi / 180.0);

    final Paint bodyPaint = Paint()
      ..color = stageColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double bodyLen = 50.0;
    // ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n
    canvas.drawLine(const Offset(0, 0), Offset(0, -bodyLen), bodyPaint);

    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u
    canvas.drawCircle(Offset(0, -bodyLen - 9), 8, bodyPaint);

    // Tay
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(-12, -bodyLen * 0.4), bodyPaint);
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(12, -bodyLen * 0.4), bodyPaint);

    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n
    canvas.drawLine(const Offset(0, 0), const Offset(-10, 16), bodyPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(10, 16), bodyPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HumanMotionPlaybackPainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg ||
           oldDelegate.heightMm != heightMm ||
           oldDelegate.currentTime != currentTime ||
           oldDelegate.stageColor != stageColor;
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶T CHUNG CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¦A ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨NG DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¤NG (GENERAL SETTINGS SCREEN)
// =========================================================================
class GeneralSettingsScreen extends StatefulWidget {
  final bool alarmSound;
  final bool alarmVibrate;
  final double alarmVolume;
  final bool autoEmergency115;
  final bool autoReconnect;
  final String heightUnit;
  final String tempUnit;
  final int deviceHistoryCount;
  final Function(bool sound, bool vib, double vol, bool em115, bool autoRec, String hUnit, String tUnit) onSettingsChanged;
  final VoidCallback onClearHistory;

  const GeneralSettingsScreen({
    super.key,
    required this.alarmSound,
    required this.alarmVibrate,
    required this.alarmVolume,
    required this.autoEmergency115,
    required this.autoReconnect,
    required this.heightUnit,
    required this.tempUnit,
    required this.deviceHistoryCount,
    required this.onSettingsChanged,
    required this.onClearHistory,
  });

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late bool _alarmSound;
  late bool _alarmVibrate;
  late double _alarmVolume;
  late bool _autoEmergency115;
  late bool _autoReconnect;
  late String _heightUnit;
  late String _tempUnit;

  @override
  void initState() {
    super.initState();
    _alarmSound = widget.alarmSound;
    _alarmVibrate = widget.alarmVibrate;
    _alarmVolume = widget.alarmVolume;
    _autoEmergency115 = widget.autoEmergency115;
    _autoReconnect = widget.autoReconnect;
    _heightUnit = widget.heightUnit;
    _tempUnit = widget.tempUnit;
  }

  void _notifyChanges() {
    widget.onSettingsChanged(
      _alarmSound,
      _alarmVibrate,
      _alarmVolume,
      _autoEmergency115,
      _autoReconnect,
      _heightUnit,
      _tempUnit,
    );
  }

  // HÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u khi phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£
  void _showFirstAidGuide() {
    showFirstAidGuideModal(context);
  }

  void _openMedicalProfile() async {
    final p = await ElderlyMedicalProfile.load();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => EmergencyMedicalIdCardDialog(
        profile: p,
        onEdit: () {
          showDialog(
            context: context,
            builder: (c) => MedicalProfileEditDialog(
              profile: p,
              onSaved: (_) {},
            ),
          );
        },
      ),
    );
  }

  void _openCdcAssessment() {
    showDialog(
      context: context,
      builder: (ctx) => CdcSteadiAssessmentDialog(
        onCompleted: (score, risk) {},
      ),
    );
  }

  // KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t OTA tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung
  void _triggerOtaUpdate() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = true;
        Map<String, dynamic>? releaseInfo;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (isLoading && releaseInfo == null) {
              () async {
                try {
                  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
                  final request = await client.getUrl(
                    Uri.parse('https://api.github.com/repos/anlq295-work/FallDetection_S3R8/releases/latest'),
                  );
                  request.headers.set('User-Agent', 'FallGuardApp');
                  request.headers.set('Accept', 'application/vnd.github.v3+json');
                  final response = await request.close();
                  if (response.statusCode == 200) {
                    final body = await response.transform(utf8.decoder).join();
                    final data = jsonDecode(body) as Map<String, dynamic>;
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        releaseInfo = data;
                        isLoading = false;
                      });
                    }
                  } else {
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        isLoading = false;
                      });
                    }
                  }
                } catch (_) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              }();
            }

            int? apkSize;
            if (releaseInfo != null && releaseInfo!['assets'] is List) {
              for (var asset in (releaseInfo!['assets'] as List)) {
                if (asset is Map && asset['name'] == 'app-release.apk') {
                  apkSize = asset['size'] as int?;
                  break;
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng OTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done, color: Colors.blueAccent, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("GitHub Releases (TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                                  Text(
                                    Platform.isIOS ? "Apple In-House OTA (FallGuard_iOS_unsigned.ipa)" : "Android APK Release (app-release.apk)",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("PhiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("v1.2.0 (Build 2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn GitHub:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  releaseInfo?['name']?.toString() ?? (isLoading ? "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âang kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i..." : "Fall Guard Latest Release"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            if (apkSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Dung lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng file APK:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    "${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Platform.isIOS
                            ? "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub Releases. NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n [CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t] ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p."
                            : "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n APK mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn GitHub Releases vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t Android ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ nguyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u.",
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final releasesPage = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest");
                    try {
                      await launchUrl(releasesPage, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text("Xem Release GitHub"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (Platform.isIOS) {
                      const otaUrl = "itms-services://?action=download-manifest&url=https://raw.githubusercontent.com/anlq295-work/FallDetection_S3R8/main/ios_ota/manifest.plist";
                      final uri = Uri.parse(otaUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        final ipaUrl = Uri.parse("https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/FallGuard_iOS_unsigned.ipa");
                        await launchUrl(ipaUrl, mode: LaunchMode.externalApplication);
                      }
                    } else {
                      const apkUrl = "https://github.com/anlq295-work/FallDetection_S3R8/releases/latest/download/app-release.apk";
                      final uri = Uri.parse(apkUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t APK: $e")),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t ngay"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tune, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t chung App", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P & ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚M THANH
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m thanh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›n trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y khi phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _alarmSound,
                    onChanged: (val) {
                      setState(() => _alarmSound = val);
                      _notifyChanges();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Rung mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p (SOS)", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Rung liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c theo nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _alarmVibrate,
                    onChanged: (val) {
                      setState(() => _alarmVibrate = val);
                      _notifyChanges();
                    },
                  ),
                  if (_alarmSound) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚m lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i:", style: TextStyle(fontSize: 13)),
                        Text("${(_alarmVolume * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                      ],
                    ),
                    Slider(
                      value: _alarmVolume,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() => _alarmVolume = val);
                        _notifyChanges();
                      },
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£i ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ 1 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ cuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™c gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi 115 khi xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y ra chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _autoEmergency115,
                    onChanged: (val) {
                      setState(() => _autoEmergency115 = val);
                      _notifyChanges();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂI & THIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ GHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰P NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i & ThiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i Bluetooth ngay khi mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ app", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _autoReconnect,
                    onChanged: (val) {
                      setState(() => _autoReconnect = val);
                      _notifyChanges();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: Text("LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u: ${widget.deviceHistoryCount} thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹", style: const TextStyle(fontSize: 14)),
                    subtitle: const Text("Xem vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng ghÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: widget.deviceHistoryCount > 0
                        ? TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­?"),
                                  content: const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯c muÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘n xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y")),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(c);
                                        widget.onClearHistory();
                                        setState(() {});
                                      },
                                      child: const Text("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t", style: TextStyle(color: Colors.redAccent)),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. HIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‚N THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â N VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂO
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ khoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch:", style: TextStyle(fontSize: 14)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "mm", label: Text("mm", style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: "cm", label: Text("cm", style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_heightUnit},
                        onSelectionChanged: (val) {
                          setState(() => _heightUnit = val.first);
                          _notifyChanges();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng Radar:", style: TextStyle(fontSize: 14)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "%", label: Text("% (TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡)", style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: "dB", label: Text("dB (CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™)", style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_tempUnit == "dB" ? "dB" : "%"},
                        onSelectionChanged: (val) {
                          setState(() => _tempUnit = val.first);
                          _notifyChanges();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. AN TOÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬P NHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬T PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¦N MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â€M
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety, color: Colors.green),
                      SizedBox(width: 8),
                      Text("An toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.badge, color: Colors.redAccent),
                    title: const Text("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cao tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u, thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u, tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½, liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ 115", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openMedicalProfile,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                    title: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ CDC STEADI", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ 12 cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng theo chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n CDC Hoa KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openCdcAssessment,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.medical_information, color: Colors.orangeAccent),
                    title: const Text("HÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Quy tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯c cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFirstAidGuide,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_download, color: Colors.blueAccent),
                    title: const Text("KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t OTA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p phiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« GitHub qua mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _triggerOtaUpdate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG TIN HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â† THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂNG
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text("ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tin hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng: Fall Guard S3R8", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("PhiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Vi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu khiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn: ESP32-S3-WROOM-1-N16R8 (16MB Flash / 8MB PSRAM)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p: PIR AM312 (HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng ngoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i) + ToF Laser (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao) + Radar 24GHz FMCW (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ly)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("ÃƒÂƒÃ‚Â‚ÃƒÂ‚Ã‚Â© 2026 Fall Detection System. BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cao tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i 24/7.", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =========================================================================
// HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€M MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âž HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P THOÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â I CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨M NANG SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€ TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ
// =========================================================================
void showFirstAidGuideModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const FirstAidGuideDialog(),
  );
}

class FirstAidGuideDialog extends StatefulWidget {
  const FirstAidGuideDialog({super.key});

  @override
  State<FirstAidGuideDialog> createState() => _FirstAidGuideDialogState();
}

class _FirstAidGuideDialogState extends State<FirstAidGuideDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildTipCard(String title, String content, {Color color = Colors.amberAccent, IconData icon = Icons.lightbulb}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> bodyItems,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  number,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bodyItems,
        ],
      ),
    );
  }

  Widget _bulletText(String boldPrefix, String text, {Color? prefixColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ", style: TextStyle(color: Colors.white60, fontSize: 15)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                children: [
                  if (boldPrefix.isNotEmpty)
                    TextSpan(
                      text: "$boldPrefix: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: prefixColor ?? Colors.cyanAccent),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subItemCard(String subTitle, List<Widget> items, {Color color = Colors.cyanAccent}) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subTitle,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: color),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildPrecautionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "TrÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u, bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu quan trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºng cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng",
            icon: Icons.visibility,
            color: Colors.cyanAccent,
            bodyItems: [
              _bulletText("Quan sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¹ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n", "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng?"),
              _bulletText("KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra nhanh tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ", "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ, mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y hay khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng."),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n",
            icon: Icons.health_and_safety,
            color: Colors.amberAccent,
            bodyItems: [
              _bulletText("Khu vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n", "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ra khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi khu vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c nguy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm (nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ)."),
              _bulletText("TrÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn", "TrÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u nghi ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng.", prefixColor: Colors.orangeAccent),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t",
            icon: Icons.emergency,
            color: Colors.redAccent,
            bodyItems: [
              _bulletText("ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng (vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥: mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c, gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ, chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu), hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi ngay 115 hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n."),
              _buildTipCard(
                "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹o nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â khi gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u",
                "Khi gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y cung cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tin chi tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºp ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i ngÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â© y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng nhanh hÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n.",
                color: Colors.amberAccent,
                icon: Icons.lightbulb,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicStepsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Khi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c bÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c",
            icon: Icons.psychology,
            color: Colors.purpleAccent,
            bodyItems: [
              _bulletText("PhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡", "GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi to hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c lay nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ xem hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng hay khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng."),
              _bulletText("NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ & CPR", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹p thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c tim phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i (CPR) nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "XÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ (nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³)",
            icon: Icons.healing,
            color: Colors.tealAccent,
            bodyItems: [
              _bulletText("RÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­a vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng", "RÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­a sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng nÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c dung dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t khuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n."),
              _bulletText("BÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng", "DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng bÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡c vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng bÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ ngÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«a nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…m trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng."),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "XÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm",
            icon: Icons.ac_unit,
            color: Colors.lightBlueAccent,
            bodyItems: [
              _bulletText("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh", "DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ng trong 15-20 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt."),
              _bulletText("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o quan trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng", "KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng massage hay ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng, ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "4",
            title: "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn",
            icon: Icons.accessible_forward,
            color: Colors.orangeAccent,
            bodyItems: [
              _bulletText("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºp ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng, trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng."),
              _bulletText("Nghi ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng", "TrÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p nghi ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c khi di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn.", prefixColor: Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificCasesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.category, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhau dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±a trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹",
            icon: Icons.healing_outlined,
            color: Colors.tealAccent,
            bodyItems: [
              _subItemCard(
                "TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c ngoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i da",
                [
                  _bulletText("LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng", "RÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­a bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng nÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c dung dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t khuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n."),
                  _bulletText("BÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³", "SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng bÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡c vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ che phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng, giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºp ngÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«a nhiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…m trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng."),
                  _bulletText("VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ sinh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³", "Thay bÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khi bÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›t/bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n."),
                ],
                color: Colors.tealAccent,
              ),
              _subItemCard(
                "SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§m tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­m",
                [
                  _bulletText("ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh", "DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§m trong 15-20 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ng."),
                  _bulletText("NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng cao vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ, giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng cao hÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n tim ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ng."),
                  _bulletText("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘au hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§m tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­m kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©o dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i hÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n 48 giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y tham khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.cyanAccent,
              ),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·ng",
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
            bodyItems: [
              _subItemCard(
                "GÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng",
                [
                  _bulletText("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y", "SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹p hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng (vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥: thanh gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬a cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng) ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y, trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh di lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ch xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng."),
                  _bulletText("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh", "TuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯n xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ ban ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u, dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n kinh hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ xung quanh.", prefixColor: Colors.redAccent),
                  _bulletText("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ngay", "Nhanh chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.orangeAccent,
              ),
              _subItemCard(
                "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u",
                [
                  _bulletText("Theo dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµi dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u", "ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n nguy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm nhÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° buÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n, chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i, mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi, co giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£y mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« tai, mÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©i.", prefixColor: Colors.redAccent),
                  _bulletText("GiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh", "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘a viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡c di chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u ngang bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh."),
                  _bulletText("XÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³i (TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng)", "NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n, hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â sang mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn (tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n) ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ.", prefixColor: Colors.amberAccent),
                  _bulletText("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u", "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£o nguy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm, cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ngay cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ khi hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng sau cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£.", prefixColor: Colors.redAccent),
                ],
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 580, maxHeight: screenHeight * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.redAccent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©m nang SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "HÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n",
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TabBar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.redAccent,
                  labelColor: Colors.redAccent,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  tabs: const [
                    Tab(text: "1. LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u"),
                    Tab(text: "2. CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c bÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n"),
                    Tab(text: "3. Theo trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ"),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPrecautionsTab(),
                    _buildBasicStepsTab(),
                    _buildSpecificCasesTab(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 20),
                      label: const Text("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _call115,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      side: BorderSide(color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// 1. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ minh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa BÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c 1: CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y ngay
class DoNotPullIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final double bodyX = w * 0.40;
    final Paint bodyPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    canvas.drawCircle(Offset(bodyX - 50, floorY - 10), 9, bodyPaint);
    // ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n
    canvas.drawLine(Offset(bodyX - 40, floorY - 8), Offset(bodyX + 25, floorY - 8), bodyPaint);
    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n
    canvas.drawLine(Offset(bodyX + 25, floorY - 8), Offset(bodyX + 80, floorY - 8), bodyPaint);

    // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng
    final Paint alertRing = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(bodyX - 35, floorY - 8), 16, alertRing); // CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•
    canvas.drawCircle(Offset(bodyX + 25, floorY - 8), 18, alertRing); // HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng

    // BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n tay kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©o giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng (Dashed vector)
    final Paint pullArrow = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(bodyX - 10, floorY - 60), Offset(bodyX - 10, floorY - 18), pullArrow);

    // BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥m kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y
    final Paint signPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w * 0.78, h * 0.45), 26, signPaint);
    canvas.drawLine(Offset(w * 0.78 - 18, h * 0.45 - 18), Offset(w * 0.78 + 18, h * 0.45 + 18), signPaint);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤M KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰O DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬Y!",
      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.78 - tp.width / 2, h * 0.45 + 32));

    // NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng nguy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm
    final TextPainter tpLabel = TextPainter(textDirection: TextDirection.ltr);
    tpLabel.text = const TextSpan(
      text: "Nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹i & tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng",
      style: TextStyle(color: Colors.white60, fontSize: 9.5),
    );
    tpLabel.layout();
    tpLabel.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ minh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa BÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c 2: KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra tri giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c & GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi 115
class VitalsCheckIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m
    final double vicX = w * 0.32;
    final Paint vicPaint = Paint()..color = Colors.blueGrey.shade400..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(vicX - 45, floorY - 9), 8, vicPaint);
    canvas.drawLine(Offset(vicX - 35, floorY - 7), Offset(vicX + 35, floorY - 7), vicPaint);
    canvas.drawLine(Offset(vicX + 35, floorY - 7), Offset(vicX + 85, floorY - 7), vicPaint);

    // NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra
    final double rescX = vicX - 5;
    final Paint rescPaint = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(rescX - 10, floorY - 55), 8, rescPaint); // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u
    canvas.drawLine(Offset(rescX - 10, floorY - 47), Offset(rescX, floorY - 25), rescPaint); // ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n
    canvas.drawLine(Offset(rescX, floorY - 25), Offset(rescX - 15, floorY), rescPaint); // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³
    canvas.drawLine(Offset(rescX - 10, floorY - 40), Offset(vicX, floorY - 10), rescPaint); // Tay bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch / kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra

    // HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final RRect bubbleRRect = RRect.fromRectAndRadius(Rect.fromLTWH(vicX - 60, 10, 160, 26), const Radius.circular(8));
    canvas.drawRRect(bubbleRRect, bubblePaint);

    final TextPainter tpMsg = TextPainter(textDirection: TextDirection.ltr);
    tpMsg.text = const TextSpan(
      text: "BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng? CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘au ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢u khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng?",
      style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
    );
    tpMsg.layout();
    tpMsg.paint(canvas, Offset(vicX - 55, 16));

    // Huy hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115
    final Paint sosBox = Paint()..color = Colors.red.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final RRect sosRRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.72, 25, 95, 60), const Radius.circular(10));
    canvas.drawRRect(sosRRect, sosBox);
    canvas.drawRRect(sosRRect, Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final TextPainter tp115 = TextPainter(textDirection: TextDirection.ltr);
    tp115.text = const TextSpan(
      text: "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U 115\nKhi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c\nnghi gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£y xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng",
      style: TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold, height: 1.3),
    );
    tp115.layout();
    tp115.paint(canvas, Offset(w * 0.72 + 8, 32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ minh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa BÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c 3: TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng
class RecoveryPositionIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final double cx = w * 0.38;
    final Paint p = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u kÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âª lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn mu bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n tay
    canvas.drawCircle(Offset(cx - 55, floorY - 18), 9, p);
    // Tay ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u
    canvas.drawLine(Offset(cx - 35, floorY - 14), Offset(cx - 55, floorY - 10), p);
    // ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng
    canvas.drawLine(Offset(cx - 45, floorY - 14), Offset(cx + 25, floorY - 14), p);
    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i duÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â—i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â³ng
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 85, floorY - 14), p..color = Colors.teal.shade700);
    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn co vuÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³c 90 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng
    final Paint pLeg = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 35, floorY - 3), pLeg);
    canvas.drawLine(Offset(cx + 35, floorY - 3), Offset(cx + 65, floorY - 3), pLeg);

    // MÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn luÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng thoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng
    final Paint airwayPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 68, floorY - 18), radius: 12), 0.5, 2.0, false, airwayPaint);

    // NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "TÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n (IFRC/AHA):\nÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­a nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ -> ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ rÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng\nÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n co 90ÃƒÂƒÃ‚Â‚ÃƒÂ‚Ã‚Â° giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ng\nÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´n/nÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ât vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i",
      style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.4),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.48, 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ minh hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âa BÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c 4: Quy tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯c dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y (NHS UK)
class ChairMethodIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 22;

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // GhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±a ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i
    final double chairX = w * 0.82;
    final Paint chairPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    canvas.drawLine(Offset(chairX, floorY), Offset(chairX, floorY - 45), chairPaint);
    canvas.drawLine(Offset(chairX + 30, floorY), Offset(chairX + 30, floorY - 45), chairPaint);
    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    canvas.drawLine(Offset(chairX - 5, floorY - 45), Offset(chairX + 35, floorY - 45), chairPaint);
    // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±a ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    canvas.drawLine(Offset(chairX + 30, floorY - 45), Offset(chairX + 30, floorY - 80), chairPaint);

    // 3 giai ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘oÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n triÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn
    final Paint stepPaint = Paint()..color = Colors.white70..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    // A. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng
    canvas.drawCircle(Offset(35, floorY - 8), 6, stepPaint);
    canvas.drawLine(Offset(41, floorY - 6), Offset(65, floorY - 6), stepPaint);

    // MÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn sang B
    canvas.drawLine(Offset(75, floorY - 15), Offset(95, floorY - 15), floorPaint);

    // B. QuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ 4 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm (bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²)
    canvas.drawCircle(Offset(125, floorY - 24), 6, stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(145, floorY - 18), stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(125, floorY), stepPaint);
    canvas.drawLine(Offset(145, floorY - 18), Offset(145, floorY), stepPaint);

    // MÃƒÂƒÃ‚Â…ÃƒÂ‚Ã‚Â©i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn sang C
    canvas.drawLine(Offset(160, floorY - 25), Offset(180, floorY - 25), floorPaint);

    // C. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n 2 tay lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    canvas.drawCircle(Offset(225, floorY - 42), 6, stepPaint);
    canvas.drawLine(Offset(225, floorY - 36), Offset(225, floorY - 15), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(215, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(235, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 30), Offset(chairX - 5, floorY - 45), Paint()..color = Colors.amberAccent..strokeWidth = 2.5); // Tay vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿

    // NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£n 4 bÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "1. NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m nghiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 2. QuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ 4 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 3. VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ng ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂžÃƒÂ‚Ã‚Â” 4. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿",
      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// =========================================================================
// TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG 2: HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â’ SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI CAO TUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â”I (MEDICAL EMERGENCY PROFILE)
// =========================================================================
class ElderlyMedicalProfile {
  String fullName;
  int birthYear;
  String gender;
  String bloodType;
  List<String> chronicConditions;
  List<String> highRiskMedications;
  String allergies;
  String emergencyContact1Name;
  String emergencyContact1Phone;
  String emergencyContact2Name;
  String emergencyContact2Phone;
  String attendingDoctorName;
  String attendingDoctorPhone;
  String hospital;
  String notes;

  ElderlyMedicalProfile({
    this.fullName = "NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n VÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn An",
    this.birthYear = 1948,
    this.gender = "Nam",
    this.bloodType = "O+",
    this.chronicConditions = const ["TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p", "LoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ng xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng", "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh"],
    this.highRiskMedications = const ["ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u (Aspirin / Warfarin)", "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p Amlodipine"],
    this.allergies = "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n",
    this.emergencyContact1Name = "Con trai (NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n TuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n)",
    this.emergencyContact1Phone = "0987654321",
    this.emergencyContact2Name = "Con gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i (NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n Mai)",
    this.emergencyContact2Phone = "0912345678",
    this.attendingDoctorName = "BS. CKII LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âª HoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng",
    this.attendingDoctorPhone = "0903115115",
    this.hospital = "BV LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£o Khoa TW / BV ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âa Khoa TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh",
    this.notes = "NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ thay khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›p hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡o nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm 2022. ChÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬a khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i cÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ 402.",
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'birthYear': birthYear,
    'gender': gender,
    'bloodType': bloodType,
    'chronicConditions': chronicConditions,
    'highRiskMedications': highRiskMedications,
    'allergies': allergies,
    'emergencyContact1Name': emergencyContact1Name,
    'emergencyContact1Phone': emergencyContact1Phone,
    'emergencyContact2Name': emergencyContact2Name,
    'emergencyContact2Phone': emergencyContact2Phone,
    'attendingDoctorName': attendingDoctorName,
    'attendingDoctorPhone': attendingDoctorPhone,
    'hospital': hospital,
    'notes': notes,
  };

  factory ElderlyMedicalProfile.fromJson(Map<String, dynamic> json) {
    return ElderlyMedicalProfile(
      fullName: json['fullName'] ?? "NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n VÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn An",
      birthYear: json['birthYear'] ?? 1948,
      gender: json['gender'] ?? "Nam",
      bloodType: json['bloodType'] ?? "O+",
      chronicConditions: json['chronicConditions'] != null
          ? List<String>.from(json['chronicConditions'])
          : ["TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p", "LoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ng xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng"],
      highRiskMedications: json['highRiskMedications'] != null
          ? List<String>.from(json['highRiskMedications'])
          : ["ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u (Aspirin / Warfarin)"],
      allergies: json['allergies'] ?? "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n",
      emergencyContact1Name: json['emergencyContact1Name'] ?? "Con trai (NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n TuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n)",
      emergencyContact1Phone: json['emergencyContact1Phone'] ?? "0987654321",
      emergencyContact2Name: json['emergencyContact2Name'] ?? "Con gÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i (NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n Mai)",
      emergencyContact2Phone: json['emergencyContact2Phone'] ?? "0912345678",
      attendingDoctorName: json['attendingDoctorName'] ?? "BS. CKII LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âª HoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng",
      attendingDoctorPhone: json['attendingDoctorPhone'] ?? "0903115115",
      hospital: json['hospital'] ?? "BV LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£o Khoa TW",
      notes: json['notes'] ?? "",
    );
  }

  static Future<ElderlyMedicalProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('elderly_medical_profile');
    if (raw != null) {
      try {
        return ElderlyMedicalProfile.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return ElderlyMedicalProfile();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elderly_medical_profile', jsonEncode(toJson()));
  }

  bool get isTakingAnticoagulants => highRiskMedications.any((m) =>
      m.toLowerCase().contains("chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng") ||
      m.toLowerCase().contains("aspirin") ||
      m.toLowerCase().contains("warfarin") ||
      m.toLowerCase().contains("clopidogrel") ||
      m.toLowerCase().contains("xarelto") ||
      m.toLowerCase().contains("eliquis"));
}

// =========================================================================
// THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Âº Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P (EMERGENCY MEDICAL ID CARD DIALOG)
// =========================================================================
class EmergencyMedicalIdCardDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final VoidCallback onEdit;

  const EmergencyMedicalIdCardDialog({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  int get age => DateTime.now().year - profile.birthYear;

  void _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isNotEmpty) {
      final uri = Uri.parse("tel:$clean");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  void _copySummary(BuildContext context) {
    final text = """
[THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Âº Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P - FALLGUARD]
HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn: ${profile.fullName} ($age tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i - Sinh nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm ${profile.birthYear} - ${profile.gender})
NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u: ${profile.bloodType}
CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO THUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂC CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂNG ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG: ${profile.isTakingAnticoagulants ? 'CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â“ (NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  XUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤T HUYÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾T NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜I SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŒ CAO)' : 'KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng'}
BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân: ${profile.chronicConditions.join(', ')}
ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng: ${profile.highRiskMedications.join(', ')}
DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng: ${profile.allergies}
BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹: ${profile.attendingDoctorName} (${profile.attendingDoctorPhone})
BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh: ${profile.hospital}
NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 1: ${profile.emergencyContact1Name} (${profile.emergencyContact1Phone})
NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})
Ghi chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº: ${profile.notes}
""";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â & BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Âº Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                        Text("DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cho NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n viÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn Y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ 115 & CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    tooltip: "ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰nh sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­a hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡",
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n & nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                          const SizedBox(height: 4),
                          Text("$age tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i (${profile.birthYear}) ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ GiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh: ${profile.gender}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Text("NHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â“M MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂU", style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                          Text(profile.bloodType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶C BIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â†T NÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾U DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â™NG THUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂC CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂNG ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂU
              if (profile.isTakingAnticoagulants)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚M SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€NG: NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng THUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂC CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂNG ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂU (Aspirin/Warfarin...). Nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â cao khi chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£!",
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân
              const Text("TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.chronicConditions.map((c) => Chip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.25),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng
              const Text("ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.highRiskMedications.map((m) => Chip(
                  label: Text(m, style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  side: const BorderSide(color: Colors.redAccent, width: 0.8),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),

              // DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng & BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock("DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng:", profile.allergies, Icons.no_food),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBlock("BV chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh:", profile.hospital, Icons.local_hospital),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi nhanh 1 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m
              const Text("LiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p 1 chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber("115"),
                      icon: const Icon(Icons.phone_in_talk, size: 16),
                      label: const Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u 115", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _callNumber(profile.emergencyContact1Phone),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(profile.emergencyContact1Name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.emergencyContact2Phone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _callNumber(profile.emergencyContact2Phone),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text("NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})", style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 12),

              // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p & ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySummary(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ng"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// =========================================================================
// MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂˆNH SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¬A HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â’ SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI CAO TUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â”I (MEDICAL PROFILE EDIT DIALOG)
// =========================================================================
class MedicalProfileEditDialog extends StatefulWidget {
  final ElderlyMedicalProfile profile;
  final Function(ElderlyMedicalProfile) onSaved;

  const MedicalProfileEditDialog({super.key, required this.profile, required this.onSaved});

  @override
  State<MedicalProfileEditDialog> createState() => _MedicalProfileEditDialogState();
}

class _MedicalProfileEditDialogState extends State<MedicalProfileEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _c1NameCtrl;
  late TextEditingController _c1PhoneCtrl;
  late TextEditingController _c2NameCtrl;
  late TextEditingController _c2PhoneCtrl;
  late TextEditingController _doctorNameCtrl;
  late TextEditingController _doctorPhoneCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _notesCtrl;

  late String _gender;
  late String _bloodType;
  late List<String> _selectedConditions;
  late List<String> _selectedMeds;

  final List<String> _availableConditions = [
    "TÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p",
    "ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng Type 2",
    "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh / Tim mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ch",
    "LoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ng xÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ng nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·ng",
    "TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âµ / Tai biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n",
    "Parkinson",
    "RÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh",
    "Suy giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â› / Sa sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡",
  ];

  final List<String> _availableMeds = [
    "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u (Aspirin / Warfarin)",
    "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u (Clopidogrel / Plavix)",
    "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i (Xarelto / Eliquis)",
    "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p (Amlodipine / Losartan...)",
    "Insulin / ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng",
    "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c an thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n / ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§",
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _yearCtrl = TextEditingController(text: p.birthYear.toString());
    _allergiesCtrl = TextEditingController(text: p.allergies);
    _c1NameCtrl = TextEditingController(text: p.emergencyContact1Name);
    _c1PhoneCtrl = TextEditingController(text: p.emergencyContact1Phone);
    _c2NameCtrl = TextEditingController(text: p.emergencyContact2Name);
    _c2PhoneCtrl = TextEditingController(text: p.emergencyContact2Phone);
    _doctorNameCtrl = TextEditingController(text: p.attendingDoctorName);
    _doctorPhoneCtrl = TextEditingController(text: p.attendingDoctorPhone);
    _hospitalCtrl = TextEditingController(text: p.hospital);
    _notesCtrl = TextEditingController(text: p.notes);
    _gender = p.gender;
    _bloodType = p.bloodType;
    _selectedConditions = List<String>.from(p.chronicConditions);
    _selectedMeds = List<String>.from(p.highRiskMedications);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    _allergiesCtrl.dispose();
    _c1NameCtrl.dispose();
    _c1PhoneCtrl.dispose();
    _c2NameCtrl.dispose();
    _c2PhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = ElderlyMedicalProfile(
      fullName: _nameCtrl.text.trim().isEmpty ? "NguyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â…n VÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn An" : _nameCtrl.text.trim(),
      birthYear: int.tryParse(_yearCtrl.text.trim()) ?? 1948,
      gender: _gender,
      bloodType: _bloodType,
      chronicConditions: _selectedConditions,
      highRiskMedications: _selectedMeds,
      allergies: _allergiesCtrl.text.trim().isEmpty ? "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n" : _allergiesCtrl.text.trim(),
      emergencyContact1Name: _c1NameCtrl.text.trim(),
      emergencyContact1Phone: _c1PhoneCtrl.text.trim(),
      emergencyContact2Name: _c2NameCtrl.text.trim(),
      emergencyContact2Phone: _c2PhoneCtrl.text.trim(),
      attendingDoctorName: _doctorNameCtrl.text.trim(),
      attendingDoctorPhone: _doctorPhoneCtrl.text.trim(),
      hospital: _hospitalCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    updated.save();
    widget.onSaved(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text("1. ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng tin bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cao tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm sinh (VD: 1948)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _bloodType,
                          decoration: const InputDecoration(labelText: "NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u", border: OutlineInputBorder(), prefixIcon: Icon(Icons.bloodtype)),
                          items: ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-", "ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a rÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âµ"].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => _bloodType = val ?? "O+"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân (ChÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 6),
                  ..._availableConditions.map((cond) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cond, style: const TextStyle(fontSize: 13)),
                    value: _selectedConditions.contains(cond),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedConditions.add(cond);
                        } else {
                          _selectedConditions.remove(cond);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("3. ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t (CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ quan trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng khi cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 6),
                  ..._availableMeds.map((med) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(med, style: TextStyle(fontSize: 13, color: med.contains("chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng") ? Colors.redAccent : null)),
                    value: _selectedMeds.contains(med),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedMeds.add(med);
                        } else {
                          _selectedMeds.remove(med);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),

                  const Text("4. Danh bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p & BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c1NameCtrl, decoration: const InputDecoration(labelText: "NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 1 (TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn/Quan hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c1PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂT NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 1", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c2NameCtrl, decoration: const InputDecoration(labelText: "NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 2 (TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn/Quan hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c2PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂT NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n 2", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _doctorNameCtrl, decoration: const InputDecoration(labelText: "BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© riÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªng", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _doctorPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂT BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: "BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u tiÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh chuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒn viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n", border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                  const SizedBox(height: 10),
                  TextField(controller: _allergiesCtrl, decoration: const InputDecoration(labelText: "DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c / thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning))),
                  const SizedBox(height: 10),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Ghi chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c (VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬a khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng, tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•...)", border: OutlineInputBorder())),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ sÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG 7: ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ THEO CHUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CDC STEADI (12 CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚U HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŽI)
// =========================================================================
class CdcSteadiAssessmentDialog extends StatefulWidget {
  final Function(int score, String riskLevel) onCompleted;

  const CdcSteadiAssessmentDialog({super.key, required this.onCompleted});

  @override
  State<CdcSteadiAssessmentDialog> createState() => _CdcSteadiAssessmentDialogState();
}

class _CdcSteadiAssessmentDialogState extends State<CdcSteadiAssessmentDialog> {
  // 12 cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢u hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi chuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n CDC STEADI (Stay Independent Brochure)
  final List<Map<String, dynamic>> _questions = [
    {
      "text": "1. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ trong vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng 1 nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm qua.",
      "pts": 2,
      "why": "NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«ng ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ cao gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p 3 lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n.",
      "ans": false,
    },
    {
      "text": "2. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khung tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i, hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© khuyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng.",
      "pts": 2,
      "why": "DÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥u hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u suy giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i.",
      "ans": false,
    },
    {
      "text": "3. ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i khi tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng choÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng khi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i.",
      "pts": 1,
      "why": "RÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c yÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ chi dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i.",
      "ans": false,
    },
    {
      "text": "4. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i hay phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡c, tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng khi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i trong nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â .",
      "pts": 1,
      "why": "BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿u tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± tin vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n.",
      "ans": false,
    },
    {
      "text": "5. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng lo lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â½ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£.",
      "pts": 1,
      "why": "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ (Fear of Falling) dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  teo cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡.",
      "ans": false,
    },
    {
      "text": "6. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng tay ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©y mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹i hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£c.",
      "pts": 1,
      "why": "Suy giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â© ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹i (quadriceps weakness).",
      "ans": false,
    },
    {
      "text": "7. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ khÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒn khi bÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›c lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰a hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨ hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­c thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âm cao.",
      "pts": 1,
      "why": "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ linh hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›p cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢ng chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n.",
      "ans": false,
    },
    {
      "text": "8. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£i vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ sinh.",
      "pts": 1,
      "why": "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™i chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m tÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ban ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm.",
      "ans": false,
    },
    {
      "text": "9. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âª bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n.",
      "pts": 1,
      "why": "MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ (neuropathy) hay gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·p ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng.",
      "ans": false,
    },
    {
      "text": "10. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang uÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y choÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c buÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§.",
      "pts": 1,
      "why": "TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p, an thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng histamine.",
      "ans": false,
    },
    {
      "text": "11. TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang uÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ rÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡n tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â— trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥c ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§.",
      "pts": 1,
      "why": "ThuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â m giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng khi thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯a ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm.",
      "ans": false,
    },
    {
      "text": "12. GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢y tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng xuyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥y buÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“n bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£, chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡n nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£n hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c suy giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m tinh thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n.",
      "pts": 1,
      "why": "TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§m cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  liÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn quan mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t thiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n suy giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘i hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£p vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng.",
      "ans": false,
    },
  ];

  int get currentScore {
    int s = 0;
    for (var q in _questions) {
      if (q['ans'] == true) s += (q['pts'] as int);
    }
    return s;
  }

  String get riskLevel => currentScore >= 4 ? "NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  CAO (High Risk)" : "NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P / VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂªA (Low/Mod Risk)";

  void _finish() async {
    final score = currentScore;
    final level = riskLevel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cdc_steadi_last_score', score);
    await prefs.setString('cdc_steadi_last_date', DateTime.now().toIso8601String());

    // LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o danh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ch sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡
    final List<String> history = prefs.getStringList('cdc_steadi_history') ?? [];
    history.insert(0, jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'risk': level,
    }));
    await prefs.setStringList('cdc_steadi_history', history);

    widget.onCompleted(score, level);
    if (!mounted) return;
    Navigator.pop(context);

    // MÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™p thoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ & lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi khuyÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿
    _showResultDialog(score, level);
  }

  void _showResultDialog(int score, String level) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(score >= 4 ? Icons.warning : Icons.check_circle, color: score >= 4 ? Colors.redAccent : Colors.green),
            const SizedBox(width: 8),
            const Text("KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ CDC", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (score >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: score >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                children: [
                  Text("$score / 14 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: score >= 4 ? Colors.redAccent : Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("KhuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿n nghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng theo CDC STEADI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (score >= 4) ...[
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘o huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ (ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng sau 1-3 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt) ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§m soÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥t huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿.", style: TextStyle(fontSize: 12)),
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â nghÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ rÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  soÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c, ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c biÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡t thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c an thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p.", style: TextStyle(fontSize: 12)),
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t thanh vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n tay trong nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£t ngay lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c.", style: TextStyle(fontSize: 12)),
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ liÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c hÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â“i chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±ng (bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p Otago / ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c QuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân).", style: TextStyle(fontSize: 12)),
            ] else ...[
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ Duy trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³i quen tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­p luyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y (ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘i bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™, ThÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c QuyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân 30 phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt/ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y).", style: TextStyle(fontSize: 12)),
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â• sung ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ Canxi vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  Vitamin D theo hÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›ng dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§a bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©.", style: TextStyle(fontSize: 12)),
              const Text("ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ 6 thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n.", style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ CDC STEADI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("ChuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n y khoa Trung tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm soÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t Hoa KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³ (CDC)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (currentScore >= 4 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: currentScore >= 4 ? Colors.redAccent : Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: $currentScore / 14 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm", style: TextStyle(fontWeight: FontWeight.bold, color: currentScore >= 4 ? Colors.redAccent : Colors.green)),
                  Text(currentScore >= 4 ? "Nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cao (>= 4)" : "Nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p (< 4)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (ctx, idx) {
                  final q = _questions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: q['ans'] == true ? Colors.red.withValues(alpha: 0.08) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: q['ans'] == true ? Colors.redAccent : Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(q['text'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("+${q['pts']}ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Y khoa: ${q['why']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ChoiceChip(
                                label: const Text("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng"),
                                selected: q['ans'] == false,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ / ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºng"),
                                selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                                selected: q['ans'] == true,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: currentScore >= 4 ? Colors.redAccent : Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _finish,
              icon: const Icon(Icons.check_circle_outline),
              label: Text("HoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â nh ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ ($currentScore ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG 3: BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO Y KHOA XUÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤T ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŠNH KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â² (MEDICAL AUDIT REPORT DIALOG)
// =========================================================================
class MedicalAuditReportDialog extends StatelessWidget {
  final ElderlyMedicalProfile profile;
  final List<dynamic> eventHistory;
  final int cdcScore;
  final DateTime? cdcDate;
  final int inactivityEventsCount;
  final int tofHeight;
  final int radarMotion;

  const MedicalAuditReportDialog({
    super.key,
    required this.profile,
    required this.eventHistory,
    required this.cdcScore,
    required this.cdcDate,
    required this.inactivityEventsCount,
    required this.tofHeight,
    required this.radarMotion,
  });

  String _generateReportText() {
    final now = DateTime.now();
    final age = now.year - profile.birthYear;
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return """
======================================================================
BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚M SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€NG GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂM SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂT TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ & VÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬N ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG (FALLGUARD CLINICAL REPORT)
HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t vi ba Radar FMCW 24GHz & Laser ToF AI ESP32-S3R8
ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o: $dateStr
======================================================================

I. THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”NG TIN BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â†NH NHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N & HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â’ SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªn: ${profile.fullName}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i: $age tuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•i (Sinh nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm ${profile.birthYear} - GiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh: ${profile.gender})
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ NhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u: ${profile.bloodType}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u: ${profile.isTakingAnticoagulants ? 'CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â“ (Aspirin/Warfarin/Xarelto - CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â°C KÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â² LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯U ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â)' : 'KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n'}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â½ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Ân: ${profile.chronicConditions.join(', ')}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡n thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­ dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ng: ${profile.highRiskMedications.join(', ')}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â© phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ch: ${profile.attendingDoctorName} (SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂT: ${profile.attendingDoctorPhone})
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh viÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh: ${profile.hospital}

II. CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âˆ SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH GIÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ (CDC STEADI USA)
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡: $cdcScore / 14 ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡: ${cdcScore >= 4 ? 'NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  CAO (High Fall Risk >= 4)' : 'NGUY CÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â  THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P / TRUNG BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH (< 4)'}
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ NgÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â y ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh giÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t: ${cdcDate != null ? '${cdcDate!.day}/${cdcDate!.month}/${cdcDate!.year}' : 'ChÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n'}

III. THÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂNG KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŠ SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â° CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â & HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜P ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂEN NVS (BLACKBOX AUDIT)
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ tÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â© ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh ghi nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n: ${eventHistory.where((e) => e['type'] == 1).length} sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â•ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­m / nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng: ${eventHistory.where((e) => e['type'] == 2).length} sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ SÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o lÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°u trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng trong nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯m (>30p): $inactivityEventsCount lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n
ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i: ChiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu cao ToF $tofHeight mm | ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar $radarMotion/100

IV. KHUYÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾N CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO LÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚M SÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€NG DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€NH CHO BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂC SÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â¨ & GIA ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH
1. NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³ phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§ng nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ ${cdcScore >= 4 ? 'CAO' : 'TRUNG BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH'}. CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§n kiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra huyÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿t ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡p tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â° thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ nÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â±m vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng (Orthostatic Hypotension) tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m.
2. ${profile.isTakingAnticoagulants ? 'ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶C BIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â†T LÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯U ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â: Do bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹ thuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng, mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â§u dÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¹ chÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°a xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n triÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡u chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng ngoÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â i da vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â«n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t buÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™c chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥p CT sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â nÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£o trong 24h ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒ loÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â« tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡u dÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â›i mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©ng muÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™n.' : 'Duy trÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬ chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¹ nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng.'}
3. KiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm tra mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŸ: LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯p ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·t tay vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹n nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ sinh, giÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¯ sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ rÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o, ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£m bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£o ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡nh sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ng ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¨n ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­t khi ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡nh thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©c dÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­y ban ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âªm.
======================================================================
""";
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o y khoa vÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â o clipboard!"), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReportText();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.tealAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o y tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ xuÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‹nh kÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â³", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text("TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³m tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¯t lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m sÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â ng phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥c vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¥ thÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒm khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡m BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      _copyToClipboard(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text("Sao chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â©p & GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â­i BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c sÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â©"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG 4: CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P VÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¢T CHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¾ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜ IM LÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¶NG (CRITICAL ALARM MODAL)
// =========================================================================
class CriticalEmergencyAlarmDialog extends StatefulWidget {
  final bool isFall;
  final String? customReason;
  final ElderlyMedicalProfile profile;
  final int tofHeight;
  final int radarMotion;
  final double dropRate;
  final String roomName;
  final VoidCallback onCancelAlarm;
  final VoidCallback onOpenMedicalId;
  final VoidCallback onOpenFirstAid;

  const CriticalEmergencyAlarmDialog({
    super.key,
    this.isFall = true,
    this.customReason,
    required this.profile,
    required this.tofHeight,
    required this.radarMotion,
    required this.dropRate,
    required this.roomName,
    required this.onCancelAlarm,
    required this.onOpenMedicalId,
    required this.onOpenFirstAid,
  });

  @override
  State<CriticalEmergencyAlarmDialog> createState() => _CriticalEmergencyAlarmDialogState();
}

class _CriticalEmergencyAlarmDialogState extends State<CriticalEmergencyAlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _hapticLoopTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // VÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²ng lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·p rung chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥n mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh & ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢m thanh cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£nh bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o vÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£t chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿ ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ im lÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·ng
    _hapticLoopTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _hapticLoopTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _call115() async {
    final uri = Uri.parse("tel:115");
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _callFamily() async {
    final phone = widget.profile.emergencyContact1Phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isNotEmpty) {
      final uri = Uri.parse("tel:$phone");
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final Color flashColor = Color.lerp(Colors.red.shade900, Colors.amber.shade900, _pulseController.value)!;
        return Dialog(
          backgroundColor: const Color(0xFF140303),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: flashColor, width: 3.5),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu tÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£ng & NhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p nhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡y bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡o ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2 + 0.3 * _pulseController.value),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2.5),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.redAccent, size: 48),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      widget.isFall ? "ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Â¨ CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰ NGÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âƒ KHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¨N CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P!" : "ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚ÂšÃƒÂ‚Ã‚Â ÃƒÂƒÃ‚Â¯ÃƒÂ‚Ã‚Â¸ÃƒÂ‚Ã‚Â CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¢NH BÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂO BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤T ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â˜NG KÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‰O DÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€I!",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.customReason ?? (widget.isFall
                        ? "HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡ thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ng AI vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â«a phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ va chÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡m mÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡nh tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i khu vÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c [${widget.roomName}]!"
                        : "PhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n bÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng quÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡ lÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢u trong [${widget.roomName}]. Nghi ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â ngÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥t xÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‰u hoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â·c ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™t quÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âµ!"),
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // BÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â£ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘ tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i thÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘iÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒm sÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â± cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‘
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric("V_rÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡i", "${widget.dropRate.toStringAsFixed(0)} mm/s"),
                        _buildMetric("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ cao ToF", "${widget.tofHeight} mm"),
                        _buildMetric("ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚ÂÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng nÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Âƒng Radar", "${widget.radarMotion}%"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi 115 khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _call115,
                    icon: const Icon(Icons.phone_in_talk, size: 22),
                    label: const Text("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŒI CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¤P CÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â¨U 115 NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),

                  // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt gÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi ngÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n khÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â©n cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¥p
                  if (widget.profile.emergencyContact1Phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _callFamily,
                      icon: const Icon(Icons.call, size: 20),
                      label: Text("GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŒI NGÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¯ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂœI THÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â‚N (${widget.profile.emergencyContact1Name})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenMedicalId();
                          },
                          icon: const Icon(Icons.badge, size: 16),
                          label: const Text("ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenFirstAid();
                          },
                          icon: const Icon(Icons.medical_services, size: 16),
                          label: const Text("SÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ cÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â©u", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // NÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âºt xÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡c nhÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â­n an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n & HÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â§y cÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â²i hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âº
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _hapticLoopTimer?.cancel();
                      widget.onCancelAlarm();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("XÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂC NHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¬N AN TOÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N / TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â®T CÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â’I HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Âš", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
      ],
    );
  }
}

// =========================================================================
// TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH NÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‚NG 6: WIDGET TIÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â†N ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂCH MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH KHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â“A & MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH (PREVIEW MODAL)
// =========================================================================
class LockscreenWidgetPreviewDialog extends StatelessWidget {
  final String posture;
  final int tofHeight;
  final int radarMotion;
  final String roomName;
  final String sysState;

  const LockscreenWidgetPreviewDialog({
    super.key,
    required this.posture,
    required this.tofHeight,
    required this.radarMotion,
    required this.roomName,
    required this.sysState,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.widgets, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ phÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng Widget MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("iOS Dynamic Island & Android Glance Widget", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // 1. MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â” PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŽNG DYNAMIC ISLAND (iOS 16.1+)
              const Text("1. iOS Dynamic Island & HoÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡t ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â™ng trÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p (Live Activity):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sysState == "ALERT" ? Colors.red : Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.shield, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "FallGuard: $roomName ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ An toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("${tofHeight}mm", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â” PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŽNG WIDGET MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH KHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â“A iOS (2x1)
              const Text("2. TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh khÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â³a iOS Lock Screen (Widget 2x1):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        const Text("FALL GUARD S3R8", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const Spacer(),
                        Text(posture, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("NgÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¢n ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ang an toÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n tÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡i $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Radar: $radarMotion% ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ ChiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âu cao: ${tofHeight}mm ÃƒÂƒÃ‚Â¢ÃƒÂ‚Ã‚Â€ÃƒÂ‚Ã‚Â¢ TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â±c tiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿p", style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â” PHÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚ÂŽNG WIDGET MÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â€N HÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂŒNH CHÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚ÂNH ANDROID (Glance 4x2)
              const Text("3. TiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­ch mÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â n hÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh chÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â­nh Android Home Widget (Material You):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900.withValues(alpha: 0.5), Colors.teal.shade900.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â”ng An: TrÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¡ng thÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡i bÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¬nh thÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("KhÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´ng phÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â¡t hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â‡n nguy cÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â¡ trÃƒÂƒÃ‚Â†ÃƒÂ‚Ã‚Â°ÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Â£t ngÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.battery_charging_full, size: 16, color: Colors.greenAccent),
                        const SizedBox(width: 2),
                        const Text("100%", style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚Â“ÃƒÂ‚Ã‚Âž GÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âi 115", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("ÃƒÂƒÃ‚Â°ÃƒÂ‚Ã‚ÂŸÃƒÂ‚Ã‚ÂªÃƒÂ‚Ã‚Âª ThÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â» Y TÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚ÂºÃƒÂ‚Ã‚Â¿", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.tealAccent))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("TÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â´i ÃƒÂƒÃ‚Â„ÃƒÂ‚Ã‚Â‘ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â£ hiÃƒÂƒÃ‚Â¡ÃƒÂ‚Ã‚Â»ÃƒÂ‚Ã‚Âƒu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
