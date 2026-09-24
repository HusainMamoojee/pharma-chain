import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ValidationSuccessScreen extends StatelessWidget {
  final String batchCode;

  const ValidationSuccessScreen({super.key, required this.batchCode});

  @override
  Widget build(BuildContext context) {
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
                'This batch has been confirmed on the blockchain ledger.',
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
                    // TODO: replace these with real fields once batches are
                    // actually stored/minted on-chain and looked up by batchCode
                    const _DetailRow(label: 'Manufacturer', value: 'Aspen Pharmacare'),
                    const Divider(height: 24),
                    const _DetailRow(label: 'Expiry Date', value: '2027-03-14'),
                    const Divider(height: 24),
                    const _DetailRow(label: 'Verified On', value: 'Blockchain Ledger'),
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