import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/optimizer_provider.dart';
import '../utils/constants.dart';

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OptimizerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengaturan', style: AppTextStyles.headline),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Notifikasi Peringatan',
                        style: TextStyle(color: AppColors.textPrimary)),
                    value: provider.notificationEnabled,
                    onChanged: (val) => provider.setNotificationEnabled(val),
                    thumbColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                         ? AppColors.accentGreen
                         : null),
                    secondary: const Icon(Icons.notifications_active,
                        color: AppColors.accentGreen),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Interval Pengecekan',
                        style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text('${provider.intervalSeconds} detik',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: provider.intervalSeconds.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: AppColors.accentGreen,
                        onChanged: (val) => provider.setInterval(val.round()),
                        label: '${provider.intervalSeconds} d',
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.card),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Tentang Aplikasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Driver Optimizer'),
                            content: const Text(
                              'Versi 1.0\n\nAplikasi ini membantu driver ojek online menjaga koneksi internet dan GPS tetap aktif selama perjalanan.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}