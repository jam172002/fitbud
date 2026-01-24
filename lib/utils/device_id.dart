import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceId {
  static Future<String> get() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return a.id; // stable per device build
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return i.identifierForVendor ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
