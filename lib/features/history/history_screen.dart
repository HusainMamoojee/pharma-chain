import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} week${diff.inDays >= 14 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verification History', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: uid == null
          ? Center(
              child: Text(
                'Please log in to see your verification history.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('verifications')
                  .where('userId', isEqualTo: uid)
                  .orderBy('verifiedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SelectableText(
                        'Error loading history:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.danger),
                      ),
                    ),
                  );
                }

        

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No verifications yet.\nScan a medicine to get started.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final verifiedAt = (data['verifiedAt'] as Timestamp?)?.toDate();
                    final status = data['status'] as String? ?? 'Authentic';
                    return _HistoryItem(
                      medicineName: data['productName'] as String? ?? 'Unknown item',
                      batchNumber: 'Batch #${data['batchCode'] ?? '—'}',
                      time: verifiedAt != null ? _timeAgo(verifiedAt) : '—',
                      status: status,
                      warning: status != 'Authentic',
                    );
                  },
                );
              },
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