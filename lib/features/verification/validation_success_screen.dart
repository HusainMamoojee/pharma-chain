import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class ValidationSuccessScreen extends StatefulWidget {
  final String batchCode;
  final Map<String, dynamic>? batchData;

  const ValidationSuccessScreen({super.key, required this.batchCode, this.batchData});

  @override
  State<ValidationSuccessScreen> createState() => _ValidationSuccessScreenState();
}

class _ValidationSuccessScreenState extends State<ValidationSuccessScreen> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _orgFuture;

  @override
  void initState() {
    super.initState();
    final orgId = widget.batchData?['organizationId'] as String?;
    if (orgId != null && orgId.isNotEmpty) {
      _orgFuture =
          FirebaseFirestore.instance.collection('stakeholders').doc(orgId).get();
    }
  }

  void _scanAnother() {
    // The scanner is the screen underneath, so go back to it (it restarts
    // its camera). Fall back to opening it if we arrived some other way.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/patient-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.batchData?['productName'] as String? ?? 'Unknown product';
    final expiryRaw = widget.batchData?['expiryDate'] as String?;
    final orgId = widget.batchData?['organizationId'] as String?;

    // --- Expiry check (date only, so a batch is valid through its last day) ---
    final parsed = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry =
        parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
    final expired = expiry != null && today.isAfter(expiry);
    final daysLeft = expiry?.difference(today).inDays;
    final expiringSoon = !expired && daysLeft != null && daysLeft <= 30;

    final expiryText = expiry == null
        ? (expiryRaw ?? '—')
        : '${expiry.day} ${_months[expiry.month - 1]} ${expiry.year}';

    // --- Look depends on the result ---
    final Color accent = expired ? AppColors.danger : AppColors.primary;
    final IconData icon = expired ? Icons.warning_amber_rounded : Icons.check;
    final String title = expired ? 'Batch Expired' : 'Batch Verified';
    final String message = expired
        ? 'Do not use this medicine. Return it to a pharmacist.'
        : 'This batch is registered with the manufacturer.';

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
                        color: accent.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                          child: Icon(icon, color: Colors.white, size: 44),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: expired ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Batch Code', value: widget.batchCode),
                          const Divider(height: 24),
                          _OrganizationRow(orgId: orgId, future: _orgFuture),
                          const Divider(height: 24),
                          _DetailRow(
                            label: expired ? 'Expired On' : 'Expiry Date',
                            value: expiryText,
                            valueColor: expired ? AppColors.danger : null,
                          ),
                          if (expiringSoon) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                daysLeft == 0
                                    ? 'Expires today'
                                    : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _scanAnother,
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text(
                          'Scan Another Item',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.label.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}

class _OrganizationRow extends StatelessWidget {
  final String? orgId;
  final Future<DocumentSnapshot<Map<String, dynamic>>>? future;

  const _OrganizationRow({required this.orgId, required this.future});

  @override
  Widget build(BuildContext context) {
    if (orgId == null || future == null) {
      return const _DetailRow(label: 'Registered by', value: '—');
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['organizationName'] as String? ?? orgId!;
        return _DetailRow(label: 'Registered by', value: name);
      },
    );
  }
}