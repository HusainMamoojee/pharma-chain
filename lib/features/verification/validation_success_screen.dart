import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ValidationSuccessScreen extends StatelessWidget {
  final String batchCode;
  final Map<String, dynamic>? batchData;

  const ValidationSuccessScreen({super.key, required this.batchCode, this.batchData});

  @override
  Widget build(BuildContext context) {
    final productName = batchData?['productName'] as String? ?? 'Unknown product';
    final expiryDate = batchData?['expiryDate'] as String? ?? '—';
    final organizationId = batchData?['organizationId'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Authentic Medicine\nVerified',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                productName,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Batch Code', value: batchCode),
                    const Divider(height: 24),
                    _DetailRow(label: 'Product', value: productName),
                    const Divider(height: 24),
                    _OrganizationRow(organizationId: organizationId),
                    const Divider(height: 24),
                    _DetailRow(label: 'Expiry Date', value: expiryDate),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/patient-verification'),
                child: Text(
                  'Scan Another Item',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.label,
          ),
        ),
      ],
    );
  }
}

class _OrganizationRow extends StatelessWidget {
  final String? organizationId;

  const _OrganizationRow({required this.organizationId});

  @override
  Widget build(BuildContext context) {
    if (organizationId == null) {
      return const _DetailRow(label: 'Organization', value: '—');
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('stakeholders').doc(organizationId).get(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['organizationName'] as String? ?? organizationId!;
        return _DetailRow(label: 'Organization', value: name);
      },
    );
  }
}