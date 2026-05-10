import 'package:flutter/material.dart';

class DetailGps extends StatelessWidget {
  final String latitude;
  final String longitude;
  final String accuracy;
  final String speed;
  final String bearing;
  final String altitude;
  final bool isFixed;

  const DetailGps({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.altitude,
    required this.isFixed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail GPS', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!isFixed)
              Center(
                child: Column(
                  children: [
                    Text('Menunggu fix GPS', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text(
                        'Mulai optimizer untuk mengaktifkan pemantauan GPS terus-menerus.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _GpsItem(label: 'Koordinat', value: '$latitude, $longitude', theme: theme),
                  _GpsItem(label: 'Akurasi', value: accuracy, theme: theme),
                  _GpsItem(label: 'Kecepatan', value: speed, theme: theme),
                  _GpsItem(label: 'Arah', value: bearing, theme: theme),
                  _GpsItem(label: 'Ketinggian', value: altitude, theme: theme),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GpsItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _GpsItem({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}