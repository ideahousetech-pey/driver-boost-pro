import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
    return Card(
      color: AppColors.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.accentGreen),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.metricLabel),
            if (value != null)
              Text(value!, style: AppTextStyles.metricValue),
            if (subtitle != null)
              Text(subtitle!, style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}