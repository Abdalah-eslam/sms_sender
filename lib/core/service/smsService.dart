import 'dart:developer' as developer;
import 'package:telephony/telephony.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;
  static const String _tag = 'SmsService';

  /// ارسال رسالة لشخص واحد
  static Future<void> sendToSingle({
    required String phone,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      developer.log('Message cannot be empty', name: _tag);
      throw ArgumentError('Message cannot be empty');
    }

    final permissionsGranted = await _telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      _telephony.sendSms(to: phone, message: message);
      developer.log('SMS sent to $phone', name: _tag);
    } else {
      developer.log('SMS permission not granted', name: _tag);
      throw Exception('SMS permission not granted');
    }
  }

  /// ارسال رسالة لجروب - يرسل رسالة لكل رقم
  static Future<void> sendToGroup({
    required List<String> phones,
    required String message,
  }) async {
    if (phones.isEmpty) {
      developer.log('Phone list is empty', name: _tag);
      throw ArgumentError('Phone list cannot be empty');
    }

    if (message.trim().isEmpty) {
      developer.log('Message cannot be empty', name: _tag);
      throw ArgumentError('Message cannot be empty');
    }

    final permissionsGranted = await _telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      for (final phone in phones) {
        await sendToSingle(phone: phone, message: message);
      }
    } else {
      developer.log('SMS permission not granted', name: _tag);
      throw Exception('SMS permission not granted');
    }
  }
}
