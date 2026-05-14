import 'package:flutter/material.dart';

class ConfirmExitDialog {
  static Future<bool> show(BuildContext context, {required bool isOptimizerActive}) async {
    if (!isOptimizerActive) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optimizer Sedang Aktif'),
        content: const Text('Optimizer masih berjalan. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di sini'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}