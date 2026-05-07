import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A2E);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.textSecondary);
  static const TextStyle metricLabel = TextStyle(
    fontSize: 12, color: AppColors.textSecondary, letterSpacing: 1.2);
  static const TextStyle metricValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
}