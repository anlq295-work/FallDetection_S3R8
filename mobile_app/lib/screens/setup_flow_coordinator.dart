import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services/hearth_controller.dart';
import 's2_find_sensor_screen.dart';
import 's3_wifi_setup_screen.dart';
import 's4_name_room_screen.dart';
import 's5_test_sensor_screen.dart';
import 's9_contacts_screen.dart';

/// Guided sensor setup with emergency contacts before the sensor test on first use.
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
  int _step = 2;
  DiscoveredSensor? _sensor;
  String _wifiSsid = '';
  String? _lanIp;
  HearthRoom? _createdRoom;
  bool _contactsConfigured = false;

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
              _step = widget.isFirstTimeOnboarding ? 9 : 5;
            });
          },
        );
      case 5:
        return S5TestSensorScreen(
          ctrl: ctrl,
          room: _createdRoom!,
          onBack: () => setState(() => _step = _contactsConfigured ? 9 : 4),
          onFinish: () async {
            if (widget.isFirstTimeOnboarding) await ctrl.completeOnboarding();
            widget.onComplete();
          },
        );
      case 9:
      default:
        return S9ContactsScreen(
          ctrl: ctrl,
          isOnboarding: true,
          onBack: () => setState(() => _step = 4),
          onFinishOnboarding: () {
            setState(() {
              _contactsConfigured = true;
              _step = 5;
            });
          },
        );
    }
  }
}
