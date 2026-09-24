import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CounterfeitCatchScreen extends StatelessWidget {
  final String batchCode;

  const CounterfeitCatchScreen({super.key, required this.batchCode});

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
                  color: AppColors.danger.withOpacity(0.12),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger,
                    ),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Potential Counterfeit\nDetected',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(fontSize: 24, color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              Text(
                'This batch code could not be verified on the blockchain ledger. Do not use this medicine.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Text('Scanned Code', style: AppTextStyles.label.copyWith(color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(batchCode, style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: hook up to a real reporting flow (Firestore 'reports' collection)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. Thank you for helping keep the supply chain safe.')),
                    );
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Report This Item'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Dismiss',
                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}