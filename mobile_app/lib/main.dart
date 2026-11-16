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
import 'package:package_info_plus/package_info_plus.dart';
part 'startup.dart';
part 'dashboard.dart';
part 'device_detail.dart';
part 'telemetry_widgets.dart';
part 'settings.dart';
part 'dialogs.dart';


final Future<PackageInfo> _appPackageInfo = PackageInfo.fromPlatform();

String _appVersionLabel(PackageInfo info) {
  final build = info.buildNumber.trim();
  return 'v${info.version}${build.isEmpty ? '' : ' (Build $build)'}';
}

double _dialogContentWidth(BuildContext context, {double max = 400}) =>
    math.min(max, math.max(0, MediaQuery.sizeOf(context).width - 32));

// =========================================================================
// CÁC UUID TRÙNG KHỚP 100% VỚI FIRMWARE ESP32-S3 N16R8
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
// CỔNG KIỂM TRA KHỞI ĐỘNG (STARTUP PERMISSION GATE CHO IOS & ANDROID)
// Bắt buộc xác nhận cho phép quét thiết bị xung quanh trước khi vào app lần đầu
// =========================================================================
