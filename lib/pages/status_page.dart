import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../providers/optimizer_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/detail_connection.dart';
import '../widgets/detail_gps.dart';
import '../widgets/session_summary.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  Map<String, String> manualResult = {'latency': '', 'reachable': ''};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OptimizerProvider>();
      provider.addListener(_checkDropDialog);
    });
  }

  void _checkDropDialog() {
    final provider = context.read<OptimizerProvider>();
    if (provider.showDropDialog) {
      _showDropAlert(provider);
    }
  }

  void _showDropAlert(OptimizerProvider provider) {
    final type = provider.dropType;
    final title = type == 'internet' ? 'Internet Terputus' : 'GPS Tidak Aktif';
    final content = type == 'internet'
        ? 'Aktifkan data seluler atau WiFi.'
        : 'Aktifkan GPS di pengaturan perangkat.';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              provider.dismissDropDialog();
              Navigator.pop(ctx);
            },
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.dismissDropDialog();
              Navigator.pop(ctx);
              if (type == 'internet') {
                AppSettings.openAppSettings(type: AppSettingsType.wifi);
              } else {
                AppSettings.openAppSettings(type: AppSettingsType.location);
              }
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    ).then((_) => provider.dismissDropDialog());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final accentGreen = theme.primaryColor;

    return Consumer<OptimizerProvider>(
      builder: (context, provider, child) {
        final isActive = provider.isActive;
        final conn = provider.connectionStatus;
        final gps = provider.gpsStatus;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text('Driver Optimizer', style: textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text('Jaga koneksi & GPS Anda tetap hidup di jalan.',
                      style: textTheme.bodyMedium),
                  const SizedBox(height: 24),

                  // Tombol Mulai / Status Aktif
                  if (!isActive) _buildStartButton(provider, accentGreen, textTheme)
                  else _buildActiveBadge(provider, accentGreen, textTheme),

                  const SizedBox(height: 24),

                  // Dua Kartu Status
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          icon: Icons.signal_cellular_alt,
                          label: 'INTERNET',
                          value: isActive ? conn.stabilityText : null,
                          subtitle: isActive ? conn.typeText : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          icon: Icons.location_on,
                          label: 'GPS',
                          value: isActive ? gps.fixText : null,
                          subtitle: isActive ? gps.accuracyText : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Detail Koneksi
                  DetailConnection(
                    latency: isActive
                        ? '${conn.latencyMs} ms'
                        : (manualResult['latency'] ?? 'Belum ada'),
                    reachable: isActive
                        ? (conn.reachable ? 'Ya' : 'Tidak')
                        : (manualResult['reachable'] ?? 'Belum ada'),
                    onCheck: () {
                      provider.manualCheck().then((res) {
                        setState(() {
                          manualResult = res;
                        });
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Detail GPS
                  DetailGps(
                    isFixed: gps.isFixed,
                    latitude: gps.latitude.toStringAsFixed(5),
                    longitude: gps.longitude.toStringAsFixed(5),
                    accuracy: gps.accuracyText,
                    speed: '${gps.speed.toStringAsFixed(1)} km/j',
                    bearing: '${gps.bearing.toStringAsFixed(1)}°',
                    altitude: '${gps.altitude.toStringAsFixed(0)} m',
                  ),

                  const SizedBox(height: 24),

                  // Sesi Saat Ini
                  SessionSummary(
                    isActive: isActive,
                    totalDisplaySeconds: provider.totalDisplaySeconds,
                    sessionDuration: provider.sessionDurationSecs,
                    heartbeats: provider.heartbeatCount,
                    fixGps: provider.fixGpsCount,
                    dropNet: provider.dropNetCount,
                    dronGps: provider.dronGpsCount,
                    batteryLevel: provider.batteryLevel,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton(OptimizerProvider provider, Color accentGreen, TextTheme textTheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              try {
                await provider.startOptimizer();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('TEKAN UNTUK MULAI'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.battery_alert, color: textTheme.bodySmall?.color, size: 18),
            const SizedBox(width: 4),
            Text('Tidak aktif', style: textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBadge(OptimizerProvider provider, Color accentGreen, TextTheme textTheme) {
    final totalSecs = provider.totalDisplaySeconds;
    final hours = totalSecs ~/ 3600;
    final days = hours ~/ 24;
    final displayDuration = days > 0 ? '${days}d' : '${totalSecs}s';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accentGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentGreen),
          ),
          child: Row(children: [
            Icon(Icons.check_circle, color: accentGreen),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('OPTIMIZER AKTIF',
                  style: TextStyle(
                      color: accentGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(displayDuration,
                  style: TextStyle(color: accentGreen, fontSize: 14)),
            ]),
          ]),
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => provider.stopOptimizer(),
          child: const Text('HENTIKAN'),
        ),
      ],
    );
  }
}