import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services/hearth_controller.dart';
import 's2_find_sensor_screen.dart';
import 's3_wifi_setup_screen.dart';
import 's4_name_room_screen.dart';
import 's5_test_sensor_screen.dart';
import 's9_contacts_screen.dart';

/// Guided S2 → S3 → S4 → S5 → (S9 if first time) flow, also reused for Reconnect (S2→S3) and Add Room (S2..S5).
class SensorSetupFlow extends StatefulWidget {
  final HearthController ctrl;
  final bool isFirstTimeOnboarding;
  final HearthRoom? reconnectTargetRoom;
  final VoidCallback onComplete;
  final VoidCallback? onCancel;

  const SensorSetupFlow({
    super.key,
    required this.ctrl,
    this.isFirstTimeOnboarding = false,
    this.reconnectTargetRoom,
    required this.onComplete,
    this.onCancel,
  });

  @override
  State<SensorSetupFlow> createState() => _SensorSetupFlowState();
}

class _SensorSetupFlowState extends State<SensorSetupFlow> {
  int _step = 2; // 2=S2, 3=S3, 4=S4, 5=S5, 9=S9
  DiscoveredSensor? _sensor;
  String _wifiSsid = '';
  String? _lanIp;
  HearthRoom? _createdRoom;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    switch (_step) {
      case 2:
        return S2FindSensorScreen(
          ctrl: ctrl,
          showIntroBanner: widget.isFirstTimeOnboarding,
          onBack: widget.onCancel,
          onSensorConnected: (sensor) {
            setState(() {
              _sensor = sensor;
              _step = 3;
            });
          },
        );
      case 3:
        return S3WifiSetupScreen(
          ctrl: ctrl,
          sensor: _sensor!,
          onBack: () => setState(() => _step = 2),
          onCancel: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              setState(() => _step = 2);
            }
          },
          onWifiConnected: (ssid, ip) async {
            _wifiSsid = ssid;
            _lanIp = ip;
            if (widget.reconnectTargetRoom != null) {
              await ctrl.markRoomOnlineAfterReconnect(
                widget.reconnectTargetRoom!.id,
                wifiSsid: ssid,
                lanIp: ip,
              );
              widget.onComplete();
              return;
            }
            setState(() => _step = 4);
          },
        );
      case 4:
        return S4NameRoomScreen(
          ctrl: ctrl,
          sensor: _sensor!,
          wifiSsid: _wifiSsid,
          lanIp: _lanIp,
          onBack: () => setState(() => _step = 3),
          onRoomSaved: (room) {
            setState(() {
              _createdRoom = room;
              _step = 5;
            });
          },
        );
      case 5:
        return S5TestSensorScreen(
          ctrl: ctrl,
          room: _createdRoom!,
          onBack: () => setState(() => _step = 4),
          onFinish: () {
            if (widget.isFirstTimeOnboarding) {
              setState(() => _step = 9);
            } else {
              widget.onComplete();
            }
          },
        );
      case 9:
      default:
        return S9ContactsScreen(
          ctrl: ctrl,
          isOnboarding: true,
          onBack: () => setState(() => _step = 5),
          onFinishOnboarding: () async {
            await ctrl.completeOnboarding();
            widget.onComplete();
          },
        );
    }
  }
}
