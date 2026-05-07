import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
    return Card(
      color: AppColors.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail GPS', style: AppTextStyles.headline),
            const SizedBox(height: 12),
            if (!isFixed)
              const Center(
                child: Column(
                  children: [
                    Text('Menunggu fix GPS', style: AppTextStyles.metricValue),
                    SizedBox(height: 8),
                    Text('Mulai optimizer untuk mengaktifkan pemantauan GPS terus-menerus.',
                        style: AppTextStyles.body, textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _GpsItem(label: 'Koordinat', value: '$latitude, $longitude'),
                  _GpsItem(label: 'Akurasi', value: accuracy),
                  _GpsItem(label: 'Kecepatan', value: speed),
                  _GpsItem(label: 'Arah', value: bearing),
                  _GpsItem(label: 'Ketinggian', value: altitude),
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
  const _GpsItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.metricLabel),
          Text(value, style: AppTextStyles.metricValue.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}