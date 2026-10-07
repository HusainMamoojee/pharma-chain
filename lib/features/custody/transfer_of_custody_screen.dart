import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/widgets/staff_name_text.dart';

class CustodyStage {
  final String label;
  final String? staffUid;
  final String when;
  final bool completed;


  const CustodyStage({
    required this.label,
    required this.staffUid,
    required this.when,
    required this.completed,
  });
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
  // Live custody history for this batch. No orderBy on purpose, so no
  // composite index is needed; we sort on the device instead.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream =
      FirebaseFirestore.instance
          .collection('custody_events')
          .where('batchCode', isEqualTo: widget.batchCode)
          .snapshots();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sorted(
      QuerySnapshot<Map<String, dynamic>> snap) {
    final docs = snap.docs.toList();
    docs.sort((a, b) {
      final ta = a.data()['timestamp'] as Timestamp?;
      final tb = b.data()['timestamp'] as Timestamp?;
      // A just-written event has a null timestamp until the server fills it in; treat it as newest.
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    return docs;
  }

   CustodyStage _stageFrom(Map<String, dynamic> data) {
    final action = data['action'] as String? ?? 'Event';
    final uid = data['staffUid'] as String?;
    final ts = data['timestamp'] as Timestamp?;

    String when = 'Just now';
    if (ts != null) {
      final d = ts.toDate();
      String two(int n) => n.toString().padLeft(2, '0');
      when = '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    }

    return CustodyStage(label: action, staffUid: uid, when: when, completed: true);
  }


  
  

  Future<void> _handleAction(String action) async {
    setState(() => _isProcessing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Look up the product name so the dashboard's recent-scans list has
      // something readable to show, instead of just the raw batch code.
      final batchDoc = await FirebaseFirestore.instance.collection('batches').doc(widget.batchCode).get();
      final productName = batchDoc.data()?['productName'] as String? ?? widget.batchCode;

      await FirebaseFirestore.instance.collection('custody_events').add({
        'batchCode': widget.batchCode,
        'action': action,
        'staffUid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('scan_logs').add({
        'productName': productName,
        'lotNumber': widget.batchCode,
        'status': action,
        'location': 'Bay 4 (Gauteng Central Depot)',
        'scannedAt': FieldValue.serverTimestamp(),
        'scannedBy': uid,
      });

      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action recorded for ${widget.batchCode}')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not record this action. Please try again.')),
      );
    }
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Could not load custody history:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _sorted(snapshot.data!);
          final stages = docs.map((d) => _stageFrom(d.data())).toList();
          final lastAction = docs.isEmpty ? null : docs.last.data()['action'] as String?;

          // A batch can only be received once someone has sent it, and can only be
          // sent when it is new or has just been received.
          final canConfirmReceipt = lastAction == 'Transfer initiated';
          final canInitiateTransfer = lastAction == null || lastAction == 'Receipt confirmed';

          return Stack(
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

                    if (stages.isEmpty)
                      Text(
                        'No custody events recorded for this batch yet.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      )
                    else
                      Column(
                        children: List.generate(stages.length, (i) {
                          return _CustodyTimelineTile(
                            stage: stages[i],
                            isLast: i == stages.length - 1,
                          );
                        }),
                      ),

                    const SizedBox(height: 32),
                    Text('Take Action', style: AppTextStyles.label.copyWith(fontSize: 15)),
                    const SizedBox(height: 12),

                    if (canConfirmReceipt)
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
                    if (canConfirmReceipt && canInitiateTransfer) const SizedBox(height: 12),
                    if (canInitiateTransfer)
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
          );
        },
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
                 StaffNameText(
                    uid: stage.staffUid,
                    suffix: ' • ${stage.when}',
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