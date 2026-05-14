import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  void _showDropAlert(OptimizerProvider provider) async {
    final type = provider.dropType;
    final title = type == 'internet' ? 'Internet Terputus' : 'GPS Tidak Aktif';
    final content = type == 'internet'
        ? 'Aktifkan data seluler atau WiFi.'
        : 'Aktifkan GPS di pengaturan perangkat.';

    // Tampilkan dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );

    // Reset flag setelah dialog benar-benar ditutup
    provider.dismissDropDialog();

    if (result == true) {
      // Buka pengaturan
      if (type == 'internet') {
        AppSettings.openAppSettings(type: AppSettingsType.wifi);
      } else {
        AppSettings.openAppSettings(type: AppSettingsType.location);
      }
    }
    // Sekarang UI kembali normal, tidak ada panggilan ulang dialog
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final accent = theme.primaryColor;   // warna aksen dari tema

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

                  // Tombol toggle besar di tengah
                  Center(
                    child: _OptimizerToggle(
                      isActive: isActive,
                      accent: accent,                // <-- oper accent
                      onToggle: (value) {
                        if (value) {
                          _startWithPermission(context, provider);
                        } else {
                          provider.stopOptimizer();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status teks di bawah tombol
                  Center(
                    child: Text(
                      isActive ? 'OPTIMIZER AKTIF' : 'Optimizer Tidak Aktif',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? accent : Colors.grey,
                      ),
                    ),
                  ),
                  if (isActive)
                    Center(
                      child: Text(
                        '${provider.totalDisplaySeconds}d',
                        style: textTheme.bodySmall?.copyWith(color: accent),
                      ),
                    ),

                  const SizedBox(height: 32),

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
                        if (!mounted) return;
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
                    accuracy: gps.isFixed ? '${gps.accuracy.toStringAsFixed(1)} m' : '--',
                    speed: gps.isFixed
                       ? (gps.speed >= 0.1 ? '${gps.speed.toStringAsFixed(1)} km/j' : '0 km/j')
                       : '--',
                    bearing: gps.isFixed
                       ? '${gps.bearing.toStringAsFixed(1)}°'
                       : '--',
                    altitude: gps.isFixed
                       ? '${gps.altitude.toStringAsFixed(0)} m'
                       : '--',
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

  void _startWithPermission(BuildContext context, OptimizerProvider provider) async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isDenied && !status.isPermanentlyDenied) {
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Izin Lokasi Diperlukan'),
          content: const Text(
            'Aplikasi ini memerlukan akses lokasi untuk memantau GPS Anda selama perjalanan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Izinkan'),
            ),
          ],
        ),
      );
      if (result == true) {
        await Permission.locationWhenInUse.request();
      }
    }

    if (!mounted) return;
    try {
      await provider.startOptimizer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

// Widget tombol toggle bulat
class _OptimizerToggle extends StatefulWidget {
  final bool isActive;
  final Color accent;
  final ValueChanged<bool> onToggle;

  const _OptimizerToggle({
    required this.isActive,
    required this.accent,
    required this.onToggle,
  });

  @override
  State<_OptimizerToggle> createState() => _OptimizerToggleState();
}

class _OptimizerToggleState extends State<_OptimizerToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _OptimizerToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onToggle(!widget.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.accent;
    final inactiveColor = Colors.grey.shade600;
    final bgColor = widget.isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: widget.isActive
                        ? activeColor.withAlpha((0.4 * 255).round())
                        : Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.power_settings_new,
                size: 48,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}