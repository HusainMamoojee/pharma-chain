import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CounterfeitCatchScreen extends StatelessWidget {
  final String batchCode;

  const CounterfeitCatchScreen({super.key, required this.batchCode});

  void _checkAnother(BuildContext context) {
    // The scanner is the screen underneath, so go back to it.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/patient-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
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
                          child: const Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Batch Not Recognised',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 26,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We couldn't find this code in PharmaChain's records.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Check the code and try again. If it's correct, don't use "
                      'this medicine until a pharmacist has checked it.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                              Icon(Icons.info_outline,
                                  color: AppColors.danger, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Code checked',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.danger),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            batchCode,
                            maxLines: 4,
                            style: AppTextStyles.body.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // push (not go) so Back from the report returns here.
                        onPressed: () =>
                            context.push('/report-detail', extra: batchCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Report This Item',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _checkAnother(context),
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text(
                          'Check Another Code',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Back to Home',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}