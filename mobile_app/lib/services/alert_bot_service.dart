import 'dart:convert';
import 'dart:io';
import '../core/models.dart';

class AlertBotHealthResult {
  final bool ok;
  final Map<String, bool> providers;
  final int enabledRecipients;
  final String message;

  const AlertBotHealthResult({
    required this.ok,
    this.providers = const {},
    this.enabledRecipients = 0,
    this.message = '',
  });
}

class AlertBotDispatchResult {
  final bool ok;
  final String? alertId;
  final int deliveredCount;
  final int attemptedCount;
  final String summary;

  const AlertBotDispatchResult({
    required this.ok,
    this.alertId,
    this.deliveredCount = 0,
    this.attemptedCount = 0,
    this.summary = '',
  });
}

class OtpApiResult {
  final bool ok;
  final String provider;
  final String message;
  final int expiresInSec;

  const OtpApiResult({
    required this.ok,
    this.provider = '',
    this.message = '',
    this.expiresInSec = 300,
  });
}

/// Client for FallDetection_S3R8 Multi-Channel Alert Bot Server (Telegram + SMS + Voice Call)
/// with direct Telegram Bot API & CallMeBot fallback when no Bot Server URL is configured.
class AlertBotService {
  String _normalizeBaseUrl(String rawUrl) {
    var url = rawUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }

  Future<AlertBotHealthResult> checkHealth({
    required String botUrl,
    String apiKey = '',
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty) {
      return const AlertBotHealthResult(ok: false, message: 'Chưa nhập URL Bot Server');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(Uri.parse('$base/health'));
      if (apiKey.trim().isNotEmpty) {
        req.headers.set('X-API-Key', apiKey.trim());
      }
      final resp = await req.close().timeout(const Duration(seconds: 5));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final rawProviders = decoded['providers'];
          final providers = <String, bool>{};
          if (rawProviders is Map) {
            for (final entry in rawProviders.entries) {
              providers[entry.key.toString()] = entry.value == true;
            }
          }
          final count = ((decoded['enabled_recipient_count'] as num?) ?? 0).toInt();
          return AlertBotHealthResult(
            ok: true,
            providers: providers,
            enabledRecipients: count,
            message: 'OK ($count người nhận)',
          );
        }
      }
      return AlertBotHealthResult(ok: false, message: 'HTTP ${resp.statusCode}');
    } catch (e) {
      return AlertBotHealthResult(ok: false, message: e.toString());
    } finally {
      client.close();
    }
  }

  /// Syncs Hearth App contacts, channel toggles, and escalation mode to the Alert Bot Server.
  Future<bool> syncSettingsToBot({
    required String botUrl,
    String apiKey = '',
    required AlertDispatchMode dispatchMode,
    required int escalationMinutes,
    required bool telegramEnabled,
    required bool smsEnabled,
    required bool callEnabled,
    required String personName,
    required String homeAddress,
    required String doorCode,
    required String emergencyNumber,
    required String esp32LanIp,
    required List<AlertContact> contacts,
    required String defaultTelegramChatIds,
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty) return false;

    final recipients = <Map<String, dynamic>>[];
    final seenChatIds = <String>{};

    for (final c in contacts) {
      final cid = c.telegramChatId.trim();
      final tuser = c.telegramUsername.trim();
      final phone = c.phone.trim();
      if (cid.isEmpty && tuser.isEmpty && phone.isEmpty) continue;
      if (cid.isNotEmpty) seenChatIds.add(cid);
      recipients.add({
        'id': c.id,
        'name': c.name,
        'phone': phone,
        'telegram_chat_id': cid,
        'telegram_username': tuser,
        'enabled': true,
        'is_primary': c.isPrimaryUser,
        'notify_telegram': c.notifyTelegram,
        'notify_sms': c.notifySms,
        'notify_call': c.notifyCall,
      });
    }

    // Also include any default Telegram Group/Chat IDs configured globally
    final globalIds = defaultTelegramChatIds
        .replaceAll(';', ',')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    var groupIdx = 1;
    for (final gid in globalIds) {
      if (seenChatIds.contains(gid)) continue;
      seenChatIds.add(gid);
      recipients.add({
        'id': 'tg_group_$groupIdx',
        'name': 'Telegram Group #$groupIdx',
        'phone': '',
        'telegram_chat_id': gid,
        'telegram_username': '',
        'enabled': true,
        'is_primary': false,
        'notify_telegram': true,
        'notify_sms': false,
        'notify_call': false,
      });
      groupIdx++;
    }

    final payload = {
      'dispatch_mode': dispatchMode == AlertDispatchMode.sequential ? 'sequential' : 'simultaneous',
      'escalation_minutes': escalationMinutes.clamp(1, 30),
      'channels': {
        'telegram': telegramEnabled,
        'sms': smsEnabled,
        'call': callEnabled,
      },
      'person_name': personName,
      'home_address': homeAddress,
      'door_code': doorCode,
      'emergency_number': emergencyNumber,
      'esp32_lan_ip': esp32LanIp,
      'recipients': recipients,
    };

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.putUrl(Uri.parse('$base/api/settings'));
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) {
        req.headers.set('X-API-Key', apiKey.trim());
      }
      req.write(jsonEncode(payload));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Pulls contacts registered via Telegram (/start, /register) from the Alert Bot Server.
  Future<List<AlertContact>?> fetchRecipientsFromBot({
    required String botUrl,
    String apiKey = '',
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(Uri.parse('$base/api/settings'));
      if (apiKey.trim().isNotEmpty) {
        req.headers.set('X-API-Key', apiKey.trim());
      }
      final resp = await req.close().timeout(const Duration(seconds: 5));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['recipients'] is List) {
        return (decoded['recipients'] as List)
            .whereType<Map<String, dynamic>>()
            .map(AlertContact.fromJson)
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Dispatches a fall alert or test alert via Alert Bot Server, or direct Telegram + CallMeBot fallback.
  Future<AlertBotDispatchResult> dispatchFallAlert({
    required String botUrl,
    String apiKey = '',
    required String eventType,
    required String roomName,
    required String personName,
    required bool simulated,
    TelemetrySnapshot? telemetry,
    String note = '',
    // Direct fallback credentials if Alert Bot Server is not configured
    String telegramBotToken = '',
    List<String> telegramChatIds = const [],
    List<String> telegramUsernames = const [],
    List<String> phones = const [],
    bool telegramEnabled = true,
    bool callEnabled = true,
    String fallbackMessage = '',
    List<String>? channelsOverride,
    List<String>? targetRecipientIds,
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isNotEmpty) {
      final endpoint = eventType == 'test' ? '$base/api/alerts/test' : '$base/api/alerts/fall';
      final payload = <String, dynamic>{
        'event_type': eventType,
        'room_name': roomName,
        'person_name': personName,
        'velocity_mm_s': telemetry?.dropRateMmS ?? 0.0,
        'motion_peak': telemetry?.radarMotion ?? 0,
        'target_dist_cm': 0,
        'tof_height_mm': telemetry?.tofHeightMm ?? 0,
        'confidence': telemetry?.confidence ?? 0.0,
        'device_id': telemetry?.deviceId ?? '',
        'device_ip': telemetry?.ipAddress ?? '',
        'uptime_sec': telemetry?.uptimeSec ?? 0,
        'simulated': simulated,
        'note': note,
        'fallback_phones': phones,
        'fallback_chat_ids': telegramChatIds,
        'fallback_telegram_users': telegramUsernames,
      };
      if (channelsOverride != null && channelsOverride.isNotEmpty) {
        payload['channels_override'] = channelsOverride;
      }
      if (targetRecipientIds != null && targetRecipientIds.isNotEmpty) {
        payload['target_recipient_ids'] = targetRecipientIds;
      }
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final req = await client.postUrl(Uri.parse(endpoint));
        req.headers.contentType = ContentType.json;
        if (apiKey.trim().isNotEmpty) {
          req.headers.set('X-API-Key', apiKey.trim());
        }
        req.write(jsonEncode(payload));
        final resp = await req.close().timeout(const Duration(seconds: 8));
        final body = await resp.transform(utf8.decoder).join();
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            final delivered = ((decoded['delivered_count'] as num?) ?? 0).toInt();
            final attempted = ((decoded['attempted_count'] as num?) ?? 0).toInt();
            final alertMap = decoded['alert'];
            final alertId = alertMap is Map<String, dynamic> ? alertMap['alert_id']?.toString() : null;
            return AlertBotDispatchResult(
              ok: decoded['ok'] == true,
              alertId: alertId,
              deliveredCount: delivered,
              attemptedCount: attempted,
              summary: 'Bot: $delivered/$attempted',
            );
          }
        }
      } catch (_) {
        // Fall through to direct Telegram/CallMeBot fallback below
      } finally {
        client.close();
      }
    }

    // Direct fallback (no Bot Server or unreachable): Telegram Bot API + CallMeBot
    var delivered = 0;
    var attempted = 0;
    final text = fallbackMessage.isNotEmpty
        ? fallbackMessage
        : '🚨 HEARTH: $personName — $roomName (${simulated ? "TEST" : "CẢNH BÁO TÉ NGÃ"})';

    if (telegramEnabled && telegramBotToken.trim().isNotEmpty && telegramChatIds.isNotEmpty) {
      for (final cid in telegramChatIds) {
        attempted++;
        final ok = await _sendDirectTelegram(telegramBotToken.trim(), cid, text);
        if (ok) delivered++;
      }
    }

    if (callEnabled && telegramUsernames.isNotEmpty) {
      for (final user in telegramUsernames) {
        attempted++;
        final ok = await _callDirectCallMeBot(user, text);
        if (ok) delivered++;
      }
    }

    return AlertBotDispatchResult(
      ok: delivered > 0,
      deliveredCount: delivered,
      attemptedCount: attempted,
      summary: attempted > 0 ? 'Direct: $delivered/$attempted' : 'Chưa cấu hình Bot / Telegram',
    );
  }

  Future<bool> _sendDirectTelegram(String token, String chatId, String text) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.postUrl(Uri.parse('https://api.telegram.org/bot$token/sendMessage'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'chat_id': chatId.trim(),
        'text': text,
        'parse_mode': 'HTML',
      }));
      final resp = await req.close().timeout(const Duration(seconds: 6));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> _callDirectCallMeBot(String username, String text) async {
    var user = username.trim();
    if (user.isEmpty) return false;
    if (!user.startsWith('@')) user = '@$user';

    final uri = Uri.http('api.callmebot.com', '/start.php', {
      'user': user,
      'text': text,
      'lang': 'vi-VN-Standard-A',
      'rpt': '3',
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> acknowledgeAlert({
    required String botUrl,
    String apiKey = '',
    required String alertId,
    required String by,
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty || alertId.isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.postUrl(Uri.parse('$base/api/alerts/$alertId/ack'));
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) req.headers.set('X-API-Key', apiKey.trim());
      req.write(jsonEncode({'by': by}));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> resolveAlert({
    required String botUrl,
    String apiKey = '',
    required String alertId,
    required String by,
    required String outcome,
    String falseAlarmReason = '',
    String note = '',
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty || alertId.isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.postUrl(Uri.parse('$base/api/alerts/$alertId/resolve'));
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) req.headers.set('X-API-Key', apiKey.trim());
      req.write(jsonEncode({
        'by': by,
        'outcome': outcome,
        'false_alarm_reason': falseAlarmReason,
        'note': note,
      }));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Requests a 6-digit login verification OTP via Alert Bot Server (Twilio Verify Email/SMS / SendGrid / SMTP).
  Future<OtpApiResult> sendEmailOtp({
    required String botUrl,
    String apiKey = '',
    required String email,
    String phone = '',
    String carerName = '',
    String language = 'vi',
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty) {
      return const OtpApiResult(ok: false, message: 'Chưa cấu hình URL Bot Server');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.postUrl(Uri.parse('$base/api/auth/otp/send'));
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) req.headers.set('X-API-Key', apiKey.trim());
      req.write(jsonEncode({
        'email': email.trim(),
        'phone': phone.trim(),
        'carer_name': carerName.trim(),
        'language': language,
      }));
      final resp = await req.close().timeout(const Duration(seconds: 12));
      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return OtpApiResult(
          ok: resp.statusCode == 200 && decoded['ok'] == true,
          provider: (decoded['provider'] ?? '').toString(),
          message: (decoded['detail'] ?? decoded['message'] ?? '').toString(),
          expiresInSec: ((decoded['expires_in_sec'] as num?) ?? 300).toInt(),
        );
      }
      return OtpApiResult(ok: false, message: 'HTTP ${resp.statusCode}');
    } catch (e) {
      return OtpApiResult(ok: false, message: e.toString());
    } finally {
      client.close();
    }
  }

  /// Verifies a 6-digit email/SMS OTP against Alert Bot Server.
  Future<OtpApiResult> verifyEmailOtp({
    required String botUrl,
    String apiKey = '',
    required String email,
    String phone = '',
    required String code,
  }) async {
    final base = _normalizeBaseUrl(botUrl);
    if (base.isEmpty) {
      return const OtpApiResult(ok: false, message: 'Chưa cấu hình URL Bot Server');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.postUrl(Uri.parse('$base/api/auth/otp/verify'));
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) req.headers.set('X-API-Key', apiKey.trim());
      req.write(jsonEncode({
        'email': email.trim(),
        'phone': phone.trim(),
        'code': code.trim(),
      }));
      final resp = await req.close().timeout(const Duration(seconds: 10));
      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return OtpApiResult(
          ok: resp.statusCode == 200 && decoded['ok'] == true,
          provider: (decoded['provider'] ?? '').toString(),
          message: (decoded['detail'] ?? decoded['message'] ?? '').toString(),
        );
      }
      return OtpApiResult(ok: false, message: 'HTTP ${resp.statusCode}');
    } catch (e) {
      return OtpApiResult(ok: false, message: e.toString());
    } finally {
      client.close();
    }
  }
}
