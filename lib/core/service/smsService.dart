import 'package:telephony/telephony.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  /// ارسال رسالة لشخص واحد
  static Future<void> sendToSingle({
    required String phone,
    required String message,
  }) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      telephony.sendSms(to: phone, message: message);
    } else {
      print("SMS permission not granted!");
    }
  }

  /// ارسال رسالة لجروب
  static Future<void> sendToGroup({
    required List<String> phones,
    required String message,
  }) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      for (String phone in phones) {
        telephony.sendSms(to: phone, message: message);
      }
    } else {
      print("SMS permission not granted!");
    }
  }
}
