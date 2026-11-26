import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/models.dart';

/// Exact UUID mapping matching ESP32-S3 N16R8 firmware (src/ble_provision.cpp)
class Esp32Uuids {
  static const String service = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String wifi = '0beb5483-e18e-4f36-9e1b-b4d6b63c7b28';
  static const String contact = '1c6f8742-9a6d-4785-b9e1-e63f9b8c0011';
  static const String status = '2d8a9e22-7f1c-4b53-8d2a-f58c7e9a3344';
  static const String telemetry = '3e9baf33-8a2d-4c64-9e3b-a69d8f0b4455';
  static const String command = '4fa0b044-9b3e-4d75-af4c-b70e901c5566';
  static const String ota = '5fa0b055-9b3e-4d75-af4c-b70e901c5566';
}

class GitHubReleaseInfo {
  final String tagName;
  final String releaseNotes;
  final String htmlUrl;
  final String? apkUrl;
  final String? ipaUrl;
  final String? firmwareUrl;

  const GitHubReleaseInfo({
    required this.tagName,
    required this.releaseNotes,
    required this.htmlUrl,
    this.apkUrl,
    this.ipaUrl,
    this.firmwareUrl,
  });
}

/// Manages real BLE GATT + Wi-Fi LAN HTTP API + 3-way OTA for ESP32-S3 FallDetection_S3R8.
class Esp32HardwareService {
  BluetoothDevice? _connectedDevice;
  DiscoveredSensor? _lastSensor;
  String? _lastBleError;
  BluetoothCharacteristic? _wifiChar;
  BluetoothCharacteristic? _contactChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _otaChar;

  StreamSubscription<List<int>>? _statusSub;
  StreamSubscription<List<int>>? _telemetrySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _lanPollTimer;
  int _lanPollFailures = 0;
  int _lanPollGeneration = 0;
  bool _lanPollInFlight = false;

  String? _activeLanIp;
  bool _wifiProvisionAwaitingReboot = false;
  bool _wifiRebootObserved = false;
  ConnectionTransport _transport = ConnectionTransport.disconnected;

  final StreamController<TelemetrySnapshot> _telemetryStream = StreamController.broadcast();
  final StreamController<String> _statusStream = StreamController.broadcast();
  final StreamController<List<BlackboxEvent>> _blackboxStream = StreamController.broadcast();

  Stream<TelemetrySnapshot> get telemetryStream => _telemetryStream.stream;
  Stream<String> get statusStream => _statusStream.stream;
  Stream<List<BlackboxEvent>> get blackboxStream => _blackboxStream.stream;

  ConnectionTransport get transport => _transport;
  bool get isBleConnected => _connectedDevice != null && _transport == ConnectionTransport.ble;
  bool get isLanConnected => _activeLanIp != null && _activeLanIp!.isNotEmpty && _activeLanIp != '0.0.0.0';
  String? get activeLanIp => _activeLanIp;
  String? get connectedDeviceId => _connectedDevice?.remoteId.str;
  String? get lastBleError => _lastBleError;

  bool get isMobileBleSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<bool> isBluetoothOn() async {
    if (!isMobileBleSupported) return false;
    try {
      final state = await FlutterBluePlus.adapterState.first.timeout(const Duration(seconds: 2));
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Scans for physical ESP32-S3 FallDetector_S3R8 / Hearth sensors via BLE.
  Future<List<DiscoveredSensor>> scanNearbySensors({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final Map<String, DiscoveredSensor> found = {};
    if (!isMobileBleSupported) return [];

    try {
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;
          final hasService = r.advertisementData.serviceUuids
              .any((u) => u.str.toLowerCase() == Esp32Uuids.service.toLowerCase());
          final nameMatch = name.toLowerCase().contains('falldetector') ||
              name.toLowerCase().contains('hearth') ||
              name.toLowerCase().contains('s3r8');
          if (hasService || nameMatch) {
            final rawId = r.device.remoteId.str;
            final clean = rawId.replaceAll(':', '').replaceAll('-', '');
            final shortCode = clean.length >= 4 ? clean.substring(clean.length - 4).toUpperCase() : 'S3R8';
            found[rawId] = DiscoveredSensor(
              id: rawId,
              shortCode: shortCode,
              name: name.isNotEmpty ? name : 'FallDetector_S3R8',
              rssi: r.rssi,
              isSimulated: false,
              rawBleDevice: r.device,
            );
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout + const Duration(milliseconds: 250));
      await FlutterBluePlus.stopScan();
      await sub.cancel();
    } catch (_) {
      // Safe fallback when BLE permission or hardware is unavailable.
    }

    final list = found.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  /// Pairs and discovers all 6 GATT characteristics on ESP32-S3.
  Future<bool> connectBleSensor(DiscoveredSensor sensor) async {
    _lastSensor = sensor;
    _lastBleError = null;
    if (sensor.isSimulated) {
      _transport = ConnectionTransport.simulated;
      return true;
    }
    if (sensor.rawBleDevice is! BluetoothDevice) {
      _lastBleError = 'No physical BLE device available';
      return false;
    }

    final device = sensor.rawBleDevice as BluetoothDevice;
    try {
      await disconnectBle();
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 12), autoConnect: false);
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (_) {}
      }

      final services = await device.discoverServices();
      _wifiChar = null;
      _contactChar = null;
      _statusChar = null;
      _telemetryChar = null;
      _cmdChar = null;
      _otaChar = null;

      for (final svc in services) {
        if (svc.uuid.str.toLowerCase() == Esp32Uuids.service.toLowerCase()) {
          for (final c in svc.characteristics) {
            final u = c.uuid.str.toLowerCase();
            if (u == Esp32Uuids.wifi) _wifiChar = c;
            if (u == Esp32Uuids.contact) _contactChar = c;
            if (u == Esp32Uuids.status) _statusChar = c;
            if (u == Esp32Uuids.telemetry) _telemetryChar = c;
            if (u == Esp32Uuids.command) _cmdChar = c;
            if (u == Esp32Uuids.ota) _otaChar = c;
          }
        }
      }

      if (_statusChar != null) {
        await _statusChar!.setNotifyValue(true);
        _statusSub = _statusChar!.onValueReceived.listen((bytes) {
          _handleStatusMessage(utf8.decode(bytes, allowMalformed: true).trim());
        });
        await _readWifiStatus();
      }

      if (_telemetryChar != null) {
        await _telemetryChar!.setNotifyValue(true);
        _telemetrySub = _telemetryChar!.onValueReceived.listen((bytes) {
          final raw = utf8.decode(bytes, allowMalformed: true).trim();
          _handleIncomingJsonPayload(raw);
        });
      }

      _connSub = device.connectionState.listen((st) {
        if (st == BluetoothConnectionState.disconnected) {
          if (_wifiProvisionAwaitingReboot) _wifiRebootObserved = true;
          _connectedDevice = null;
          if (!isLanConnected) {
            _transport = ConnectionTransport.disconnected;
          }
          _statusStream.add('BLE_DISCONNECTED');
        }
      });

      _connectedDevice = device;
      _transport = ConnectionTransport.ble;
      // GET_VERSION replaces the readable status characteristic, so keep the
      // Wi-Fi result intact while confirming a provisioning reboot.
      if (!_wifiProvisionAwaitingReboot) await sendCommand('GET_VERSION');
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleStatusMessage(String msg) {
    if (msg.isEmpty) return;
    if (msg.startsWith('CONNECTED_IP:')) {
      final ip = msg.substring('CONNECTED_IP:'.length).trim();
      if (ip.isNotEmpty && ip != '0.0.0.0') _activeLanIp = ip;
    } else if (msg == 'WIFI_CONNECT_FAILED' || msg == 'WIFI_SAVED_REBOOTING') {
      _activeLanIp = null;
      if (msg == 'WIFI_SAVED_REBOOTING' && _wifiProvisionAwaitingReboot) {
        _wifiRebootObserved = true;
      }
    }
    _statusStream.add(msg);
  }

  Future<String?> _readWifiStatus() async {
    if (_statusChar == null) return null;
    try {
      final bytes = await _statusChar!.read();
      final status = utf8.decode(bytes, allowMalformed: true).trim();
      _handleStatusMessage(status);
      return status;
    } catch (_) {}
    return null;
  }

  void _handleIncomingJsonPayload(String raw) {
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('events') && decoded['events'] is List) {
          final list = (decoded['events'] as List)
              .whereType<Map<String, dynamic>>()
              .map(BlackboxEvent.fromJson)
              .toList();
          _blackboxStream.add(list);
        } else if (decoded.containsKey('st')) {
          final snap = TelemetrySnapshot.fromJson(decoded);
          if (snap.ipAddress.isNotEmpty && snap.ipAddress != '0.0.0.0') {
            _activeLanIp = snap.ipAddress;
          } else {
            // Do not keep an old IP after the ESP32 loses Wi-Fi.
            _activeLanIp = null;
            if (!isBleConnected) {
              _transport = ConnectionTransport.disconnected;
            }
          }
          _telemetryStream.add(snap);
        }
      }
    } catch (_) {}
  }

  Future<void> disconnectBle() async {
    await _statusSub?.cancel();
    await _telemetrySub?.cancel();
    await _connSub?.cancel();
    _statusSub = null;
    _telemetrySub = null;
    _connSub = null;
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
    if (_transport == ConnectionTransport.ble) {
      _transport = isLanConnected ? ConnectionTransport.wifiLan : ConnectionTransport.disconnected;
    }
  }

  /// Writes Wi-Fi SSID & Password to ESP32-S3 via BLE CHAR_WIFI_UUID.
  Future<bool> provisionWifi(String ssid, String password, {DiscoveredSensor? sensor}) async {
    _lastBleError = null;
    _activeLanIp = null;
    _wifiProvisionAwaitingReboot = false;
    _wifiRebootObserved = false;
    final targetSensor = sensor ?? _lastSensor;
    if (targetSensor != null && targetSensor.isSimulated) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return true;
    }

    // Auto-reconnect BLE if it dropped while user was typing Wi-Fi credentials.
    if ((!isBleConnected || _wifiChar == null) && targetSensor != null && !targetSensor.isSimulated) {
      final reconnected = await connectBleSensor(targetSensor);
      if (!reconnected) {
        _lastBleError = 'BLE disconnected and reconnect failed';
        return false;
      }
    }

    if (_wifiChar == null) {
      if (targetSensor == null) {
        _lastBleError = 'No sensor selected for Wi-Fi provisioning';
        return false;
      }
      _lastBleError = 'BLE Wi-Fi characteristic not found';
      return false;
    }

    final payloadBytes = utf8.encode(jsonEncode({'ssid': ssid, 'pass': password}));
    // The device may notify and reboot before the BLE write future completes.
    _wifiProvisionAwaitingReboot = true;
    try {
      await _wifiChar!.write(
        payloadBytes,
        withoutResponse: false,
        allowLongWrite: true,
      );
      return true;
    } catch (e) {
      _lastBleError = e.toString();
      // Fallback 1: retry once after reconnecting BLE (handles transient 2.4 GHz drop).
      if (targetSensor != null && !targetSensor.isSimulated) {
        final reconnected = await connectBleSensor(targetSensor);
        if (reconnected && _wifiChar != null) {
          try {
            await _wifiChar!.write(
              payloadBytes,
              withoutResponse: false,
              allowLongWrite: true,
            );
            _lastBleError = null;
            return true;
          } catch (e2) {
            _lastBleError = e2.toString();
            // Fallback 2: write without response if characteristic supports it.
            if (_wifiChar!.properties.writeWithoutResponse) {
              try {
                await _wifiChar!.write(payloadBytes, withoutResponse: true);
                _lastBleError = null;
                return true;
              } catch (e3) {
                _lastBleError = e3.toString();
              }
            }
          }
        }
      }
      _wifiProvisionAwaitingReboot = false;
      return false;
    }
  }

  /// A BLE write only stores credentials. Reconnect after the device reboots
  /// and read its Wi-Fi status before reporting success to the user.
  Future<bool> waitForWifiConnection(DiscoveredSensor sensor) async {
    if (sensor.isSimulated) return false;
    await Future<void>.delayed(const Duration(seconds: 2));
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (!isBleConnected) await connectBleSensor(sensor);
      final status = await _readWifiStatus();
      if (_wifiRebootObserved && status?.startsWith('CONNECTED_IP:') == true && isLanConnected) {
        _wifiProvisionAwaitingReboot = false;
        return true;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    _wifiProvisionAwaitingReboot = false;
    return false;
  }

  /// Syncs emergency phones, Telegram Bot Token / Chat ID, Alert Bot Server URL/Key,
  /// CallMeBot @usernames, channel mask, and floor threshold to ESP32 NVS (BLE first, LAN fallback).
  Future<bool> writeContactConfig({
    String? phoneList,
    String? telegramChatId,
    String? telegramBotToken,
    String? alertBotUrl,
    String? alertBotApiKey,
    String? telegramUsers,
    int? channelMask,
    int? floorMm,
    String? overrideLanIp,
  }) async {
    final Map<String, dynamic> data = {};
    if (phoneList != null) data['phone'] = phoneList;
    if (telegramChatId != null) data['chat_id'] = telegramChatId;
    if (telegramBotToken != null && telegramBotToken.isNotEmpty) {
      data['bot_token'] = telegramBotToken;
    }
    if (alertBotUrl != null) data['bot_url'] = alertBotUrl;
    if (alertBotApiKey != null && alertBotApiKey.isNotEmpty) {
      data['bot_key'] = alertBotApiKey;
    }
    if (telegramUsers != null) data['tg_user'] = telegramUsers;
    if (channelMask != null) data['ch_mask'] = channelMask;
    if (floorMm != null) data['floor_mm'] = floorMm;
    if (data.isEmpty) return false;

    final encoded = jsonEncode(data);

    if (_contactChar != null && isBleConnected) {
      try {
        await _contactChar!.write(
          utf8.encode(encoded),
          withoutResponse: false,
          allowLongWrite: true,
        );
        return true;
      } catch (_) {}
    }

    final ip = overrideLanIp ?? _activeLanIp;
    if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final req = await client.postUrl(Uri.parse('http://$ip/api/config'));
        req.headers.contentType = ContentType.json;
        req.write(encoded);
        final resp = await req.close().timeout(const Duration(seconds: 5));
        await resp.drain<void>();
        client.close();
        return resp.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Sends a control command over BLE first, falling back to Wi-Fi LAN HTTP POST /api/command.
  Future<bool> sendCommand(String cmd, {String? overrideLanIp}) async {
    if (_cmdChar != null && isBleConnected) {
      try {
        await _cmdChar!.write(utf8.encode(cmd), withoutResponse: false);
        return true;
      } catch (_) {}
    }

    final ip = overrideLanIp ?? _activeLanIp;
    if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final uri = Uri.parse('http://$ip/api/command');
        final req = await client.postUrl(uri);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'cmd': cmd}));
        final resp = await req.close().timeout(const Duration(seconds: 5));
        await resp.drain<void>();
        client.close();
        return resp.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Starts periodic Wi-Fi LAN HTTP telemetry polling when operating away from BLE range.
  void startLanPolling(String ip, {String? expectedSensorId}) {
    _activeLanIp = ip;
    _lanPollFailures = 0;
    final generation = ++_lanPollGeneration;
    _lanPollTimer?.cancel();
    if (ip.isEmpty || ip == '0.0.0.0') return;
    _lanPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_lanPollInFlight) return;
      _lanPollInFlight = true;
      final snap = await fetchLanTelemetry(ip);
      _lanPollInFlight = false;
      if (generation != _lanPollGeneration) return;
      final expected = expectedSensorId?.toUpperCase().replaceAll(RegExp(r'[^A-F0-9]'), '') ?? '';
      final actual = snap?.deviceId.toUpperCase().replaceAll(RegExp(r'[^A-F0-9]'), '') ?? '';
      final verified = snap != null && actual.isNotEmpty &&
          (expected.length < 12 || actual == expected) && snap.ipAddress == ip;
      if (verified) {
        _lanPollFailures = 0;
        if (!isBleConnected) _transport = ConnectionTransport.wifiLan;
        _telemetryStream.add(snap);
      } else {
        _lanPollFailures++;
        if (_lanPollFailures >= 3) {
          _activeLanIp = null;
          if (!isBleConnected) _transport = ConnectionTransport.disconnected;
        }
      }
    });
  }

  void stopLanPolling() {
    _lanPollGeneration++;
    _lanPollTimer?.cancel();
    _lanPollTimer = null;
  }

  Future<TelemetrySnapshot?> fetchLanTelemetry(String ip) async {
    if (ip.isEmpty || ip == '0.0.0.0') return null;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('http://$ip/api/telemetry'));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return TelemetrySnapshot.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<BlackboxEvent>> fetchLanEvents(String ip) async {
    if (ip.isEmpty || ip == '0.0.0.0') return [];
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('http://$ip/api/events'));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['events'] is List) {
          return (decoded['events'] as List)
              .whereType<Map<String, dynamic>>()
              .map(BlackboxEvent.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Streams firmware binary chunks over BLE OTA characteristic (CHAR_OTA_UUID).
  Future<bool> performBleOta(
    Uint8List firmwareBytes, {
    required ValueChanged<double> onProgress,
  }) async {
    if (_otaChar == null || !isBleConnected) return false;
    try {
      await _otaChar!.write(utf8.encode('OTA_BEGIN:${firmwareBytes.length}'), withoutResponse: false);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      const int chunkSize = 240;
      int offset = 0;
      while (offset < firmwareBytes.length) {
        final end = (offset + chunkSize < firmwareBytes.length) ? offset + chunkSize : firmwareBytes.length;
        final chunk = firmwareBytes.sublist(offset, end);
        await _otaChar!.write(chunk, withoutResponse: true);
        offset = end;
        onProgress(offset / firmwareBytes.length);
        await Future<void>.delayed(const Duration(milliseconds: 12));
      }

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _otaChar!.write(utf8.encode('OTA_END'), withoutResponse: false);
      return true;
    } catch (_) {
      try {
        await _otaChar!.write(utf8.encode('OTA_ABORT'), withoutResponse: false);
      } catch (_) {}
      return false;
    }
  }

  /// Queries latest GitHub Release (including Pre-releases) for App APK/IPA & ESP32 firmware.bin.
  Future<GitHubReleaseInfo?> fetchLatestGitHubRelease() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(
        Uri.parse('https://api.github.com/repos/anlq295-work/FallDetection_S3R8/releases?per_page=1'),
      );
      req.headers.set('User-Agent', 'HearthApp');
      req.headers.set('Accept', 'application/vnd.github.v3+json');
      final resp = await req.close().timeout(const Duration(seconds: 6));
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          final data = decoded.first as Map<String, dynamic>;
          String? apkUrl;
          String? ipaUrl;
          String? fwUrl;
          final assets = (data['assets'] as List?) ?? [];
          for (final a in assets) {
            if (a is Map<String, dynamic>) {
              final name = (a['name'] ?? '').toString().toLowerCase();
              final url = (a['browser_download_url'] ?? '').toString();
              if (name.endsWith('.apk')) apkUrl = url;
              if (name.endsWith('.ipa')) ipaUrl = url;
              if (name == 'firmware.bin') fwUrl = url;
            }
          }
          return GitHubReleaseInfo(
            tagName: (data['tag_name'] ?? kAppReleaseLabel).toString(),
            releaseNotes: (data['body'] ?? '').toString(),
            htmlUrl: (data['html_url'] ?? 'https://github.com/anlq295-work/FallDetection_S3R8/releases').toString(),
            apkUrl: apkUrl,
            ipaUrl: ipaUrl,
            firmwareUrl: fwUrl,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    stopLanPolling();
    disconnectBle();
    _telemetryStream.close();
    _statusStream.close();
    _blackboxStream.close();
  }
}
