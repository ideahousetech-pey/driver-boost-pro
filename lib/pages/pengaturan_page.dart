import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../providers/optimizer_provider.dart';
import '../providers/settings_store.dart';
import '../utils/constants.dart';

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cardColor = theme.cardColor;

    return Consumer2<OptimizerProvider, SettingsStore>(
      builder: (context, provider, settingsStore, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Pengaturan', style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Atur perilaku optimizer sesuai gaya berkendara Anda.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // -------------------- Izin --------------------
                _buildSectionTitle('Izin', textTheme),
                const SizedBox(height: 8),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.location_on,
                        color: AppColors.accentGreen),
                    title: Text('Izin Lokasi', style: textTheme.bodyLarge),
                    subtitle: Text(
                        'Butuh akses lokasi untuk memulai pemantauan.',
                        style: textTheme.bodySmall),
                    trailing: Icon(Icons.chevron_right,
                        color: textTheme.bodySmall?.color ?? Colors.grey),
                    onTap: () {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.location);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Pengaturan Lanjutan --------------------
                _buildSectionTitle('Pengaturan Lanjutan', textTheme),
                const SizedBox(height: 8),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.power_settings_new,
                        color: AppColors.accentGreen),
                    title: Text('Autostart & Baterai',
                        style: textTheme.bodyLarge),
                    subtitle: Text(
                        'Cegah Xiaomi mematikan aplikasi.',
                        style: textTheme.bodySmall),
                    trailing: Icon(Icons.chevron_right,
                        color: textTheme.bodySmall?.color ?? Colors.grey),
                    onTap: () {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.settings);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Interval Heartbeat --------------------
                _buildSectionTitle('Interval Heartbeat', textTheme),
                const SizedBox(height: 4),
                Text('Frekuensi pengecekan koneksi internet.',
                    style: textTheme.bodySmall),
                const SizedBox(height: 8),
                _buildIntervalSelector(provider),
                const SizedBox(height: 24),

                // -------------------- Akurasi GPS --------------------
                _buildSectionTitle('Akurasi GPS', textTheme),
                const SizedBox(height: 4),
                Text('Pilih keseimbangan akurasi & baterai.',
                    style: textTheme.bodySmall),
                const SizedBox(height: 8),
                _buildGpsAccuracySelector(provider, textTheme, cardColor),
                const SizedBox(height: 24),

                // -------------------- Perilaku --------------------
                _buildSectionTitle('Perilaku', textTheme),
                const SizedBox(height: 8),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Layar tetap menyala',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Cegah perangkat tidur saat optimizer berjalan.',
                            style: textTheme.bodySmall),
                        value: provider.keepScreenOn,
                        onChanged: (val) => provider.setKeepScreenOn(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: Text('Auto-reconnect',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Coba pulihkan koneksi otomatis saat terputus.',
                            style: textTheme.bodySmall),
                        value: provider.autoReconnect,
                        onChanged: (val) => provider.setAutoReconnect(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: Text('Notifikasi drop sinyal',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Catat setiap drop ke riwayat untuk diperiksa nanti.',
                            style: textTheme.bodySmall),
                        value: provider.notifikasiDrop,
                        onChanged: (val) => provider.setNotifikasiDrop(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: Text('Mode hemat baterai',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Kurangi frekuensi polling GPS untuk hemat daya.',
                            style: textTheme.bodySmall),
                        value: provider.modeHematBaterai,
                        onChanged: (val) => provider.setModeHematBaterai(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      // ---------- Suara & Getar (dari SettingsStore) ----------
                      SwitchListTile(
                        title: Text('Suara Peringatan',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Bunyi saat terjadi drop sinyal.',
                            style: textTheme.bodySmall),
                        value: settingsStore.soundAlert,
                        onChanged: (val) => settingsStore.setSoundAlert(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                      SwitchListTile(
                        title: Text('Getar Peringatan',
                            style: textTheme.bodyLarge),
                        subtitle: Text(
                            'Getar saat terjadi drop sinyal.',
                            style: textTheme.bodySmall),
                        value: settingsStore.vibrationAlert,
                        onChanged: (val) =>
                            settingsStore.setVibrationAlert(val),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.accentGreen
                                : null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Tema --------------------
                _buildSectionTitle('Tema', textTheme),
                const SizedBox(height: 8),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Gelap', style: textTheme.bodyLarge),
                        subtitle: Text('Tema gelap (default)',
                            style: textTheme.bodySmall),
                        value: 'dark',
                        groupValue: provider.themeMode,
                        onChanged: (val) => provider.setThemeMode(val!),
                        activeColor: AppColors.accentGreen,
                      ),
                      RadioListTile<String>(
                        title: Text('Terang', style: textTheme.bodyLarge),
                        subtitle: Text('Tema terang',
                            style: textTheme.bodySmall),
                        value: 'light',
                        groupValue: provider.themeMode,
                        onChanged: (val) => provider.setThemeMode(val!),
                        activeColor: AppColors.accentGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------- Tentang --------------------
                _buildSectionTitle('Tentang', textTheme),
                const SizedBox(height: 8),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver Optimizer',
                            style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            'Versi 1.0.0 — Pemantau koneksi & GPS untuk pengemudi.',
                            style: textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Text(
                          'Driver Optimizer berjalan di latar depan untuk menjaga sinyal GPS dan internet tetap aktif. Untuk hasil maksimal, biarkan aplikasi terbuka selama berkendara. © M.P.V. Cloud CIS & ferry pey',
                          style: textTheme.bodySmall,
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

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Text(title,
        style: textTheme.titleMedium?.copyWith(
            color: AppColors.accentGreen, fontWeight: FontWeight.bold));
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
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildGpsAccuracySelector(
      OptimizerProvider provider, TextTheme textTheme, Color cardColor) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('Hemat', style: textTheme.bodyLarge),
            subtitle: Text('Hemat baterai, akurasi ±50 m',
                style: textTheme.bodySmall),
            value: 'low',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
            activeColor: AppColors.accentGreen,
          ),
          RadioListTile<String>(
            title: Text('Tinggi', style: textTheme.bodyLarge),
            subtitle: Text('Direkomendasikan, akurasi ±10 m',
                style: textTheme.bodySmall),
            value: 'high',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
            activeColor: AppColors.accentGreen,
          ),
          RadioListTile<String>(
            title: Text('Maksimum', style: textTheme.bodyLarge),
            subtitle: Text('Akurasi navigasi, boros baterai',
                style: textTheme.bodySmall),
            value: 'max',
            groupValue: provider.gpsAccuracy,
            onChanged: (val) => provider.setGpsAccuracy(val!),
            activeColor: AppColors.accentGreen,
          ),
        ],
      ),
    );
  }
}