import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: accentGreen),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
            if (value != null)
              Text(value!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null)
              Text(subtitle!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}