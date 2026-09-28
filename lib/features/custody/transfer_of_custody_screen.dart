import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustodyStage {
  final String label;
  final String subLabel;
  final bool completed;

  const CustodyStage({required this.label, required this.subLabel, required this.completed});
}

class TransferOfCustodyScreen extends StatefulWidget {
  final String batchCode;

  const TransferOfCustodyScreen({super.key, required this.batchCode});

  @override
  State<TransferOfCustodyScreen> createState() => _TransferOfCustodyScreenState();
}

class _TransferOfCustodyScreenState extends State<TransferOfCustodyScreen> {
  bool _isProcessing = false;

  // TODO: replace with a real Firestore/blockchain lookup keyed by widget.batchCode
  final List<CustodyStage> _stages = const [
    CustodyStage(label: 'Manufacturer', subLabel: 'Aspen Pharmacare — Inspected', completed: true),
    CustodyStage(label: 'Distribution Depot', subLabel: 'CPT Depot — Temp OK', completed: true),
    CustodyStage(label: 'Pharmacy', subLabel: 'Dis-Chem — Awaiting Receipt', completed: false),
  ];

  // TODO: derive this from the logged-in staff member's actual role/location
  final bool _canConfirmReceipt = true;

  Future<void> _handleAction(String action) async {
    setState(() => _isProcessing = true);

    // TODO: write the custody event to Firestore/blockchain here:
    // { batchCode, action, staffUid, timestamp, location }
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action recorded for ${widget.batchCode}')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Transfer of Custody', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Batch Code', style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(widget.batchCode, style: AppTextStyles.label.copyWith(fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Chain of Custody', style: AppTextStyles.label.copyWith(fontSize: 15)),
                const SizedBox(height: 16),

                Column(
                  children: List.generate(_stages.length, (i) {
                    final stage = _stages[i];
                    final isLast = i == _stages.length - 1;
                    return _CustodyTimelineTile(stage: stage, isLast: isLast);
                  }),
                ),

                const SizedBox(height: 32),
                Text('Take Action', style: AppTextStyles.label.copyWith(fontSize: 15)),
                const SizedBox(height: 12),

                if (_canConfirmReceipt)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleAction('Receipt confirmed'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleAction('Transfer initiated'),
                    icon: Icon(Icons.local_shipping_outlined, color: AppColors.tertiary),
                    label: Text('Initiate Transfer', style: TextStyle(color: AppColors.tertiary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.tertiary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _CustodyTimelineTile extends StatelessWidget {
  final CustodyStage stage;
  final bool isLast;

  const _CustodyTimelineTile({required this.stage, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stage.completed ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
                ),
                child: stage.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: stage.completed ? AppColors.primary.withOpacity(0.4) : AppColors.textSecondary.withOpacity(0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.label, style: AppTextStyles.label.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    stage.subLabel,
                    style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}