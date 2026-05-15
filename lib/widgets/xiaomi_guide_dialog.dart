import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../utils/device_helper.dart';

class XiaomiGuideDialog {
  static Future<void> showIfNeeded(BuildContext context) async {
    final isXiaomi = await DeviceHelper.isXiaomi();
    if (!isXiaomi) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Xiaomi Diperlukan'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Agar Driver Optimizer berfungsi, ikuti langkah berikut:'),
              SizedBox(height: 8),
              Text('1. Izinkan Autostart'),
              Text('   Setelan > Aplikasi > Driver Optimizer > Autostart (NYALAKAN).'),
              SizedBox(height: 8),
              Text('2. Nonaktifkan Penghemat Baterai'),
              Text('   Setelan > Aplikasi > Driver Optimizer > Penghemat Baterai > Tanpa batasan.'),
              SizedBox(height: 8),
              Text('3. Izin Lokasi "Sepanjang Waktu"'),
              Text('   Pastikan izin lokasi diatur ke Izinkan sepanjang waktu.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              AppSettings.openAppSettings(type: AppSettingsType.settings);
              Navigator.pop(ctx);
            },
            child: const Text('Buka Setelan'),
          ),
        ],
      ),
    );
  }
}