import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DetailConnection extends StatelessWidget {
  final String latency;
  final String reachable;
  final VoidCallback? onCheck;

  const DetailConnection({
    super.key,
    required this.latency,
    required this.reachable,
    this.onCheck,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Koneksi', style: AppTextStyles.headline),
                TextButton.icon(
                  onPressed: onCheck,
                  icon: const Icon(Icons.refresh, color: AppColors.accentGreen),
                  label: const Text('Cek sekarang',
                      style: TextStyle(color: AppColors.accentGreen)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _MetricTile(
                        label: 'Latensi', value: latency.isEmpty ? 'Belum ada' : latency)),
                Expanded(
                    child: _MetricTile(
                        label: 'Jangkau internet',
                        value: reachable.isEmpty ? 'Belum ada' : reachable)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.metricLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.metricValue.copyWith(fontSize: 16)),
      ],
    );
  }
}