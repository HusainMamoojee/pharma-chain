import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';



import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with a real Firestore query on a 'verifications' collection,
    // scoped to the current user's uid, ordered by timestamp descending.
    final items = const [
      _HistoryItem(
        medicineName: 'Amoxicillin 500mg',
        batchNumber: 'Batch #RX-881',
        time: '10m ago',
        status: 'Authentic',
      ),
      _HistoryItem(
        medicineName: 'Lipitor 20mg',
        batchNumber: 'Batch #LP-429',
        time: 'Yesterday',
        status: 'Authentic',
      ),
      _HistoryItem(
        medicineName: 'Augmentin 625mg',
        batchNumber: 'Batch #AUG-991',
        time: '3 days ago',
        status: 'Under Review',
        warning: true,
      ),
      _HistoryItem(
        medicineName: 'Panado Paracetamol',
        batchNumber: 'Batch #PA-0129',
        time: '1 week ago',
        status: 'Authentic',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verification History', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No verifications yet.\nScan a medicine to get started.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => items[index],
            ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String medicineName;
  final String batchNumber;
  final String time;
  final String status;
  final bool warning;

  const _HistoryItem({
    required this.medicineName,
    required this.batchNumber,
    required this.time,
    required this.status,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool authentic = !warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: authentic ? AppColors.primary.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              authentic ? Icons.medication_outlined : Icons.warning_amber_rounded,
              size: 20,
              color: authentic ? AppColors.primary : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicineName, style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(
                  '$batchNumber • $time',
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: authentic ? AppColors.primary.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: authentic ? AppColors.primary : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}