import 'package:flutter/material.dart';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Koneksi', style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: onCheck,
                  icon: Icon(Icons.refresh, color: accentGreen),
                  label: Text('Cek sekarang', style: TextStyle(color: accentGreen)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _MetricTile(
                        label: 'Latensi',
                        value: latency.isEmpty ? 'Belum ada' : latency,
                        theme: theme)),
                Expanded(
                    child: _MetricTile(
                        label: 'Jangkau internet',
                        value: reachable.isEmpty ? 'Belum ada' : reachable,
                        theme: theme)),
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
  final ThemeData theme;
  const _MetricTile({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}