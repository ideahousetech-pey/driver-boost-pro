import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final accentGreen = theme.primaryColor;

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesi Saat Ini', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!isActive)
              Text('Mulai sesi optimizer untuk perjalanan ini',
                  style: theme.textTheme.bodySmall)
            else ...[
              Center(
                child: Text('${totalDisplaySeconds}d',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _StatChip(label: 'Durasi', value: '${sessionDuration}s', accent: accentGreen),
                  _StatChip(label: 'Heartbeat', value: '$heartbeats', accent: accentGreen),
                  _StatChip(label: 'Fix GPS', value: '$fixGps', accent: accentGreen),
                  _StatChip(label: 'Drop net', value: '$dropNet', accent: accentGreen),
                  _StatChip(label: 'Dron GPS', value: '$dronGps', accent: accentGreen),
                  _StatChip(label: 'Baterai', value: '$batteryLevel%', accent: accentGreen),
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
  final Color accent;
  const _StatChip({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: accent.withValues(alpha: 0.1),
      label: Text('$label: $value', style: TextStyle(color: accent, fontSize: 13)),
    );
  }
}