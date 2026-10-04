import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Reports', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: uid == null
          ? Center(
              child: Text('Sign in to see your reports', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('reportedBy', isEqualTo: uid)
                  .orderBy('reportedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Could not load your reports.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fact_check_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            "You haven't reported anything yet.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return _ReportCard(data: data);
                  },
                );
              },
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportCard({required this.data});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.danger;
      case 'dismissed':
        return AppColors.textSecondary;
      case 'reviewed':
        return AppColors.tertiary;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final batchCode = data['batchCode'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'pending';
    final notes = data['notes'] as String?;
    final location = data['location'] as String?;
    final photoUrl = data['photoUrl'] as String?;
    final reportedAt = data['reportedAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(photoUrl, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(batchCode, style: AppTextStyles.label),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: AppTextStyles.body.copyWith(color: _statusColor(status), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_formatDate(reportedAt), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12)),
                if (location != null && location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Location: $location', style: AppTextStyles.body.copyWith(fontSize: 13)),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notes, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}