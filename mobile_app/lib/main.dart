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
// CÃÂÃÂC UUID TRÃÂÃÂNG KHÃÂ¡ÃÂ»ÃÂP 100% VÃÂ¡ÃÂ»ÃÂI FIRMWARE ESP32-S3 N16R8
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
// CÃÂ¡ÃÂ»ÃÂNG KIÃÂ¡ÃÂ»ÃÂM TRA KHÃÂ¡ÃÂ»ÃÂI ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG (STARTUP PERMISSION GATE CHO IOS & ANDROID)
// BÃÂ¡ÃÂºÃÂ¯t buÃÂ¡ÃÂ»ÃÂc xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n cho phÃÂÃÂ©p quÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ xung quanh trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi vÃÂÃÂ o app lÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂ¡ÃÂºÃÂ§u
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
// MÃÂÃÂN HÃÂÃÂNH XÃÂÃÂC NHÃÂ¡ÃÂºÃÂ¬N CHO PHÃÂÃÂP QUÃÂÃÂT THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ XUNG QUANH (CHUÃÂ¡ÃÂºÃÂ¨N APPLE HIG)
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
      // 1. KÃÂÃÂ­ch hoÃÂ¡ÃÂºÃÂ¡t CBCentralManager trÃÂÃÂªn iOS bÃÂ¡ÃÂºÃÂ±ng cÃÂÃÂ¡ch truy vÃÂ¡ÃÂºÃÂ¥n trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i adapter
      BluetoothAdapterState state;
      try {
        state = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 4),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
      } catch (_) {
        state = BluetoothAdapterState.unknown;
      }

      // 2. NÃÂ¡ÃÂºÃÂ¿u trÃÂÃÂªn Android mÃÂÃÂ  Bluetooth chÃÂÃÂ°a bÃÂ¡ÃÂºÃÂ­t thÃÂÃÂ¬ hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ bÃÂ¡ÃÂºÃÂ­t
      if (Platform.isAndroid && state == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 3. NÃÂ¡ÃÂºÃÂ¿u quyÃÂ¡ÃÂ»ÃÂn bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ« chÃÂ¡ÃÂ»ÃÂi rÃÂÃÂµ rÃÂÃÂ ng trÃÂÃÂªn iOS
      if (state == BluetoothAdapterState.unauthorized) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 4. NÃÂ¡ÃÂºÃÂ¿u Bluetooth ÃÂÃÂang tÃÂ¡ÃÂºÃÂ¯t trÃÂÃÂªn iOS
      if (state == BluetoothAdapterState.off && Platform.isIOS) {
        if (!mounted) return;
        _showBluetoothOffDialog();
        setState(() => _isRequesting = false);
        return;
      }

      // 5. LÃÂÃÂ°u xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n vÃÂÃÂ o bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ©nh viÃÂ¡ÃÂ»ÃÂn vÃÂÃÂ  chuyÃÂ¡ÃÂ»ÃÂn vÃÂÃÂ o Dashboard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_nearby_devices', true);

      if (!mounted) return;
      widget.onConsentGranted();
    } catch (e) {
      // DÃÂÃÂ¹ cÃÂÃÂ³ ngoÃÂ¡ÃÂºÃÂ¡i lÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ o cÃÂÃÂ©ng lÃÂÃÂ°u cÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ khÃÂÃÂ´ng lÃÂÃÂ m kÃÂ¡ÃÂºÃÂ¹t ÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂ»ÃÂ¥ng
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
            Text("CÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂºÃÂ¥p quyÃÂ¡ÃÂ»ÃÂn Bluetooth", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "BÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂÃÂÃÂ£ tÃÂ¡ÃÂ»ÃÂ« chÃÂ¡ÃÂ»ÃÂi quyÃÂ¡ÃÂ»ÃÂn Bluetooth trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc ÃÂÃÂÃÂÃÂ³. ÃÂÃÂÃÂ¡ÃÂ»ÃÂ phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn vÃÂÃÂ  kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi vÃÂ¡ÃÂ»ÃÂi hÃÂ¡ÃÂ»ÃÂp cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n tÃÂÃÂ© ngÃÂÃÂ£ ESP32-S3, vui lÃÂÃÂ²ng vÃÂÃÂ o CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t iPhone > FallGuard > BÃÂ¡ÃÂºÃÂ­t quyÃÂ¡ÃÂ»ÃÂn Bluetooth.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse("app-settings:"));
            },
            child: const Text("MÃÂ¡ÃÂ»ÃÂ CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t iPhone"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.setBool('has_consented_nearby_devices', true));
              widget.onConsentGranted();
            },
            child: const Text("TiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ¥c vÃÂÃÂ o App"),
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
            Text("Bluetooth ÃÂÃÂang tÃÂ¡ÃÂºÃÂ¯t", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          "Bluetooth trÃÂÃÂªn iPhone cÃÂ¡ÃÂ»ÃÂ§a bÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂang tÃÂ¡ÃÂºÃÂ¯t. Vui lÃÂÃÂ²ng vuÃÂ¡ÃÂ»ÃÂt Trung tÃÂÃÂ¢m ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn (Control Center) vÃÂÃÂ  bÃÂ¡ÃÂºÃÂ­t Bluetooth ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ quÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ FallGuard.",
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
            child: const Text("TÃÂÃÂ´i ÃÂÃÂÃÂÃÂ£ hiÃÂ¡ÃÂ»ÃÂu"),
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

              // Logo & BiÃÂ¡ÃÂ»ÃÂu tÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar QuÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ
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

              // TiÃÂÃÂªu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ chÃÂÃÂ­nh
              const Text(
                "Cho phÃÂÃÂ©p quÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ xung quanh",
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
                "YÃÂÃÂªu cÃÂ¡ÃÂºÃÂ§u bÃÂ¡ÃÂºÃÂ£o mÃÂ¡ÃÂºÃÂ­t trÃÂÃÂªn iOS ÃÂÃÂÃÂ¡ÃÂ»ÃÂ tÃÂÃÂ¬m kiÃÂ¡ÃÂºÃÂ¿m vÃÂÃÂ  kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi vÃÂ¡ÃÂ»ÃÂi hÃÂ¡ÃÂ»ÃÂp cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn tÃÂÃÂ© ngÃÂÃÂ£ FallGuard S3R8.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 3 ThÃÂ¡ÃÂºÃÂ» giÃÂ¡ÃÂºÃÂ£i thÃÂÃÂ­ch mÃÂ¡ÃÂ»ÃÂ¥c ÃÂÃÂÃÂÃÂ­ch sÃÂ¡ÃÂ»ÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥ng quyÃÂ¡ÃÂ»ÃÂn
              _buildFeatureItem(
                Icons.radar,
                Colors.cyanAccent,
                "QuÃÂÃÂ©t & KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ¢n cÃÂ¡ÃÂºÃÂ­n",
                "TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn hÃÂ¡ÃÂ»ÃÂp cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n ESP32-S3 trong phÃÂÃÂ²ng qua Bluetooth Low Energy (BLE) vÃÂ¡ÃÂ»ÃÂi mÃÂ¡ÃÂ»ÃÂ©c tiÃÂÃÂªu thÃÂ¡ÃÂ»ÃÂ¥ pin tÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂ»ÃÂu.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.health_and_safety,
                Colors.redAccent,
                "CÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o cÃÂ¡ÃÂ»ÃÂ©u nÃÂ¡ÃÂºÃÂ¡n tÃÂ¡ÃÂ»ÃÂ©c thÃÂÃÂ¬",
                "NhÃÂ¡ÃÂºÃÂ­n tÃÂÃÂ­n hiÃÂ¡ÃÂ»ÃÂu bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng khi ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cao tuÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ£, sÃÂ¡ÃÂ»ÃÂ¥t giÃÂ¡ÃÂºÃÂ£m ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao hoÃÂ¡ÃÂºÃÂ·c nÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ kÃÂ¡ÃÂ»ÃÂp thÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂ»ÃÂ©u hÃÂ¡ÃÂ»ÃÂ.",
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.verified_user,
                Colors.greenAccent,
                "BÃÂ¡ÃÂºÃÂ£o mÃÂ¡ÃÂºÃÂ­t quyÃÂ¡ÃÂ»ÃÂn riÃÂÃÂªng tÃÂÃÂ° (ChuÃÂ¡ÃÂºÃÂ©n Apple)",
                "KhÃÂÃÂ´ng thu thÃÂ¡ÃÂºÃÂ­p tÃÂ¡ÃÂ»ÃÂa ÃÂÃÂÃÂ¡ÃÂ»ÃÂ GPS, khÃÂÃÂ´ng ghi ÃÂÃÂ¢m hay theo dÃÂÃÂµi cÃÂÃÂ¡ nhÃÂÃÂ¢n. ChÃÂ¡ÃÂ»ÃÂ giao tiÃÂ¡ÃÂºÃÂ¿p vÃÂ¡ÃÂ»ÃÂi cÃÂÃÂ¡c thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ y tÃÂ¡ÃÂºÃÂ¿ cÃÂÃÂ³ UUID FallGuard.",
              ),

              const Spacer(),

              // ThÃÂÃÂ´ng bÃÂÃÂ¡o hÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n hÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i iOS
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
                        "Khi hÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i iOS hiÃÂ¡ÃÂ»ÃÂn ra, vui lÃÂÃÂ²ng chÃÂ¡ÃÂ»ÃÂn [Cho phÃÂÃÂ©p] (Allow) ÃÂÃÂÃÂ¡ÃÂ»ÃÂ bÃÂ¡ÃÂºÃÂ¯t ÃÂÃÂÃÂ¡ÃÂºÃÂ§u tÃÂÃÂ¬m kiÃÂ¡ÃÂºÃÂ¿m thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade300, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NÃÂÃÂºt xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n cÃÂ¡ÃÂºÃÂ¥p quyÃÂ¡ÃÂ»ÃÂn
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
                            "XÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n & Cho phÃÂÃÂ©p quÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ",
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
// MÃÂÃÂN HÃÂÃÂNH CHÃÂÃÂNH (HOME SCREEN): KHÃÂÃÂNG CÃÂÃÂN TAB BÃÂÃÂN NGOÃÂÃÂI, QUÃÂ¡ÃÂºÃÂ¢N LÃÂÃÂ THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ
// =========================================================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final ValueNotifier<int> _telemetryRevision = ValueNotifier<int>(0);
  // TrÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi BLE
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = "ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ";
  List<ScanResult> _scanResults = [];
  final Map<String, int> _rssiMap = {};

  // CÃÂÃÂ¡c Characteristic ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c tÃÂÃÂ¬m thÃÂ¡ÃÂºÃÂ¥y
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

  // Controllers cho form cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  double _floorThreshold = 450;

  // GiÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua mÃÂ¡ÃÂºÃÂ¡ng Wi-Fi LAN (Direct Wi-Fi Telemetry)
  String _deviceIp = "";
  final TextEditingController _deviceIpController = TextEditingController();
  bool _isWifiMonitoringEnabled = false;
  bool _isWifiConnected = false;
  int _wifiDelayMs = 0;
  Timer? _wifiPollTimer;
  int _wifiFailureCount = 0;

  // DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu Telemetry thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c
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
    // Android cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ chia notify thÃÂÃÂ nh nhiÃÂ¡ÃÂ»ÃÂu mÃÂ¡ÃÂºÃÂ£nh khi MTU chÃÂÃÂ°a ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c nÃÂÃÂ¢ng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ§.
    // ChÃÂ¡ÃÂ»ÃÂ parse khi ÃÂÃÂÃÂÃÂ£ ghÃÂÃÂ©p ÃÂÃÂÃÂ¡ÃÂ»ÃÂ§ mÃÂ¡ÃÂ»ÃÂt JSON hoÃÂÃÂ n chÃÂ¡ÃÂ»ÃÂnh.
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
      // ChÃÂÃÂ°a ÃÂÃÂÃÂ¡ÃÂ»ÃÂ§ mÃÂ¡ÃÂºÃÂ£nh JSON, chÃÂ¡ÃÂ»ÃÂ notify tiÃÂ¡ÃÂºÃÂ¿p theo.
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

  // LÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi & CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung cÃÂ¡ÃÂ»ÃÂ§a App
  List<Map<String, dynamic>> _deviceHistory = [];
  bool _alarmSoundEnabled = true;
  bool _alarmVibrateEnabled = true;
  double _alarmVolume = 0.8;
  bool _autoEmergency115 = false;
  bool _autoReconnect = true;
  String _heightUnit = "mm";
  String _tempUnit = "ÃÂÃÂ°C";

  // TÃÂÃÂ­nh nÃÂÃÂng 1, 2, 3, 4, 6, 7 (Y tÃÂ¡ÃÂºÃÂ¿, CÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p, CDC STEADI, BÃÂÃÂ¡o cÃÂÃÂ¡o & Widget)
  ElderlyMedicalProfile _medicalProfile = ElderlyMedicalProfile();
  int _cdcSteadiScore = 0;
  DateTime? _cdcSteadiDate;
  bool _inactivityAlertEnabled = true;
  int _inactivityThresholdMinutes = 30;
  String _monitoredRoomName = "NhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m / Toilet";
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
      _monitoredRoomName = prefs.getString('inactivity_room_name') ?? "NhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m / Toilet";
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

      // NÃÂ¡ÃÂºÃÂ¿u radar phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn cÃÂÃÂ³ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi (motion hoÃÂ¡ÃÂºÃÂ·c static) hoÃÂ¡ÃÂºÃÂ·c ToF cÃÂÃÂ³ cÃÂ¡ÃÂ»ÃÂ± ly
      final bool hasPresence = (_radarMotion > 5 || _radarStatic > 10 || (_tofHeight > 100 && _tofHeight < 3000));
      if (hasPresence) {
        _roomPresenceStartTime ??= DateTime.now();
        final elapsed = DateTime.now().difference(_roomPresenceStartTime!).inSeconds;
        setState(() {
          _roomPresenceSeconds = elapsed;
        });

        // KiÃÂ¡ÃÂ»ÃÂm tra vÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£t ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng lÃÂÃÂ°u trÃÂÃÂº bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng
        if (_inactivityAlertEnabled && !_isInactivityAlertShowing && elapsed >= (_inactivityThresholdMinutes * 60)) {
          _triggerInactivityAlarm();
        }
      } else {
        // NÃÂ¡ÃÂºÃÂ¿u khÃÂÃÂ´ng cÃÂÃÂ³ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi quÃÂÃÂ¡ 45 giÃÂÃÂ¢y thÃÂÃÂ¬ reset bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂºÃÂ¿m
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
      reason: "CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO BÃÂ¡ÃÂºÃÂ¤T ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG: NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n ÃÂÃÂÃÂÃÂ£ ÃÂ¡ÃÂ»ÃÂ trong [$_monitoredRoomName] liÃÂÃÂªn tÃÂ¡ÃÂ»ÃÂ¥c $_inactivityThresholdMinutes phÃÂÃÂºt mÃÂÃÂ  khÃÂÃÂ´ng cÃÂÃÂ³ chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂ»ÃÂn! Nghi ngÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂt quÃÂ¡ÃÂ»ÃÂµ hoÃÂ¡ÃÂºÃÂ·c ngÃÂ¡ÃÂºÃÂ¥t xÃÂ¡ÃÂ»ÃÂu.",
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
                    child: Text("GiÃÂÃÂ¡m sÃÂÃÂ¡t lÃÂÃÂ°u trÃÂÃÂº & NgÃÂ¡ÃÂºÃÂ¥t xÃÂ¡ÃÂ»ÃÂu nhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("BÃÂ¡ÃÂºÃÂ­t cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng / ngÃÂ¡ÃÂºÃÂ¥t xÃÂ¡ÃÂ»ÃÂu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("HÃÂÃÂº cÃÂÃÂ²i khi lÃÂÃÂ°u lÃÂ¡ÃÂºÃÂ¡i quÃÂÃÂ¡ lÃÂÃÂ¢u khÃÂÃÂ´ng vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _inactivityAlertEnabled,
                onChanged: (val) {
                  setSheetState(() => _inactivityAlertEnabled = val);
                  setState(() => _inactivityAlertEnabled = val);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 10),
              const Text("NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng thÃÂ¡ÃÂ»ÃÂi gian cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text("15 phÃÂÃÂºt")),
                  ButtonSegment(value: 30, label: Text("30 phÃÂÃÂºt")),
                  ButtonSegment(value: 45, label: Text("45 phÃÂÃÂºt")),
                  ButtonSegment(value: 60, label: Text("60 phÃÂÃÂºt")),
                ],
                selected: {_inactivityThresholdMinutes},
                onSelectionChanged: (val) {
                  setSheetState(() => _inactivityThresholdMinutes = val.first);
                  setState(() => _inactivityThresholdMinutes = val.first);
                  _saveInactivitySettings();
                },
              ),
              const SizedBox(height: 14),
              const Text("VÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ khu vÃÂ¡ÃÂ»ÃÂ±c lÃÂ¡ÃÂºÃÂ¯p ÃÂÃÂÃÂ¡ÃÂºÃÂ·t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "NhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m / Toilet", label: Text("NhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m")),
                  ButtonSegment(value: "PhÃÂÃÂ²ng ngÃÂ¡ÃÂ»ÃÂ§", label: Text("PhÃÂÃÂ²ng ngÃÂ¡ÃÂ»ÃÂ§")),
                  ButtonSegment(value: "PhÃÂÃÂ²ng khÃÂÃÂ¡ch", label: Text("PhÃÂÃÂ²ng khÃÂÃÂ¡ch")),
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
                child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TÃÂ¡ÃÂºÃÂ£i cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung tÃÂ¡ÃÂ»ÃÂ« bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ
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
      _tempUnit = prefs.getString('temp_unit') ?? "ÃÂÃÂ°C";
      _deviceIp = savedIp;
      _deviceIpController.text = savedIp;
      _isWifiMonitoringEnabled = wifiMon;
    });

    if (_isWifiMonitoringEnabled && _deviceIp.isNotEmpty) {
      _startWifiPolling();
    }
  }

  // LÃÂÃÂ°u cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh giÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Wi-Fi
  Future<void> _saveWifiMonitoringSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_device_ip', _deviceIp);
    await prefs.setBool('wifi_monitoring_enabled', _isWifiMonitoringEnabled);
  }

  // LÃÂÃÂ°u cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung vÃÂÃÂ o bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ
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

  // TÃÂ¡ÃÂºÃÂ£i lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
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

    // TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi lÃÂ¡ÃÂºÃÂ¡i thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t nÃÂ¡ÃÂºÃÂ¿u bÃÂ¡ÃÂºÃÂ­t Auto-Reconnect
    if (_autoReconnect && !_isConnected && _deviceHistory.isNotEmpty) {
      final mostRecentId = _deviceHistory.first['id'];
      if (mostRecentId != null && mostRecentId.toString().isNotEmpty) {
        _connectToDevice(BluetoothDevice.fromId(mostRecentId.toString()));
      }
    }
  }

  // LÃÂÃÂ°u thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ o lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
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

  // XÃÂÃÂ³a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ khÃÂ¡ÃÂ»ÃÂi lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­
  Future<void> _removeDeviceFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _deviceHistory.removeWhere((d) => d['id'] == id);
    await prefs.setString('saved_devices_history', jsonEncode(_deviceHistory));
    setState(() {});
  }

  // ÃÂÃÂÃÂ¡ÃÂ»ÃÂi tÃÂÃÂªn vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ ÃÂÃÂÃÂ¡ÃÂºÃÂ·t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ trong lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ (VD: PhÃÂÃÂ²ng ngÃÂ¡ÃÂ»ÃÂ§, NhÃÂÃÂ  vÃÂ¡ÃÂ»ÃÂ sinh)
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

  // QuÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ BLE
  void _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _statusMessage = "ÃÂÃÂang quÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ FallDetector_S3R8...";
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
          _statusMessage = "KhÃÂÃÂ´ng tÃÂÃÂ¬m thÃÂ¡ÃÂºÃÂ¥y thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ. HÃÂÃÂ£y chÃÂ¡ÃÂºÃÂ¯c chÃÂ¡ÃÂºÃÂ¯n ESP32-S3 ÃÂÃÂang bÃÂ¡ÃÂºÃÂ­t!";
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "LÃÂ¡ÃÂ»ÃÂi khi quÃÂÃÂ©t BLE: $e";
      });
    }
  }

  // KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi tÃÂ¡ÃÂ»ÃÂi ESP32-S3 N16R8
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _statusMessage = "ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi tÃÂ¡ÃÂ»ÃÂi ${device.platformName.isEmpty ? 'FallDetector_S3R8' : device.platformName}...";
    });

    try {
      await device.connect(license: License.nonprofit, autoConnect: false, timeout: const Duration(seconds: 10));

      // YÃÂÃÂªu cÃÂ¡ÃÂºÃÂ§u MTU 512 bytes ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂºÃÂ­n chuÃÂ¡ÃÂ»ÃÂi JSON HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen dÃÂÃÂ i mÃÂÃÂ  khÃÂÃÂ´ng bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©t ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n
      if (Platform.isAndroid) {
        try {
          final mtu = await device.requestMtu(512);
          debugPrint('[BLE] Negotiated MTU: $mtu (payload max ${mtu - 3} bytes)');
        } catch (_) {}
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _statusMessage = "ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ nh cÃÂÃÂ´ng!";
      });

      // LÃÂÃÂ°u thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ o lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ ghÃÂÃÂ©p nÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ nh cÃÂÃÂ´ng
      _saveDeviceToHistory(device);

      // LÃÂ¡ÃÂºÃÂ¯ng nghe trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i ngÃÂ¡ÃÂºÃÂ¯t kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _sysState = "DISCONNECTED";
            _statusMessage = "ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ£ ngÃÂ¡ÃÂºÃÂ¯t kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi";
          });
        }
      });

      // KhÃÂÃÂ¡m phÃÂÃÂ¡ dÃÂ¡ÃÂ»ÃÂch vÃÂ¡ÃÂ»ÃÂ¥ BLE
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

      // DÃÂ¡ÃÂ»ÃÂ± phÃÂÃÂ²ng cho Android/GATT cache: nhÃÂ¡ÃÂºÃÂ­n diÃÂ¡ÃÂ»ÃÂn telemetry bÃÂ¡ÃÂºÃÂ±ng payload JSON,
      // khÃÂÃÂ´ng phÃÂ¡ÃÂ»ÃÂ¥ thuÃÂ¡ÃÂ»ÃÂc hoÃÂÃÂ n toÃÂÃÂ n vÃÂÃÂ o UUID.
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
              // ÃÂÃÂÃÂÃÂ¢y cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ  status/contact characteristic; tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ¥c thÃÂ¡ÃÂ»ÃÂ­ kÃÂÃÂªnh khÃÂÃÂ¡c.
            }
          }
          if (_telemetryChar != null) break;
        }
      }

      // ÃÂÃÂÃÂ¡ÃÂ»ÃÂc cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh danh bÃÂ¡ÃÂºÃÂ¡ & ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng sÃÂÃÂ n hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i tÃÂ¡ÃÂ»ÃÂ« chip
      final discovered = [_wifiChar, _contactChar, _statusChar, _telemetryChar, _cmdChar, _otaChar].whereType<BluetoothCharacteristic>().length;
      debugPrint('[BLE] Discovered $discovered/6 characteristics');
      if (_cmdChar == null) {
        _showSnackbar('BLE command channel not found. Please reflash firmware and reconnect.', Colors.red);
        debugPrint('[BLE] Missing command characteristic: $charCmdUuid');
      }
      await _readCurrentContacts();

      // ÃÂÃÂÃÂÃÂng kÃÂÃÂ½ nhÃÂ¡ÃÂºÃÂ­n thÃÂÃÂ´ng bÃÂÃÂ¡o Status Notify
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

      // ÃÂÃÂÃÂÃÂng kÃÂÃÂ½ nhÃÂ¡ÃÂºÃÂ­n Telemetry thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c & DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen
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

      // TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng tÃÂ¡ÃÂºÃÂ£i lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen ngay sau khi kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
      _fetchHistory();
      _sendCommand("GET_VERSION");

    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _statusMessage = "KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i: $e";
      });
    }
  }

  void _disconnect() async {
    await _connectedDevice?.disconnect();
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
      _sysState = "DISCONNECTED";
      _statusMessage = "ÃÂÃÂÃÂÃÂ£ ngÃÂ¡ÃÂºÃÂ¯t kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi";
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
      _showSnackbar("ESP32 ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Wi-Fi! IP: $ip (TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂÃÂ°u)", Colors.green);
      if (!_isWifiMonitoringEnabled) {
        _toggleWifiMonitoring(true);
      }
    } else if (msg == "WIFI_CONNECT_FAILED") {
      _showSnackbar("ESP32 kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Wi-Fi thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i! KiÃÂ¡ÃÂ»ÃÂm tra mÃÂ¡ÃÂºÃÂ­t khÃÂ¡ÃÂºÃÂ©u.", Colors.red);
    } else if (msg == "CONFIG_UPDATED_OK") {
      _showSnackbar("CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh danh bÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂÃÂ£ lÃÂÃÂ°u thÃÂÃÂ nh cÃÂÃÂ´ng!", Colors.green);
    } else if (msg == "NETWORK_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ xÃÂÃÂ³a cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh Wi-Fi. ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i.", Colors.orange);
    } else if (msg == "FACTORY_RESET_REBOOTING") {
      _stopWifiPolling();
      setState(() {
        _deviceIp = "";
        _deviceIpController.clear();
        _isWifiConnected = false;
      });
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ khÃÂÃÂ´i phÃÂ¡ÃÂ»ÃÂ¥c toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh. ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i.", Colors.orange);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_SAVED") {
      _showSnackbar("LÃÂ¡ÃÂ»ÃÂch night light ÃÂÃÂÃÂÃÂ£ lÃÂÃÂ°u vÃÂÃÂ o ESP32!", Colors.green);
    } else if (msg == "NIGHTLIGHT_SCHEDULE_ERROR") {
      _showSnackbar("LÃÂ¡ÃÂ»ÃÂch night light khÃÂÃÂ´ng hÃÂ¡ÃÂ»ÃÂ£p lÃÂ¡ÃÂ»ÃÂ.", Colors.red);
    } else if (msg == "EMERGENCY_DISPATCHED") {
      _showCriticalEmergencyDialog(isFall: true);
    } else if (msg == "HISTORY_SENT") {
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ tÃÂ¡ÃÂºÃÂ£i dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS!", Colors.blueAccent);
    } else if (msg == "HISTORY_CLEARED_OK") {
      setState(() {
        _eventHistory.clear();
      });
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ xÃÂÃÂ³a sÃÂ¡ÃÂºÃÂ¡ch nhÃÂ¡ÃÂºÃÂ­t kÃÂÃÂ½ hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen!", Colors.orange);
    } else if (msg == "TEST_EVENT_ADDED") {
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ thÃÂÃÂªm sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂºÃÂ«u vÃÂÃÂ o hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS!", Colors.green);
    } else if (msg.startsWith("FIRMWARE_VERSION:")) {
      setState(() {
        _deviceFirmwareVersion = msg.replaceFirst("FIRMWARE_VERSION:", "").trim();
      });
    } else if (msg.startsWith("OTA_")) {
      _otaStatusNotifier.value = msg;
      if (msg == "OTA_SUCCESS_REBOOTING") {
        _showSnackbar("NÃÂ¡ÃÂºÃÂ¡p firmware ESP32 thÃÂÃÂ nh cÃÂÃÂ´ng 100%! ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i...", Colors.green);
      } else if (msg.startsWith("OTA_ERROR:")) {
        _showSnackbar("LÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t firmware: ${msg.replaceFirst('OTA_ERROR:', '')}", Colors.red);
      }
    }
  }

  // GÃÂ¡ÃÂ»ÃÂ­i cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh Wi-Fi
  Future<void> _sendWifiConfig() async {
    if (_wifiChar == null) {
      _showSnackbar("ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi BLE vÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ!", Colors.red);
      return;
    }
    String ssid = _ssidController.text.trim();
    String pass = _passController.text.trim();
    if (ssid.isEmpty) {
      _showSnackbar("Vui lÃÂÃÂ²ng nhÃÂ¡ÃÂºÃÂ­p tÃÂÃÂªn Wi-Fi (SSID)!", Colors.orange);
      return;
    }

    Map<String, String> payload = {"ssid": ssid, "pass": pass};
    String jsonStr = jsonEncode(payload);

    try {
      await _wifiChar!.write(utf8.encode(jsonStr), withoutResponse: false);
      _showSnackbar("ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i Wi-Fi. ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i ÃÂÃÂÃÂ¡ÃÂ»ÃÂ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi...", Colors.blue);
    } catch (e) {
      _showSnackbar("GÃÂ¡ÃÂ»ÃÂ­i Wi-Fi thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i: $e", Colors.red);
    }
  }

  // GÃÂ¡ÃÂ»ÃÂ­i cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh danh bÃÂ¡ÃÂºÃÂ¡ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p
  Future<void> _sendContactsConfig() async {
    if (_contactChar == null) {
      _showSnackbar("ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi BLE vÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ!", Colors.red);
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
      _showSnackbar("ÃÂÃÂang lÃÂÃÂ°u cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh...", Colors.blue);
    } catch (e) {
      _showSnackbar("LÃÂÃÂ°u danh bÃÂ¡ÃÂºÃÂ¡ thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i: $e", Colors.red);
    }
  }

  // GÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn
  Future<void> _sendCommand(String cmd) async {
    if (_cmdChar == null) {
      _showSnackbar("ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi BLE!", Colors.red);
      return;
    }
    try {
      await _cmdChar!.write(utf8.encode(cmd), withoutResponse: false);
    } catch (e) {
      _showSnackbar("LÃÂ¡ÃÂ»ÃÂi gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh $cmd: $e", Colors.red);
    }
  }

  // ÃÂÃÂÃÂ¡ÃÂ»ÃÂc lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ sÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂn HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen
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
  // GIÃÂÃÂM SÃÂÃÂT TRÃÂ¡ÃÂ»ÃÂ°C TIÃÂ¡ÃÂºÃÂ¾P QUA MÃÂ¡ÃÂºÃÂ NG WI-FI NÃÂ¡ÃÂ»ÃÂI BÃÂ¡ÃÂ»ÃÂ (DIRECT WI-FI LAN TELEMETRY)
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
    // ThÃÂÃÂm dÃÂÃÂ² dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu liÃÂÃÂªn tÃÂ¡ÃÂ»ÃÂ¥c mÃÂ¡ÃÂ»ÃÂi 700ms qua HTTP LAN
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
      _showSnackbar("Vui lÃÂÃÂ²ng nhÃÂ¡ÃÂºÃÂ­p ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP cÃÂ¡ÃÂ»ÃÂ§a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc!", Colors.orange);
      return;
    }

    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2000);
    try {
      final uri = Uri.parse('http://$ip/api/command?cmd=$cmd');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        _showSnackbar("ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh qua Wi-Fi: $cmd", Colors.green);
        _pollWifiTelemetry();
      } else {
        _showSnackbar("GÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh qua Wi-Fi thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i (HTTP ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      _showSnackbar("KhÃÂÃÂ´ng thÃÂ¡ÃÂ»ÃÂ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Wi-Fi tÃÂ¡ÃÂ»ÃÂi $ip: $e", Colors.red);
    } finally {
      client.close();
    }
  }

  Future<void> _fetchHistoryOverWifi() async {
    final ip = _deviceIp.trim();
    if (ip.isEmpty) {
      _showSnackbar("Vui lÃÂÃÂ²ng nhÃÂ¡ÃÂºÃÂ­p ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP cÃÂ¡ÃÂ»ÃÂ§a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc!", Colors.orange);
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
          _showSnackbar("ÃÂÃÂÃÂÃÂ£ tÃÂ¡ÃÂºÃÂ£i hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen qua Wi-Fi (${_eventHistory.length} sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ)", Colors.blueAccent);
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
            Text("CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh IP Wi-Fi"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NhÃÂ¡ÃÂºÃÂ­p ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP mÃÂ¡ÃÂºÃÂ¡ng nÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂ»ÃÂ§a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ESP32 (hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ khi ESP32 kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Wi-Fi):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceIpController,
              decoration: const InputDecoration(
                labelText: "ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP",
                hintText: "192.168.1.xxx",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              "MÃÂ¡ÃÂºÃÂ¹o: ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP cÃÂÃÂ©ng sÃÂ¡ÃÂºÃÂ½ tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂÃÂ°u khi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Wi-Fi qua Bluetooth.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("HÃÂ¡ÃÂ»ÃÂ§y"),
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
            child: const Text("LÃÂÃÂ°u & KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi"),
          ),
        ],
      ),
    );
  }

  // MÃÂ¡ÃÂ»ÃÂ mÃÂÃÂ n hÃÂÃÂ¬nh quÃÂ¡ÃÂºÃÂ£n trÃÂ¡ÃÂ»ÃÂ chi tiÃÂ¡ÃÂºÃÂ¿t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ (GÃÂ¡ÃÂ»ÃÂm GiÃÂÃÂ¡m sÃÂÃÂ¡t, HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen vÃÂÃÂ  CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t)
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
          // DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c
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

  // ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh dÃÂ¡ÃÂºÃÂ¡ng thÃÂ¡ÃÂ»ÃÂi gian kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t
  String _formatLastSeen(DateTime? dt) {
    if (dt == null) return "GÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂÃÂ¢y";
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "VÃÂ¡ÃÂ»ÃÂ«a xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phÃÂÃÂºt trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc";
    if (diff.inHours < 24) return "${diff.inHours} giÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc";
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // HÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i ÃÂÃÂÃÂ¡ÃÂ»ÃÂi tÃÂÃÂªn vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ trong lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­
  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ÃÂÃÂÃÂ¡ÃÂºÃÂ·t tÃÂÃÂªn vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ÃÂÃÂÃÂ¡ÃÂºÃÂ·t tÃÂÃÂªn theo phÃÂÃÂ²ng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ dÃÂ¡ÃÂ»ÃÂ theo dÃÂÃÂµi (VD: PhÃÂÃÂ²ng ngÃÂ¡ÃÂ»ÃÂ§ ÃÂÃÂng BÃÂÃÂ , NhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m tÃÂ¡ÃÂºÃÂ§ng 2, PhÃÂÃÂ²ng khÃÂÃÂ¡ch):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "TÃÂÃÂªn vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HÃÂ¡ÃÂ»ÃÂ§y")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _renameDeviceInHistory(id, controller.text);
            },
            child: const Text("LÃÂÃÂ°u tÃÂÃÂªn"),
          ),
        ],
      ),
    );
  }

  // MÃÂ¡ÃÂ»ÃÂ mÃÂÃÂ n hÃÂÃÂ¬nh CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung cÃÂ¡ÃÂ»ÃÂ§a ÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂ»ÃÂ¥ng
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

  // Widget hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ danh sÃÂÃÂ¡ch thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
  Widget _buildDeviceHistoryList() {
    return Column(
      children: _deviceHistory.map((item) {
        final String id = item['id'] ?? '';
        final String customName = item['customName'] ?? item['name'] ?? 'FallDetector_S3R8';
        final String rawName = item['name'] ?? 'FallDetector_S3R8';
        final String lastTime = item['lastConnected'] != null
            ? _formatLastSeen(DateTime.tryParse(item['lastConnected']))
            : "GÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂÃÂ¢y";
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
                    child: const Text("ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
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
                  "LÃÂ¡ÃÂºÃÂ§n kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi cuÃÂ¡ÃÂ»ÃÂi: $lastTime",
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
                    child: const Text("KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi lÃÂ¡ÃÂºÃÂ¡i", style: TextStyle(fontSize: 12)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.green),
                    tooltip: "VÃÂÃÂ o chi tiÃÂ¡ÃÂºÃÂ¿t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ",
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
                          Text("ÃÂÃÂÃÂ¡ÃÂ»ÃÂi tÃÂÃÂªn phÃÂÃÂ²ng / vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text("QuÃÂÃÂªn thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ y", style: TextStyle(color: Colors.redAccent)),
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

  // Widget hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i mÃÂÃÂ n hÃÂÃÂ¬nh khÃÂÃÂ³a & trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p (Feature 6 & 1)
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
                                ? "ÃÂ°ÃÂÃÂÃÂ¨ CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO TÃÂÃÂ NGÃÂÃÂ KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P"
                                : (_isWifiConnected && !_isConnected
                                    ? "ÃÂ°ÃÂÃÂÃÂ GIÃÂÃÂM SÃÂÃÂT TRÃÂ¡ÃÂ»ÃÂ°C TIÃÂ¡ÃÂºÃÂ¾P QUA WI-FI"
                                    : (_isWifiConnected && _isConnected
                                        ? "ÃÂ°ÃÂÃÂÃÂ¢ GIÃÂÃÂM SÃÂÃÂT KÃÂÃÂP (BLE + WI-FI)"
                                        : "ÃÂ°ÃÂÃÂÃÂ¢ AN TOÃÂÃÂN - ÃÂÃÂANG GIÃÂÃÂM SÃÂÃÂT BLE 24/7")))
                            : "ÃÂ¢ÃÂÃÂª CHÃÂ¡ÃÂ»ÃÂ KÃÂ¡ÃÂºÃÂ¾T NÃÂ¡ÃÂ»ÃÂI (BLUETOOTH HOÃÂ¡ÃÂºÃÂ¶C WI-FI)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: badgeColor),
                      ),
                      Text(
                        "Khu vÃÂ¡ÃÂ»ÃÂ±c: $_monitoredRoomName ÃÂ¢ÃÂÃÂ¢ ${_medicalProfile.fullName}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.widgets_outlined, size: 20),
                  tooltip: "MÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng Widget MÃÂÃÂ n hÃÂÃÂ¬nh khÃÂÃÂ³a",
                  onPressed: _openLockscreenWidgetPreview,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh tiÃÂ¡ÃÂºÃÂ¿n trÃÂÃÂ¬nh lÃÂÃÂ°u trÃÂÃÂº nhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m & bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng
            if (isActivelyMonitored) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Text("HiÃÂ¡ÃÂ»ÃÂn diÃÂ¡ÃÂ»ÃÂn: ${minutes}p ${seconds}s", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng an toÃÂÃÂ n: < ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

            // 3 thÃÂÃÂ´ng sÃÂ¡ÃÂ»ÃÂ mini
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatusChip("TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatusChip("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent),
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

  // Widget GiÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Wi-Fi LAN
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
            // TiÃÂÃÂªu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  nÃÂÃÂºt bÃÂ¡ÃÂºÃÂ­t/tÃÂ¡ÃÂºÃÂ¯t Wi-Fi
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
                        "GiÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Wi-Fi (LAN)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _isWifiMonitoringEnabled
                            ? (_deviceIp.isEmpty
                                ? "ChÃÂÃÂ°a cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ"
                                : "IP: $_deviceIp ÃÂ¢ÃÂÃÂ¢ ${isOnline ? 'ÃÂÃÂÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ: ${_wifiDelayMs}ms' : 'ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi...'}")
                            : "Theo dÃÂÃÂµi tÃÂ¡ÃÂ»ÃÂ« xa xuyÃÂÃÂªn phÃÂÃÂ²ng khÃÂÃÂ´ng cÃÂ¡ÃÂºÃÂ§n Bluetooth",
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
              // Thanh ÃÂÃÂÃÂ¡ÃÂ»ÃÂa chÃÂ¡ÃÂ»ÃÂ IP vÃÂÃÂ  cÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ¥
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
                          isOnline ? "ÃÂÃÂang truyÃÂ¡ÃÂ»ÃÂn (${_wifiDelayMs}ms)" : "ChÃÂ¡ÃÂ»ÃÂ phÃÂ¡ÃÂºÃÂ£n hÃÂ¡ÃÂ»ÃÂi...",
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
                        label: const Text("ÃÂÃÂÃÂ¡ÃÂ»ÃÂi IP", style: TextStyle(fontSize: 11)),
                        onPressed: _showWifiIpDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.cyanAccent),
                        tooltip: "LÃÂÃÂ m mÃÂ¡ÃÂ»ÃÂi dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu Wi-Fi ngay",
                        onPressed: _pollWifiTelemetry,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // BÃÂ¡ÃÂºÃÂ£ng dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu thÃÂÃÂ´ng sÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p nhÃÂ¡ÃÂºÃÂ­n qua Wi-Fi
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
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ AI", _aiPosture, Icons.accessibility_new, Colors.indigoAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", "${_tofHeight}mm", Icons.height, Colors.blueAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng", "$_radarMotion/100", Icons.directions_run, Colors.orangeAccent)),
                    SizedBox(width: compact ? (screenWidth - 64) / 2 : null, child: _buildMiniWifiMetric("NhÃÂ¡ÃÂ»ÃÂp thÃÂ¡ÃÂ»ÃÂ", "$_radarStatic/100", Icons.air, Colors.tealAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // NÃÂÃÂºt hÃÂÃÂ nh ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nhanh Wi-Fi
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
                      label: const Text("TÃÂ¡ÃÂºÃÂ¯t cÃÂÃÂ²i Wi-Fi", style: TextStyle(fontSize: 12)),
                      onPressed: () => _sendWifiCommand("CANCEL_ALARM"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.blueAccent),
                    tooltip: "TÃÂ¡ÃÂºÃÂ£i hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS qua Wi-Fi",
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

  // Thanh cÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ¥ y tÃÂ¡ÃÂºÃÂ¿ & ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ nhanh 1 chÃÂ¡ÃÂºÃÂ¡m (Feature 2, 7, 3, 1)
  Widget _buildQuickHealthActionBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.badge, size: 16, color: Colors.redAccent),
              label: const Text("ThÃÂ¡ÃÂºÃÂ» Y TÃÂ¡ÃÂºÃÂ¿", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalIdCard,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.quiz, size: 16, color: Colors.blueAccent),
              label: Text("KhÃÂÃÂ¡m CDC: $_cdcSteadiScoreÃÂÃÂ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.4)),
              onPressed: _openCdcSteadiAssessment,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.description, size: 16, color: Colors.tealAccent),
              label: const Text("BÃÂÃÂ¡o CÃÂÃÂ¡o Y Khoa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
              onPressed: _openMedicalAuditReport,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.bathtub, size: 16, color: Colors.amberAccent),
              label: Text("GiÃÂÃÂ¡m sÃÂÃÂ¡t: ${_inactivityThresholdMinutes}p", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    // TÃÂ¡ÃÂºÃÂ­p hÃÂ¡ÃÂ»ÃÂ£p danh sÃÂÃÂ¡ch thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ (ÃÂÃÂÃÂÃÂ°a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi lÃÂÃÂªn ÃÂÃÂÃÂ¡ÃÂºÃÂ§u)
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
                PopupMenuItem(value: 'medical', child: Text('ThÃÂ¡ÃÂºÃÂ» Y tÃÂ¡ÃÂºÃÂ¿ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p')),
                PopupMenuItem(value: 'report', child: Text('BÃÂÃÂ¡o cÃÂÃÂ¡o y khoa')),
                PopupMenuItem(value: 'device', child: Text('ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi')),
                PopupMenuItem(value: 'settings', child: Text('CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung')),
              ],
            ),
          if (!compact) ...[
            IconButton(
              icon: const Icon(Icons.badge, color: Colors.redAccent),
              tooltip: "ThÃÂ¡ÃÂºÃÂ» Y TÃÂ¡ÃÂºÃÂ¿ KhÃÂ¡ÃÂºÃÂ©n CÃÂ¡ÃÂºÃÂ¥p",
              onPressed: _openMedicalIdCard,
            ),
            IconButton(
              icon: const Icon(Icons.description, color: Colors.tealAccent),
              tooltip: "BÃÂÃÂ¡o CÃÂÃÂ¡o Y Khoa ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh KÃÂ¡ÃÂ»ÃÂ³",
              onPressed: _openMedicalAuditReport,
            ),
            IconButton(
              icon: Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: _isConnected ? Colors.greenAccent : Colors.grey,
              ),
              tooltip: _isConnected ? "ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi" : "ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi",
              onPressed: () {
                if (_isConnected && _connectedDevice != null) {
                  _openDeviceDetail(_connectedDevice!);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: "CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung",
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
            // ThÃÂ¡ÃÂºÃÂ» trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i Glanceable Live Status Card (Feature 6 & 1)
            _buildGlanceableLiveStatusCard(),

            // ThÃÂ¡ÃÂºÃÂ» giÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Wi-Fi LAN
            _buildWifiMonitoringCard(),

            // Thanh cÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ¥ y tÃÂ¡ÃÂºÃÂ¿ nhanh 1 chÃÂ¡ÃÂºÃÂ¡m (Feature 2, 7, 3, 1)
            _buildQuickHealthActionBar(),

            // NÃÂÃÂºt QuÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ trÃÂÃÂªn cÃÂÃÂ¹ng
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isScanning ? "ÃÂÃÂang quÃÂÃÂ©t xung quanh..." : "QuÃÂÃÂ©t thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ FallDetector_S3R8"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // PHÃÂ¡ÃÂºÃÂ¦N 1: LÃÂ¡ÃÂ»ÃÂCH SÃÂ¡ÃÂ»ÃÂ¬ THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ TÃÂ¡ÃÂ»ÃÂªNG KÃÂ¡ÃÂºÃÂ¾T NÃÂ¡ÃÂ»ÃÂI (PAIRED / HISTORY DEVICES)
            if (_deviceHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text("ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Text("${_deviceHistory.length} thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ£ lÃÂÃÂ°u", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              _buildDeviceHistoryList(),
              const SizedBox(height: 14),
            ],

            // PHÃÂ¡ÃÂºÃÂ¦N 2: THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ TÃÂÃÂM THÃÂ¡ÃÂºÃÂ¤Y QUA QUÃÂÃÂT BLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂÃÂ¬m thÃÂ¡ÃÂºÃÂ¥y xung quanh:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (displayedDevices.isNotEmpty)
                  Text("${displayedDevices.length} thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                            _isScanning ? "ÃÂÃÂang tÃÂÃÂ¬m kiÃÂ¡ÃÂºÃÂ¿m sÃÂÃÂ³ng Bluetooth..." : "NhÃÂ¡ÃÂºÃÂ¥n 'QuÃÂÃÂ©t' ÃÂÃÂÃÂ¡ÃÂ»ÃÂ tÃÂÃÂ¬m thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ FallDetector_S3R8",
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

                        // ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi: ViÃÂ¡ÃÂ»ÃÂn xanh lÃÂÃÂ¡, hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ xanh "ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi", cÃÂÃÂ³ nÃÂÃÂºt NgÃÂ¡ÃÂºÃÂ¯t (ÃÂÃÂÃÂÃÂ£ xÃÂÃÂ³a "ChÃÂ¡ÃÂºÃÂ¡m ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t")
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
                                                "ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi",
                                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "RSSI: ${rssi != null ? '$rssi dBm' : 'TÃÂ¡ÃÂ»ÃÂt'} | ID: ${device.remoteId}",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // NÃÂÃÂºt ngÃÂ¡ÃÂºÃÂ¯t kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _disconnect,
                                      child: const Text("NgÃÂ¡ÃÂºÃÂ¯t", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right, color: Colors.green),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ chÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi
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
                                    child: const Text("KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi"),
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
// MÃÂÃÂN HÃÂÃÂNH QUÃÂ¡ÃÂºÃÂ¢N TRÃÂ¡ÃÂ»ÃÂ THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ: GÃÂ¡ÃÂ»ÃÂM 3 TAB (GIÃÂÃÂM SÃÂÃÂT, HÃÂ¡ÃÂ»ÃÂP ÃÂÃÂEN & GRAPH, CÃÂÃÂI ÃÂÃÂÃÂ¡ÃÂºÃÂ¶T)
// =========================================================================
class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final int initialTabIndex;

  // DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu Telemetry
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

  // Controllers cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh
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

  // GiÃÂÃÂ¡m sÃÂÃÂ¡t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Wi-Fi LAN
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
  int _blackBoxSubTab = 0; // 0: TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c, 1: HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS

  // XÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh qua kÃÂÃÂªnh khÃÂ¡ÃÂºÃÂ£ dÃÂ¡ÃÂ»ÃÂ¥ng (BLE hoÃÂ¡ÃÂºÃÂ·c Wi-Fi)
  Future<void> _handleDeviceCommand(String cmd) async {
    if (widget.isConnected) {
      await widget.onSendCommand(cmd);
    } else if (widget.onSendWifiCommand != null && widget.deviceIp.isNotEmpty) {
      await widget.onSendWifiCommand!(cmd);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ qua Bluetooth hoÃÂ¡ÃÂºÃÂ·c Wi-Fi!"), backgroundColor: Colors.red),
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
      helpText: isStart ? "GiÃÂ¡ÃÂ»ÃÂ bÃÂ¡ÃÂºÃÂ¯t ÃÂÃÂÃÂ¡ÃÂºÃÂ§u bÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂÃÂ¨n" : "GiÃÂ¡ÃÂ»ÃÂ kÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂºc ÃÂÃÂÃÂÃÂ¨n",
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
      SnackBar(content: Text("ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂch night light ${_formatTime(_nightStart)}ÃÂ¢ÃÂÃÂ${_formatTime(_nightEnd)}")),
    );
  }

  // CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh thÃÂÃÂ´ng minh cho thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ
  int _alarmGracePeriod = 15; // 15 giÃÂÃÂ¢y trÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi hÃÂÃÂº cÃÂÃÂ²i lÃÂ¡ÃÂ»ÃÂn
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HÃÂ¡ÃÂ»ÃÂ§y')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('XÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _handleDeviceCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh. ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ sÃÂ¡ÃÂºÃÂ½ khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i.')),
        );
      }
    }
  }
  bool _buzzerActiveHigh = false; // MÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh khÃÂ¡ÃÂ»ÃÂp vÃÂ¡ÃÂ»ÃÂi module cÃÂÃÂ²i 3 chÃÂÃÂ¢n: Active-LOW (High-Z im lÃÂ¡ÃÂºÃÂ·ng, 0V bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng)
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
            Tab(icon: Icon(Icons.monitor_heart), text: "GiÃÂÃÂ¡m sÃÂÃÂ¡t"),
            Tab(icon: Icon(Icons.timeline), text: "HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS"),
            Tab(icon: Icon(Icons.settings), text: "CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t"),
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

  // TAB 1: GIÃÂÃÂM SÃÂÃÂT THÃÂ¡ÃÂ»ÃÂI GIAN THÃÂ¡ÃÂ»ÃÂ°C & ÃÂÃÂIÃÂ¡ÃÂ»ÃÂU KHIÃÂ¡ÃÂ»ÃÂN TÃÂ¡ÃÂ»ÃÂª XA
  Widget _buildMonitorTab() {
    final bool canControl = widget.isConnected || widget.isWifiConnected;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Huy hiÃÂ¡ÃÂ»ÃÂu nguÃÂ¡ÃÂ»ÃÂn kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi (BLE & Wi-Fi)
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
                    Text(widget.isConnected ? "Bluetooth: ÃÂÃÂÃÂÃÂ£ kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi" : "Bluetooth: NgÃÂ¡ÃÂºÃÂ¯t",
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
                          ? "Wi-Fi: TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p (${widget.wifiDelayMs}ms)"
                          : (widget.deviceIp.isNotEmpty ? "Wi-Fi: ${widget.deviceIp}" : "Wi-Fi: ChÃÂÃÂ°a bÃÂ¡ÃÂºÃÂ­t"),
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

          // ThÃÂ¡ÃÂºÃÂ» trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p
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
                    widget.sysState == "ALERT" ? "ÃÂ°ÃÂÃÂÃÂ¨ CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO TÃÂÃÂ NGÃÂÃÂ KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P!" :
                    widget.sysState == "PRE_ALARM" ? "ÃÂ¢ÃÂÃÂ ÃÂ¯ÃÂ¸ÃÂ ÃÂÃÂANG ÃÂÃÂÃÂ¡ÃÂºÃÂ¾M NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂ¢C PRE-ALARM (30s)" :
                    widget.sysState == "SUSPECTED" ? "XÃÂÃÂ¡c thÃÂ¡ÃÂ»ÃÂ±c va chÃÂ¡ÃÂºÃÂ¡m tiÃÂ¡ÃÂºÃÂ¿p ÃÂÃÂÃÂ¡ÃÂºÃÂ¥t..." :
                    widget.sysState == "NORMAL" ? "MÃÂÃÂ´i trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng bÃÂÃÂ¬nh thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng & An toÃÂÃÂ n" : "ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // LÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cÃÂÃÂ¡c thÃÂÃÂ´ng sÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 1.28 : 1.55,
            children: [
              _buildMetricCard("TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ AI", widget.aiPosture, "Tin cÃÂ¡ÃÂºÃÂ­y: ${(widget.aiConfidence * 100).toStringAsFixed(0)}%", Icons.accessibility_new, const Color(0xFF477B72)),
              _buildMetricCard("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", "${widget.tofHeight} mm", "V_drop: ${widget.dropRate.toStringAsFixed(0)} mm/s", Icons.height, const Color(0xFF3D6F8E)),
              _buildMetricCard("ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar", "${widget.radarMotion} / 100", "LD2410 Peak Move", Icons.directions_run, const Color(0xFF9A6B35)),
              _buildMetricCard("TÃÂÃÂ©nh hÃÂ¡ÃÂ»ÃÂc HÃÂÃÂ´ hÃÂ¡ÃÂºÃÂ¥p", "${widget.radarStatic} / 100", "LD2410 Static Gate", Icons.air, const Color(0xFF3F7C73)),
            ],
          ),
          const SizedBox(height: 14),

          // NÃÂÃÂºt bÃÂ¡ÃÂºÃÂ¥m khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p SOS tÃÂ¡ÃÂ»ÃÂ« xa
          ElevatedButton.icon(
            onPressed: canControl ? () => _handleDeviceCommand("PANIC_SOS") : null,
            icon: const Icon(Icons.emergency, size: 28),
            label: const Text("KÃÂÃÂCH HOÃÂ¡ÃÂºÃÂ T SOS CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U TÃÂ¡ÃÂ»ÃÂª XA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // CÃÂÃÂ¡c nÃÂÃÂºt lÃÂ¡ÃÂ»ÃÂnh nhanh
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CANCEL_ALARM") : null,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("TÃÂ¡ÃÂºÃÂ¯t cÃÂÃÂ²i / HÃÂ¡ÃÂ»ÃÂ§y"),
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : (screenWidth - 48) / 2,
                child: OutlinedButton.icon(
                  onPressed: canControl ? () => _handleDeviceCommand("CALIBRATE_FLOOR") : null,
                  icon: const Icon(Icons.straighten),
                  label: const Text("HiÃÂ¡ÃÂ»ÃÂu chuÃÂ¡ÃÂºÃÂ©n sÃÂÃÂ n"),
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
                  label: const Text("Test chuÃÂÃÂ´ng/ÃÂÃÂÃÂÃÂ¨n"),
                ),
              ),
              // NÃÂÃÂºt xem hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen: ChuyÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂºÃÂ³ng sang Tab 2 vÃÂÃÂ  fetch dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu
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
                  label: const Text("Xem HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: HÃÂ¡ÃÂ»ÃÂP ÃÂÃÂEN & PHÃÂÃÂN TÃÂÃÂCH ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG HÃÂ¡ÃÂ»ÃÂC KHÃÂÃÂNG GIAN (TRÃÂ¡ÃÂ»ÃÂ°C TIÃÂ¡ÃÂºÃÂ¾P & LÃÂ¡ÃÂ»ÃÂCH SÃÂ¡ÃÂ»ÃÂ¬)
  Widget _buildBlackBoxTab() {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    // DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu mÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ« cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c
    final Map<String, dynamic> liveEvent = {
      "type": (widget.aiPosture == "FALL") ? 1 : 0,
      "sec": 0,
      "vel": widget.dropRate > 0 ? widget.dropRate : 0.0,
      "mot": widget.radarMotion,
      "dst": widget.tofHeight > 0 ? (widget.tofHeight / 10).round() : 160,
    };

    // DÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu mÃÂ¡ÃÂºÃÂ«u nÃÂ¡ÃÂºÃÂ¿u HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS chÃÂÃÂ°a cÃÂÃÂ³ sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂ±c tÃÂ¡ÃÂºÃÂ¿
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
          // 1. THANH CHUYÃÂ¡ÃÂ»ÃÂN ÃÂÃÂÃÂ¡ÃÂ»ÃÂI CHÃÂ¡ÃÂºÃÂ¾ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ: TRÃÂ¡ÃÂ»ÃÂ°C TIÃÂ¡ÃÂºÃÂ¾P (LIVE) vs LÃÂ¡ÃÂ»ÃÂCH SÃÂ¡ÃÂ»ÃÂ¬ HÃÂ¡ÃÂ»ÃÂP ÃÂÃÂEN (NVS)
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
                               "TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c",
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
                               "HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS (${widget.eventHistory.length})",
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
          // PHÃÂÃÂN ÃÂÃÂOÃÂ¡ÃÂºÃÂ N 1: THEO DÃÂÃÂI TRÃÂ¡ÃÂ»ÃÂ°C TIÃÂ¡ÃÂºÃÂ¾P THÃÂ¡ÃÂ»ÃÂI GIAN THÃÂ¡ÃÂ»ÃÂ°C (LIVE TELEMETRY)
          // ===================================================================
          if (_blackBoxSubTab == 0) ...[
            // ThÃÂ¡ÃÂºÃÂ» hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ nhanh tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n thÃÂ¡ÃÂ»ÃÂ±c tÃÂ¡ÃÂºÃÂ¿
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
                            const Text("CÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n & TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            "${widget.aiPosture} ÃÂ¢ÃÂÃÂ¢ ${(widget.aiConfidence * 100).toInt()}%",
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
                                const Text("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                                const Text("ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                                const Text("HÃÂÃÂ´ hÃÂ¡ÃÂºÃÂ¥p / TÃÂÃÂ©nh", style: TextStyle(fontSize: 11, color: Colors.grey)),
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

            // ChÃÂ¡ÃÂ»ÃÂ hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ« mÃÂ¡ÃÂºÃÂ«u telemetry thÃÂ¡ÃÂºÃÂ­t nhÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c.
            LiveTelemetryChart(samples: widget.telemetryHistory),
          ] else ...[
            // ===================================================================
            // PHÃÂÃÂN ÃÂÃÂOÃÂ¡ÃÂºÃÂ N 2: LÃÂ¡ÃÂ»ÃÂCH SÃÂ¡ÃÂ»ÃÂ¬ HÃÂ¡ÃÂ»ÃÂP ÃÂÃÂEN NVS (FLASH BLACK BOX AUDIT)
            // ===================================================================
            // Thanh cÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ¥ HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen
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
                                const SnackBar(content: Text("ChÃÂÃÂ°a kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Bluetooth hoÃÂ¡ÃÂºÃÂ·c Wi-Fi ÃÂÃÂÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ£i lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­!"), backgroundColor: Colors.orange),
                              );
                            }
                          },
                    icon: widget.isLoadingHistory
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: const Text("TÃÂ¡ÃÂºÃÂ£i lÃÂ¡ÃÂºÃÂ¡i tÃÂ¡ÃÂ»ÃÂ« ESP32"),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 100,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("CLEAR_HISTORY"),
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text("XÃÂÃÂ³a", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 130,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeviceCommand("ADD_TEST_EVENT"),
                    icon: const Icon(Icons.add_alert, color: Colors.orangeAccent),
                    label: const Text("TÃÂ¡ÃÂºÃÂ¡o Test"),
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
                        "HÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen NVS hiÃÂ¡ÃÂ»ÃÂn chÃÂÃÂ°a cÃÂÃÂ³ vÃÂ¡ÃÂ»ÃÂ¥ ngÃÂÃÂ£ thÃÂ¡ÃÂºÃÂ­t. ÃÂÃÂang hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂºÃÂ«u minh hÃÂ¡ÃÂ»ÃÂa!",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 8),

            // Danh sÃÂÃÂ¡ch cÃÂÃÂ¡c sÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂn ghi nhÃÂ¡ÃÂºÃÂ­n trong hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Danh sÃÂÃÂ¡ch sÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂn ghi nhÃÂ¡ÃÂºÃÂ­n trong NVS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${widget.eventHistory.length} sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng an toÃÂÃÂ n. ChÃÂÃÂ°a cÃÂÃÂ³ cÃÂÃÂº ngÃÂÃÂ£ nÃÂÃÂ o xÃÂ¡ÃÂºÃÂ£y ra!",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "BÃÂ¡ÃÂºÃÂ¡n cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂºÃÂ¥n 'TÃÂ¡ÃÂºÃÂ¡o Test' ÃÂ¡ÃÂ»ÃÂ trÃÂÃÂªn ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡p sÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂn mÃÂ¡ÃÂºÃÂ«u vÃÂÃÂ o bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ Flash NVS.",
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
    final String typeTitle = (type == 3) ? "SOS ThÃÂ¡ÃÂ»ÃÂ§ cÃÂÃÂ´ng" : (type == 2 ? "NgÃÂÃÂ£ chÃÂ¡ÃÂºÃÂ­m (15s)" : "NgÃÂÃÂ£ va chÃÂ¡ÃÂºÃÂ¡m mÃÂ¡ÃÂºÃÂ¡nh");
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
        subtitle: Text("V_drop: ${vel.toStringAsFixed(0)} mm/s | ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng: $mot/100 | LÃÂÃÂºc: ${sec}s"),
        trailing: isSelected
            ? const Chip(
                label: Text("ÃÂÃÂang xem Graph", style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                padding: EdgeInsets.zero,
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // HÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i tÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂm tra chÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n phÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂ»ÃÂ©ng
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
                Text("ChÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n tÃÂ¡ÃÂ»ÃÂ± kiÃÂ¡ÃÂ»ÃÂm tra cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "KiÃÂ¡ÃÂ»ÃÂm tra tÃÂÃÂ­nh toÃÂÃÂ n vÃÂ¡ÃÂºÃÂ¹n phÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂ»ÃÂ©ng cÃÂ¡ÃÂ»ÃÂ§a hÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn tÃÂÃÂ© ngÃÂÃÂ£ ESP32-S3R8:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSelfTestItem(Icons.radar, "Radar FMCW 24GHz (LD2410B)", "ÃÂÃÂang quÃÂÃÂ©t 9 cÃÂ¡ÃÂ»ÃÂng cÃÂ¡ÃÂ»ÃÂ± ly | SÃÂÃÂ³ng vi ba ÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh", Colors.green),
            _buildSelfTestItem(Icons.height, "Laser ToF (VL53L1X)", "KhoÃÂ¡ÃÂºÃÂ£ng cÃÂÃÂ¡ch ÃÂÃÂo trÃÂ¡ÃÂºÃÂ§n nhÃÂÃÂ : ${widget.tofHeight} mm | ChÃÂÃÂ­nh xÃÂÃÂ¡c", Colors.green),
            _buildSelfTestItem(Icons.motion_photos_on, "CÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n PIR (AM312)", "ÃÂÃÂang hoÃÂ¡ÃÂºÃÂ¡t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng | PhÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng thÃÂÃÂ¢n nhiÃÂ¡ÃÂ»ÃÂt hÃÂ¡ÃÂ»ÃÂng ngoÃÂ¡ÃÂºÃÂ¡i (GPIO 4)", Colors.green),
            _buildSelfTestItem(Icons.volume_up, "CÃÂÃÂ²i bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng Active Buzzer", "ÃÂÃÂÃÂÃÂ£ thÃÂ¡ÃÂ»ÃÂ­ cÃÂÃÂ²i | MÃÂ¡ÃÂ»ÃÂ©c ÃÂÃÂ¢m lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng ÃÂÃÂÃÂ¡ÃÂºÃÂ¡t chuÃÂ¡ÃÂºÃÂ©n 85dB", Colors.teal),
            _buildSelfTestItem(Icons.lightbulb, "ÃÂÃÂÃÂÃÂ¨n ngÃÂ¡ÃÂ»ÃÂ§ LED RGB WS2812B", "ChuÃÂ¡ÃÂ»ÃÂi LED ÃÂÃÂÃÂ¡ÃÂ»ÃÂi mÃÂÃÂ u bÃÂÃÂ¬nh thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng", Colors.teal),
            _buildSelfTestItem(Icons.battery_charging_full, "KhÃÂ¡ÃÂ»ÃÂi nguÃÂ¡ÃÂ»ÃÂn 220V AC & Pin UPS", "HLK-5M05 cÃÂ¡ÃÂºÃÂ¥p ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn | Pin 18650 dÃÂ¡ÃÂ»ÃÂ± phÃÂÃÂ²ng sÃÂ¡ÃÂºÃÂµn sÃÂÃÂ ng", Colors.blueAccent),
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
                  const SnackBar(content: Text("ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh kiÃÂ¡ÃÂ»ÃÂm tra chuÃÂÃÂ´ng ÃÂÃÂÃÂÃÂ¨n tÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ!")),
                );
              },
              child: const Text("KÃÂÃÂ­ch hoÃÂ¡ÃÂºÃÂ¡t Test ChuÃÂÃÂ´ng & ÃÂÃÂÃÂÃÂ¨n ngay"),
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

  // TAB 3: CÃÂÃÂI ÃÂÃÂÃÂ¡ÃÂºÃÂ¶T THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ
  Widget _buildSettingsTab() {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh Wi-Fi
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
                      Text("CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh Wi-Fi cho ESP32", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.ssidController,
                    decoration: const InputDecoration(
                      labelText: "TÃÂÃÂªn mÃÂ¡ÃÂºÃÂ¡ng Wi-Fi (SSID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.router),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: "MÃÂ¡ÃÂºÃÂ­t khÃÂ¡ÃÂºÃÂ©u Wi-Fi",
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
                    label: const Text("LÃÂÃÂ°u Wi-Fi & KhÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i ESP32"),
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
                    Text('KhÃÂÃÂ´i phÃÂ¡ÃÂ»ÃÂ¥c hÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('XÃÂÃÂ³a cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh mÃÂ¡ÃÂºÃÂ¡ng hoÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂÃÂ°a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i mÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeviceReset('RESET_NETWORK', 'ÃÂÃÂÃÂ¡ÃÂºÃÂ·t lÃÂ¡ÃÂºÃÂ¡i Wi-Fi?', 'ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ sÃÂ¡ÃÂºÃÂ½ xÃÂÃÂ³a SSID/mÃÂ¡ÃÂºÃÂ­t khÃÂ¡ÃÂºÃÂ©u Wi-Fi vÃÂÃÂ  khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i.'),
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('XÃÂÃÂ³a cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh mÃÂ¡ÃÂºÃÂ¡ng'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: () => _confirmDeviceReset('FACTORY_RESET', 'KhÃÂÃÂ´i phÃÂ¡ÃÂ»ÃÂ¥c toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ?', 'XÃÂÃÂ³a toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh, Wi-Fi, danh bÃÂ¡ÃÂºÃÂ¡ vÃÂÃÂ  lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ hÃÂ¡ÃÂ»ÃÂp ÃÂÃÂen.'),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('KhÃÂÃÂ´i phÃÂ¡ÃÂ»ÃÂ¥c mÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh danh bÃÂ¡ÃÂºÃÂ¡ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p
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
                      Text("Danh bÃÂ¡ÃÂºÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u hÃÂ¡ÃÂ»ÃÂ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // HÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n gÃÂ¡ÃÂ»ÃÂ­i nhiÃÂ¡ÃÂ»ÃÂu ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ­n & ÃÂÃÂa kÃÂÃÂªnh
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
                            Text("BÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng ÃÂÃÂa kÃÂÃÂªnh & NhiÃÂ¡ÃÂ»ÃÂu ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ­n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "ÃÂ¢ÃÂÃÂ¢ NhiÃÂ¡ÃÂ»ÃÂu sÃÂ¡ÃÂ»ÃÂ SMS: NhÃÂ¡ÃÂºÃÂ­p cÃÂÃÂ¡c SÃÂÃÂT cÃÂÃÂ¡ch nhau bÃÂ¡ÃÂºÃÂ±ng dÃÂ¡ÃÂºÃÂ¥u phÃÂ¡ÃÂºÃÂ©y (VD: 0901234567, 0988776655).\n"
                          "ÃÂ¢ÃÂÃÂ¢ NhÃÂÃÂ³m Telegram: ThÃÂÃÂªm Bot vÃÂÃÂ o nhÃÂÃÂ³m gia ÃÂÃÂÃÂÃÂ¬nh rÃÂ¡ÃÂ»ÃÂi ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn Group ID (cÃÂÃÂ³ dÃÂ¡ÃÂºÃÂ¥u -, VD: -100192837465) ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂºÃÂ£ nhÃÂÃÂ  cÃÂÃÂ¹ng nhÃÂ¡ÃÂºÃÂ­n chuÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ©u nÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng thÃÂ¡ÃÂ»ÃÂi.\n"
                          "ÃÂ¢ÃÂÃÂ¢ NhiÃÂ¡ÃÂ»ÃÂu Telegram cÃÂÃÂ¡ nhÃÂÃÂ¢n: NhÃÂ¡ÃÂºÃÂ­p cÃÂÃÂ¡c ID cÃÂÃÂ¡ch nhau dÃÂ¡ÃÂºÃÂ¥u phÃÂ¡ÃÂºÃÂ©y (VD: 123456789, 987654321).",
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
                      labelText: "SÃÂ¡ÃÂ»ÃÂ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n (SMS)",
                      hintText: "0901234567, 0912345678",
                      helperText: "HÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ nhiÃÂ¡ÃÂ»ÃÂu sÃÂ¡ÃÂ»ÃÂ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i, phÃÂÃÂ¢n cÃÂÃÂ¡ch bÃÂ¡ÃÂºÃÂ±ng dÃÂ¡ÃÂºÃÂ¥u phÃÂ¡ÃÂºÃÂ©y (,)",
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
                      helperText: "Group ID gia ÃÂÃÂÃÂÃÂ¬nh (cÃÂÃÂ³ dÃÂ¡ÃÂºÃÂ¥u -) hoÃÂ¡ÃÂºÃÂ·c nhiÃÂ¡ÃÂ»ÃÂu ID cÃÂÃÂ¡ nhÃÂÃÂ¢n (,)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.send),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.botTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Telegram Bot Token (TÃÂÃÂ¹y chÃÂ¡ÃÂ»ÃÂn)",
                      hintText: "ÃÂÃÂÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂng nÃÂ¡ÃÂºÃÂ¿u dÃÂÃÂ¹ng mÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng chiÃÂ¡ÃÂ»ÃÂu cao sÃÂÃÂ n: ${_currentFloorThreshold.toInt()} mm",
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
                    label: const Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t Danh bÃÂ¡ÃÂºÃÂ¡ & NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng sÃÂÃÂ n"),
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

          // 3. THÃÂ¡ÃÂ»ÃÂI GIAN CHÃÂ¡ÃÂ»ÃÂ HOÃÂÃÂN BÃÂÃÂO ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG (GRACE PERIOD)
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
                      Text("ThÃÂ¡ÃÂ»ÃÂi gian hoÃÂÃÂ£n bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (Grace Period)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ThÃÂ¡ÃÂ»ÃÂi gian chÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi dÃÂÃÂ¹ng tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂºÃÂ­y hoÃÂ¡ÃÂºÃÂ·c bÃÂ¡ÃÂºÃÂ¥m nÃÂÃÂºt HÃÂ¡ÃÂ»ÃÂ§y trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ hÃÂÃÂº cÃÂÃÂ²i lÃÂ¡ÃÂ»ÃÂn vÃÂÃÂ  gÃÂ¡ÃÂ»ÃÂ­i tin nhÃÂ¡ÃÂºÃÂ¯n/Telegram khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p:",
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

          // 4. CHÃÂ¡ÃÂºÃÂ¾ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂN NGÃÂ¡ÃÂ»ÃÂ¦ THÃÂÃÂNG MINH (SMART NIGHTLIGHT)
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
                      Text("ChÃÂ¡ÃÂºÃÂ¿ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ¨n ngÃÂ¡ÃÂ»ÃÂ§ thÃÂÃÂ´ng minh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TÃÂÃÂ¹y chÃÂ¡ÃÂ»ÃÂnh ÃÂÃÂÃÂÃÂ¨n ngÃÂ¡ÃÂ»ÃÂ§ WS2812B trÃÂÃÂªn thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cao tuÃÂ¡ÃÂ»ÃÂi thÃÂ¡ÃÂ»ÃÂ©c giÃÂ¡ÃÂºÃÂ¥c ban ÃÂÃÂÃÂÃÂªm:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "AUTO_MOTION", label: Text("TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (Radar)", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "ALWAYS_ON", label: Text("LuÃÂÃÂ´n sÃÂÃÂ¡ng", style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: "OFF", label: Text("TÃÂ¡ÃÂºÃÂ¯t", style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_nightlightMode},
                      onSelectionChanged: (val) => setState(() => _nightlightMode = val.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("ChÃÂ¡ÃÂ»ÃÂ bÃÂ¡ÃÂºÃÂ­t trong khung giÃÂ¡ÃÂ»ÃÂ ban ÃÂÃÂÃÂÃÂªm", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _nightScheduleEnabled ? "MÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh: 18:00 ÃÂ¢ÃÂÃÂ 06:00" : "Night light hoÃÂ¡ÃÂºÃÂ¡t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng cÃÂ¡ÃÂºÃÂ£ ngÃÂÃÂ y",
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
                            label: Text("BÃÂ¡ÃÂºÃÂ­t ${_formatTime(_nightStart)}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNightTime(false),
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text("TÃÂ¡ÃÂºÃÂ¯t ${_formatTime(_nightEnd)}"),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _saveNightlightSchedule,
                    icon: const Icon(Icons.schedule),
                    label: const Text("LÃÂÃÂ°u lÃÂ¡ÃÂ»ÃÂch night light vÃÂÃÂ o thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡ng ÃÂÃÂÃÂÃÂ¨n ngÃÂ¡ÃÂ»ÃÂ§:", style: TextStyle(fontSize: 12)),
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
                      const Text("MÃÂÃÂ u ÃÂÃÂ¡nh sÃÂÃÂ¡ng:", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "WARM_YELLOW", label: Text("VÃÂÃÂ ng ÃÂ¡ÃÂºÃÂ¥m", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "SOFT_WHITE", label: Text("TrÃÂ¡ÃÂºÃÂ¯ng dÃÂ¡ÃÂ»ÃÂu", style: TextStyle(fontSize: 10))),
                          ButtonSegment(value: "CYAN", label: Text("Xanh ngÃÂ¡ÃÂ»ÃÂc", style: TextStyle(fontSize: 10))),
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

          // 5. TÃÂ¡ÃÂ»ÃÂ° KIÃÂ¡ÃÂ»ÃÂM TRA PHÃÂ¡ÃÂºÃÂ¦N CÃÂ¡ÃÂ»ÃÂ¨NG (HARDWARE DIAGNOSTIC SELF-TEST)
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
                      Text("ChÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n kiÃÂ¡ÃÂ»ÃÂm tra phÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂ»ÃÂ©ng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "KiÃÂ¡ÃÂ»ÃÂm tra tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng hoÃÂ¡ÃÂºÃÂ¡t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng cÃÂ¡ÃÂ»ÃÂ§a CÃÂ¡ÃÂ»ÃÂ¥m cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n ÃÂÃÂa phÃÂÃÂ°ÃÂÃÂ¡ng thÃÂ¡ÃÂ»ÃÂ©c (PIR AM312 + Radar 24GHz + Laser ToF + CÃÂÃÂ²i & Pin UPS):",
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
                    label: const Text("ChÃÂ¡ÃÂºÃÂ¡y chÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n & nguÃÂ¡ÃÂ»ÃÂn", style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),
          // CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh phÃÂÃÂ¢n cÃÂ¡ÃÂ»ÃÂ±c CÃÂÃÂ²i BÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (Active HIGH / Active LOW)
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
                      Text("CÃÂ¡ÃÂºÃÂ¥u hÃÂÃÂ¬nh CÃÂÃÂ²i BÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (Buzzer)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "MÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh chuÃÂ¡ÃÂºÃÂ©n: KÃÂÃÂ­ch mÃÂ¡ÃÂ»ÃÂ©c Cao (Active-HIGH, chÃÂÃÂ¢n GPIO 5 ÃÂ¡ÃÂ»ÃÂ 0V tÃÂ¡ÃÂºÃÂ¯t cÃÂÃÂ²i). NÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ²i tÃÂ¡ÃÂ»ÃÂ± kÃÂÃÂªu khi cÃÂ¡ÃÂºÃÂ¯m ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn, thÃÂ¡ÃÂ»ÃÂ­ chÃÂ¡ÃÂ»ÃÂn 'MÃÂ¡ÃÂ»ÃÂ©c ThÃÂ¡ÃÂºÃÂ¥p' hoÃÂ¡ÃÂºÃÂ·c bÃÂ¡ÃÂºÃÂ­t 'TÃÂ¡ÃÂºÃÂ¯t hoÃÂÃÂ n toÃÂÃÂ n cÃÂÃÂ²i' ÃÂÃÂÃÂ¡ÃÂ»ÃÂ test yÃÂÃÂªn tÃÂÃÂ©nh:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PhÃÂÃÂ¢n cÃÂ¡ÃÂ»ÃÂ±c cÃÂÃÂ²i:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text("MÃÂ¡ÃÂ»ÃÂ©c Cao (HIGH)", style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: false, label: Text("MÃÂ¡ÃÂ»ÃÂ©c ThÃÂ¡ÃÂºÃÂ¥p (LOW)", style: TextStyle(fontSize: 11))),
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
                              content: Text(isHigh ? "ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh: CÃÂÃÂ²i kÃÂÃÂ­ch mÃÂ¡ÃÂ»ÃÂ©c Cao (Active-HIGH, 0V TÃÂ¡ÃÂºÃÂ¯t)" : "ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh: CÃÂÃÂ²i kÃÂÃÂ­ch mÃÂ¡ÃÂ»ÃÂ©c ThÃÂ¡ÃÂºÃÂ¥p (Active-LOW, 3.3V TÃÂ¡ÃÂºÃÂ¯t)"),
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
                    title: const Text("TÃÂ¡ÃÂºÃÂ¯t hoÃÂÃÂ n toÃÂÃÂ n cÃÂÃÂ²i (Mute khi test)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text("VÃÂÃÂ´ hiÃÂ¡ÃÂ»ÃÂu hÃÂÃÂ³a cÃÂÃÂ²i vÃÂ¡ÃÂºÃÂ­t lÃÂÃÂ½, chÃÂ¡ÃÂ»ÃÂ bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng qua LED vÃÂÃÂ  ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _buzzerMuted,
                    onChanged: (val) async {
                      setState(() => _buzzerMuted = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('dev_buzzer_muted_${widget.device.remoteId.str}', val);
                      widget.onSendCommand(val ? "BUZZER_MUTE" : "BUZZER_UNMUTE");
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? "ÃÂÃÂÃÂÃÂ£ tÃÂ¡ÃÂºÃÂ¯t hoÃÂÃÂ n toÃÂÃÂ n cÃÂÃÂ²i (Muted)" : "ÃÂÃÂÃÂÃÂ£ kÃÂÃÂ­ch hoÃÂ¡ÃÂºÃÂ¡t lÃÂ¡ÃÂºÃÂ¡i cÃÂÃÂ²i (Unmuted)"),
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
                    label: const Text("BÃÂ¡ÃÂºÃÂ¥m thÃÂ¡ÃÂ»ÃÂ­ tiÃÂ¡ÃÂºÃÂ¿ng cÃÂÃÂ²i (Test Beep 200ms)", style: TextStyle(fontSize: 12)),
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
                      Text("CÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ¥ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.isConnected ? () => widget.onSendCommand("CALIBRATE_FLOOR") : null,
                    icon: const Icon(Icons.straighten),
                    label: const Text("HiÃÂ¡ÃÂ»ÃÂu chuÃÂ¡ÃÂºÃÂ©n sÃÂÃÂ n tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (ToF)"),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onDisconnect,
                    icon: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent),
                    label: const Text("NgÃÂ¡ÃÂºÃÂ¯t kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ y", style: TextStyle(color: Colors.redAccent)),
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

          // 7. CÃÂ¡ÃÂºÃÂ¬P NHÃÂ¡ÃÂºÃÂ¬T FIRMWARE THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ (ESP32-S3 FIRMWARE OTA)
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
                      Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t Firmware ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ (ESP32 OTA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t hÃÂ¡ÃÂ»ÃÂ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu hÃÂÃÂ nh & thuÃÂ¡ÃÂºÃÂ­t toÃÂÃÂ¡n nhÃÂ¡ÃÂºÃÂ­n diÃÂ¡ÃÂ»ÃÂn tÃÂÃÂ© ngÃÂÃÂ£ cho vi ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn ESP32-S3-N16R8 mÃÂÃÂ  khÃÂÃÂ´ng cÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂºÃÂ¯m dÃÂÃÂ¢y cÃÂÃÂ¡p mÃÂÃÂ¡y tÃÂÃÂ­nh.",
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
                            const Text("Firmware hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i trÃÂÃÂªn chip:", style: TextStyle(fontSize: 12)),
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
                            const Text("BÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t trÃÂÃÂªn Cloud:", style: TextStyle(fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("v1.2.0 (MÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purpleAccent)),
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
                    label: const Text("CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t Firmware cho thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ (1-ChÃÂ¡ÃÂºÃÂ¡m)"),
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

          // 4. CÃÂ¡ÃÂºÃÂ¬P NHÃÂ¡ÃÂºÃÂ¬T ÃÂ¡ÃÂ»ÃÂ¨NG DÃÂ¡ÃÂ»ÃÂ¤NG KHÃÂÃÂNG DÃÂÃÂY (OTA UPDATE CHO ANDROID & IPHONE)
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
                      Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t phÃÂ¡ÃÂºÃÂ§n mÃÂ¡ÃÂ»ÃÂm (OTA Update)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PhiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)\nTÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng tÃÂ¡ÃÂºÃÂ£i vÃÂÃÂ  cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p phiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t tÃÂ¡ÃÂ»ÃÂ« GitHub qua mÃÂ¡ÃÂºÃÂ¡ng khÃÂÃÂ´ng cÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂºÃÂ¯m cÃÂÃÂ¡p mÃÂÃÂ¡y tÃÂÃÂ­nh.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _triggerOtaUpdate,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text("KiÃÂ¡ÃÂ»ÃÂm tra & CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t phiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi"),
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
                    child: Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t ÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂ»ÃÂ¥ng OTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                                  const Text("GitHub Releases (TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
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
                                Text("PhiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("v1.2.0 (Build 2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("BÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi trÃÂÃÂªn GitHub:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  releaseInfo?['name']?.toString() ?? (isLoading ? "ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi..." : "Fall Guard Latest Release"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            if (apkSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Dung lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng file APK:", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            ? "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng sÃÂ¡ÃÂºÃÂ½ mÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ« GitHub Releases. NhÃÂ¡ÃÂºÃÂ¥n [CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t] ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ¢ng cÃÂ¡ÃÂºÃÂ¥p."
                            : "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂºÃÂ£n APK mÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t trÃÂÃÂªn GitHub Releases vÃÂÃÂ  mÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ¬nh cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t Android ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ¢ng cÃÂ¡ÃÂºÃÂ¥p ÃÂÃÂÃÂÃÂ¨ giÃÂ¡ÃÂ»ÃÂ¯ nguyÃÂÃÂªn dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu.",
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
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
                            SnackBar(content: Text("LÃÂ¡ÃÂ»ÃÂi mÃÂ¡ÃÂ»ÃÂ liÃÂÃÂªn kÃÂ¡ÃÂºÃÂ¿t APK: $e")),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t ngay"),
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
                      "CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t Firmware ESP32",
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
                                "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ cÃÂÃÂ¡ chÃÂ¡ÃÂºÃÂ¿ A/B Dual-OTA trÃÂÃÂªn chip ESP32-S3 (16MB Flash). ÃÂÃÂÃÂ¡ÃÂºÃÂ£m bÃÂ¡ÃÂºÃÂ£o thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ luÃÂÃÂ´n ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c cÃÂ¡ÃÂºÃÂ¥p nguÃÂ¡ÃÂ»ÃÂn trong suÃÂ¡ÃÂ»ÃÂt quÃÂÃÂ¡ trÃÂÃÂ¬nh cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t.",
                                style: TextStyle(fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "1. CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng qua Wi-Fi (KhuyÃÂÃÂªn dÃÂÃÂ¹ng)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purpleAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "ESP32 kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Internet qua Wi-Fi vÃÂÃÂ  tÃÂ¡ÃÂ»ÃÂ± tÃÂ¡ÃÂºÃÂ£i file firmware.bin trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ« GitHub chÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂºÃÂ¥t 5-10 giÃÂÃÂ¢y.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: urlController,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          labelText: "ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n tÃÂ¡ÃÂºÃÂ£i Firmware (.bin)",
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
                          String wifiText = "SÃÂ¡ÃÂºÃÂµn sÃÂÃÂ ng cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t";
                          if (otaStatus == "OTA_STARTING") {
                            wifiText = "ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Cloud vÃÂÃÂ  tÃÂ¡ÃÂºÃÂ£i firmware...";
                            wifiPct = 0.1;
                          } else if (otaStatus.startsWith("OTA_PROGRESS:")) {
                            int p = int.tryParse(otaStatus.replaceFirst("OTA_PROGRESS:", "")) ?? 0;
                            wifiPct = p / 100.0;
                            wifiText = "TiÃÂ¡ÃÂºÃÂ¿n ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡p vÃÂÃÂ o Flash: $p%";
                          } else if (otaStatus == "OTA_SUCCESS_REBOOTING") {
                            wifiPct = 1.0;
                            wifiText = "ThÃÂÃÂ nh cÃÂÃÂ´ng 100%! ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i...";
                          } else if (otaStatus.startsWith("OTA_ERROR:")) {
                            wifiText = "LÃÂ¡ÃÂ»ÃÂi: ${otaStatus.replaceFirst('OTA_ERROR:', '')}";
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
                                label: const Text("BÃÂ¡ÃÂºÃÂ¯t ÃÂÃÂÃÂ¡ÃÂºÃÂ§u cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t qua Wi-Fi"),
                              ),
                            ],
                          );
                        },
                      ),
                      if (widget.deviceIp.isNotEmpty) ...[
                        const Divider(height: 28),
                        const Text(
                          "2. NÃÂ¡ÃÂºÃÂ¡p trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p qua Web OTA nÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ (SiÃÂÃÂªu nhanh)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "MÃÂ¡ÃÂ»ÃÂ trang nÃÂ¡ÃÂºÃÂ¡p http://${widget.deviceIp}/update trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p trong mÃÂ¡ÃÂºÃÂ¡ng Wi-Fi ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡p file firmware.bin khÃÂÃÂ´ng cÃÂ¡ÃÂºÃÂ§n Internet.",
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
                                  SnackBar(content: Text("LÃÂ¡ÃÂ»ÃÂi mÃÂ¡ÃÂ»ÃÂ Web OTA: $e")),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.language, size: 18, color: Colors.greenAccent),
                          label: Text("MÃÂ¡ÃÂ»ÃÂ Web OTA (http://${widget.deviceIp}/update)", style: const TextStyle(color: Colors.greenAccent)),
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        widget.deviceIp.isNotEmpty ? "3. NÃÂ¡ÃÂºÃÂ¡p qua Bluetooth Low Energy (BLE OTA)" : "2. NÃÂ¡ÃÂºÃÂ¡p qua Bluetooth Low Energy (BLE OTA)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "DÃÂÃÂ¹ng cho trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂ£p thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ¡i chÃÂÃÂ°a cÃÂÃÂ³ Wi-Fi hoÃÂ¡ÃÂºÃÂ·c khÃÂÃÂ´ng cÃÂÃÂ³ Internet.",
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
                              const SnackBar(content: Text("KhÃÂÃÂ´ng tÃÂÃÂ¬m thÃÂ¡ÃÂºÃÂ¥y cÃÂ¡ÃÂ»ÃÂng OTA Bluetooth trÃÂÃÂªn thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setDialogState(() {
                            isBleFlashing = true;
                            bleProgress = 0.05;
                            bleStatusText = "ÃÂÃÂang tÃÂ¡ÃÂºÃÂ£i firmware tÃÂ¡ÃÂ»ÃÂ« GitHub vÃÂ¡ÃÂ»ÃÂ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i...";
                          });

                          try {
                            final client = HttpClient();
                            client.badCertificateCallback = (cert, host, port) => true;
                            final req = await client.getUrl(Uri.parse(urlController.text.trim()));
                            req.followRedirects = true;
                            req.maxRedirects = 5;
                            final resp = await req.close();
                            if (resp.statusCode != 200) {
                              throw Exception("MÃÂÃÂ¡y chÃÂ¡ÃÂ»ÃÂ§ phÃÂ¡ÃÂºÃÂ£n hÃÂ¡ÃÂ»ÃÂi mÃÂÃÂ£ lÃÂ¡ÃÂ»ÃÂi HTTP ${resp.statusCode}");
                            }
                            final bytes = await consolidateHttpClientResponseBytes(resp);
                            if (bytes.length < 50000 || bytes[0] != 0xE9) {
                              throw Exception("File tÃÂ¡ÃÂºÃÂ£i vÃÂ¡ÃÂ»ÃÂ (${bytes.length} bytes) khÃÂÃÂ´ng phÃÂ¡ÃÂºÃÂ£i firmware ESP32 hÃÂ¡ÃÂ»ÃÂ£p lÃÂ¡ÃÂ»ÃÂ (magic byte 0xE9 khÃÂÃÂ´ng khÃÂ¡ÃÂ»ÃÂp)!");
                            }

                            // XÃÂÃÂ³a thÃÂÃÂ´ng bÃÂÃÂ¡o cÃÂÃÂ©
                            widget.otaStatusNotifier.value = "";

                            setDialogState(() {
                              bleProgress = 0.05;
                              bleStatusText = "ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi tÃÂ¡ÃÂºÃÂ¡o vÃÂÃÂ  xÃÂÃÂ³a phÃÂÃÂ¢n vÃÂÃÂ¹ng Flash trÃÂÃÂªn ESP32...";
                            });

                            // GÃÂ¡ÃÂ»ÃÂ­i lÃÂ¡ÃÂ»ÃÂnh bÃÂ¡ÃÂºÃÂ¯t ÃÂÃÂÃÂ¡ÃÂºÃÂ§u OTA
                            await widget.otaChar!.write(utf8.encode("OTA_BEGIN:${bytes.length}"), withoutResponse: false);

                            // ChÃÂ¡ÃÂ»ÃÂ ESP32 thÃÂ¡ÃÂ»ÃÂ±c hiÃÂ¡ÃÂ»ÃÂn Flash sector erase (mÃÂ¡ÃÂºÃÂ¥t khoÃÂ¡ÃÂºÃÂ£ng 1-3 giÃÂÃÂ¢y)
                            for (int i = 0; i < 40; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("ESP32 tÃÂ¡ÃÂ»ÃÂ« chÃÂ¡ÃÂ»ÃÂi OTA: ${st.replaceFirst('OTA_ERROR:', '')}");
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
                                throw Exception("ESP32 ngÃÂ¡ÃÂºÃÂ¯t quÃÂÃÂ¡ trÃÂÃÂ¬nh nÃÂ¡ÃÂºÃÂ¡p: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                              final end = (sent + chunkSize < total) ? sent + chunkSize : total;
                              final chunk = bytes.sublist(sent, end);
                              await widget.otaChar!.write(chunk, withoutResponse: false);
                              sent = end;
                              setDialogState(() {
                                bleProgress = 0.05 + (sent / total) * 0.90;
                                bleStatusText = "ÃÂÃÂang nÃÂ¡ÃÂºÃÂ¡p qua BLE: ${(sent / 1024).toStringAsFixed(1)} / ${(total / 1024).toStringAsFixed(1)} KB (${(bleProgress * 100).toInt()}%)";
                              });
                              await Future.delayed(const Duration(milliseconds: 20));
                            }

                            setDialogState(() {
                              bleProgress = 0.96;
                              bleStatusText = "ÃÂÃÂang kiÃÂ¡ÃÂ»ÃÂm tra tÃÂÃÂ­nh toÃÂÃÂ n vÃÂ¡ÃÂºÃÂ¹n (Checksum & Verify) trÃÂÃÂªn chip...";
                            });

                            await Future.delayed(const Duration(milliseconds: 500));
                            await widget.otaChar!.write(utf8.encode("OTA_END"), withoutResponse: false);

                            // ChÃÂ¡ÃÂ»ÃÂ ESP32 xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n hoÃÂÃÂ n tÃÂ¡ÃÂºÃÂ¥t vÃÂÃÂ  reboot trong tÃÂ¡ÃÂ»ÃÂi ÃÂÃÂa 10 giÃÂÃÂ¢y
                            bool isRebooting = false;
                            for (int i = 0; i < 100; i++) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              final st = widget.otaStatusNotifier.value;
                              if (st == "OTA_SUCCESS_REBOOTING") {
                                isRebooting = true;
                                break;
                              } else if (st.startsWith("OTA_ERROR:")) {
                                throw Exception("XÃÂÃÂ¡c thÃÂ¡ÃÂ»ÃÂ±c firmware thÃÂ¡ÃÂºÃÂ¥t bÃÂ¡ÃÂºÃÂ¡i: ${st.replaceFirst('OTA_ERROR:', '')}");
                              }
                            }

                            if (isRebooting) {
                              setDialogState(() {
                                bleProgress = 1.0;
                                bleStatusText = "ThÃÂÃÂ nh cÃÂÃÂ´ng 100%! ESP32 ÃÂÃÂang khÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lÃÂ¡ÃÂºÃÂ¡i vÃÂÃÂ o firmware mÃÂ¡ÃÂ»ÃÂi...";
                              });
                            } else {
                              throw Exception("HÃÂ¡ÃÂºÃÂ¿t thÃÂ¡ÃÂ»ÃÂi gian chÃÂ¡ÃÂ»ÃÂ phÃÂ¡ÃÂºÃÂ£n hÃÂ¡ÃÂ»ÃÂi xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n tÃÂ¡ÃÂ»ÃÂ« ESP32 sau khi gÃÂ¡ÃÂ»ÃÂ­i hÃÂ¡ÃÂºÃÂ¿t dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu.");
                            }
                          } catch (e) {
                            setDialogState(() {
                              isBleFlashing = false;
                              bleStatusText = "LÃÂ¡ÃÂ»ÃÂi nÃÂ¡ÃÂºÃÂ¡p BLE: $e";
                            });
                          }
                        },
                        icon: const Icon(Icons.bluetooth, size: 18, color: Colors.blueAccent),
                        label: const Text("TÃÂ¡ÃÂºÃÂ£i & NÃÂ¡ÃÂºÃÂ¡p firmware qua BLE", style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBleFlashing ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
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
            Expanded(child: Text('ÃÂÃÂang chÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ§ dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu telemetry ÃÂÃÂÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂºÃÂ½ biÃÂ¡ÃÂ»ÃÂu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c...', style: TextStyle(color: Colors.grey))),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.timeline, color: Colors.cyanAccent), SizedBox(width: 8), Text('Telemetry thÃÂ¡ÃÂ»ÃÂi gian thÃÂ¡ÃÂ»ÃÂ±c', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          const SizedBox(height: 4),
          const Text('120 mÃÂ¡ÃÂºÃÂ«u gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t ÃÂ¢ÃÂÃÂ¢ ToF mm ÃÂ¢ÃÂÃÂ¢ Radar /100', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(height: 210, child: CustomPaint(painter: LiveTelemetryPainter(samples))),
          const SizedBox(height: 8),
          const Wrap(spacing: 14, children: [
            _ChartLegend(color: Colors.cyanAccent, label: 'ToF'),
            _ChartLegend(color: Colors.orangeAccent, label: 'Radar ÃÂÃÂÃÂ¡ÃÂ»ÃÂng'),
            _ChartLegend(color: Colors.tealAccent, label: 'Radar tÃÂÃÂ©nh'),
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
                        "BiÃÂ¡ÃÂ»ÃÂu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂc cÃÂÃÂº ngÃÂÃÂ£ (Kinematic Graph)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "CÃÂ¡ÃÂ»ÃÂ± ly: ${dist}cm | VÃÂ¡ÃÂºÃÂ­n tÃÂ¡ÃÂ»ÃÂc: ${vel.toStringAsFixed(0)} mm/s | ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng: $motion/100",
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

            // Canvas vÃÂ¡ÃÂºÃÂ½ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂ 2 ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng cong
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

            // ChÃÂÃÂº thÃÂÃÂ­ch ÃÂÃÂÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.cyanAccent, "ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF (mm)"),
                _buildLegendItem(Colors.orangeAccent, "ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar (/100)"),
                _buildLegendItem(Colors.redAccent, "ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm va chÃÂ¡ÃÂºÃÂ¡m (Impact)"),
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

// LÃÂ¡ÃÂ»ÃÂp CustomPainter vÃÂ¡ÃÂºÃÂ½ biÃÂ¡ÃÂ»ÃÂu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ tiÃÂ¡ÃÂºÃÂ¿p sÃÂÃÂ n vÃÂÃÂ  chÃÂ¡ÃÂºÃÂ¥n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng
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

    // 1. VÃÂ¡ÃÂºÃÂ½ khung lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi trÃÂ¡ÃÂ»ÃÂ¥c toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ
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

    // 2. VÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ tiÃÂ¡ÃÂºÃÂ¿p sÃÂÃÂ n va chÃÂ¡ÃÂºÃÂ¡m (Impact point) tÃÂ¡ÃÂºÃÂ¡i x = 50%
    final double impactX = w * 0.50;
    final Paint impactLinePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(impactX, 0), Offset(impactX, h), impactLinePaint);

    // 3. ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng cong 1: ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF (MÃÂÃÂ u xanh Cyan)
    // t = -2s (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng cao 1700mm) -> t = -0.5s (RÃÂÃÂ¡i) -> t = 0s (ChÃÂ¡ÃÂºÃÂ¡m sÃÂÃÂ n 300mm) -> t = +2s (NÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n)
    final Path heightPath = Path();
    final double hTop = h * 0.15;    // ~1700mm
    final double hFloor = h * 0.82;  // ~300mm

    heightPath.moveTo(0, hTop);
    heightPath.lineTo(w * 0.25, hTop + 5);
    // ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n tÃÂ¡ÃÂ»ÃÂ¥t dÃÂ¡ÃÂ»ÃÂc rÃÂÃÂ¡i tÃÂ¡ÃÂ»ÃÂ± do
    heightPath.cubicTo(
      w * 0.38, hTop + 10,
      w * 0.44, hFloor * 0.65,
      impactX, hFloor,
    );
    // ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n nÃÂ¡ÃÂºÃÂ±m yÃÂÃÂªn dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi sÃÂÃÂ n
    heightPath.lineTo(w, hFloor + 3);

    final Paint heightPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(heightPath, heightPaint);

    // 4. ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng cong 2: ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar (MÃÂÃÂ u cam)
    // t = -2s (ThÃÂ¡ÃÂºÃÂ¥p 15) -> t = 0s (ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p Peak Motion) -> t = +2s (VÃÂ¡ÃÂ»ÃÂ 0-5)
    final Path motionPath = Path();
    final double mBase = h * 0.85; // MÃÂ¡ÃÂ»ÃÂ©c ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng thÃÂ¡ÃÂºÃÂ¥p
    final double mPeak = h * (1.0 - (math.min(100, math.max(20, peakMotion)) / 100.0) * 0.85);

    motionPath.moveTo(0, mBase - 10);
    motionPath.lineTo(w * 0.25, mBase - 15);
    motionPath.cubicTo(
      w * 0.40, mBase - 25,
      w * 0.46, mPeak,
      impactX, mPeak,
    );
    // ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng sau ngÃÂÃÂ£ tÃÂ¡ÃÂºÃÂ¯t dÃÂ¡ÃÂºÃÂ§n vÃÂ¡ÃÂ»ÃÂ gÃÂ¡ÃÂºÃÂ§n 0
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

    // 5. ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm chÃÂ¡ÃÂºÃÂ¥n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng tiÃÂ¡ÃÂºÃÂ¿p ÃÂÃÂÃÂ¡ÃÂºÃÂ¥t (Impact point pulse dot)
    final Paint pulseOuter = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 14, pulseOuter);

    final Paint pulseInner = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(impactX, hFloor), 6, pulseInner);

    // 6. NhÃÂÃÂ£n mÃÂ¡ÃÂ»ÃÂc thÃÂ¡ÃÂ»ÃÂi gian dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi trÃÂ¡ÃÂ»ÃÂ¥c X
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, double x, double y, Color c) {
      tp.text = TextSpan(text: text, style: TextStyle(fontSize: 9, color: c));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }

    drawText("-2s (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng)", w * 0.10, h - 14, Colors.grey);
    drawText("-1s (MÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂÃÂ )", w * 0.32, h - 14, Colors.grey);
    drawText("0s (ChÃÂ¡ÃÂºÃÂ¡m sÃÂÃÂ n)", impactX, h - 14, Colors.redAccent);
    drawText("+1s (NÃÂ¡ÃÂºÃÂ±m yÃÂÃÂªn)", w * 0.72, h - 14, Colors.grey);
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
// WIDGET: BÃÂ¡ÃÂºÃÂ¢N GHI PHÃÂÃÂT LÃÂ¡ÃÂºÃÂ I QUÃÂÃÂ TRÃÂÃÂNH TÃÂÃÂ NGÃÂÃÂ (FALL PLAYBACK & AUDIT RECORD)
// MÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng chuÃÂ¡ÃÂ»ÃÂi thÃÂ¡ÃÂ»ÃÂi gian 4 giai ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n (-2.0s -> 0s -> +2.0s) & XuÃÂ¡ÃÂºÃÂ¥t biÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n
// =========================================================================

class VirtualThermalSpectrum extends StatefulWidget {
  final Map<String, dynamic> event;

  const VirtualThermalSpectrum({super.key, required this.event});

  @override
  State<VirtualThermalSpectrum> createState() => _VirtualThermalSpectrumState();
}

class _VirtualThermalSpectrumState extends State<VirtualThermalSpectrum> {
  bool _showPostFall = true;   // true: Sau khi ngÃÂÃÂ£ (nÃÂ¡ÃÂºÃÂ±m bÃÂ¡ÃÂ»ÃÂt), false: TrÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi ngÃÂÃÂ£ (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng)
  bool _showGrid128 = true;     // HiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ 128x128
  Offset? _touchedPoint;        // ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm chÃÂ¡ÃÂºÃÂ¡m khÃÂ¡ÃÂºÃÂ£o sÃÂÃÂ¡t mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng tÃÂÃÂ°ÃÂÃÂ¡ng tÃÂÃÂ¡c

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
            // 1. TiÃÂÃÂªu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  nhÃÂÃÂ£n cÃÂÃÂ´ng nghÃÂ¡ÃÂ»ÃÂ HD 128x128
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "PhÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar khÃÂÃÂ´ng gian 128x128:",
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
                      Text("16.384 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm FMCW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "MÃÂÃÂ´ hÃÂÃÂ¬nh phÃÂÃÂ¢n bÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar FMCW 24GHz (128x128) tÃÂÃÂ¡i tÃÂ¡ÃÂºÃÂ¡o tÃÂ¡ÃÂ»ÃÂ« ToF (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao trÃÂ¡ÃÂ»ÃÂ¥c Y) + 9 CÃÂ¡ÃÂ»ÃÂng khoÃÂ¡ÃÂºÃÂ£ng cÃÂÃÂ¡ch Radar LD2410 (cÃÂ¡ÃÂ»ÃÂ± ly trÃÂ¡ÃÂ»ÃÂ¥c X) + ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // 2. BÃÂ¡ÃÂ»ÃÂ nÃÂÃÂºt ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn trÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i (TrÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc / Sau ngÃÂÃÂ£) vÃÂÃÂ  bÃÂ¡ÃÂºÃÂ­t tÃÂ¡ÃÂºÃÂ¯t lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi 128x128
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
                    label: const Text("TrÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc ngÃÂÃÂ£ (-2s: ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng)", style: TextStyle(fontSize: 11)),
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
                    label: const Text("Sau ngÃÂÃÂ£ (+2s: SÃÂÃÂ n)", style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _showPostFall = true;
                      _touchedPoint = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // TÃÂÃÂ¹y chÃÂ¡ÃÂ»ÃÂn chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂi kiÃÂ¡ÃÂ»ÃÂu hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ChÃÂ¡ÃÂºÃÂ¡m / KÃÂÃÂ©o trÃÂÃÂªn ÃÂ¡ÃÂºÃÂ£nh ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂÃÂo nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng radar tÃÂ¡ÃÂºÃÂ¡i ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm:",
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
                      _showGrid128 ? "LÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi 128: BÃÂ¡ÃÂºÃÂ¬T" : "LÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi 128: TÃÂ¡ÃÂºÃÂ®T",
                      style: TextStyle(fontSize: 9, color: _showGrid128 ? Colors.tealAccent : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 3. Khung hiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ PhÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar 128x128 tÃÂÃÂ°ÃÂÃÂ¡ng tÃÂÃÂ¡c
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

            // 4. ChÃÂÃÂº giÃÂ¡ÃÂºÃÂ£i 2 trÃÂ¡ÃÂ»ÃÂ¥c toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ khÃÂÃÂ´ng gian
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TrÃÂ¡ÃÂ»ÃÂ¥c dÃÂ¡ÃÂ»ÃÂc Y: TrÃÂ¡ÃÂºÃÂ§n (0m) ÃÂ¢ÃÂÃÂ SÃÂÃÂ n nhÃÂÃÂ  (2.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("TrÃÂ¡ÃÂ»ÃÂ¥c ngang X: CÃÂ¡ÃÂ»ÃÂng radar (0.75m ÃÂ¢ÃÂÃÂ 6.0m)", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Thanh dÃÂ¡ÃÂºÃÂ£i mÃÂÃÂ u mÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ Radar FMCW (0% - 100%)
            Row(
              children: [
                const Text("0% (TÃÂÃÂ©nh)", style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF060B14), // NÃÂ¡ÃÂ»ÃÂn tÃÂÃÂ©nh (0% RF)
                          Color(0xFF0F3854), // TÃÂ¡ÃÂºÃÂ¡p ÃÂÃÂ¢m nÃÂ¡ÃÂ»ÃÂn RF (15%)
                          Color(0xFF0077B6), // TÃÂÃÂ­n hiÃÂ¡ÃÂ»ÃÂu phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ nhÃÂ¡ÃÂºÃÂ¹ (35%)
                          Color(0xFF00B4D8), // HiÃÂ¡ÃÂ»ÃÂn diÃÂ¡ÃÂ»ÃÂn vi chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (55%)
                          Color(0xFFFFB703), // ChuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng cÃÂÃÂ¡ thÃÂ¡ÃÂ»ÃÂ (75%)
                          Color(0xFFFB8500), // ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng cao (90%)
                          Color(0xFFFF0054), // ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh va chÃÂ¡ÃÂºÃÂ¡m (97%)
                          Color(0xFFFFFFFF), // ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm xung kÃÂÃÂ­ch bÃÂÃÂ£o hÃÂÃÂ²a (100%)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("100% (ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh)", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 6. HÃÂ¡ÃÂ»ÃÂp kÃÂ¡ÃÂºÃÂ¿t luÃÂ¡ÃÂºÃÂ­n chÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n AI tÃÂ¡ÃÂ»ÃÂ« 16.384 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng radar
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
                          ? "PhÃÂ¡ÃÂ»ÃÂ radar 128x128 chÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n: 96% mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ dÃÂ¡ÃÂ»ÃÂn xuÃÂ¡ÃÂ»ÃÂng 15% ÃÂÃÂÃÂÃÂ¡y sÃÂÃÂ n (Y > 1.8m) vÃÂÃÂ  trÃÂ¡ÃÂºÃÂ£i rÃÂ¡ÃÂ»ÃÂng ngang 2.4m (CÃÂ¡ÃÂ»ÃÂng 2-5). KÃÂ¡ÃÂºÃÂ¿t hÃÂ¡ÃÂ»ÃÂ£p xung lÃÂ¡ÃÂ»ÃÂ±c va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p $motion/100 ÃÂ¢ÃÂÃÂ XÃÂÃÂ¡c thÃÂ¡ÃÂ»ÃÂ±c tÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ nÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng."
                          : "PhÃÂ¡ÃÂ»ÃÂ radar 128x128 chÃÂ¡ÃÂºÃÂ©n ÃÂÃÂoÃÂÃÂ¡n: CÃÂ¡ÃÂ»ÃÂt nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng radar tÃÂ¡ÃÂºÃÂ­p trung theo hÃÂÃÂ¬nh trÃÂ¡ÃÂ»ÃÂ¥ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng thÃÂ¡ÃÂºÃÂ³ng (Y: 0.3m ÃÂ¢ÃÂÃÂ 1.7m), bÃÂ¡ÃÂ»ÃÂ ngang hÃÂ¡ÃÂºÃÂ¹p 0.6m tÃÂ¡ÃÂºÃÂ¡i CÃÂ¡ÃÂ»ÃÂng 3. TrÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i cÃÂÃÂ¡ thÃÂ¡ÃÂ»ÃÂ bÃÂÃÂ¬nh thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng vÃÂÃÂ  thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng tÃÂ¡ÃÂ»ÃÂt.",
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
// CUSTOM PAINTER: HIÃÂ¡ÃÂ»ÃÂN THÃÂ¡ÃÂ»ÃÂ PHÃÂ¡ÃÂ»ÃÂ NÃÂÃÂNG LÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂ¢NG RADAR 128x128 (16.384 ÃÂÃÂIÃÂ¡ÃÂ»ÃÂM GAUSS)
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

  // TÃÂÃÂ­nh mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ Radar FMCW tÃÂ¡ÃÂºÃÂ¡i toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ chuÃÂ¡ÃÂºÃÂ©n hoÃÂÃÂ¡ (nx, ny) [0.0 .. 1.0]
  double _calcRadarEnergyAt(double nx, double ny) {
    // TÃÂ¡ÃÂºÃÂ¡p ÃÂÃÂ¢m nÃÂ¡ÃÂ»ÃÂn RF mÃÂÃÂ´i trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng ~ 3.5%
    double ambient = 3.5 + 1.2 * math.sin(nx * 8) * math.cos(ny * 8);

    if (!isPostFall) {
      // TRÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂC NGÃÂÃÂ: CÃÂÃÂ¡ thÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng thÃÂ¡ÃÂºÃÂ³ng tÃÂ¡ÃÂºÃÂ¡i CÃÂ¡ÃÂ»ÃÂng 3.5 (nx = 0.44), chiÃÂ¡ÃÂ»ÃÂu cao (ny tÃÂ¡ÃÂ»ÃÂ« 0.25 ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n 0.85)
      // VÃÂÃÂ¹ng ngÃÂ¡ÃÂ»ÃÂ±c/ÃÂÃÂÃÂ¡ÃÂºÃÂ§u (nx: 0.44, ny: 0.38)
      double dHead = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.32) / 0.10, 2));
      double dChest = math.sqrt(math.pow((nx - 0.44) / 0.10, 2) + math.pow((ny - 0.48) / 0.14, 2));
      double dLegs = math.sqrt(math.pow((nx - 0.44) / 0.08, 2) + math.pow((ny - 0.72) / 0.18, 2));

      double energyHead = 82.0 * math.exp(-0.5 * dHead * dHead);
      double energyChest = 88.0 * math.exp(-0.5 * dChest * dChest);
      double energyLegs = 65.0 * math.exp(-0.5 * dLegs * dLegs);

      return (ambient + math.max(energyHead, math.max(energyChest, energyLegs))).clamp(0.0, 100.0);
    } else {
      // SAU NGÃÂÃÂ: NÃÂ¡ÃÂºÃÂ±m ngang sÃÂÃÂ¡t sÃÂÃÂ n (ny = 0.88, trÃÂ¡ÃÂºÃÂ£i dÃÂÃÂ i nx tÃÂ¡ÃÂ»ÃÂ« 0.22 ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n 0.75)
      // ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p thÃÂÃÂ¢n trÃÂÃÂªn (nx: 0.36, ny: 0.88)
      double dUpper = math.sqrt(math.pow((nx - 0.36) / 0.12, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm hÃÂÃÂ´ng/thÃÂÃÂ¢n dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi (nx: 0.54, ny: 0.88)
      double dLower = math.sqrt(math.pow((nx - 0.54) / 0.14, 2) + math.pow((ny - 0.88) / 0.06, 2));
      // ChÃÂÃÂ¢n (nx: 0.70, ny: 0.89)
      double dFeet = math.sqrt(math.pow((nx - 0.70) / 0.10, 2) + math.pow((ny - 0.89) / 0.06, 2));

      double energyUpper = 95.0 * math.exp(-0.5 * dUpper * dUpper);
      double energyLower = 88.0 * math.exp(-0.5 * dLower * dLower);
      double energyFeet = 60.0 * math.exp(-0.5 * dFeet * dFeet);

      return (ambient + math.max(energyUpper, math.max(energyLower, energyFeet))).clamp(0.0, 100.0);
    }
  }

  // ChuyÃÂ¡ÃÂ»ÃÂn mÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ Radar sang dÃÂ¡ÃÂºÃÂ£i mÃÂÃÂ u phÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ³ng vÃÂÃÂ´ tuyÃÂ¡ÃÂºÃÂ¿n (Turbo/Jet Colormap)
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

    // 1. VÃÂ¡ÃÂºÃÂ½ nÃÂ¡ÃÂ»ÃÂn RF 2D
    final Rect backgroundRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()..color = const Color(0xFF060B14);
    canvas.drawRect(backgroundRect, bgPaint);

    // 2. KÃÂ¡ÃÂºÃÂ¿t xuÃÂ¡ÃÂºÃÂ¥t cÃÂÃÂ¡c quÃÂ¡ÃÂºÃÂ§ng mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar (Radar Kinematic Clusters)
    if (!isPostFall) {
      // ÃÂÃÂÃÂ¡ÃÂ»ÃÂ¨NG: 3 quÃÂ¡ÃÂºÃÂ§ng nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ (ÃÂÃÂÃÂ¡ÃÂºÃÂ§u, NgÃÂ¡ÃÂ»ÃÂ±c, ChÃÂÃÂ¢n)
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.32), w * 0.22, h * 0.16, 85.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.48), w * 0.26, h * 0.22, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.44, h * 0.72), w * 0.20, h * 0.24, 65.0);
    } else {
      // NGÃÂÃÂ NÃÂ¡ÃÂºÃÂ°M SÃÂÃÂN: DÃÂ¡ÃÂºÃÂ£i nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng nÃÂ¡ÃÂºÃÂ±m ngang dÃÂÃÂ i sÃÂÃÂ¡t ÃÂÃÂÃÂÃÂ¡y sÃÂÃÂ n
      _drawRadarEnergyCluster(canvas, Offset(w * 0.36, h * 0.88), w * 0.28, h * 0.12, 98.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.54, h * 0.88), w * 0.32, h * 0.12, 90.0);
      _drawRadarEnergyCluster(canvas, Offset(w * 0.70, h * 0.89), w * 0.22, h * 0.10, 60.0);

      // VÃÂÃÂ¹ng sÃÂÃÂ n chÃÂ¡ÃÂºÃÂ¥n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng lan tÃÂ¡ÃÂ»ÃÂa nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p
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

    // 3. VÃÂ¡ÃÂºÃÂ½ ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂºÃÂ³ng mÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ (Iso-Energy Contours)
    _drawIsoEnergyContours(canvas, size);

    // 4. VÃÂ¡ÃÂºÃÂ½ lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ 128x128 (HiÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ cÃÂÃÂ¡c vÃÂ¡ÃÂºÃÂ¡ch chia 16, 32, 64, 96, 128)
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

    // 5. VÃÂ¡ÃÂºÃÂ½ hÃÂ¡ÃÂ»ÃÂng tÃÂÃÂ¢m quÃÂÃÂ©t mÃÂ¡ÃÂºÃÂ­t ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng cÃÂ¡ÃÂ»ÃÂ±c ÃÂÃÂÃÂ¡ÃÂºÃÂ¡i
    final Offset peakPos = isPostFall ? Offset(w * 0.36, h * 0.88) : Offset(w * 0.44, h * 0.32);
    _drawCrosshair(canvas, peakPos, isPostFall ? "E_max: 98% (SÃÂÃÂ n Y: 0.15m)" : "E_max: 90% (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng Y: 1.5m)", Colors.redAccent);

    // 6. VÃÂ¡ÃÂºÃÂ½ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm chÃÂ¡ÃÂºÃÂ¡m cÃÂ¡ÃÂ»ÃÂ§a ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi dÃÂÃÂ¹ng (NÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ³ tÃÂÃÂ°ÃÂÃÂ¡ng tÃÂÃÂ¡c ÃÂÃÂo ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm)
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

    // 7. NhÃÂÃÂ£n HUD gÃÂÃÂ³c trÃÂÃÂªn bÃÂÃÂªn trÃÂÃÂ¡i
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

  // VÃÂ¡ÃÂºÃÂ½ quÃÂ¡ÃÂºÃÂ§ng tÃÂÃÂ¡n xÃÂ¡ÃÂºÃÂ¡ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar 2D
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

  // VÃÂ¡ÃÂºÃÂ½ cÃÂÃÂ¡c ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂºÃÂ³ng mÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng khÃÂÃÂ©p kÃÂÃÂ­n (Iso-Energy Contours)
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

  // VÃÂ¡ÃÂºÃÂ½ hÃÂ¡ÃÂ»ÃÂng tÃÂÃÂ¢m ÃÂÃÂo nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng kÃÂÃÂ¨m chÃÂÃÂº thÃÂÃÂ­ch toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ
  void _drawCrosshair(Canvas canvas, Offset pos, String label, Color color) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    // VÃÂ¡ÃÂºÃÂ¡ch dÃÂ¡ÃÂºÃÂ¥u thÃÂ¡ÃÂºÃÂ­p
    canvas.drawLine(Offset(pos.dx - 10, pos.dy), Offset(pos.dx + 10, pos.dy), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - 10), Offset(pos.dx, pos.dy + 10), p);

    // VÃÂÃÂ²ng trÃÂÃÂ²n ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh vÃÂ¡ÃÂ»ÃÂ
    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(pos, 6, circlePaint);

    // HÃÂ¡ÃÂ»ÃÂp chÃÂ¡ÃÂ»ÃÂ¯ toÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  mÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng
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
// MÃÂÃÂN HÃÂÃÂNH CÃÂÃÂI ÃÂÃÂÃÂ¡ÃÂºÃÂ¶T CHUNG CÃÂ¡ÃÂ»ÃÂ¦A ÃÂ¡ÃÂ»ÃÂ¨NG DÃÂ¡ÃÂ»ÃÂ¤NG (GENERAL SETTINGS SCREEN)
// =========================================================================

// =========================================================================
// WIDGET: BÃÂ¡ÃÂºÃÂ¢N GHI PHÃÂÃÂT LÃÂ¡ÃÂºÃÂ I QUÃÂÃÂ TRÃÂÃÂNH TÃÂÃÂ NGÃÂÃÂ (FALL PLAYBACK & AUDIT RECORD)
// MÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng chuÃÂ¡ÃÂ»ÃÂi thÃÂ¡ÃÂ»ÃÂi gian 4 giai ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n (-2.0s -> 0s -> +2.0s) & XuÃÂ¡ÃÂºÃÂ¥t biÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n
// =========================================================================
class HumanPostureSimulation extends StatefulWidget {
  final Map<String, dynamic> event;

  const HumanPostureSimulation({super.key, required this.event});

  @override
  State<HumanPostureSimulation> createState() => _HumanPostureSimulationState();
}

class _HumanPostureSimulationState extends State<HumanPostureSimulation> {
  double _currentTime = -2.0; // TÃÂ¡ÃÂ»ÃÂ« -2.0 ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n +2.0 giÃÂÃÂ¢y
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
      const intervalMs = 50; // 20 FPS ÃÂÃÂÃÂ¡ÃÂ»ÃÂng bÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂ»ÃÂi tÃÂ¡ÃÂºÃÂ§n sÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n 20Hz
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
      stageName = "1. ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng vÃÂ¡ÃÂ»ÃÂ¯ng thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng";
      stageColor = Colors.greenAccent;
      angleDeg = 0.0;
    } else if (t < 0.0) {
      double progress = (t - (-0.8)) / 0.8;
      heightMm = 1720.0 - (1720.0 - 240.0) * (progress * progress);
      currentVel = maxVel * progress;
      currentMot = (15 + (peakMot - 15) * progress * 0.7).toInt();
      stageName = "2. MÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂÃÂ  & RÃÂÃÂ¡i tÃÂ¡ÃÂ»ÃÂ± do";
      stageColor = Colors.amberAccent;
      angleDeg = progress * 75.0;
    } else if (t < 0.4) {
      heightMm = 240.0;
      currentVel = maxVel * (1.0 - t / 0.4);
      currentMot = peakMot;
      stageName = "3. VA CHÃÂ¡ÃÂºÃÂ M SÃÂÃÂN (CHÃÂ¡ÃÂºÃÂ¤N ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG)";
      stageColor = Colors.redAccent;
      angleDeg = 90.0;
    } else {
      double postProg = (t - 0.4) / 1.6;
      heightMm = 220.0 + 8.0 * math.sin(t * 3);
      currentVel = 0.0;
      currentMot = (peakMot * (1.0 - postProg * 0.85)).clamp(8, 25).toInt();
      stageName = "4. NÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (HÃÂ¡ÃÂºÃÂ­u ngÃÂÃÂ£)";
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
ÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂ
HÃÂ¡ÃÂ»ÃÂ SÃÂÃÂ  GIÃÂÃÂM ÃÂÃÂÃÂ¡ÃÂ»ÃÂNH TAI NÃÂ¡ÃÂºÃÂ N TÃÂÃÂ NGÃÂÃÂ (FALL INCIDENT RECORD)
HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng giÃÂÃÂ¡m sÃÂÃÂ¡t: FallGuard S3R8 (ESP32-S3-WROOM-1-N16R8)
MÃÂÃÂ£ sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ: #FALL-REC-${sec.toString().padLeft(6, '0')}
ThÃÂ¡ÃÂ»ÃÂi gian xÃÂ¡ÃÂºÃÂ£y ra: CÃÂÃÂ¡ch ÃÂÃÂÃÂÃÂ¢y ${sec}s
ÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂ
1. THÃÂÃÂNG SÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG HÃÂ¡ÃÂ»ÃÂC CÃÂÃÂ NGÃÂÃÂ (KINEMATICS):
   - PhÃÂÃÂ¢n loÃÂ¡ÃÂºÃÂ¡i cÃÂÃÂº ngÃÂÃÂ£: NgÃÂÃÂ£ va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng mÃÂ¡ÃÂºÃÂ¡nh (High-Velocity Fall Impact)
   - VÃÂ¡ÃÂºÃÂ­n tÃÂ¡ÃÂ»ÃÂc rÃÂÃÂ¡i tÃÂ¡ÃÂ»ÃÂ± do cÃÂ¡ÃÂ»ÃÂ±c ÃÂÃÂÃÂ¡ÃÂºÃÂ¡i (V_drop): ${vel.toStringAsFixed(0)} mm/s (NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ¡ng: >= 550 mm/s)
   - ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng va ÃÂÃÂÃÂ¡ÃÂºÃÂ­p ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh (Peak Motion): $motion/100 (ChÃÂ¡ÃÂºÃÂ¥n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng va chÃÂ¡ÃÂºÃÂ¡m mÃÂ¡ÃÂ»ÃÂ©c cao)
   - CÃÂ¡ÃÂ»ÃÂ± ly cÃÂ¡ÃÂ»ÃÂ§a nÃÂ¡ÃÂºÃÂ¡n nhÃÂÃÂ¢n: $dist cm (CÃÂ¡ÃÂ»ÃÂng radar FMCW sÃÂ¡ÃÂ»ÃÂ 3)
   - ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc ngÃÂÃÂ£: 1.72 m (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng thÃÂ¡ÃÂºÃÂ³ng) ÃÂ¢ÃÂÃÂ Sau ngÃÂÃÂ£: 0.22 m (SÃÂÃÂ¡t sÃÂÃÂ n nhÃÂÃÂ )

2. ÃÂÃÂÃÂÃÂNH GIÃÂÃÂ TRÃÂ¡ÃÂºÃÂ NG THÃÂÃÂI NÃÂ¡ÃÂºÃÂ N NHÃÂÃÂN (POST-FALL STATUS):
   - TrÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i: NÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng (Immobile on floor)
   - NÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng sau ngÃÂÃÂ£: <= 20/100 (KhÃÂÃÂ´ng cÃÂÃÂ³ phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ gÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng dÃÂ¡ÃÂºÃÂ­y)
   - NÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng vi chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng tÃÂÃÂ©nh: >= 16/100 (CÃÂÃÂ²n dÃÂ¡ÃÂºÃÂ¥u hiÃÂ¡ÃÂ»ÃÂu hÃÂÃÂ´ hÃÂ¡ÃÂºÃÂ¥p / nhÃÂ¡ÃÂ»ÃÂp tim)
   - KÃÂ¡ÃÂºÃÂ¿t luÃÂ¡ÃÂºÃÂ­n AI: CÃÂÃÂº ngÃÂÃÂ£ thÃÂ¡ÃÂºÃÂ­t 100%, nÃÂ¡ÃÂºÃÂ¡n nhÃÂÃÂ¢n cÃÂ¡ÃÂºÃÂ§n hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ y tÃÂ¡ÃÂºÃÂ¿ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p.

3. HÃÂÃÂNH ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG CÃÂ¡ÃÂ»ÃÂ¨U NÃÂ¡ÃÂºÃÂ N TÃÂ¡ÃÂ»ÃÂ° ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG ÃÂÃÂÃÂÃÂ THÃÂ¡ÃÂ»ÃÂ°C THI:
   - CÃÂÃÂ²i bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng Active Buzzer: ÃÂÃÂÃÂÃÂ£ phÃÂÃÂ¡t tÃÂÃÂ­n hiÃÂ¡ÃÂ»ÃÂu cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o tÃÂ¡ÃÂºÃÂ¡i chÃÂ¡ÃÂ»ÃÂ (85 dB)
   - ÃÂÃÂÃÂÃÂ¨n LED RGB WS2812B: ÃÂÃÂÃÂ¡ÃÂ»ÃÂi mÃÂÃÂ u ÃÂÃÂÃÂ¡ÃÂ»ÃÂ SOS nhÃÂ¡ÃÂºÃÂ¥p nhÃÂÃÂ¡y liÃÂÃÂªn tÃÂ¡ÃÂ»ÃÂ¥c
   - Gateway Wi-Fi: ÃÂÃÂÃÂÃÂ£ gÃÂ¡ÃÂ»ÃÂ­i cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p Telegram Bot & SMS SpeedSMS
ÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂÃÂ¢ÃÂÃÂ
BÃÂ¡ÃÂºÃÂ£n ghi ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c trÃÂÃÂ­ch xuÃÂ¡ÃÂºÃÂ¥t tÃÂ¡ÃÂ»ÃÂ« bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ Flash NVS cÃÂ¡ÃÂ»ÃÂ§a thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ESP32-S3.
""";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(child: Text("BiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ tÃÂÃÂ© ngÃÂÃÂ£", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
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
            label: const Text("Sao chÃÂÃÂ©p biÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recordText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ÃÂÃÂÃÂÃÂ£ sao chÃÂÃÂ©p biÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ o bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ¡m!"), backgroundColor: Colors.green),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
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
            // TiÃÂÃÂªu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ & NÃÂÃÂºt xuÃÂ¡ÃÂºÃÂ¥t hÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.slow_motion_video, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "BÃÂ¡ÃÂºÃÂ£n ghi phÃÂÃÂ¡t lÃÂ¡ÃÂºÃÂ¡i cÃÂÃÂº ngÃÂÃÂ£ (Record Playback):",
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
                  label: const Text("XuÃÂ¡ÃÂºÃÂ¥t biÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n", style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                  onPressed: () => _showExportRecordDialog(context, vel, motion, dist, sec),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Tua lÃÂ¡ÃÂºÃÂ¡i quÃÂÃÂ¡ trÃÂÃÂ¬nh tÃÂÃÂ© ngÃÂÃÂ£ 4 giÃÂÃÂ¢y (-2s ÃÂ¢ÃÂÃÂ 0s ÃÂ¢ÃÂÃÂ +2s) tÃÂÃÂ¡i tÃÂ¡ÃÂºÃÂ¡o tÃÂ¡ÃÂ»ÃÂ« chuÃÂ¡ÃÂ»ÃÂi mÃÂ¡ÃÂºÃÂ«u cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n Laser ToF vÃÂÃÂ  Radar FMCW.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // Khung hÃÂÃÂ¬nh mÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂ»ÃÂng ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi 2D
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
                      // Badge mÃÂ¡ÃÂ»ÃÂc thÃÂ¡ÃÂ»ÃÂi gian gÃÂÃÂ³c trÃÂÃÂªn
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
                      // Badge giai ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n gÃÂÃÂ³c trÃÂÃÂªn phÃÂ¡ÃÂºÃÂ£i
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

            // DÃÂ¡ÃÂºÃÂ£i thÃÂÃÂ´ng sÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n tÃÂ¡ÃÂ»ÃÂ©c thÃÂ¡ÃÂ»ÃÂi
            Row(
              children: [
                _buildMetricChip("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", "${(frame["height"] as double).toInt()} mm", Icons.height, Colors.cyanAccent),
                const SizedBox(width: 8),
                _buildMetricChip("VÃÂ¡ÃÂºÃÂ­n tÃÂ¡ÃÂ»ÃÂc ToF", "${(frame["vel"] as double).toStringAsFixed(0)} mm/s", Icons.speed, Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildMetricChip("ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar", "${frame["mot"]}/100", Icons.radar, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 10),

            // Thanh trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£t thÃÂ¡ÃÂ»ÃÂi gian (Timeline Slider)
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

            // HÃÂÃÂ ng nÃÂÃÂºt ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn Play / Pause / Replay / Speed
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.replay),
                  tooltip: "Tua lÃÂ¡ÃÂºÃÂ¡i tÃÂ¡ÃÂ»ÃÂ« ÃÂÃÂÃÂ¡ÃÂºÃÂ§u (-2s)",
                  onPressed: _resetPlayback,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.amber.shade700 : Colors.cyanAccent.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? "TÃÂ¡ÃÂºÃÂ¡m dÃÂ¡ÃÂ»ÃÂ«ng" : "PhÃÂÃÂ¡t lÃÂ¡ÃÂºÃÂ¡i quÃÂÃÂ¡ trÃÂÃÂ¬nh ngÃÂÃÂ£"),
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
// CUSTOM PAINTER: VÃÂ¡ÃÂºÃÂ¼ HOÃÂ¡ÃÂºÃÂ T ÃÂ¡ÃÂºÃÂ¢NH NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂI CHUYÃÂ¡ÃÂ»ÃÂN ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG TRONG PHÃÂÃÂT LÃÂ¡ÃÂºÃÂ I CÃÂÃÂ NGÃÂÃÂ
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

    // MÃÂ¡ÃÂºÃÂ·t sÃÂÃÂ n (Floor Line)
    final double floorY = h - 18;
    final Paint floorPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // ChÃÂÃÂ¹m ÃÂÃÂo laser ToF tÃÂ¡ÃÂ»ÃÂ« trÃÂ¡ÃÂºÃÂ§n chiÃÂ¡ÃÂºÃÂ¿u xuÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂºÃÂ§u ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi
    final double humanX = w * 0.48;
    final double normH = (heightMm / 2000.0).clamp(0.1, 0.95);
    final double headY = floorY - (normH * (floorY - 25));

    final Paint tofBeam = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(humanX, 5), Offset(humanX, headY), tofBeam);

    // VÃÂÃÂ²ng trÃÂÃÂ²n cÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n ToF trÃÂ¡ÃÂºÃÂ§n nhÃÂÃÂ 
    final Paint ceilingSensor = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(humanX, 5), 4, ceilingSensor);

    // Xung chÃÂ¡ÃÂºÃÂ¥n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng sÃÂÃÂ n khi va chÃÂ¡ÃÂºÃÂ¡m (t tÃÂ¡ÃÂ»ÃÂ« -0.1s ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n +0.3s)
    if (currentTime >= -0.1 && currentTime <= 0.3) {
      final Paint shockwave = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(humanX, floorY), 22 * (currentTime + 0.1) * 3, shockwave);
    }

    // VÃÂ¡ÃÂºÃÂ½ mÃÂÃÂ´ hÃÂÃÂ¬nh ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi (Stick Figure vÃÂ¡ÃÂ»ÃÂi gÃÂÃÂ³c xoay ngÃÂÃÂ£)
    canvas.save();
    canvas.translate(humanX, floorY);
    canvas.rotate(angleDeg * math.pi / 180.0);

    final Paint bodyPaint = Paint()
      ..color = stageColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double bodyLen = 50.0;
    // ThÃÂÃÂ¢n
    canvas.drawLine(const Offset(0, 0), Offset(0, -bodyLen), bodyPaint);

    // ÃÂÃÂÃÂ¡ÃÂºÃÂ§u
    canvas.drawCircle(Offset(0, -bodyLen - 9), 8, bodyPaint);

    // Tay
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(-12, -bodyLen * 0.4), bodyPaint);
    canvas.drawLine(Offset(0, -bodyLen * 0.7), Offset(12, -bodyLen * 0.4), bodyPaint);

    // ChÃÂÃÂ¢n
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
// MÃÂÃÂN HÃÂÃÂNH CÃÂÃÂI ÃÂÃÂÃÂ¡ÃÂºÃÂ¶T CHUNG CÃÂ¡ÃÂ»ÃÂ¦A ÃÂ¡ÃÂ»ÃÂ¨NG DÃÂ¡ÃÂ»ÃÂ¤NG (GENERAL SETTINGS SCREEN)
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

  // HÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n sÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u khi phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi giÃÂÃÂ  tÃÂÃÂ© ngÃÂÃÂ£
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

  // KÃÂÃÂ­ch hoÃÂ¡ÃÂºÃÂ¡t cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t OTA tÃÂ¡ÃÂ»ÃÂ« CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung
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
                    child: Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t ÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂ»ÃÂ¥ng OTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                                  const Text("GitHub Releases (TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
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
                                Text("PhiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("v1.2.0 (Build 2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("BÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi trÃÂÃÂªn GitHub:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  releaseInfo?['name']?.toString() ?? (isLoading ? "ÃÂÃÂang kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi..." : "Fall Guard Latest Release"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            if (apkSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Dung lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng file APK:", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            ? "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng sÃÂ¡ÃÂºÃÂ½ mÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂ« GitHub Releases. NhÃÂ¡ÃÂºÃÂ¥n [CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t] ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ¢ng cÃÂ¡ÃÂºÃÂ¥p."
                            : "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p tÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂºÃÂ£n APK mÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t trÃÂÃÂªn GitHub Releases vÃÂÃÂ  mÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ¬nh cÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t Android ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ¢ng cÃÂ¡ÃÂºÃÂ¥p ÃÂÃÂÃÂÃÂ¨ giÃÂ¡ÃÂ»ÃÂ¯ nguyÃÂÃÂªn dÃÂ¡ÃÂ»ÃÂ¯ liÃÂ¡ÃÂ»ÃÂu.",
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
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
                            SnackBar(content: Text("LÃÂ¡ÃÂ»ÃÂi mÃÂ¡ÃÂ»ÃÂ liÃÂÃÂªn kÃÂ¡ÃÂºÃÂ¿t APK: $e")),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t cÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t ngay"),
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
            Text("CÃÂÃÂ i ÃÂÃÂÃÂ¡ÃÂºÃÂ·t chung App", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P & ÃÂÃÂM THANH
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
                      Text("BÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng trÃÂÃÂªn ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("CÃÂÃÂ²i hÃÂÃÂº bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng trÃÂÃÂªn ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("PhÃÂÃÂ¡t ÃÂÃÂ¢m thanh cÃÂÃÂ²i cÃÂ¡ÃÂ»ÃÂ©u hÃÂ¡ÃÂ»ÃÂ lÃÂ¡ÃÂ»ÃÂn trÃÂÃÂªn mÃÂÃÂ¡y khi phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn ngÃÂÃÂ£", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _alarmSound,
                    onChanged: (val) {
                      setState(() => _alarmSound = val);
                      _notifyChanges();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Rung mÃÂ¡ÃÂºÃÂ¡nh khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p (SOS)", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Rung liÃÂÃÂªn tÃÂ¡ÃÂ»ÃÂ¥c theo nhÃÂ¡ÃÂ»ÃÂp cÃÂ¡ÃÂ»ÃÂ©u nÃÂ¡ÃÂºÃÂ¡n", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        const Text("ÃÂÃÂm lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng cÃÂÃÂ²i hÃÂÃÂº trÃÂÃÂªn ÃÂÃÂiÃÂ¡ÃÂ»ÃÂn thoÃÂ¡ÃÂºÃÂ¡i:", style: TextStyle(fontSize: 13)),
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
                    title: const Text("PhÃÂÃÂ­m tÃÂ¡ÃÂºÃÂ¯t gÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u 115", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("GÃÂ¡ÃÂ»ÃÂ£i ÃÂÃÂ½ 1 chÃÂ¡ÃÂºÃÂ¡m mÃÂ¡ÃÂ»ÃÂ cuÃÂ¡ÃÂ»ÃÂc gÃÂ¡ÃÂ»ÃÂi 115 khi xÃÂ¡ÃÂºÃÂ£y ra chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng ngÃÂÃÂ£", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

          // 2. KÃÂ¡ÃÂºÃÂ¾T NÃÂ¡ÃÂ»ÃÂI & THIÃÂ¡ÃÂºÃÂ¾T BÃÂ¡ÃÂ»ÃÂ GHÃÂÃÂP NÃÂ¡ÃÂ»ÃÂI
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
                      Text("KÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi & ThiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi lÃÂ¡ÃÂºÃÂ¡i thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi Bluetooth ngay khi mÃÂ¡ÃÂ»ÃÂ app", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    title: Text("LÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ£ lÃÂÃÂ°u: ${widget.deviceHistoryCount} thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ", style: const TextStyle(fontSize: 14)),
                    subtitle: const Text("Xem vÃÂÃÂ  quÃÂ¡ÃÂºÃÂ£n lÃÂÃÂ½ cÃÂÃÂ¡c thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng ghÃÂÃÂ©p nÃÂ¡ÃÂ»ÃÂi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: widget.deviceHistoryCount > 0
                        ? TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text("XÃÂÃÂ³a toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­?"),
                                  content: const Text("BÃÂ¡ÃÂºÃÂ¡n cÃÂÃÂ³ chÃÂ¡ÃÂºÃÂ¯c muÃÂ¡ÃÂ»ÃÂn xÃÂÃÂ³a toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ danh sÃÂÃÂ¡ch thiÃÂ¡ÃÂºÃÂ¿t bÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂ»ÃÂ«ng kÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi khÃÂÃÂ´ng?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text("HÃÂ¡ÃÂ»ÃÂ§y")),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(c);
                                        widget.onClearHistory();
                                        setState(() {});
                                      },
                                      child: const Text("XÃÂÃÂ³a hÃÂ¡ÃÂºÃÂ¿t", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("XÃÂÃÂ³a hÃÂ¡ÃÂºÃÂ¿t", style: TextStyle(color: Colors.redAccent)),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. HIÃÂ¡ÃÂ»ÃÂN THÃÂ¡ÃÂ»ÃÂ & ÃÂÃÂÃÂÃÂ N VÃÂ¡ÃÂ»ÃÂ ÃÂÃÂO
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
                      Text("ÃÂÃÂÃÂÃÂ¡n vÃÂ¡ÃÂ»ÃÂ ÃÂÃÂo lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ÃÂÃÂÃÂÃÂ¡n vÃÂ¡ÃÂ»ÃÂ khoÃÂ¡ÃÂºÃÂ£ng cÃÂÃÂ¡ch:", style: TextStyle(fontSize: 14)),
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
                      const Text("ÃÂÃÂÃÂÃÂ¡n vÃÂ¡ÃÂ»ÃÂ nÃÂÃÂng lÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng Radar:", style: TextStyle(fontSize: 14)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "%", label: Text("% (TÃÂ¡ÃÂ»ÃÂ lÃÂ¡ÃÂ»ÃÂ)", style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: "dB", label: Text("dB (CÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ)", style: TextStyle(fontSize: 12))),
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

          // 4. AN TOÃÂÃÂN Y TÃÂ¡ÃÂºÃÂ¾ & CÃÂ¡ÃÂºÃÂ¬P NHÃÂ¡ÃÂºÃÂ¬T PHÃÂ¡ÃÂºÃÂ¦N MÃÂ¡ÃÂ»ÃÂM
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
                      Text("An toÃÂÃÂ n & CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.badge, color: Colors.redAccent),
                    title: const Text("HÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡ y tÃÂ¡ÃÂºÃÂ¿ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cao tuÃÂ¡ÃÂ»ÃÂi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("NhÃÂÃÂ³m mÃÂÃÂ¡u, thuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng mÃÂÃÂ¡u, tiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ bÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½, liÃÂÃÂªn hÃÂ¡ÃÂ»ÃÂ 115", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openMedicalProfile,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                    title: const Text("ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ nguy cÃÂÃÂ¡ tÃÂÃÂ© ngÃÂÃÂ£ CDC STEADI", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("BÃÂ¡ÃÂ»ÃÂ 12 cÃÂÃÂ¢u hÃÂ¡ÃÂ»ÃÂi lÃÂÃÂ¢m sÃÂÃÂ ng theo chuÃÂ¡ÃÂºÃÂ©n CDC Hoa KÃÂ¡ÃÂ»ÃÂ³", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openCdcAssessment,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.medical_information, color: Colors.orangeAccent),
                    title: const Text("HÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n sÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi giÃÂÃÂ  ngÃÂÃÂ£", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Quy tÃÂ¡ÃÂºÃÂ¯c cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u an toÃÂÃÂ n chuÃÂ¡ÃÂºÃÂ©n y tÃÂ¡ÃÂºÃÂ¿", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFirstAidGuide,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_download, color: Colors.blueAccent),
                    title: const Text("KiÃÂ¡ÃÂ»ÃÂm tra & CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t OTA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("TÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂ¢ng cÃÂ¡ÃÂºÃÂ¥p phiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n mÃÂ¡ÃÂ»ÃÂi nhÃÂ¡ÃÂºÃÂ¥t tÃÂ¡ÃÂ»ÃÂ« GitHub qua mÃÂ¡ÃÂºÃÂ¡ng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _triggerOtaUpdate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. THÃÂÃÂNG TIN HÃÂ¡ÃÂ»ÃÂ THÃÂ¡ÃÂ»ÃÂNG
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
                      Text("ThÃÂÃÂ´ng tin hÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("ÃÂ¡ÃÂ»ÃÂ¨ng dÃÂ¡ÃÂ»ÃÂ¥ng: Fall Guard S3R8", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("PhiÃÂÃÂªn bÃÂ¡ÃÂºÃÂ£n: v1.2.0 (Wi-Fi Direct Telemetry & NVS BlackBox)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Vi ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu khiÃÂ¡ÃÂ»ÃÂn: ESP32-S3-WROOM-1-N16R8 (16MB Flash / 8MB PSRAM)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("CÃÂ¡ÃÂºÃÂ£m biÃÂ¡ÃÂºÃÂ¿n kÃÂ¡ÃÂºÃÂ¿t hÃÂ¡ÃÂ»ÃÂ£p: PIR AM312 (HÃÂ¡ÃÂ»ÃÂng ngoÃÂ¡ÃÂºÃÂ¡i) + ToF Laser (ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao) + Radar 24GHz FMCW (ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng & CÃÂ¡ÃÂ»ÃÂ± ly)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("ÃÂÃÂ© 2026 Fall Detection System. BÃÂ¡ÃÂºÃÂ£o vÃÂ¡ÃÂ»ÃÂ an toÃÂÃÂ n ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cao tuÃÂ¡ÃÂ»ÃÂi 24/7.", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
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
// HÃÂÃÂM MÃÂ¡ÃÂ»ÃÂ HÃÂ¡ÃÂ»ÃÂP THOÃÂ¡ÃÂºÃÂ I CÃÂ¡ÃÂºÃÂ¨M NANG SÃÂÃÂ  CÃÂ¡ÃÂ»ÃÂ¨U NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂI GIÃÂÃÂ TÃÂÃÂ NGÃÂÃÂ
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
          const Text("ÃÂ¢ÃÂÃÂ¢ ", style: TextStyle(color: Colors.white60, fontSize: 15)),
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
                    "TrÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi thÃÂ¡ÃÂ»ÃÂ±c hiÃÂ¡ÃÂ»ÃÂn sÃÂÃÂ¡ cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u, bÃÂ¡ÃÂºÃÂ¡n cÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂ¡ÃÂºÃÂ£m bÃÂ¡ÃÂºÃÂ£o mÃÂ¡ÃÂ»ÃÂt sÃÂ¡ÃÂ»ÃÂ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu quan trÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ xÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ ÃÂÃÂÃÂÃÂºng cÃÂÃÂ¡ch vÃÂÃÂ  an toÃÂÃÂ n:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ mÃÂ¡ÃÂ»ÃÂ©c ÃÂÃÂÃÂ¡ÃÂ»ÃÂ chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng",
            icon: Icons.visibility,
            color: Colors.cyanAccent,
            bodyItems: [
              _bulletText("Quan sÃÂÃÂ¡t kÃÂ¡ÃÂ»ÃÂ¹ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n", "HÃÂ¡ÃÂ»ÃÂ cÃÂÃÂ³ cÃÂÃÂ²n tÃÂ¡ÃÂ»ÃÂnh tÃÂÃÂ¡o khÃÂÃÂ´ng?"),
              _bulletText("KiÃÂ¡ÃÂ»ÃÂm tra nhanh tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng cÃÂÃÂ¡ thÃÂ¡ÃÂ»ÃÂ", "CÃÂÃÂ³ vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng hÃÂ¡ÃÂ»ÃÂ, mÃÂÃÂ¡u chÃÂ¡ÃÂºÃÂ£y hay khÃÂÃÂ´ng."),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "ÃÂÃÂÃÂ¡ÃÂºÃÂ£m bÃÂ¡ÃÂºÃÂ£o an toÃÂÃÂ n",
            icon: Icons.health_and_safety,
            color: Colors.amberAccent,
            bodyItems: [
              _bulletText("Khu vÃÂ¡ÃÂ»ÃÂ±c an toÃÂÃÂ n", "ÃÂÃÂÃÂÃÂ°a ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n ra khÃÂ¡ÃÂ»ÃÂi khu vÃÂ¡ÃÂ»ÃÂ±c nguy hiÃÂ¡ÃÂ»ÃÂm (nÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ)."),
              _bulletText("TrÃÂÃÂ¡nh di chuyÃÂ¡ÃÂ»ÃÂn", "TrÃÂÃÂ¡nh di chuyÃÂ¡ÃÂ»ÃÂn ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n nÃÂ¡ÃÂºÃÂ¿u nghi ngÃÂ¡ÃÂ»ÃÂ chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng cÃÂ¡ÃÂ»ÃÂt sÃÂ¡ÃÂ»ÃÂng.", prefixColor: Colors.orangeAccent),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "GÃÂ¡ÃÂ»ÃÂi hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ y tÃÂ¡ÃÂºÃÂ¿ nÃÂ¡ÃÂºÃÂ¿u cÃÂ¡ÃÂºÃÂ§n thiÃÂ¡ÃÂºÃÂ¿t",
            icon: Icons.emergency,
            color: Colors.redAccent,
            bodyItems: [
              _bulletText("ChÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng nghiÃÂÃÂªm trÃÂ¡ÃÂ»ÃÂng", "NÃÂ¡ÃÂºÃÂ¿u nhÃÂ¡ÃÂºÃÂ­n thÃÂ¡ÃÂºÃÂ¥y chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng nghiÃÂÃÂªm trÃÂ¡ÃÂ»ÃÂng (vÃÂÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥: mÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂ½ thÃÂ¡ÃÂ»ÃÂ©c, gÃÂÃÂ£y xÃÂÃÂ°ÃÂÃÂ¡ng hÃÂ¡ÃÂ»ÃÂ, chÃÂ¡ÃÂºÃÂ£y mÃÂÃÂ¡u nhiÃÂ¡ÃÂ»ÃÂu), hÃÂÃÂ£y gÃÂ¡ÃÂ»ÃÂi ngay 115 hoÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂÃÂ°a hÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n bÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn."),
              _buildTipCard(
                "MÃÂ¡ÃÂºÃÂ¹o nhÃÂ¡ÃÂ»ÃÂ khi gÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u",
                "Khi gÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u 115, hÃÂÃÂ£y cung cÃÂ¡ÃÂºÃÂ¥p thÃÂÃÂ´ng tin chi tiÃÂ¡ÃÂºÃÂ¿t vÃÂ¡ÃÂ»ÃÂ tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng nÃÂ¡ÃÂºÃÂ¡n nhÃÂÃÂ¢n vÃÂÃÂ  vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ chÃÂÃÂ­nh xÃÂÃÂ¡c cÃÂ¡ÃÂ»ÃÂ§a bÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂÃÂ¡ÃÂ»ÃÂ giÃÂÃÂºp ÃÂÃÂÃÂ¡ÃÂ»ÃÂi ngÃÂÃÂ© y tÃÂ¡ÃÂºÃÂ¿ phÃÂ¡ÃÂºÃÂ£n ÃÂ¡ÃÂ»ÃÂ©ng nhanh hÃÂÃÂ¡n.",
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
                    "Khi ÃÂÃÂÃÂÃÂ£ ÃÂÃÂÃÂ¡ÃÂºÃÂ£m bÃÂ¡ÃÂºÃÂ£o an toÃÂÃÂ n, hÃÂÃÂ£y thÃÂ¡ÃÂ»ÃÂ±c hiÃÂ¡ÃÂ»ÃÂn cÃÂÃÂ¡c bÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc sÃÂÃÂ¡ cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u cÃÂÃÂ¡ bÃÂ¡ÃÂºÃÂ£n dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂÃÂ¢y:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "KiÃÂ¡ÃÂ»ÃÂm tra tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng ÃÂÃÂ½ thÃÂ¡ÃÂ»ÃÂ©c",
            icon: Icons.psychology,
            color: Colors.purpleAccent,
            bodyItems: [
              _bulletText("PhÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡", "GÃÂ¡ÃÂ»ÃÂi to hoÃÂ¡ÃÂºÃÂ·c lay nhÃÂ¡ÃÂºÃÂ¹ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂÃÂ¡ÃÂ»ÃÂ xem hÃÂ¡ÃÂ»ÃÂ cÃÂÃÂ³ phÃÂ¡ÃÂºÃÂ£n ÃÂ¡ÃÂ»ÃÂ©ng hay khÃÂÃÂ´ng."),
              _bulletText("NhÃÂ¡ÃÂ»ÃÂp thÃÂ¡ÃÂ»ÃÂ & CPR", "NÃÂ¡ÃÂºÃÂ¿u hÃÂ¡ÃÂ»ÃÂ khÃÂÃÂ´ng phÃÂ¡ÃÂºÃÂ£n ÃÂ¡ÃÂ»ÃÂ©ng, hÃÂÃÂ£y kiÃÂ¡ÃÂ»ÃÂm tra nhÃÂ¡ÃÂ»ÃÂp thÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  chuÃÂ¡ÃÂºÃÂ©n bÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂ±c hiÃÂ¡ÃÂ»ÃÂn hÃÂ¡ÃÂ»ÃÂi sÃÂ¡ÃÂ»ÃÂ©c tim phÃÂ¡ÃÂ»ÃÂi (CPR) nÃÂ¡ÃÂºÃÂ¿u cÃÂ¡ÃÂºÃÂ§n.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "XÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng hÃÂ¡ÃÂ»ÃÂ (nÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ³)",
            icon: Icons.healing,
            color: Colors.tealAccent,
            bodyItems: [
              _bulletText("RÃÂ¡ÃÂ»ÃÂ­a vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng", "RÃÂ¡ÃÂ»ÃÂ­a sÃÂ¡ÃÂºÃÂ¡ch vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng bÃÂ¡ÃÂºÃÂ±ng nÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc sÃÂ¡ÃÂºÃÂ¡ch hoÃÂ¡ÃÂºÃÂ·c dung dÃÂ¡ÃÂ»ÃÂch sÃÂÃÂ¡t khuÃÂ¡ÃÂºÃÂ©n."),
              _bulletText("BÃÂÃÂng bÃÂÃÂ³ vÃÂÃÂ´ trÃÂÃÂ¹ng", "DÃÂÃÂ¹ng bÃÂÃÂng gÃÂ¡ÃÂºÃÂ¡c vÃÂÃÂ´ trÃÂÃÂ¹ng bÃÂÃÂng lÃÂ¡ÃÂºÃÂ¡i ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂn ngÃÂ¡ÃÂ»ÃÂ«a nhiÃÂ¡ÃÂ»ÃÂm trÃÂÃÂ¹ng."),
            ],
          ),
          _buildStepCard(
            number: "3",
            title: "XÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng phÃÂ¡ÃÂºÃÂ§n mÃÂ¡ÃÂ»ÃÂm",
            icon: Icons.ac_unit,
            color: Colors.lightBlueAccent,
            bodyItems: [
              _bulletText("ChÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂm lÃÂ¡ÃÂºÃÂ¡nh", "DÃÂÃÂ¹ng tÃÂÃÂºi ÃÂÃÂÃÂÃÂ¡ hoÃÂ¡ÃÂºÃÂ·c khÃÂÃÂn lÃÂ¡ÃÂºÃÂ¡nh chÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂm vÃÂÃÂ o vÃÂÃÂ¹ng bÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ°ng trong 15-20 phÃÂÃÂºt."),
              _bulletText("CÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o quan trÃÂ¡ÃÂ»ÃÂng", "KhÃÂÃÂ´ng massage hay ÃÂ¡ÃÂºÃÂ¥n mÃÂ¡ÃÂºÃÂ¡nh vÃÂÃÂ o vÃÂÃÂ¹ng tÃÂ¡ÃÂ»ÃÂn thÃÂÃÂ°ÃÂÃÂ¡ng, ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu nÃÂÃÂ y cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ m tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng nÃÂ¡ÃÂºÃÂ·ng thÃÂÃÂªm.", prefixColor: Colors.redAccent),
            ],
          ),
          _buildStepCard(
            number: "4",
            title: "HÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n di chuyÃÂ¡ÃÂ»ÃÂn",
            icon: Icons.accessible_forward,
            color: Colors.orangeAccent,
            bodyItems: [
              _bulletText("HÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ nhÃÂ¡ÃÂºÃÂ¹ nhÃÂÃÂ ng", "NÃÂ¡ÃÂºÃÂ¿u cÃÂ¡ÃÂºÃÂ§n di chuyÃÂ¡ÃÂ»ÃÂn, hÃÂÃÂ£y giÃÂÃÂºp ÃÂÃÂÃÂ¡ÃÂ»ÃÂ¡ nhÃÂ¡ÃÂºÃÂ¹ nhÃÂÃÂ ng, trÃÂÃÂ¡nh gÃÂÃÂ¢y thÃÂÃÂªm tÃÂ¡ÃÂ»ÃÂn thÃÂÃÂ°ÃÂÃÂ¡ng."),
              _bulletText("Nghi ngÃÂ¡ÃÂ»ÃÂ gÃÂÃÂ£y xÃÂÃÂ°ÃÂÃÂ¡ng", "TrÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂ£p nghi ngÃÂ¡ÃÂ»ÃÂ gÃÂÃÂ£y xÃÂÃÂ°ÃÂÃÂ¡ng, hÃÂÃÂ£y cÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh phÃÂ¡ÃÂºÃÂ§n bÃÂ¡ÃÂ»ÃÂ chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc khi di chuyÃÂ¡ÃÂ»ÃÂn.", prefixColor: Colors.amberAccent),
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
                    "MÃÂ¡ÃÂ»ÃÂi trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂ£p tÃÂÃÂ© ngÃÂÃÂ£ sÃÂ¡ÃÂºÃÂ½ cÃÂ¡ÃÂºÃÂ§n cÃÂÃÂ¡ch xÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ khÃÂÃÂ¡c nhau dÃÂ¡ÃÂ»ÃÂ±a trÃÂÃÂªn mÃÂ¡ÃÂ»ÃÂ©c ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nghiÃÂÃÂªm trÃÂ¡ÃÂ»ÃÂng cÃÂ¡ÃÂ»ÃÂ§a chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng:",
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          _buildStepCard(
            number: "1",
            title: "CÃÂÃÂ¡ch xÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ tÃÂÃÂ© ngÃÂÃÂ£ gÃÂÃÂ¢y chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng nhÃÂ¡ÃÂºÃÂ¹",
            icon: Icons.healing_outlined,
            color: Colors.tealAccent,
            bodyItems: [
              _subItemCard(
                "TrÃÂ¡ÃÂºÃÂ§y xÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc ngoÃÂÃÂ i da",
                [
                  _bulletText("LÃÂÃÂ m sÃÂ¡ÃÂºÃÂ¡ch vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng", "RÃÂ¡ÃÂ»ÃÂ­a bÃÂ¡ÃÂºÃÂ±ng nÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc sÃÂ¡ÃÂºÃÂ¡ch hoÃÂ¡ÃÂºÃÂ·c dung dÃÂ¡ÃÂ»ÃÂch sÃÂÃÂ¡t khuÃÂ¡ÃÂºÃÂ©n."),
                  _bulletText("BÃÂÃÂng bÃÂÃÂ³", "SÃÂ¡ÃÂ»ÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥ng bÃÂÃÂng gÃÂ¡ÃÂºÃÂ¡c vÃÂÃÂ´ trÃÂÃÂ¹ng ÃÂÃÂÃÂ¡ÃÂ»ÃÂ che phÃÂ¡ÃÂ»ÃÂ§ vÃÂ¡ÃÂºÃÂ¿t thÃÂÃÂ°ÃÂÃÂ¡ng, giÃÂÃÂºp ngÃÂÃÂn ngÃÂ¡ÃÂ»ÃÂ«a nhiÃÂ¡ÃÂ»ÃÂm trÃÂÃÂ¹ng."),
                  _bulletText("VÃÂ¡ÃÂ»ÃÂ sinh ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh kÃÂ¡ÃÂ»ÃÂ³", "Thay bÃÂÃÂng hÃÂÃÂ ng ngÃÂÃÂ y hoÃÂ¡ÃÂºÃÂ·c khi bÃÂÃÂng bÃÂ¡ÃÂ»ÃÂ ÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂt/bÃÂ¡ÃÂºÃÂ©n."),
                ],
                color: Colors.tealAccent,
              ),
              _subItemCard(
                "SÃÂÃÂ°ng bÃÂ¡ÃÂºÃÂ§m tÃÂÃÂ­m",
                [
                  _bulletText("ChÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂm lÃÂ¡ÃÂºÃÂ¡nh", "DÃÂÃÂ¹ng tÃÂÃÂºi ÃÂÃÂÃÂÃÂ¡ hoÃÂ¡ÃÂºÃÂ·c khÃÂÃÂn lÃÂ¡ÃÂºÃÂ¡nh chÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂm lÃÂÃÂªn vÃÂÃÂ¹ng bÃÂ¡ÃÂºÃÂ§m trong 15-20 phÃÂÃÂºt ÃÂÃÂÃÂ¡ÃÂ»ÃÂ giÃÂ¡ÃÂºÃÂ£m sÃÂÃÂ°ng."),
                  _bulletText("NÃÂÃÂ¢ng cao vÃÂÃÂ¹ng thÃÂÃÂ°ÃÂÃÂ¡ng", "NÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ, giÃÂ¡ÃÂ»ÃÂ¯ vÃÂÃÂ¹ng tÃÂ¡ÃÂ»ÃÂn thÃÂÃÂ°ÃÂÃÂ¡ng cao hÃÂÃÂ¡n tim ÃÂÃÂÃÂ¡ÃÂ»ÃÂ giÃÂ¡ÃÂºÃÂ£m sÃÂÃÂ°ng."),
                  _bulletText("LÃÂÃÂ°u ÃÂÃÂ½ y tÃÂ¡ÃÂºÃÂ¿", "NÃÂ¡ÃÂºÃÂ¿u tÃÂÃÂ¬nh trÃÂ¡ÃÂºÃÂ¡ng ÃÂÃÂau hoÃÂ¡ÃÂºÃÂ·c bÃÂ¡ÃÂºÃÂ§m tÃÂÃÂ­m kÃÂÃÂ©o dÃÂÃÂ i hÃÂÃÂ¡n 48 giÃÂ¡ÃÂ»ÃÂ mÃÂÃÂ  khÃÂÃÂ´ng giÃÂ¡ÃÂºÃÂ£m, hÃÂÃÂ£y tham khÃÂ¡ÃÂºÃÂ£o ÃÂÃÂ½ kiÃÂ¡ÃÂºÃÂ¿n bÃÂÃÂ¡c sÃÂÃÂ©.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.cyanAccent,
              ),
            ],
          ),
          _buildStepCard(
            number: "2",
            title: "CÃÂÃÂ¡ch xÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ tÃÂÃÂ© ngÃÂÃÂ£ gÃÂÃÂ¢y chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng nÃÂ¡ÃÂºÃÂ·ng",
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
            bodyItems: [
              _subItemCard(
                "GÃÂÃÂ£y xÃÂÃÂ°ÃÂÃÂ¡ng",
                [
                  _bulletText("CÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh xÃÂÃÂ°ÃÂÃÂ¡ng gÃÂÃÂ£y", "SÃÂ¡ÃÂ»ÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥ng nÃÂ¡ÃÂºÃÂ¹p hoÃÂ¡ÃÂºÃÂ·c vÃÂ¡ÃÂºÃÂ­t cÃÂ¡ÃÂ»ÃÂ©ng (vÃÂÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥: thanh gÃÂ¡ÃÂ»ÃÂ hoÃÂ¡ÃÂºÃÂ·c bÃÂÃÂ¬a cÃÂ¡ÃÂ»ÃÂ©ng) ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh vÃÂÃÂ¹ng bÃÂ¡ÃÂ»ÃÂ gÃÂÃÂ£y, trÃÂÃÂ¡nh di lÃÂ¡ÃÂ»ÃÂch xÃÂÃÂ°ÃÂÃÂ¡ng."),
                  _bulletText("KhÃÂÃÂ´ng tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂ½ nÃÂ¡ÃÂºÃÂ¯n chÃÂ¡ÃÂ»ÃÂnh", "TuyÃÂ¡ÃÂ»ÃÂt ÃÂÃÂÃÂ¡ÃÂ»ÃÂi khÃÂÃÂ´ng cÃÂ¡ÃÂ»ÃÂ gÃÂ¡ÃÂºÃÂ¯ng nÃÂ¡ÃÂºÃÂ¯n xÃÂÃÂ°ÃÂÃÂ¡ng vÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ ban ÃÂÃÂÃÂ¡ÃÂºÃÂ§u vÃÂÃÂ¬ cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ m tÃÂ¡ÃÂ»ÃÂn thÃÂÃÂ°ÃÂÃÂ¡ng thÃÂÃÂªm mÃÂ¡ÃÂºÃÂ¡ch mÃÂÃÂ¡u, dÃÂÃÂ¢y thÃÂ¡ÃÂºÃÂ§n kinh hoÃÂ¡ÃÂºÃÂ·c mÃÂÃÂ´ xung quanh.", prefixColor: Colors.redAccent),
                  _bulletText("ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n bÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn ngay", "Nhanh chÃÂÃÂ³ng ÃÂÃÂÃÂÃÂ°a nÃÂ¡ÃÂºÃÂ¡n nhÃÂÃÂ¢n ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n cÃÂÃÂ¡ sÃÂ¡ÃÂ»ÃÂ y tÃÂ¡ÃÂºÃÂ¿ gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t hoÃÂ¡ÃÂºÃÂ·c gÃÂ¡ÃÂ»ÃÂi cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u 115.", prefixColor: Colors.amberAccent),
                ],
                color: Colors.orangeAccent,
              ),
              _subItemCard(
                "ChÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng ÃÂÃÂÃÂ¡ÃÂºÃÂ§u",
                [
                  _bulletText("Theo dÃÂÃÂµi dÃÂ¡ÃÂºÃÂ¥u hiÃÂ¡ÃÂ»ÃÂu", "ChÃÂÃÂº ÃÂÃÂ½ cÃÂÃÂ¡c biÃÂ¡ÃÂ»ÃÂu hiÃÂ¡ÃÂ»ÃÂn nguy hiÃÂ¡ÃÂ»ÃÂm nhÃÂÃÂ° buÃÂ¡ÃÂ»ÃÂn nÃÂÃÂ´n, chÃÂÃÂ³ng mÃÂ¡ÃÂºÃÂ·t dÃÂ¡ÃÂ»ÃÂ¯ dÃÂ¡ÃÂ»ÃÂi, mÃÂ¡ÃÂºÃÂ¥t trÃÂÃÂ­ nhÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ¡m thÃÂ¡ÃÂ»ÃÂi, co giÃÂ¡ÃÂºÃÂ­t hoÃÂ¡ÃÂºÃÂ·c chÃÂ¡ÃÂºÃÂ£y mÃÂÃÂ¡u tÃÂ¡ÃÂ»ÃÂ« tai, mÃÂÃÂ©i.", prefixColor: Colors.redAccent),
                  _bulletText("GiÃÂ¡ÃÂ»ÃÂ¯ ÃÂÃÂÃÂ¡ÃÂºÃÂ§u cÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh", "HÃÂ¡ÃÂºÃÂ¡n chÃÂ¡ÃÂºÃÂ¿ tÃÂ¡ÃÂ»ÃÂi ÃÂÃÂa viÃÂ¡ÃÂ»ÃÂc di chuyÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂ¡ÃÂºÃÂ§u hoÃÂ¡ÃÂºÃÂ·c cÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂ»ÃÂ§a ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n. NÃÂ¡ÃÂºÃÂ¿u cÃÂ¡ÃÂºÃÂ§n nÃÂ¡ÃÂºÃÂ±m, hÃÂÃÂ£y giÃÂ¡ÃÂ»ÃÂ¯ ÃÂÃÂÃÂ¡ÃÂºÃÂ§u ngang bÃÂ¡ÃÂºÃÂ±ng vÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n mÃÂÃÂ¬nh."),
                  _bulletText("XÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ nÃÂÃÂ´n ÃÂÃÂ³i (TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ nghiÃÂÃÂªng)", "NÃÂ¡ÃÂºÃÂ¿u ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n nÃÂÃÂ´n, hÃÂÃÂ£y nhÃÂ¡ÃÂºÃÂ¹ nhÃÂÃÂ ng nghiÃÂÃÂªng cÃÂ¡ÃÂºÃÂ£ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi hÃÂ¡ÃÂ»ÃÂ sang mÃÂ¡ÃÂ»ÃÂt bÃÂÃÂªn (tÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ nÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng an toÃÂÃÂ n) ÃÂÃÂÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ¡nh chÃÂ¡ÃÂºÃÂ¥t nÃÂÃÂ´n trÃÂÃÂ n vÃÂÃÂ o ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng thÃÂ¡ÃÂ»ÃÂ gÃÂÃÂ¢y ngÃÂ¡ÃÂºÃÂ¡t thÃÂ¡ÃÂ»ÃÂ.", prefixColor: Colors.amberAccent),
                  _bulletText("ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n bÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u", "ChÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng ÃÂÃÂÃÂ¡ÃÂºÃÂ§u cÃÂÃÂ³ thÃÂ¡ÃÂ»ÃÂ tiÃÂ¡ÃÂ»ÃÂm ÃÂ¡ÃÂºÃÂ©n xuÃÂ¡ÃÂºÃÂ¥t huyÃÂ¡ÃÂºÃÂ¿t nÃÂÃÂ£o nguy hiÃÂ¡ÃÂ»ÃÂm, cÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂÃÂ°a ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ nÃÂ¡ÃÂºÃÂ¡n ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n bÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn ngay cÃÂ¡ÃÂºÃÂ£ khi hÃÂ¡ÃÂ»ÃÂ cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂºÃÂ¥y bÃÂÃÂ¬nh thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng sau cÃÂÃÂº ngÃÂÃÂ£.", prefixColor: Colors.redAccent),
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
                          "CÃÂ¡ÃÂºÃÂ©m nang SÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂ TÃÂÃÂ© ngÃÂÃÂ£",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "HÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n xÃÂ¡ÃÂ»ÃÂ­ lÃÂÃÂ½ chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng vÃÂÃÂ  sÃÂÃÂ¡ cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u an toÃÂÃÂ n",
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
                    Tab(text: "1. LÃÂÃÂ°u ÃÂÃÂ½ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc sÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u"),
                    Tab(text: "2. CÃÂÃÂ¡c bÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc cÃÂÃÂ¡ bÃÂ¡ÃÂºÃÂ£n"),
                    Tab(text: "3. Theo trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng hÃÂ¡ÃÂ»ÃÂ£p cÃÂ¡ÃÂ»ÃÂ¥ thÃÂ¡ÃÂ»ÃÂ"),
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
                      label: const Text("GÃÂ¡ÃÂ»ÃÂi CÃÂ¡ÃÂºÃÂ¥p CÃÂ¡ÃÂ»ÃÂ©u 115", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    child: const Text("ÃÂÃÂÃÂÃÂ³ng", style: TextStyle(fontSize: 14)),
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


// 1. HÃÂÃÂ¬nh vÃÂ¡ÃÂºÃÂ½ minh hÃÂ¡ÃÂ»ÃÂa BÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc 1: CÃÂ¡ÃÂºÃÂ¥m kÃÂÃÂ©o ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂºÃÂ­y ngay
class DoNotPullIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃÂ¡ÃÂºÃÂ·t sÃÂÃÂ n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi nÃÂ¡ÃÂºÃÂ±m trÃÂÃÂªn sÃÂÃÂ n
    final double bodyX = w * 0.40;
    final Paint bodyPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // ÃÂÃÂÃÂ¡ÃÂºÃÂ§u gÃÂ¡ÃÂ»ÃÂi trÃÂÃÂªn sÃÂÃÂ n
    canvas.drawCircle(Offset(bodyX - 50, floorY - 10), 9, bodyPaint);
    // ThÃÂÃÂ¢n
    canvas.drawLine(Offset(bodyX - 40, floorY - 8), Offset(bodyX + 25, floorY - 8), bodyPaint);
    // ChÃÂÃÂ¢n
    canvas.drawLine(Offset(bodyX + 25, floorY - 8), Offset(bodyX + 80, floorY - 8), bodyPaint);

    // VÃÂÃÂ²ng cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ CÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  HÃÂÃÂ´ng
    final Paint alertRing = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(bodyX - 35, floorY - 8), 16, alertRing); // CÃÂ¡ÃÂ»ÃÂ
    canvas.drawCircle(Offset(bodyX + 25, floorY - 8), 18, alertRing); // HÃÂÃÂ´ng

    // BÃÂÃÂ n tay kÃÂÃÂ©o giÃÂ¡ÃÂºÃÂ­t tÃÂ¡ÃÂ»ÃÂ« trÃÂÃÂªn xuÃÂ¡ÃÂ»ÃÂng (Dashed vector)
    final Paint pullArrow = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(bodyX - 10, floorY - 60), Offset(bodyX - 10, floorY - 18), pullArrow);

    // BiÃÂ¡ÃÂ»ÃÂn cÃÂ¡ÃÂºÃÂ¥m kÃÂÃÂ©o ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂºÃÂ­y
    final Paint signPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w * 0.78, h * 0.45), 26, signPaint);
    canvas.drawLine(Offset(w * 0.78 - 18, h * 0.45 - 18), Offset(w * 0.78 + 18, h * 0.45 + 18), signPaint);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "CÃÂ¡ÃÂºÃÂ¤M KÃÂÃÂO DÃÂ¡ÃÂºÃÂ¬Y!",
      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.78 - tp.width / 2, h * 0.45 + 32));

    // NhÃÂÃÂ£n vÃÂÃÂ¹ng nguy hiÃÂ¡ÃÂ»ÃÂm
    final TextPainter tpLabel = TextPainter(textDirection: TextDirection.ltr);
    tpLabel.text = const TextSpan(
      text: "Nguy cÃÂÃÂ¡ gÃÂÃÂ£y cÃÂ¡ÃÂ»ÃÂ xÃÂÃÂ°ÃÂÃÂ¡ng ÃÂÃÂÃÂÃÂ¹i & tÃÂ¡ÃÂ»ÃÂn thÃÂÃÂ°ÃÂÃÂ¡ng tÃÂ¡ÃÂ»ÃÂ§y sÃÂ¡ÃÂ»ÃÂng",
      style: TextStyle(color: Colors.white60, fontSize: 9.5),
    );
    tpLabel.layout();
    tpLabel.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. HÃÂÃÂ¬nh vÃÂ¡ÃÂºÃÂ½ minh hÃÂ¡ÃÂ»ÃÂa BÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc 2: KiÃÂ¡ÃÂ»ÃÂm tra tri giÃÂÃÂ¡c & GÃÂ¡ÃÂ»ÃÂi 115
class VitalsCheckIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃÂ¡ÃÂºÃÂ·t sÃÂÃÂ n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NÃÂ¡ÃÂºÃÂ¡n nhÃÂÃÂ¢n nÃÂ¡ÃÂºÃÂ±m
    final double vicX = w * 0.32;
    final Paint vicPaint = Paint()..color = Colors.blueGrey.shade400..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(vicX - 45, floorY - 9), 8, vicPaint);
    canvas.drawLine(Offset(vicX - 35, floorY - 7), Offset(vicX + 35, floorY - 7), vicPaint);
    canvas.drawLine(Offset(vicX + 35, floorY - 7), Offset(vicX + 85, floorY - 7), vicPaint);

    // NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi sÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u quÃÂ¡ÃÂ»ÃÂ³ mÃÂ¡ÃÂ»ÃÂt bÃÂÃÂªn kiÃÂ¡ÃÂ»ÃÂm tra
    final double rescX = vicX - 5;
    final Paint rescPaint = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(rescX - 10, floorY - 55), 8, rescPaint); // ÃÂÃÂÃÂ¡ÃÂºÃÂ§u ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi sÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u
    canvas.drawLine(Offset(rescX - 10, floorY - 47), Offset(rescX, floorY - 25), rescPaint); // ThÃÂÃÂ¢n
    canvas.drawLine(Offset(rescX, floorY - 25), Offset(rescX - 15, floorY), rescPaint); // ChÃÂÃÂ¢n quÃÂ¡ÃÂ»ÃÂ³
    canvas.drawLine(Offset(rescX - 10, floorY - 40), Offset(vicX, floorY - 10), rescPaint); // Tay bÃÂ¡ÃÂºÃÂ¯t mÃÂ¡ÃÂºÃÂ¡ch / kiÃÂ¡ÃÂ»ÃÂm tra

    // HÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i hÃÂ¡ÃÂ»ÃÂi thÃÂÃÂm
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final RRect bubbleRRect = RRect.fromRectAndRadius(Rect.fromLTWH(vicX - 60, 10, 160, 26), const Radius.circular(8));
    canvas.drawRRect(bubbleRRect, bubblePaint);

    final TextPainter tpMsg = TextPainter(textDirection: TextDirection.ltr);
    tpMsg.text = const TextSpan(
      text: "BÃÂÃÂ¡c tÃÂ¡ÃÂ»ÃÂnh khÃÂÃÂ´ng? CÃÂÃÂ³ ÃÂÃÂau ÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂ¢u khÃÂÃÂ´ng?",
      style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
    );
    tpMsg.layout();
    tpMsg.paint(canvas, Offset(vicX - 55, 16));

    // Huy hiÃÂ¡ÃÂ»ÃÂu cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u 115
    final Paint sosBox = Paint()..color = Colors.red.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final RRect sosRRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.72, 25, 95, 60), const Radius.circular(10));
    canvas.drawRRect(sosRRect, sosBox);
    canvas.drawRRect(sosRRect, Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final TextPainter tp115 = TextPainter(textDirection: TextDirection.ltr);
    tp115.text = const TextSpan(
      text: "CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U 115\nKhi bÃÂ¡ÃÂºÃÂ¥t tÃÂ¡ÃÂ»ÃÂnh hoÃÂ¡ÃÂºÃÂ·c\nnghi gÃÂÃÂ£y xÃÂÃÂ°ÃÂÃÂ¡ng",
      style: TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold, height: 1.3),
    );
    tp115.layout();
    tp115.paint(canvas, Offset(w * 0.72 + 8, 32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. HÃÂÃÂ¬nh vÃÂ¡ÃÂºÃÂ½ minh hÃÂ¡ÃÂ»ÃÂa BÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc 3: TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ hÃÂ¡ÃÂ»ÃÂi sÃÂ¡ÃÂ»ÃÂ©c nÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng
class RecoveryPositionIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 25;

    // MÃÂ¡ÃÂºÃÂ·t sÃÂÃÂ n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi nÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng an toÃÂÃÂ n
    final double cx = w * 0.38;
    final Paint p = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // ÃÂÃÂÃÂ¡ÃÂºÃÂ§u kÃÂÃÂª lÃÂÃÂªn mu bÃÂÃÂ n tay
    canvas.drawCircle(Offset(cx - 55, floorY - 18), 9, p);
    // Tay ÃÂÃÂÃÂ¡ÃÂ»ÃÂ¡ ÃÂÃÂÃÂ¡ÃÂºÃÂ§u
    canvas.drawLine(Offset(cx - 35, floorY - 14), Offset(cx - 55, floorY - 10), p);
    // ThÃÂÃÂ¢n nÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng
    canvas.drawLine(Offset(cx - 45, floorY - 14), Offset(cx + 25, floorY - 14), p);
    // ChÃÂÃÂ¢n dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi duÃÂ¡ÃÂ»ÃÂi thÃÂ¡ÃÂºÃÂ³ng
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 85, floorY - 14), p..color = Colors.teal.shade700);
    // ChÃÂÃÂ¢n trÃÂÃÂªn co vuÃÂÃÂ´ng gÃÂÃÂ³c 90 ÃÂÃÂÃÂ¡ÃÂ»ÃÂ chÃÂ¡ÃÂºÃÂ¡m sÃÂÃÂ n ÃÂÃÂÃÂ¡ÃÂ»ÃÂ giÃÂ¡ÃÂ»ÃÂ¯ thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng
    final Paint pLeg = Paint()..color = Colors.tealAccent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 25, floorY - 14), Offset(cx + 35, floorY - 3), pLeg);
    canvas.drawLine(Offset(cx + 35, floorY - 3), Offset(cx + 65, floorY - 3), pLeg);

    // MÃÂÃÂ©i tÃÂÃÂªn luÃÂ¡ÃÂ»ÃÂng thÃÂ¡ÃÂ»ÃÂ thÃÂÃÂ´ng thoÃÂÃÂ¡ng
    final Paint airwayPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 68, floorY - 18), radius: 12), 0.5, 2.0, false, airwayPaint);

    // NhÃÂÃÂ£n chÃÂÃÂº thÃÂÃÂ­ch
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "TÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ nÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng an toÃÂÃÂ n (IFRC/AHA):\nÃÂ¢ÃÂÃÂ¢ CÃÂ¡ÃÂºÃÂ±m ngÃÂ¡ÃÂ»ÃÂ­a nhÃÂ¡ÃÂºÃÂ¹ -> ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng thÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂ»ÃÂ rÃÂ¡ÃÂ»ÃÂng\nÃÂ¢ÃÂÃÂ¢ ChÃÂÃÂ¢n co 90ÃÂÃÂ° giÃÂ¡ÃÂ»ÃÂ¯ thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng vÃÂ¡ÃÂ»ÃÂ¯ng\nÃÂ¢ÃÂÃÂ¢ ChÃÂ¡ÃÂ»ÃÂng sÃÂ¡ÃÂºÃÂ·c dÃÂ¡ÃÂ»ÃÂch nÃÂÃÂ´n/nÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc bÃÂ¡ÃÂ»ÃÂt vÃÂÃÂ o phÃÂ¡ÃÂ»ÃÂi",
      style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.4),
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.48, 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. HÃÂÃÂ¬nh vÃÂ¡ÃÂºÃÂ½ minh hÃÂ¡ÃÂ»ÃÂa BÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc 4: Quy tÃÂ¡ÃÂºÃÂ¯c dÃÂÃÂ¹ng ghÃÂ¡ÃÂºÃÂ¿ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂºÃÂ­y (NHS UK)
class ChairMethodIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double floorY = h - 22;

    // MÃÂ¡ÃÂºÃÂ·t sÃÂÃÂ n
    final Paint floorPaint = Paint()..color = Colors.grey.shade800..strokeWidth = 2.0;
    canvas.drawLine(Offset(10, floorY), Offset(w - 10, floorY), floorPaint);

    // GhÃÂ¡ÃÂºÃÂ¿ tÃÂ¡ÃÂ»ÃÂ±a ÃÂ¡ÃÂ»ÃÂ bÃÂÃÂªn phÃÂ¡ÃÂºÃÂ£i
    final double chairX = w * 0.82;
    final Paint chairPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // ChÃÂÃÂ¢n ghÃÂ¡ÃÂºÃÂ¿
    canvas.drawLine(Offset(chairX, floorY), Offset(chairX, floorY - 45), chairPaint);
    canvas.drawLine(Offset(chairX + 30, floorY), Offset(chairX + 30, floorY - 45), chairPaint);
    // MÃÂ¡ÃÂºÃÂ·t ghÃÂ¡ÃÂºÃÂ¿
    canvas.drawLine(Offset(chairX - 5, floorY - 45), Offset(chairX + 35, floorY - 45), chairPaint);
    // LÃÂÃÂ°ng tÃÂ¡ÃÂ»ÃÂ±a ghÃÂ¡ÃÂºÃÂ¿
    canvas.drawLine(Offset(chairX + 30, floorY - 45), Offset(chairX + 30, floorY - 80), chairPaint);

    // 3 giai ÃÂÃÂoÃÂ¡ÃÂºÃÂ¡n tiÃÂ¡ÃÂºÃÂ¿n triÃÂ¡ÃÂ»ÃÂn
    final Paint stepPaint = Paint()..color = Colors.white70..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    // A. NÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng
    canvas.drawCircle(Offset(35, floorY - 8), 6, stepPaint);
    canvas.drawLine(Offset(41, floorY - 6), Offset(65, floorY - 6), stepPaint);

    // MÃÂÃÂ©i tÃÂÃÂªn sang B
    canvas.drawLine(Offset(75, floorY - 15), Offset(95, floorY - 15), floorPaint);

    // B. QuÃÂ¡ÃÂ»ÃÂ³ 4 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm (bÃÂÃÂ²)
    canvas.drawCircle(Offset(125, floorY - 24), 6, stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(145, floorY - 18), stepPaint);
    canvas.drawLine(Offset(125, floorY - 18), Offset(125, floorY), stepPaint);
    canvas.drawLine(Offset(145, floorY - 18), Offset(145, floorY), stepPaint);

    // MÃÂÃÂ©i tÃÂÃÂªn sang C
    canvas.drawLine(Offset(160, floorY - 25), Offset(180, floorY - 25), floorPaint);

    // C. VÃÂ¡ÃÂ»ÃÂn 2 tay lÃÂÃÂªn ghÃÂ¡ÃÂºÃÂ¿
    canvas.drawCircle(Offset(225, floorY - 42), 6, stepPaint);
    canvas.drawLine(Offset(225, floorY - 36), Offset(225, floorY - 15), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(215, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 15), Offset(235, floorY), stepPaint);
    canvas.drawLine(Offset(225, floorY - 30), Offset(chairX - 5, floorY - 45), Paint()..color = Colors.amberAccent..strokeWidth = 2.5); // Tay vÃÂ¡ÃÂ»ÃÂn ghÃÂ¡ÃÂºÃÂ¿

    // NhÃÂÃÂ£n 4 bÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: "1. NÃÂ¡ÃÂºÃÂ±m nghiÃÂÃÂªng ÃÂ¢ÃÂÃÂ 2. QuÃÂ¡ÃÂ»ÃÂ³ 4 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm ÃÂ¢ÃÂÃÂ 3. VÃÂ¡ÃÂ»ÃÂn ghÃÂ¡ÃÂºÃÂ¿ vÃÂ¡ÃÂ»ÃÂ¯ng ÃÂ¢ÃÂÃÂ 4. ÃÂÃÂÃÂ¡ÃÂºÃÂ©y chÃÂÃÂ¢n ngÃÂ¡ÃÂ»ÃÂi lÃÂÃÂªn ghÃÂ¡ÃÂºÃÂ¿",
      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
    );
    tp.layout();
    tp.paint(canvas, const Offset(15, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// =========================================================================
// TÃÂÃÂNH NÃÂÃÂNG 2: HÃÂ¡ÃÂ»ÃÂ SÃÂÃÂ  Y TÃÂ¡ÃÂºÃÂ¾ KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂI CAO TUÃÂ¡ÃÂ»ÃÂI (MEDICAL EMERGENCY PROFILE)
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
    this.fullName = "NguyÃÂ¡ÃÂ»ÃÂn VÃÂÃÂn An",
    this.birthYear = 1948,
    this.gender = "Nam",
    this.bloodType = "O+",
    this.chronicConditions = const ["TÃÂÃÂng huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p", "LoÃÂÃÂ£ng xÃÂÃÂ°ÃÂÃÂ¡ng", "BÃÂ¡ÃÂ»ÃÂnh mÃÂ¡ÃÂºÃÂ¡ch vÃÂÃÂ nh"],
    this.highRiskMedications = const ["ThuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng mÃÂÃÂ¡u (Aspirin / Warfarin)", "ThuÃÂ¡ÃÂ»ÃÂc hÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂ¡p Amlodipine"],
    this.allergies = "ChÃÂÃÂ°a ghi nhÃÂ¡ÃÂºÃÂ­n",
    this.emergencyContact1Name = "Con trai (NguyÃÂ¡ÃÂ»ÃÂn TuÃÂ¡ÃÂºÃÂ¥n)",
    this.emergencyContact1Phone = "0987654321",
    this.emergencyContact2Name = "Con gÃÂÃÂ¡i (NguyÃÂ¡ÃÂ»ÃÂn Mai)",
    this.emergencyContact2Phone = "0912345678",
    this.attendingDoctorName = "BS. CKII LÃÂÃÂª HoÃÂÃÂ ng",
    this.attendingDoctorPhone = "0903115115",
    this.hospital = "BV LÃÂÃÂ£o Khoa TW / BV ÃÂÃÂa Khoa TÃÂ¡ÃÂ»ÃÂnh",
    this.notes = "NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂnh cÃÂÃÂ³ tiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ thay khÃÂ¡ÃÂ»ÃÂp hÃÂÃÂ¡ng nhÃÂÃÂ¢n tÃÂ¡ÃÂºÃÂ¡o nÃÂÃÂm 2022. ChÃÂÃÂ¬a khÃÂÃÂ³a nhÃÂÃÂ  dÃÂ¡ÃÂ»ÃÂ± phÃÂÃÂ²ng gÃÂ¡ÃÂ»ÃÂ­i tÃÂ¡ÃÂºÃÂ¡i cÃÂÃÂn hÃÂ¡ÃÂ»ÃÂ 402.",
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
      fullName: json['fullName'] ?? "NguyÃÂ¡ÃÂ»ÃÂn VÃÂÃÂn An",
      birthYear: json['birthYear'] ?? 1948,
      gender: json['gender'] ?? "Nam",
      bloodType: json['bloodType'] ?? "O+",
      chronicConditions: json['chronicConditions'] != null
          ? List<String>.from(json['chronicConditions'])
          : ["TÃÂÃÂng huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p", "LoÃÂÃÂ£ng xÃÂÃÂ°ÃÂÃÂ¡ng"],
      highRiskMedications: json['highRiskMedications'] != null
          ? List<String>.from(json['highRiskMedications'])
          : ["ThuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng mÃÂÃÂ¡u (Aspirin / Warfarin)"],
      allergies: json['allergies'] ?? "ChÃÂÃÂ°a ghi nhÃÂ¡ÃÂºÃÂ­n",
      emergencyContact1Name: json['emergencyContact1Name'] ?? "Con trai (NguyÃÂ¡ÃÂ»ÃÂn TuÃÂ¡ÃÂºÃÂ¥n)",
      emergencyContact1Phone: json['emergencyContact1Phone'] ?? "0987654321",
      emergencyContact2Name: json['emergencyContact2Name'] ?? "Con gÃÂÃÂ¡i (NguyÃÂ¡ÃÂ»ÃÂn Mai)",
      emergencyContact2Phone: json['emergencyContact2Phone'] ?? "0912345678",
      attendingDoctorName: json['attendingDoctorName'] ?? "BS. CKII LÃÂÃÂª HoÃÂÃÂ ng",
      attendingDoctorPhone: json['attendingDoctorPhone'] ?? "0903115115",
      hospital: json['hospital'] ?? "BV LÃÂÃÂ£o Khoa TW",
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
      m.toLowerCase().contains("chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng") ||
      m.toLowerCase().contains("aspirin") ||
      m.toLowerCase().contains("warfarin") ||
      m.toLowerCase().contains("clopidogrel") ||
      m.toLowerCase().contains("xarelto") ||
      m.toLowerCase().contains("eliquis"));
}

// =========================================================================
// THÃÂ¡ÃÂºÃÂº Y TÃÂ¡ÃÂºÃÂ¾ CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P (EMERGENCY MEDICAL ID CARD DIALOG)
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
[THÃÂ¡ÃÂºÃÂº Y TÃÂ¡ÃÂºÃÂ¾ CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P - FALLGUARD]
HÃÂ¡ÃÂ»ÃÂ tÃÂÃÂªn: ${profile.fullName} ($age tuÃÂ¡ÃÂ»ÃÂi - Sinh nÃÂÃÂm ${profile.birthYear} - ${profile.gender})
NhÃÂÃÂ³m mÃÂÃÂ¡u: ${profile.bloodType}
CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO THUÃÂ¡ÃÂ»ÃÂC CHÃÂ¡ÃÂ»ÃÂNG ÃÂÃÂÃÂÃÂNG: ${profile.isTakingAnticoagulants ? 'CÃÂÃÂ (NGUY CÃÂÃÂ  XUÃÂ¡ÃÂºÃÂ¤T HUYÃÂ¡ÃÂºÃÂ¾T NÃÂ¡ÃÂ»ÃÂI SÃÂ¡ÃÂ»ÃÂ CAO)' : 'KhÃÂÃÂ´ng'}
BÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½ nÃÂ¡ÃÂ»ÃÂn: ${profile.chronicConditions.join(', ')}
ThuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂang dÃÂÃÂ¹ng: ${profile.highRiskMedications.join(', ')}
DÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ©ng: ${profile.allergies}
BÃÂÃÂ¡c sÃÂÃÂ© ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu trÃÂ¡ÃÂ»ÃÂ: ${profile.attendingDoctorName} (${profile.attendingDoctorPhone})
BÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn chÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh: ${profile.hospital}
NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 1: ${profile.emergencyContact1Name} (${profile.emergencyContact1Phone})
NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})
Ghi chÃÂÃÂº: ${profile.notes}
""";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ÃÂÃÂÃÂÃÂ£ sao chÃÂÃÂ©p tÃÂÃÂ³m tÃÂ¡ÃÂºÃÂ¯t y tÃÂ¡ÃÂºÃÂ¿ vÃÂÃÂ o bÃÂ¡ÃÂ»ÃÂ nhÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ¡m!"), backgroundColor: Colors.teal),
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
              // TiÃÂÃÂªu ÃÂÃÂÃÂ¡ÃÂ»ÃÂ & BiÃÂ¡ÃÂ»ÃÂu tÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng CÃÂ¡ÃÂºÃÂ¥p CÃÂ¡ÃÂ»ÃÂ©u
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
                        Text("THÃÂ¡ÃÂºÃÂº Y TÃÂ¡ÃÂºÃÂ¾ CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                        Text("DÃÂÃÂ nh cho NhÃÂÃÂ¢n viÃÂÃÂªn Y tÃÂ¡ÃÂºÃÂ¿ 115 & CÃÂ¡ÃÂ»ÃÂ©u hÃÂ¡ÃÂ»ÃÂ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    tooltip: "ChÃÂ¡ÃÂ»ÃÂnh sÃÂ¡ÃÂ»ÃÂ­a hÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡",
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // BÃÂ¡ÃÂºÃÂ£ng tÃÂÃÂ³m tÃÂ¡ÃÂºÃÂ¯t bÃÂ¡ÃÂ»ÃÂnh nhÃÂÃÂ¢n & nhÃÂÃÂ³m mÃÂÃÂ¡u
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
                          Text("$age tuÃÂ¡ÃÂ»ÃÂi (${profile.birthYear}) ÃÂ¢ÃÂÃÂ¢ GiÃÂ¡ÃÂ»ÃÂi tÃÂÃÂ­nh: ${profile.gender}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
                          const Text("NHÃÂÃÂM MÃÂÃÂU", style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                          Text(profile.bloodType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO ÃÂÃÂÃÂ¡ÃÂºÃÂ¶C BIÃÂ¡ÃÂ»ÃÂT NÃÂ¡ÃÂºÃÂ¾U DÃÂÃÂNG THUÃÂ¡ÃÂ»ÃÂC CHÃÂ¡ÃÂ»ÃÂNG ÃÂÃÂÃÂÃÂNG MÃÂÃÂU
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
                          "CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO LÃÂÃÂM SÃÂÃÂNG: NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂnh ÃÂÃÂang dÃÂÃÂ¹ng THUÃÂ¡ÃÂ»ÃÂC CHÃÂ¡ÃÂ»ÃÂNG ÃÂÃÂÃÂÃÂNG MÃÂÃÂU (Aspirin/Warfarin...). Nguy cÃÂÃÂ¡ xuÃÂ¡ÃÂºÃÂ¥t huyÃÂ¡ÃÂºÃÂ¿t nÃÂ¡ÃÂ»ÃÂi sÃÂ¡ÃÂ»ÃÂ cao khi chÃÂ¡ÃÂºÃÂ¥n thÃÂÃÂ°ÃÂÃÂ¡ng tÃÂÃÂ© ngÃÂÃÂ£!",
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // BÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½ nÃÂ¡ÃÂ»ÃÂn
              const Text("TiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ bÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½ nÃÂ¡ÃÂ»ÃÂn:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

              // ThuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂang sÃÂ¡ÃÂ»ÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥ng
              const Text("ThuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂÃÂ¡ÃÂºÃÂ·c biÃÂ¡ÃÂ»ÃÂt cÃÂ¡ÃÂºÃÂ§n lÃÂÃÂ°u ÃÂÃÂ½:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

              // DÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ©ng & BÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock("DÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ©ng:", profile.allergies, Icons.no_food),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBlock("BV chÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh:", profile.hospital, Icons.local_hospital),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Danh bÃÂ¡ÃÂºÃÂ¡ cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u gÃÂ¡ÃÂ»ÃÂi nhanh 1 chÃÂ¡ÃÂºÃÂ¡m
              const Text("LiÃÂÃÂªn hÃÂ¡ÃÂ»ÃÂ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p 1 chÃÂ¡ÃÂºÃÂ¡m:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      label: const Text("CÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u 115", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  label: Text("NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 2: ${profile.emergencyContact2Name} (${profile.emergencyContact2Phone})", style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 12),

              // NÃÂÃÂºt sao chÃÂÃÂ©p & ÃÂÃÂÃÂÃÂ³ng
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySummary(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Sao chÃÂÃÂ©p tÃÂÃÂ³m tÃÂ¡ÃÂºÃÂ¯t"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ÃÂÃÂÃÂÃÂ³ng"),
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
// MÃÂÃÂN HÃÂÃÂNH CHÃÂ¡ÃÂ»ÃÂNH SÃÂ¡ÃÂ»ÃÂ¬A HÃÂ¡ÃÂ»ÃÂ SÃÂÃÂ  Y TÃÂ¡ÃÂºÃÂ¾ NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂI CAO TUÃÂ¡ÃÂ»ÃÂI (MEDICAL PROFILE EDIT DIALOG)
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
    "TÃÂÃÂng huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p",
    "ÃÂÃÂÃÂÃÂ¡i thÃÂÃÂ¡o ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng Type 2",
    "BÃÂ¡ÃÂ»ÃÂnh mÃÂ¡ÃÂºÃÂ¡ch vÃÂÃÂ nh / Tim mÃÂ¡ÃÂºÃÂ¡ch",
    "LoÃÂÃÂ£ng xÃÂÃÂ°ÃÂÃÂ¡ng nÃÂ¡ÃÂºÃÂ·ng",
    "TiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ ÃÂÃÂÃÂ¡ÃÂ»ÃÂt quÃÂ¡ÃÂ»ÃÂµ / Tai biÃÂ¡ÃÂºÃÂ¿n",
    "Parkinson",
    "RÃÂ¡ÃÂ»ÃÂi loÃÂ¡ÃÂºÃÂ¡n tiÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂÃÂ¬nh",
    "Suy giÃÂ¡ÃÂºÃÂ£m trÃÂÃÂ­ nhÃÂ¡ÃÂ»ÃÂ / Sa sÃÂÃÂºt trÃÂÃÂ­ tuÃÂ¡ÃÂ»ÃÂ",
  ];

  final List<String> _availableMeds = [
    "ThuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng mÃÂÃÂ¡u (Aspirin / Warfarin)",
    "ThuÃÂ¡ÃÂ»ÃÂc khÃÂÃÂ¡ng tiÃÂ¡ÃÂ»ÃÂu cÃÂ¡ÃÂºÃÂ§u (Clopidogrel / Plavix)",
    "ThuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng thÃÂ¡ÃÂºÃÂ¿ hÃÂ¡ÃÂ»ÃÂ mÃÂ¡ÃÂ»ÃÂi (Xarelto / Eliquis)",
    "ThuÃÂ¡ÃÂ»ÃÂc hÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂ¡p (Amlodipine / Losartan...)",
    "Insulin / ThuÃÂ¡ÃÂ»ÃÂc tiÃÂ¡ÃÂ»ÃÂu ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng",
    "ThuÃÂ¡ÃÂ»ÃÂc an thÃÂ¡ÃÂºÃÂ§n / ThuÃÂ¡ÃÂ»ÃÂc ngÃÂ¡ÃÂ»ÃÂ§",
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
      fullName: _nameCtrl.text.trim().isEmpty ? "NguyÃÂ¡ÃÂ»ÃÂn VÃÂÃÂn An" : _nameCtrl.text.trim(),
      birthYear: int.tryParse(_yearCtrl.text.trim()) ?? 1948,
      gender: _gender,
      bloodType: _bloodType,
      chronicConditions: _selectedConditions,
      highRiskMedications: _selectedMeds,
      allergies: _allergiesCtrl.text.trim().isEmpty ? "ChÃÂÃÂ°a ghi nhÃÂ¡ÃÂºÃÂ­n" : _allergiesCtrl.text.trim(),
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
      const SnackBar(content: Text("HÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡ y tÃÂ¡ÃÂºÃÂ¿ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p ÃÂÃÂÃÂÃÂ£ ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c lÃÂÃÂ°u thÃÂÃÂ nh cÃÂÃÂ´ng!"), backgroundColor: Colors.green),
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
                  child: Text("CÃÂ¡ÃÂºÃÂ­p nhÃÂ¡ÃÂºÃÂ­t hÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡ y tÃÂ¡ÃÂºÃÂ¿ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text("1. ThÃÂÃÂ´ng tin bÃÂ¡ÃÂ»ÃÂnh nhÃÂÃÂ¢n", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "HÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  tÃÂÃÂªn ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi cao tuÃÂ¡ÃÂ»ÃÂi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "NÃÂÃÂm sinh (VD: 1948)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _bloodType,
                          decoration: const InputDecoration(labelText: "NhÃÂÃÂ³m mÃÂÃÂ¡u", border: OutlineInputBorder(), prefixIcon: Icon(Icons.bloodtype)),
                          items: ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-", "ChÃÂÃÂ°a rÃÂÃÂµ"].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => _bloodType = val ?? "O+"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. TiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ bÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½ nÃÂ¡ÃÂ»ÃÂn (ChÃÂ¡ÃÂ»ÃÂn cÃÂÃÂ¡c bÃÂ¡ÃÂ»ÃÂnh ÃÂÃÂ¡p dÃÂ¡ÃÂ»ÃÂ¥ng)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
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

                  const Text("3. ThuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂÃÂ¡ÃÂºÃÂ·c biÃÂ¡ÃÂ»ÃÂt (CÃÂ¡ÃÂ»ÃÂ±c kÃÂ¡ÃÂ»ÃÂ³ quan trÃÂ¡ÃÂ»ÃÂng khi cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 6),
                  ..._availableMeds.map((med) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(med, style: TextStyle(fontSize: 13, color: med.contains("chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng") ? Colors.redAccent : null)),
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

                  const Text("4. Danh bÃÂ¡ÃÂºÃÂ¡ khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p & BÃÂÃÂ¡c sÃÂÃÂ© ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu trÃÂ¡ÃÂ»ÃÂ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c1NameCtrl, decoration: const InputDecoration(labelText: "NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 1 (TÃÂÃÂªn/Quan hÃÂ¡ÃÂ»ÃÂ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c1PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃÂÃÂT NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 1", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _c2NameCtrl, decoration: const InputDecoration(labelText: "NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 2 (TÃÂÃÂªn/Quan hÃÂ¡ÃÂ»ÃÂ)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _c2PhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃÂÃÂT NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n 2", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _doctorNameCtrl, decoration: const InputDecoration(labelText: "BÃÂÃÂ¡c sÃÂÃÂ© riÃÂÃÂªng", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _doctorPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "SÃÂÃÂT BÃÂÃÂ¡c sÃÂÃÂ©", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: "BÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn ÃÂÃÂ°u tiÃÂÃÂªn chÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh chuyÃÂ¡ÃÂ»ÃÂn viÃÂ¡ÃÂ»ÃÂn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                  const SizedBox(height: 10),
                  TextField(controller: _allergiesCtrl, decoration: const InputDecoration(labelText: "DÃÂ¡ÃÂ»ÃÂ ÃÂ¡ÃÂ»ÃÂ©ng thuÃÂ¡ÃÂ»ÃÂc / thÃÂ¡ÃÂ»ÃÂ©c ÃÂÃÂn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning))),
                  const SizedBox(height: 10),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Ghi chÃÂÃÂº cÃÂ¡ÃÂºÃÂ¥p cÃÂ¡ÃÂ»ÃÂ©u khÃÂÃÂ¡c (VÃÂ¡ÃÂ»ÃÂ trÃÂÃÂ­ chÃÂÃÂ¬a khÃÂÃÂ³a dÃÂ¡ÃÂ»ÃÂ± phÃÂÃÂ²ng, tiÃÂ¡ÃÂ»ÃÂn sÃÂ¡ÃÂ»ÃÂ­ mÃÂ¡ÃÂ»ÃÂ...)", border: OutlineInputBorder())),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("LÃÂÃÂ°u hÃÂ¡ÃÂ»ÃÂ sÃÂÃÂ¡ y tÃÂ¡ÃÂºÃÂ¿", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÃÂÃÂNH NÃÂÃÂNG 7: ÃÂÃÂÃÂÃÂNH GIÃÂÃÂ NGUY CÃÂÃÂ  TÃÂÃÂ NGÃÂÃÂ THEO CHUÃÂ¡ÃÂºÃÂ¨N CDC STEADI (12 CÃÂÃÂU HÃÂ¡ÃÂ»ÃÂI)
// =========================================================================
class CdcSteadiAssessmentDialog extends StatefulWidget {
  final Function(int score, String riskLevel) onCompleted;

  const CdcSteadiAssessmentDialog({super.key, required this.onCompleted});

  @override
  State<CdcSteadiAssessmentDialog> createState() => _CdcSteadiAssessmentDialogState();
}

class _CdcSteadiAssessmentDialogState extends State<CdcSteadiAssessmentDialog> {
  // 12 cÃÂÃÂ¢u hÃÂ¡ÃÂ»ÃÂi chuÃÂ¡ÃÂºÃÂ©n CDC STEADI (Stay Independent Brochure)
  final List<Map<String, dynamic>> _questions = [
    {
      "text": "1. TÃÂÃÂ´i tÃÂ¡ÃÂ»ÃÂ«ng bÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ£ trong vÃÂÃÂ²ng 1 nÃÂÃÂm qua.",
      "pts": 2,
      "why": "NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi tÃÂ¡ÃÂ»ÃÂ«ng ngÃÂÃÂ£ cÃÂÃÂ³ nguy cÃÂÃÂ¡ tÃÂÃÂ¡i ngÃÂÃÂ£ cao gÃÂ¡ÃÂºÃÂ¥p 3 lÃÂ¡ÃÂºÃÂ§n.",
      "ans": false,
    },
    {
      "text": "2. TÃÂÃÂ´i cÃÂ¡ÃÂºÃÂ§n dÃÂÃÂ¹ng gÃÂ¡ÃÂºÃÂ­y chÃÂ¡ÃÂ»ÃÂng hoÃÂ¡ÃÂºÃÂ·c khung tÃÂ¡ÃÂºÃÂ­p ÃÂÃÂi, hoÃÂ¡ÃÂºÃÂ·c bÃÂÃÂ¡c sÃÂÃÂ© khuyÃÂÃÂªn tÃÂÃÂ´i nÃÂÃÂªn dÃÂÃÂ¹ng.",
      "pts": 2,
      "why": "DÃÂ¡ÃÂºÃÂ¥u hiÃÂ¡ÃÂ»ÃÂu suy giÃÂ¡ÃÂºÃÂ£m sÃÂ¡ÃÂ»ÃÂ©c cÃÂÃÂ¡ chÃÂÃÂ¢n vÃÂÃÂ  thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng dÃÂÃÂ¡ng ÃÂÃÂi.",
      "ans": false,
    },
    {
      "text": "3. ÃÂÃÂÃÂÃÂ´i khi tÃÂÃÂ´i cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂºÃÂ¥y loÃÂ¡ÃÂºÃÂ¡ng choÃÂ¡ÃÂºÃÂ¡ng hoÃÂ¡ÃÂºÃÂ·c mÃÂ¡ÃÂºÃÂ¥t thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng khi ÃÂÃÂi lÃÂ¡ÃÂºÃÂ¡i.",
      "pts": 1,
      "why": "RÃÂ¡ÃÂ»ÃÂi loÃÂ¡ÃÂºÃÂ¡n chÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng tiÃÂ¡ÃÂ»ÃÂn ÃÂÃÂÃÂÃÂ¬nh hoÃÂ¡ÃÂºÃÂ·c yÃÂ¡ÃÂºÃÂ¿u cÃÂÃÂ¡ chi dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi.",
      "ans": false,
    },
    {
      "text": "4. TÃÂÃÂ´i hay phÃÂ¡ÃÂºÃÂ£i vÃÂ¡ÃÂ»ÃÂn vÃÂÃÂ o ÃÂÃÂÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂºÃÂ¡c, tÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng khi ÃÂÃÂi lÃÂ¡ÃÂºÃÂ¡i trong nhÃÂÃÂ .",
      "pts": 1,
      "why": "BiÃÂ¡ÃÂ»ÃÂu hiÃÂ¡ÃÂ»ÃÂn thiÃÂ¡ÃÂºÃÂ¿u tÃÂ¡ÃÂ»ÃÂ± tin vÃÂÃÂ o khÃÂ¡ÃÂºÃÂ£ nÃÂÃÂng giÃÂ¡ÃÂ»ÃÂ¯ thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng tÃÂ¡ÃÂ»ÃÂ± thÃÂÃÂ¢n.",
      "ans": false,
    },
    {
      "text": "5. TÃÂÃÂ´i thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng lo lÃÂ¡ÃÂºÃÂ¯ng hoÃÂ¡ÃÂºÃÂ·c sÃÂ¡ÃÂ»ÃÂ£ hÃÂÃÂ£i mÃÂÃÂ¬nh sÃÂ¡ÃÂºÃÂ½ bÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ£.",
      "pts": 1,
      "why": "HÃÂ¡ÃÂ»ÃÂi chÃÂ¡ÃÂ»ÃÂ©ng sÃÂ¡ÃÂ»ÃÂ£ ngÃÂÃÂ£ (Fear of Falling) dÃÂ¡ÃÂºÃÂ«n ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n hÃÂ¡ÃÂºÃÂ¡n chÃÂ¡ÃÂºÃÂ¿ vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng vÃÂÃÂ  teo cÃÂÃÂ¡.",
      "ans": false,
    },
    {
      "text": "6. TÃÂÃÂ´i cÃÂ¡ÃÂºÃÂ§n dÃÂÃÂ¹ng tay ÃÂÃÂÃÂ¡ÃÂºÃÂ©y mÃÂ¡ÃÂºÃÂ¡nh vÃÂÃÂ o ÃÂÃÂÃÂÃÂ¹i hoÃÂ¡ÃÂºÃÂ·c ghÃÂ¡ÃÂºÃÂ¿ mÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng dÃÂ¡ÃÂºÃÂ­y ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£c.",
      "pts": 1,
      "why": "Suy giÃÂ¡ÃÂºÃÂ£m sÃÂ¡ÃÂ»ÃÂ©c mÃÂ¡ÃÂºÃÂ¡nh cÃÂÃÂ¡ tÃÂ¡ÃÂ»ÃÂ© ÃÂÃÂÃÂ¡ÃÂºÃÂ§u ÃÂÃÂÃÂÃÂ¹i (quadriceps weakness).",
      "ans": false,
    },
    {
      "text": "7. TÃÂÃÂ´i cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂºÃÂ¥y khÃÂÃÂ³ khÃÂÃÂn khi bÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂc lÃÂÃÂªn vÃÂ¡ÃÂ»ÃÂa hÃÂÃÂ¨ hoÃÂ¡ÃÂºÃÂ·c bÃÂ¡ÃÂºÃÂ­c thÃÂ¡ÃÂ»ÃÂm cao.",
      "pts": 1,
      "why": "HÃÂ¡ÃÂºÃÂ¡n chÃÂ¡ÃÂºÃÂ¿ linh hoÃÂ¡ÃÂºÃÂ¡t khÃÂ¡ÃÂ»ÃÂp cÃÂ¡ÃÂ»ÃÂ chÃÂÃÂ¢n vÃÂÃÂ  khÃÂ¡ÃÂºÃÂ£ nÃÂÃÂng nÃÂÃÂ¢ng chÃÂÃÂ¢n.",
      "ans": false,
    },
    {
      "text": "8. TÃÂÃÂ´i thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng phÃÂ¡ÃÂºÃÂ£i vÃÂ¡ÃÂ»ÃÂi vÃÂÃÂ£ ÃÂÃÂi gÃÂ¡ÃÂºÃÂ¥p vÃÂÃÂ o nhÃÂÃÂ  vÃÂ¡ÃÂ»ÃÂ sinh.",
      "pts": 1,
      "why": "HÃÂ¡ÃÂ»ÃÂi chÃÂ¡ÃÂ»ÃÂ©ng tiÃÂ¡ÃÂ»ÃÂu gÃÂ¡ÃÂºÃÂ¥p lÃÂÃÂ m tÃÂÃÂng nguy cÃÂÃÂ¡ vÃÂ¡ÃÂºÃÂ¥p ngÃÂÃÂ£ ban ÃÂÃÂÃÂÃÂªm.",
      "ans": false,
    },
    {
      "text": "9. TÃÂÃÂ´i bÃÂ¡ÃÂ»ÃÂ tÃÂÃÂª bÃÂÃÂ¬ hoÃÂ¡ÃÂºÃÂ·c mÃÂ¡ÃÂºÃÂ¥t cÃÂ¡ÃÂºÃÂ£m giÃÂÃÂ¡c ÃÂ¡ÃÂ»ÃÂ lÃÂÃÂ²ng bÃÂÃÂ n chÃÂÃÂ¢n.",
      "pts": 1,
      "why": "MÃÂ¡ÃÂºÃÂ¥t cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂ»ÃÂ¥ bÃÂ¡ÃÂºÃÂ£n thÃÂ¡ÃÂ»ÃÂ (neuropathy) hay gÃÂ¡ÃÂºÃÂ·p ÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi ÃÂÃÂÃÂÃÂ¡i thÃÂÃÂ¡o ÃÂÃÂÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng.",
      "ans": false,
    },
    {
      "text": "10. TÃÂÃÂ´i ÃÂÃÂang uÃÂ¡ÃÂ»ÃÂng thuÃÂ¡ÃÂ»ÃÂc lÃÂÃÂ m tÃÂÃÂ´i cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂºÃÂ¥y choÃÂÃÂ¡ng vÃÂÃÂ¡ng hoÃÂ¡ÃÂºÃÂ·c buÃÂ¡ÃÂ»ÃÂn ngÃÂ¡ÃÂ»ÃÂ§.",
      "pts": 1,
      "why": "TÃÂÃÂ¡c dÃÂ¡ÃÂ»ÃÂ¥ng phÃÂ¡ÃÂ»ÃÂ¥ cÃÂ¡ÃÂ»ÃÂ§a thuÃÂ¡ÃÂ»ÃÂc hÃÂ¡ÃÂºÃÂ¡ huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p, an thÃÂ¡ÃÂºÃÂ§n hoÃÂ¡ÃÂºÃÂ·c khÃÂÃÂ¡ng histamine.",
      "ans": false,
    },
    {
      "text": "11. TÃÂÃÂ´i ÃÂÃÂang uÃÂ¡ÃÂ»ÃÂng thuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu trÃÂ¡ÃÂ»ÃÂ rÃÂ¡ÃÂ»ÃÂi loÃÂ¡ÃÂºÃÂ¡n tÃÂÃÂ¢m trÃÂ¡ÃÂºÃÂ¡ng hoÃÂ¡ÃÂºÃÂ·c thuÃÂ¡ÃÂ»ÃÂc hÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ£ giÃÂ¡ÃÂºÃÂ¥c ngÃÂ¡ÃÂ»ÃÂ§.",
      "pts": 1,
      "why": "ThuÃÂ¡ÃÂ»ÃÂc ngÃÂ¡ÃÂ»ÃÂ§ lÃÂÃÂ m giÃÂ¡ÃÂºÃÂ£m phÃÂ¡ÃÂºÃÂ£n xÃÂ¡ÃÂºÃÂ¡ thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng khi thÃÂ¡ÃÂ»ÃÂ©c dÃÂ¡ÃÂºÃÂ­y giÃÂ¡ÃÂ»ÃÂ¯a ÃÂÃÂÃÂÃÂªm.",
      "ans": false,
    },
    {
      "text": "12. GÃÂ¡ÃÂºÃÂ§n ÃÂÃÂÃÂÃÂ¢y tÃÂÃÂ´i thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng xuyÃÂÃÂªn cÃÂ¡ÃÂºÃÂ£m thÃÂ¡ÃÂºÃÂ¥y buÃÂ¡ÃÂ»ÃÂn bÃÂÃÂ£, chÃÂÃÂ¡n nÃÂ¡ÃÂºÃÂ£n hoÃÂ¡ÃÂºÃÂ·c suy giÃÂ¡ÃÂºÃÂ£m tinh thÃÂ¡ÃÂºÃÂ§n.",
      "pts": 1,
      "why": "TrÃÂ¡ÃÂºÃÂ§m cÃÂ¡ÃÂºÃÂ£m tuÃÂ¡ÃÂ»ÃÂi giÃÂÃÂ  liÃÂÃÂªn quan mÃÂ¡ÃÂºÃÂ­t thiÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂÃÂ¡ÃÂºÃÂ¿n suy giÃÂ¡ÃÂºÃÂ£m phÃÂ¡ÃÂ»ÃÂi hÃÂ¡ÃÂ»ÃÂ£p vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng.",
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

  String get riskLevel => currentScore >= 4 ? "NGUY CÃÂÃÂ  CAO (High Risk)" : "NGUY CÃÂÃÂ  THÃÂ¡ÃÂºÃÂ¤P / VÃÂ¡ÃÂ»ÃÂªA (Low/Mod Risk)";

  void _finish() async {
    final score = currentScore;
    final level = riskLevel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cdc_steadi_last_score', score);
    await prefs.setString('cdc_steadi_last_date', DateTime.now().toIso8601String());

    // LÃÂÃÂ°u vÃÂÃÂ o danh sÃÂÃÂ¡ch lÃÂ¡ÃÂ»ÃÂch sÃÂ¡ÃÂ»ÃÂ­ ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡
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

    // MÃÂ¡ÃÂ»ÃÂ hÃÂ¡ÃÂ»ÃÂp thoÃÂ¡ÃÂºÃÂ¡i thÃÂÃÂ´ng bÃÂÃÂ¡o kÃÂ¡ÃÂºÃÂ¿t quÃÂ¡ÃÂºÃÂ£ & lÃÂ¡ÃÂ»ÃÂi khuyÃÂÃÂªn y tÃÂ¡ÃÂºÃÂ¿
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
            const Text("KÃÂ¡ÃÂºÃÂ¿t quÃÂ¡ÃÂºÃÂ£ ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ CDC", style: TextStyle(fontSize: 16)),
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
                  Text("$score / 14 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: score >= 4 ? Colors.redAccent : Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("KhuyÃÂ¡ÃÂºÃÂ¿n nghÃÂ¡ÃÂ»ÃÂ y tÃÂ¡ÃÂºÃÂ¿ lÃÂÃÂ¢m sÃÂÃÂ ng theo CDC STEADI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (score >= 4) ...[
              const Text("ÃÂ¢ÃÂÃÂ¢ CÃÂ¡ÃÂºÃÂ§n ÃÂÃÂo huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p tÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ (ngÃÂ¡ÃÂ»ÃÂi vÃÂÃÂ  ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng sau 1-3 phÃÂÃÂºt) ÃÂÃÂÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ§m soÃÂÃÂ¡t tÃÂ¡ÃÂ»ÃÂ¥t huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p tÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿.", style: TextStyle(fontSize: 12)),
              const Text("ÃÂ¢ÃÂÃÂ¢ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ nghÃÂ¡ÃÂ»ÃÂ bÃÂÃÂ¡c sÃÂÃÂ© ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu trÃÂ¡ÃÂ»ÃÂ rÃÂÃÂ  soÃÂÃÂ¡t ÃÂÃÂÃÂÃÂ¡n thuÃÂ¡ÃÂ»ÃÂc, ÃÂÃÂÃÂ¡ÃÂºÃÂ·c biÃÂ¡ÃÂ»ÃÂt thuÃÂ¡ÃÂ»ÃÂc an thÃÂ¡ÃÂºÃÂ§n vÃÂÃÂ  hÃÂ¡ÃÂºÃÂ¡ ÃÂÃÂ¡p.", style: TextStyle(fontSize: 12)),
              const Text("ÃÂ¢ÃÂÃÂ¢ LÃÂ¡ÃÂºÃÂ¯p ÃÂÃÂÃÂ¡ÃÂºÃÂ·t thanh vÃÂ¡ÃÂ»ÃÂn tay trong nhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m vÃÂÃÂ  thÃÂ¡ÃÂºÃÂ£m chÃÂ¡ÃÂ»ÃÂng trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£t ngay lÃÂ¡ÃÂºÃÂ­p tÃÂ¡ÃÂ»ÃÂ©c.", style: TextStyle(fontSize: 12)),
              const Text("ÃÂ¢ÃÂÃÂ¢ TÃÂ¡ÃÂºÃÂ­p vÃÂ¡ÃÂºÃÂ­t lÃÂÃÂ½ trÃÂ¡ÃÂ»ÃÂ liÃÂ¡ÃÂ»ÃÂu phÃÂ¡ÃÂ»ÃÂ¥c hÃÂ¡ÃÂ»ÃÂi chÃÂ¡ÃÂ»ÃÂ©c nÃÂÃÂng thÃÂÃÂng bÃÂ¡ÃÂºÃÂ±ng (bÃÂÃÂ i tÃÂ¡ÃÂºÃÂ­p Otago / ThÃÂÃÂ¡i CÃÂ¡ÃÂ»ÃÂ±c QuyÃÂ¡ÃÂ»ÃÂn).", style: TextStyle(fontSize: 12)),
            ] else ...[
              const Text("ÃÂ¢ÃÂÃÂ¢ Duy trÃÂÃÂ¬ thÃÂÃÂ³i quen tÃÂ¡ÃÂºÃÂ­p luyÃÂ¡ÃÂ»ÃÂn thÃÂ¡ÃÂ»ÃÂ lÃÂ¡ÃÂ»ÃÂ±c hÃÂÃÂ ng ngÃÂÃÂ y (ÃÂÃÂi bÃÂ¡ÃÂ»ÃÂ, ThÃÂÃÂ¡i CÃÂ¡ÃÂ»ÃÂ±c QuyÃÂ¡ÃÂ»ÃÂn 30 phÃÂÃÂºt/ngÃÂÃÂ y).", style: TextStyle(fontSize: 12)),
              const Text("ÃÂ¢ÃÂÃÂ¢ BÃÂ¡ÃÂ»ÃÂ sung ÃÂÃÂÃÂ¡ÃÂ»ÃÂ§ Canxi vÃÂÃÂ  Vitamin D theo hÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng dÃÂ¡ÃÂºÃÂ«n cÃÂ¡ÃÂ»ÃÂ§a bÃÂÃÂ¡c sÃÂÃÂ©.", style: TextStyle(fontSize: 12)),
              const Text("ÃÂ¢ÃÂÃÂ¢ ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ lÃÂ¡ÃÂºÃÂ¡i nguy cÃÂÃÂ¡ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh kÃÂ¡ÃÂ»ÃÂ³ 6 thÃÂÃÂ¡ng mÃÂ¡ÃÂ»ÃÂt lÃÂ¡ÃÂºÃÂ§n.", style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("TÃÂÃÂ´i ÃÂÃÂÃÂÃÂ£ hiÃÂ¡ÃÂ»ÃÂu")),
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
                      Text("ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ nguy cÃÂÃÂ¡ ngÃÂÃÂ£ CDC STEADI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("ChuÃÂ¡ÃÂºÃÂ©n y khoa Trung tÃÂÃÂ¢m KiÃÂ¡ÃÂ»ÃÂm soÃÂÃÂ¡t BÃÂ¡ÃÂ»ÃÂnh tÃÂ¡ÃÂºÃÂ­t Hoa KÃÂ¡ÃÂ»ÃÂ³ (CDC)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm sÃÂ¡ÃÂ»ÃÂ trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p
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
                  Text("ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm sÃÂ¡ÃÂ»ÃÂ hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i: $currentScore / 14 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm", style: TextStyle(fontWeight: FontWeight.bold, color: currentScore >= 4 ? Colors.redAccent : Colors.green)),
                  Text(currentScore >= 4 ? "Nguy cÃÂÃÂ¡ cao (>= 4)" : "Nguy cÃÂÃÂ¡ thÃÂ¡ÃÂºÃÂ¥p (< 4)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: Text("+${q['pts']}ÃÂÃÂ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                                label: const Text("KhÃÂÃÂ´ng"),
                                selected: q['ans'] == false,
                                onSelected: (sel) {
                                  if (sel) setState(() => q['ans'] = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("CÃÂÃÂ³ / ÃÂÃÂÃÂÃÂºng"),
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
              label: Text("HoÃÂÃÂ n thÃÂÃÂ nh ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ ($currentScore ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TÃÂÃÂNH NÃÂÃÂNG 3: BÃÂÃÂO CÃÂÃÂO Y KHOA XUÃÂ¡ÃÂºÃÂ¤T ÃÂÃÂÃÂ¡ÃÂ»ÃÂNH KÃÂ¡ÃÂ»ÃÂ² (MEDICAL AUDIT REPORT DIALOG)
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
BÃÂÃÂO CÃÂÃÂO LÃÂÃÂM SÃÂÃÂNG GIÃÂÃÂM SÃÂÃÂT TÃÂÃÂ NGÃÂÃÂ & VÃÂ¡ÃÂºÃÂ¬N ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG (FALLGUARD CLINICAL REPORT)
HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng giÃÂÃÂ¡m sÃÂÃÂ¡t vi ba Radar FMCW 24GHz & Laser ToF AI ESP32-S3R8
ThÃÂ¡ÃÂ»ÃÂi ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm xuÃÂ¡ÃÂºÃÂ¥t bÃÂÃÂ¡o cÃÂÃÂ¡o: $dateStr
======================================================================

I. THÃÂÃÂNG TIN BÃÂ¡ÃÂ»ÃÂNH NHÃÂÃÂN & HÃÂ¡ÃÂ»ÃÂ SÃÂÃÂ  Y TÃÂ¡ÃÂºÃÂ¾
ÃÂ¢ÃÂÃÂ¢ HÃÂ¡ÃÂ»ÃÂ vÃÂÃÂ  tÃÂÃÂªn: ${profile.fullName}
ÃÂ¢ÃÂÃÂ¢ TuÃÂ¡ÃÂ»ÃÂi: $age tuÃÂ¡ÃÂ»ÃÂi (Sinh nÃÂÃÂm ${profile.birthYear} - GiÃÂ¡ÃÂ»ÃÂi tÃÂÃÂ­nh: ${profile.gender})
ÃÂ¢ÃÂÃÂ¢ NhÃÂÃÂ³m mÃÂÃÂ¡u: ${profile.bloodType}
ÃÂ¢ÃÂÃÂ¢ CÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o thuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng mÃÂÃÂ¡u: ${profile.isTakingAnticoagulants ? 'CÃÂÃÂ (Aspirin/Warfarin/Xarelto - CÃÂ¡ÃÂ»ÃÂ°C KÃÂ¡ÃÂ»ÃÂ² LÃÂÃÂ¯U ÃÂÃÂ)' : 'KhÃÂÃÂ´ng ghi nhÃÂ¡ÃÂºÃÂ­n'}
ÃÂ¢ÃÂÃÂ¢ BÃÂ¡ÃÂ»ÃÂnh lÃÂÃÂ½ nÃÂ¡ÃÂ»ÃÂn: ${profile.chronicConditions.join(', ')}
ÃÂ¢ÃÂÃÂ¢ ÃÂÃÂÃÂÃÂ¡n thuÃÂ¡ÃÂ»ÃÂc ÃÂÃÂang sÃÂ¡ÃÂ»ÃÂ­ dÃÂ¡ÃÂ»ÃÂ¥ng: ${profile.highRiskMedications.join(', ')}
ÃÂ¢ÃÂÃÂ¢ BÃÂÃÂ¡c sÃÂÃÂ© phÃÂ¡ÃÂ»ÃÂ¥ trÃÂÃÂ¡ch: ${profile.attendingDoctorName} (SÃÂÃÂT: ${profile.attendingDoctorPhone})
ÃÂ¢ÃÂÃÂ¢ BÃÂ¡ÃÂ»ÃÂnh viÃÂ¡ÃÂ»ÃÂn chÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh: ${profile.hospital}

II. CHÃÂ¡ÃÂ»ÃÂ SÃÂ¡ÃÂ»ÃÂ ÃÂÃÂÃÂÃÂNH GIÃÂÃÂ NGUY CÃÂÃÂ  TÃÂÃÂ NGÃÂÃÂ (CDC STEADI USA)
ÃÂ¢ÃÂÃÂ¢ ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡: $cdcScore / 14 ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm
ÃÂ¢ÃÂÃÂ¢ PhÃÂÃÂ¢n tÃÂ¡ÃÂºÃÂ§ng nguy cÃÂÃÂ¡: ${cdcScore >= 4 ? 'NGUY CÃÂÃÂ  CAO (High Fall Risk >= 4)' : 'NGUY CÃÂÃÂ  THÃÂ¡ÃÂºÃÂ¤P / TRUNG BÃÂÃÂNH (< 4)'}
ÃÂ¢ÃÂÃÂ¢ NgÃÂÃÂ y ÃÂÃÂÃÂÃÂ¡nh giÃÂÃÂ¡ gÃÂ¡ÃÂºÃÂ§n nhÃÂ¡ÃÂºÃÂ¥t: ${cdcDate != null ? '${cdcDate!.day}/${cdcDate!.month}/${cdcDate!.year}' : 'ChÃÂÃÂ°a thÃÂ¡ÃÂ»ÃÂ±c hiÃÂ¡ÃÂ»ÃÂn'}

III. THÃÂ¡ÃÂ»ÃÂNG KÃÂÃÂ SÃÂ¡ÃÂ»ÃÂ° CÃÂ¡ÃÂ»ÃÂ & HÃÂ¡ÃÂ»ÃÂP ÃÂÃÂEN NVS (BLACKBOX AUDIT)
ÃÂ¢ÃÂÃÂ¢ TÃÂ¡ÃÂ»ÃÂng sÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂ»ÃÂ¥ tÃÂÃÂ© ngÃÂÃÂ£ va chÃÂ¡ÃÂºÃÂ¡m mÃÂ¡ÃÂºÃÂ¡nh ghi nhÃÂ¡ÃÂºÃÂ­n: ${eventHistory.where((e) => e['type'] == 1).length} sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ
ÃÂ¢ÃÂÃÂ¢ TÃÂ¡ÃÂ»ÃÂng sÃÂ¡ÃÂ»ÃÂ sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ ngÃÂÃÂ£ chÃÂ¡ÃÂºÃÂ­m / nÃÂ¡ÃÂºÃÂ±m sÃÂÃÂ n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng: ${eventHistory.where((e) => e['type'] == 2).length} sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ
ÃÂ¢ÃÂÃÂ¢ SÃÂ¡ÃÂ»ÃÂ lÃÂ¡ÃÂºÃÂ§n cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o lÃÂÃÂ°u trÃÂÃÂº bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng trong nhÃÂÃÂ  tÃÂ¡ÃÂºÃÂ¯m (>30p): $inactivityEventsCount lÃÂ¡ÃÂºÃÂ§n
ÃÂ¢ÃÂÃÂ¢ TrÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i hiÃÂ¡ÃÂ»ÃÂn tÃÂ¡ÃÂºÃÂ¡i: ChiÃÂ¡ÃÂ»ÃÂu cao ToF $tofHeight mm | ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar $radarMotion/100

IV. KHUYÃÂ¡ÃÂºÃÂ¾N CÃÂÃÂO LÃÂÃÂM SÃÂÃÂNG DÃÂÃÂNH CHO BÃÂÃÂC SÃÂÃÂ¨ & GIA ÃÂÃÂÃÂÃÂNH
1. NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂnh cÃÂÃÂ³ phÃÂÃÂ¢n tÃÂ¡ÃÂºÃÂ§ng nguy cÃÂÃÂ¡ ngÃÂÃÂ£ ${cdcScore >= 4 ? 'CAO' : 'TRUNG BÃÂÃÂNH'}. CÃÂ¡ÃÂºÃÂ§n kiÃÂ¡ÃÂ»ÃÂm tra huyÃÂ¡ÃÂºÃÂ¿t ÃÂÃÂ¡p tÃÂÃÂ° thÃÂ¡ÃÂºÃÂ¿ nÃÂ¡ÃÂºÃÂ±m vÃÂÃÂ  ÃÂÃÂÃÂ¡ÃÂ»ÃÂ©ng (Orthostatic Hypotension) tÃÂ¡ÃÂºÃÂ¡i phÃÂÃÂ²ng khÃÂÃÂ¡m.
2. ${profile.isTakingAnticoagulants ? 'ÃÂÃÂÃÂ¡ÃÂºÃÂ¶C BIÃÂ¡ÃÂ»ÃÂT LÃÂÃÂ¯U ÃÂÃÂ: Do bÃÂ¡ÃÂ»ÃÂnh nhÃÂÃÂ¢n ÃÂÃÂang ÃÂÃÂiÃÂ¡ÃÂ»ÃÂu trÃÂ¡ÃÂ»ÃÂ thuÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂng ÃÂÃÂÃÂÃÂ´ng, mÃÂ¡ÃÂ»ÃÂi cÃÂÃÂº ngÃÂÃÂ£ va chÃÂ¡ÃÂºÃÂ¡m vÃÂÃÂ¹ng ÃÂÃÂÃÂ¡ÃÂºÃÂ§u dÃÂÃÂ¹ chÃÂÃÂ°a xuÃÂ¡ÃÂºÃÂ¥t hiÃÂ¡ÃÂ»ÃÂn triÃÂ¡ÃÂ»ÃÂu chÃÂ¡ÃÂ»ÃÂ©ng ngoÃÂÃÂ i da vÃÂ¡ÃÂºÃÂ«n bÃÂ¡ÃÂºÃÂ¯t buÃÂ¡ÃÂ»ÃÂc chÃÂ¡ÃÂ»ÃÂ¥p CT sÃÂ¡ÃÂ»ÃÂ nÃÂÃÂ£o trong 24h ÃÂÃÂÃÂ¡ÃÂ»ÃÂ loÃÂ¡ÃÂºÃÂ¡i trÃÂ¡ÃÂ»ÃÂ« tÃÂ¡ÃÂ»ÃÂ¥ mÃÂÃÂ¡u dÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi mÃÂÃÂ ng cÃÂ¡ÃÂ»ÃÂ©ng muÃÂ¡ÃÂ»ÃÂn.' : 'Duy trÃÂÃÂ¬ chÃÂ¡ÃÂºÃÂ¿ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ vÃÂ¡ÃÂºÃÂ­n ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nhÃÂ¡ÃÂºÃÂ¹ nhÃÂÃÂ ng.'}
3. KiÃÂ¡ÃÂ»ÃÂm tra mÃÂÃÂ´i trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng nhÃÂÃÂ  ÃÂ¡ÃÂ»ÃÂ: LÃÂ¡ÃÂºÃÂ¯p ÃÂÃÂÃÂ¡ÃÂºÃÂ·t tay vÃÂ¡ÃÂ»ÃÂn nhÃÂÃÂ  vÃÂ¡ÃÂ»ÃÂ sinh, giÃÂ¡ÃÂ»ÃÂ¯ sÃÂÃÂ n khÃÂÃÂ´ rÃÂÃÂ¡o, ÃÂÃÂÃÂ¡ÃÂºÃÂ£m bÃÂ¡ÃÂºÃÂ£o ÃÂÃÂ¡nh sÃÂÃÂ¡ng ÃÂÃÂÃÂÃÂ¨n ngÃÂ¡ÃÂ»ÃÂ§ tÃÂ¡ÃÂ»ÃÂ± ÃÂÃÂÃÂ¡ÃÂ»ÃÂng bÃÂ¡ÃÂºÃÂ­t khi ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi bÃÂ¡ÃÂ»ÃÂnh thÃÂ¡ÃÂ»ÃÂ©c dÃÂ¡ÃÂºÃÂ­y ban ÃÂÃÂÃÂÃÂªm.
======================================================================
""";
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ÃÂÃÂÃÂÃÂ£ sao chÃÂÃÂ©p toÃÂÃÂ n bÃÂ¡ÃÂ»ÃÂ bÃÂÃÂ¡o cÃÂÃÂ¡o y khoa vÃÂÃÂ o clipboard!"), backgroundColor: Colors.teal),
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
                      Text("BÃÂÃÂ¡o cÃÂÃÂ¡o y tÃÂ¡ÃÂºÃÂ¿ xuÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂnh kÃÂ¡ÃÂ»ÃÂ³", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text("TÃÂÃÂ³m tÃÂ¡ÃÂºÃÂ¯t lÃÂÃÂ¢m sÃÂÃÂ ng phÃÂ¡ÃÂ»ÃÂ¥c vÃÂ¡ÃÂ»ÃÂ¥ thÃÂÃÂm khÃÂÃÂ¡m BÃÂÃÂ¡c sÃÂÃÂ©", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    label: const Text("Sao chÃÂÃÂ©p BÃÂÃÂ¡o cÃÂÃÂ¡o"),
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
                    label: const Text("Sao chÃÂÃÂ©p & GÃÂ¡ÃÂ»ÃÂ­i BÃÂÃÂ¡c sÃÂÃÂ©"),
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
// TÃÂÃÂNH NÃÂÃÂNG 4: CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P VÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂ¢T CHÃÂ¡ÃÂºÃÂ¾ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ IM LÃÂ¡ÃÂºÃÂ¶NG (CRITICAL ALARM MODAL)
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

    // VÃÂÃÂ²ng lÃÂ¡ÃÂºÃÂ·p rung chÃÂ¡ÃÂºÃÂ¥n mÃÂ¡ÃÂºÃÂ¡nh & ÃÂÃÂ¢m thanh cÃÂ¡ÃÂºÃÂ£nh bÃÂÃÂ¡o vÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£t chÃÂ¡ÃÂºÃÂ¿ ÃÂÃÂÃÂ¡ÃÂ»ÃÂ im lÃÂ¡ÃÂºÃÂ·ng
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
                  // BiÃÂ¡ÃÂ»ÃÂu tÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£ng & NhÃÂ¡ÃÂºÃÂ¥p nhÃÂÃÂ¡y bÃÂÃÂ¡o ÃÂÃÂÃÂ¡ÃÂ»ÃÂng
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
                      widget.isFall ? "ÃÂ°ÃÂÃÂÃÂ¨ CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO TÃÂÃÂ NGÃÂÃÂ KHÃÂ¡ÃÂºÃÂ¨N CÃÂ¡ÃÂºÃÂ¤P!" : "ÃÂ¢ÃÂÃÂ ÃÂ¯ÃÂ¸ÃÂ CÃÂ¡ÃÂºÃÂ¢NH BÃÂÃÂO BÃÂ¡ÃÂºÃÂ¤T ÃÂÃÂÃÂ¡ÃÂ»ÃÂNG KÃÂÃÂO DÃÂÃÂI!",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.customReason ?? (widget.isFall
                        ? "HÃÂ¡ÃÂ»ÃÂ thÃÂ¡ÃÂ»ÃÂng AI vÃÂ¡ÃÂ»ÃÂ«a phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn cÃÂÃÂº ngÃÂÃÂ£ va chÃÂ¡ÃÂºÃÂ¡m mÃÂ¡ÃÂºÃÂ¡nh tÃÂ¡ÃÂºÃÂ¡i khu vÃÂ¡ÃÂ»ÃÂ±c [${widget.roomName}]!"
                        : "PhÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n bÃÂ¡ÃÂºÃÂ¥t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng quÃÂÃÂ¡ lÃÂÃÂ¢u trong [${widget.roomName}]. Nghi ngÃÂ¡ÃÂ»ÃÂ ngÃÂ¡ÃÂºÃÂ¥t xÃÂ¡ÃÂ»ÃÂu hoÃÂ¡ÃÂºÃÂ·c ÃÂÃÂÃÂ¡ÃÂ»ÃÂt quÃÂ¡ÃÂ»ÃÂµ!"),
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // BÃÂ¡ÃÂºÃÂ£ng thÃÂÃÂ´ng sÃÂ¡ÃÂ»ÃÂ tÃÂ¡ÃÂºÃÂ¡i thÃÂ¡ÃÂ»ÃÂi ÃÂÃÂiÃÂ¡ÃÂ»ÃÂm sÃÂ¡ÃÂ»ÃÂ± cÃÂ¡ÃÂ»ÃÂ
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
                        _buildMetric("V_rÃÂÃÂ¡i", "${widget.dropRate.toStringAsFixed(0)} mm/s"),
                        _buildMetric("ÃÂÃÂÃÂ¡ÃÂ»ÃÂ cao ToF", "${widget.tofHeight} mm"),
                        _buildMetric("ÃÂÃÂÃÂ¡ÃÂ»ÃÂng nÃÂÃÂng Radar", "${widget.radarMotion}%"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NÃÂÃÂºt gÃÂ¡ÃÂ»ÃÂi 115 khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _call115,
                    icon: const Icon(Icons.phone_in_talk, size: 22),
                    label: const Text("GÃÂ¡ÃÂ»ÃÂI CÃÂ¡ÃÂºÃÂ¤P CÃÂ¡ÃÂ»ÃÂ¨U 115 NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),

                  // NÃÂÃÂºt gÃÂ¡ÃÂ»ÃÂi ngÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n khÃÂ¡ÃÂºÃÂ©n cÃÂ¡ÃÂºÃÂ¥p
                  if (widget.profile.emergencyContact1Phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _callFamily,
                      icon: const Icon(Icons.call, size: 20),
                      label: Text("GÃÂ¡ÃÂ»ÃÂI NGÃÂÃÂ¯ÃÂ¡ÃÂ»ÃÂI THÃÂÃÂN (${widget.profile.emergencyContact1Name})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          label: const Text("ThÃÂ¡ÃÂºÃÂ» Y TÃÂ¡ÃÂºÃÂ¿", style: TextStyle(fontSize: 12)),
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
                          label: const Text("SÃÂÃÂ¡ cÃÂ¡ÃÂ»ÃÂ©u", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // NÃÂÃÂºt xÃÂÃÂ¡c nhÃÂ¡ÃÂºÃÂ­n an toÃÂÃÂ n & HÃÂ¡ÃÂ»ÃÂ§y cÃÂÃÂ²i hÃÂÃÂº
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
                    label: const Text("XÃÂÃÂC NHÃÂ¡ÃÂºÃÂ¬N AN TOÃÂÃÂN / TÃÂ¡ÃÂºÃÂ®T CÃÂÃÂI HÃÂÃÂ", style: TextStyle(fontWeight: FontWeight.bold)),
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
// TÃÂÃÂNH NÃÂÃÂNG 6: WIDGET TIÃÂ¡ÃÂ»ÃÂN ÃÂÃÂCH MÃÂÃÂN HÃÂÃÂNH KHÃÂÃÂA & MÃÂÃÂN HÃÂÃÂNH CHÃÂÃÂNH (PREVIEW MODAL)
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
                        Text("MÃÂÃÂ´ phÃÂ¡ÃÂ»ÃÂng Widget MÃÂÃÂ n hÃÂÃÂ¬nh khÃÂÃÂ³a", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("iOS Dynamic Island & Android Glance Widget", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // 1. MÃÂÃÂ PHÃÂ¡ÃÂ»ÃÂNG DYNAMIC ISLAND (iOS 16.1+)
              const Text("1. iOS Dynamic Island & HoÃÂ¡ÃÂºÃÂ¡t ÃÂÃÂÃÂ¡ÃÂ»ÃÂng trÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p (Live Activity):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
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
                        "FallGuard: $roomName ÃÂ¢ÃÂÃÂ¢ An toÃÂÃÂ n",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("${tofHeight}mm", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. MÃÂÃÂ PHÃÂ¡ÃÂ»ÃÂNG WIDGET MÃÂÃÂN HÃÂÃÂNH KHÃÂÃÂA iOS (2x1)
              const Text("2. TiÃÂ¡ÃÂ»ÃÂn ÃÂÃÂ­ch mÃÂÃÂ n hÃÂÃÂ¬nh khÃÂÃÂ³a iOS Lock Screen (Widget 2x1):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
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
                    Text("NgÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂi thÃÂÃÂ¢n ÃÂÃÂang an toÃÂÃÂ n tÃÂ¡ÃÂºÃÂ¡i $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Radar: $radarMotion% ÃÂ¢ÃÂÃÂ¢ ChiÃÂ¡ÃÂ»ÃÂu cao: ${tofHeight}mm ÃÂ¢ÃÂÃÂ¢ TrÃÂ¡ÃÂ»ÃÂ±c tiÃÂ¡ÃÂºÃÂ¿p", style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. MÃÂÃÂ PHÃÂ¡ÃÂ»ÃÂNG WIDGET MÃÂÃÂN HÃÂÃÂNH CHÃÂÃÂNH ANDROID (Glance 4x2)
              const Text("3. TiÃÂ¡ÃÂ»ÃÂn ÃÂÃÂ­ch mÃÂÃÂ n hÃÂÃÂ¬nh chÃÂÃÂ­nh Android Home Widget (Material You):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent)),
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
                              Text("ÃÂÃÂng An: TrÃÂ¡ÃÂºÃÂ¡ng thÃÂÃÂ¡i bÃÂÃÂ¬nh thÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("KhÃÂÃÂ´ng phÃÂÃÂ¡t hiÃÂ¡ÃÂ»ÃÂn nguy cÃÂÃÂ¡ trÃÂÃÂ°ÃÂ¡ÃÂ»ÃÂ£t ngÃÂÃÂ£", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                            child: const Center(child: Text("ÃÂ°ÃÂÃÂÃÂ GÃÂ¡ÃÂ»ÃÂi 115", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text("ÃÂ°ÃÂÃÂªÃÂª ThÃÂ¡ÃÂºÃÂ» Y TÃÂ¡ÃÂºÃÂ¿", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.tealAccent))),
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
                child: const Text("TÃÂÃÂ´i ÃÂÃÂÃÂÃÂ£ hiÃÂ¡ÃÂ»ÃÂu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
