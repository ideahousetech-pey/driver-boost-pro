import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/optimizer_provider.dart';
import '../utils/constants.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    return Consumer<OptimizerProvider>(
      builder: (context, provider, _) {
        final logs = provider.logs.where((log) {
          if (_filterDate == null) return true;
          return DateFormat('yyyy-MM-dd').format(log.timestamp) ==
              DateFormat('yyyy-MM-dd').format(_filterDate!);
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Kejadian', style: AppTextStyles.headline),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.accentGreen,
                                  onPrimary: Colors.black,
                                  surface: AppColors.card,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _filterDate = picked);
                        },
                        icon: const Icon(Icons.filter_list, color: AppColors.accentGreen),
                        label: Text(
                          _filterDate == null
                              ? 'Filter'
                              : DateFormat('dd/MM').format(_filterDate!),
                          style: const TextStyle(color: AppColors.accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(
                          child: Text('Belum ada riwayat.', style: AppTextStyles.body))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final isDrop = log.status == 'drop';
                            return Card(
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: Icon(
                                  isDrop ? Icons.error : Icons.check_circle,
                                  color: isDrop ? AppColors.accentRed : AppColors.accentGreen,
                                ),
                                title: Text(log.eventType,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDrop
                                            ? AppColors.accentRed
                                            : AppColors.accentGreen)),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
                                  style: AppTextStyles.body,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}