import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static Future<bool> isXiaomi() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    final brand = androidInfo.brand.toLowerCase();
    return manufacturer.contains('xiaomi') ||
        brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco');
  }
}