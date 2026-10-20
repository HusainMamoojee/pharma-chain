import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'How do I verify a medicine?',
      answer:
          'Tap the scan button, then point your camera at the QR code or barcode on the packaging. '
          'If the code cannot be scanned, choose "Enter Code Manually" and type the batch code printed on the box.',
    ),
    (
      question: 'What does "Authentic" mean?',
      answer:
          'The batch code you scanned matches a batch registered in our system. '
          'You will see the product name, expiry date and the organisation it came from.',
    ),
    (
      question: 'What does "Under Review" mean?',
      answer:
          'The code you scanned was not found in our system. This can mean a counterfeit, '
          'but it can also be a mistyped code or a batch that has not been registered yet. '
          'Check the code and try again. If it still fails, do not use the medicine and report it.',
    ),
    (
      question: 'How do I report a suspected fake medicine?',
      answer:
          'After a scan that cannot be verified, tap "Report This Item", add where you bought it and any notes, '
          'and submit. You can follow the status of your reports under Profile > My Reports.',
    ),
    (
      question: 'Where can I see medicines I have checked before?',
      answer: 'Open the History tab. It lists every code you have verified, newest first.',
    ),
    (
      question: 'I am a staff member. Why do I need a verification code to log in?',
      answer:
          'Staff accounts use two-factor authentication. After your password, you enter a 6-digit code '
          'from an authenticator app such as Google Authenticator or Authy.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Help & Support', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Frequently asked questions', style: AppTextStyles.label.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          ..._faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(faq.question, style: AppTextStyles.label),
                  children: [
                    Text(
                      faq.answer,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}