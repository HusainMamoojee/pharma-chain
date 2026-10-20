import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gateway_service.dart';
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

  // Everything this screen shows comes from the blockchain ledger.
  late Future<_CustodyState> _stateFuture = _loadState();




    void _reload() {
    setState(() {
      _stateFuture = _loadState();
    });
  }



  Future<_CustodyState> _loadState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw GatewayException('You are not signed in.');

    final batch = await GatewayService.instance.verifyBatch(widget.batchCode);
    final events = await GatewayService.instance.batchHistory(widget.batchCode);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final myOrgId = userDoc.data()?['organizationId'] as String?;

    // Organisation names, for display.
    final orgIds = <String>{
      ...events.map((e) => e['orgId']).whereType<String>(),
      ...events.map((e) => e['toOrgId']).whereType<String>(),
      if (batch['holderOrgId'] is String) batch['holderOrgId'] as String,
    }..removeWhere((id) => id.isEmpty);

    final names = <String, String>{};
    await Future.wait(orgIds.map((id) async {
      final snap = await FirebaseFirestore.instance.collection('stakeholders').doc(id).get();
      names[id] = snap.data()?['organizationName'] as String? ?? id;
    }));

    return _CustodyState(batch: batch, events: events, myOrgId: myOrgId, orgNames: names);
  }

  CustodyStage _stageFrom(Map<String, dynamic> e, Map<String, String> names) {
    final action = e['action'] as String? ?? 'Event';
    final toId = e['toOrgId'] as String? ?? '';
    final staffUid = e['staffUid'] as String? ?? '';
    final orgName = names[e['orgId']] ?? '—';

    String when = '';
    final d = DateTime.tryParse(e['timestamp'] as String? ?? '')?.toLocal();
    if (d != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      when = '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    }

    return CustodyStage(
      label: toId.isEmpty ? action : '$action → ${names[toId] ?? toId}',
      staffUid: staffUid.isEmpty ? null : staffUid,
      when: '$orgName • $when',
      completed: true,
    );
  }

    /// Lets staff choose which verified organisation receives the batch.
  /// Returns that organisation's ID, or null if they cancel.
  Future<String?> _pickDestination() async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> options;
    try {
      final state = await _stateFuture;
      final snap = await FirebaseFirestore.instance
          .collection('stakeholders')
          .where('verificationStatus', isEqualTo: 'verified')
          .get();
      options = snap.docs.where((d) => d.id != state.myOrgId).toList();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the list of organisations. Please try again.')),
      );
      return null;
    }

    if (!mounted) return null;

        return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send batch to', style: AppTextStyles.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                if (options.isEmpty)
                  Text(
                    'No other verified organisations are available.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: options
                          .map((d) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(d.data()['organizationName'] as String? ?? d.id),
                                subtitle: Text(d.data()['organizationType'] as String? ?? ''),
                                onTap: () => Navigator.of(sheetContext).pop(d.id),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    String? toOrgId;
    if (action == 'Transfer initiated') {
      toOrgId = await _pickDestination();
      if (toOrgId == null) return; // cancelled
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      // The ledger decides whether this is allowed; it refuses anything the
      // signed-in staff member's organisation isn't entitled to do.
      if (action == 'Transfer initiated') {
        await GatewayService.instance.initiateTransfer(widget.batchCode, toOrgId!);
      } else {
        await GatewayService.instance.confirmReceipt(widget.batchCode);
      }

        // Keep the staff dashboard's recent-scans list working.
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final state = await _stateFuture;
        final myOrgId = state.myOrgId;

        // Real organisation name, instead of a made-up depot.
        String orgName = '';
        if (myOrgId != null) {
          final orgSnap = await FirebaseFirestore.instance
              .collection('stakeholders')
              .doc(myOrgId)
              .get();
          orgName = orgSnap.data()?['organizationName'] as String? ?? '';
        }

        final batchDoc = await FirebaseFirestore.instance
            .collection('batches')
            .doc(widget.batchCode)
            .get();
        final productName =
            batchDoc.data()?['productName'] as String? ?? widget.batchCode;

        await FirebaseFirestore.instance.collection('scan_logs').add({
          'productName': productName,
          'lotNumber': widget.batchCode,
          'status': action,
          'location': orgName,
          'organizationId': myOrgId,
          if (toOrgId != null) 'toOrgId': toOrgId,
          'scannedAt': FieldValue.serverTimestamp(),
          'scannedBy': uid,
        });
      } catch (e) {
        debugPrint('Could not save scan log: $e');
      }
            // Mirror custody into Firestore so Inventory can show what each org holds.
      // The ledger stays the source of truth.
      try {
        final myOrg = (await _stateFuture).myOrgId;
        final batchRef = FirebaseFirestore.instance.collection('batches').doc(widget.batchCode);
        if (action == 'Transfer initiated' && toOrgId != null) {
          await batchRef.update({'inTransitTo': toOrgId});
        } else if (action == 'Receipt confirmed' && myOrg != null) {
          await batchRef.update({
            'holderOrgId': myOrg,
            'inTransitTo': FieldValue.delete(),
          });
        }
      } catch (e) {
        debugPrint('Could not update batch holder: $e');
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action recorded on the blockchain for ${widget.batchCode}')),
      );
      _reload(); // show the new entry in the timeline
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final message = e is GatewayException ? e.message : 'Could not record this action. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      body: FutureBuilder<_CustodyState>(
        future: _stateFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _reload, child: const Text('Try again')),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          final stages = state.events.map((e) => _stageFrom(e, state.orgNames)).toList();
          final canConfirmReceipt = state.canConfirmReceipt;
          final canInitiateTransfer = state.canInitiateTransfer;

          String? notice;
          if (!state.onLedger) {
            notice = 'This batch is not on the blockchain ledger, so its custody cannot be recorded.';
          } else if (!canConfirmReceipt && !canInitiateTransfer) {
            notice = state.custodyStatus == 'In transit'
                ? 'Sent to ${state.orgName(state.pendingToOrgId) ?? 'another organisation'}; waiting for them to confirm receipt.'
                : 'Held by ${state.orgName(state.holderOrgId) ?? 'another organisation'}. Only they can send it on.';
          }

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
                    if (state.onLedger) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Recorded on the blockchain ledger',
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
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

                    if (notice != null)
                      Text(
                        notice,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),

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

class _CustodyState {
  final Map<String, dynamic> batch;
  final List<Map<String, dynamic>> events;
  final String? myOrgId;
  final Map<String, String> orgNames;

  _CustodyState({
    required this.batch,
    required this.events,
    required this.myOrgId,
    required this.orgNames,
  });

  bool get onLedger => batch['exists'] == true;
  String get custodyStatus => batch['custodyStatus'] as String? ?? '';
  String? get holderOrgId => batch['holderOrgId'] as String?;

  /// Who the batch has been sent to, while it is in transit.
  String? get pendingToOrgId {
    if (custodyStatus != 'In transit') return null;
    for (final e in events.reversed) {
      if (e['action'] == 'Transfer initiated') return e['toOrgId'] as String?;
    }
    return null;
  }

  bool get canInitiateTransfer =>
      onLedger && myOrgId != null && holderOrgId == myOrgId && custodyStatus != 'In transit';

  bool get canConfirmReceipt => onLedger && myOrgId != null && pendingToOrgId == myOrgId;

  String? orgName(String? id) => id == null ? null : (orgNames[id] ?? id);
}