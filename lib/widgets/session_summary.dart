import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SessionSummary extends StatelessWidget {
  final int totalDisplaySeconds;
  final int sessionDuration;
  final int heartbeats;
  final int fixGps;
  final int dropNet;
  final int dronGps;
  final int batteryLevel;
  final bool isActive;

  const SessionSummary({
    super.key,
    required this.totalDisplaySeconds,
    required this.sessionDuration,
    required this.heartbeats,
    required this.fixGps,
    required this.dropNet,
    required this.dronGps,
    required this.batteryLevel,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sesi Saat Ini', style: AppTextStyles.headline),
            const SizedBox(height: 12),
            if (!isActive)
              const Text('Mulai sesi optimizer untuk perjalanan ini',
                  style: AppTextStyles.body)
            else ...[
              Center(
                child: Text('${totalDisplaySeconds}d',
                    style: AppTextStyles.metricValue.copyWith(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _StatChip(label: 'Durasi', value: '${sessionDuration}s'),
                  _StatChip(label: 'Heartbeat', value: '$heartbeats'),
                  _StatChip(label: 'Fix GPS', value: '$fixGps'),
                  _StatChip(label: 'Drop net', value: '$dropNet'),
                  _StatChip(label: 'Dron GPS', value: '$dronGps'),
                  _StatChip(label: 'Baterai', value: '$batteryLevel%'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: AppColors.accentGreen.withAlpha((0.1 * 255).round()),
      label: Text('$label: $value',
          style: const TextStyle(color: AppColors.accentGreen, fontSize: 13)),
    );
  }
}