import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Pengaturan', style: AppTextStyles.headline),
                const SizedBox(height: 8),
                const Text(
                  'Atur perilaku optimizer sesuai gaya berkendara Anda.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 24),

                // -------------------- Izin --------------------
                _buildSectionTitle('Izin'),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.location_on,
                        color: AppColors.accentGreen),
                    title: const Text('Izin Lokasi',
                        style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text(
                        'Butuh akses lokasi untuk memulai pemantauan.',
                        style: AppTextStyles.body),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                    onTap: () {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.location);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Interval Heartbeat --------------------
                _buildSectionTitle('Interval Heartbeat'),
                const SizedBox(height: 4),
                const Text('Frekuensi pengecekan koneksi internet.',
                    style: AppTextStyles.body),
                const SizedBox(height: 8),
                _buildIntervalSelector(provider),
                const SizedBox(height: 24),

                // -------------------- Akurasi GPS --------------------
                _buildSectionTitle('Akurasi GPS'),
                const SizedBox(height: 4),
                const Text('Pilih keseimbangan akurasi & baterai.',
                    style: AppTextStyles.body),
                const SizedBox(height: 8),
                _buildGpsAccuracySelector(provider),
                const SizedBox(height: 24),

                // -------------------- Perilaku --------------------
                _buildSectionTitle('Perilaku'),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Layar tetap menyala',
                            style: TextStyle(color: AppColors.textPrimary)),
                        subtitle: const Text(
                            'Cegah perangkat tidur saat optimizer berjalan.',
                            style: AppTextStyles.body),
                        value: provider.keepScreenOn,
                        onChanged: (val) => provider.setKeepScreenOn(val),
                        // Hanya thumbColor, tanpa activeColor
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: const Text('Auto-reconnect',
                            style: TextStyle(color: AppColors.textPrimary)),
                        subtitle: const Text(
                            'Coba pulihkan koneksi otomatis saat terputus.',
                            style: AppTextStyles.body),
                        value: provider.autoReconnect,
                        onChanged: (val) => provider.setAutoReconnect(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: const Text('Notifikasi drop sinyal',
                            style: TextStyle(color: AppColors.textPrimary)),
                        subtitle: const Text(
                            'Catat setiap drop ke riwayat untuk diperiksa nanti.',
                            style: AppTextStyles.body),
                        value: provider.notifikasiDrop,
                        onChanged: (val) => provider.setNotifikasiDrop(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: const Text('Mode hemat baterai',
                            style: TextStyle(color: AppColors.textPrimary)),
                        subtitle: const Text(
                            'Kurangi frekuensi polling GPS untuk hemat daya.',
                            style: AppTextStyles.body),
                        value: provider.modeHematBaterai,
                        onChanged: (val) => provider.setModeHematBaterai(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Tentang --------------------
                _buildSectionTitle('Tentang'),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver Optimizer',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        SizedBox(height: 4),
                        Text(
                            'Versi 1.0.0 — Pemantau koneksi & GPS untuk pengemudi.',
                            style: AppTextStyles.body),
                        SizedBox(height: 12),
                        Text(
                          'Driver Optimizer berjalan di latar depan untuk menjaga sinyal GPS dan internet tetap aktif. Untuk hasil maksimal, biarkan aplikasi terbuka selama berkendara. ©M.P.V. Cloud CIS & ferry pey',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.accentGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16));
  }

  Widget _buildIntervalSelector(OptimizerProvider provider) {
    final intervals = [10, 15, 30, 60, 120];
    final labels = ['10d', '15d', '30d', '1m', '2m'];

    return SegmentedButton<int>(
      segments: List.generate(intervals.length, (i) {
        return ButtonSegment<int>(
          value: intervals[i],
          label: Text(labels[i], style: const TextStyle(fontSize: 13)),
        );
      }),
      selected: {provider.intervalSeconds},
      onSelectionChanged: (Set<int> newSelection) {
        provider.setInterval(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentGreen;
          }
          return AppColors.card;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return AppColors.textPrimary;
        }),
      ),
    );
  }

  Widget _buildGpsAccuracySelector(OptimizerProvider provider) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Hemat',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Hemat baterai, akurasi ±50 m',
                style: AppTextStyles.body),
            value: 'low',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
          ),
          RadioListTile<String>(
            title: const Text('Tinggi',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Direkomendasikan, akurasi ±10 m',
                style: AppTextStyles.body),
            value: 'high',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
          ),
          RadioListTile<String>(
            title: const Text('Maksimum',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Akurasi navigasi, boros baterai',
                style: AppTextStyles.body),
            value: 'max',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
          ),
        ],
      ),
    );
  }
}