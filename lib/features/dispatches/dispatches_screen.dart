import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';
import '../../shared/widgets/staff_name_text.dart';

class DispatchRecord {
  final String batchCode;
  final String productName;
  final bool isOutgoing;
  final bool isPending; 
  final String fromOrg;
  final DateTime? timestamp;
  final String? staffUid;

  const DispatchRecord({
    required this.batchCode,
    required this.productName,
    required this.isOutgoing,
    required this.timestamp,
    this.isPending = false,
    this.fromOrg = '',
    this.staffUid,
  });

  /// One of our own log entries: a transfer we sent, or a receipt we confirmed.
  factory DispatchRecord.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] as String? ?? '').toLowerCase();
    return DispatchRecord(
      batchCode: data['lotNumber'] as String? ?? 'Unknown batch',
      productName: data['productName'] as String? ?? '',
      isOutgoing: !status.contains('receipt'),
      timestamp: (data['scannedAt'] as Timestamp?)?.toDate(),
      staffUid: data['scannedBy'] as String?,
    );
  }

  /// A transfer another organisation sent to us.
  factory DispatchRecord.incomingTransfer(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool pending}) {
    final data = doc.data();
    return DispatchRecord(
      batchCode: data['lotNumber'] as String? ?? 'Unknown batch',
      productName: data['productName'] as String? ?? '',
      isOutgoing: false,
      isPending: pending,
      fromOrg: data['location'] as String? ?? '',
      timestamp: (data['scannedAt'] as Timestamp?)?.toDate(),
      staffUid: data['scannedBy'] as String?,
    );
  }

  String get timeInfo {
    final t = timestamp;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class DispatchesScreen extends StatefulWidget {
  const DispatchesScreen({super.key});

  @override
  State<DispatchesScreen> createState() => _DispatchesScreenState();
}

class _DispatchesScreenState extends State<DispatchesScreen> {
  bool _showOutgoing = true;
  bool _orgLoaded = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _myLogsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _sentToMeStream;

  @override
  void initState() {
    super.initState();
    _loadOrg();
  }

  Future<void> _loadOrg() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? orgId;
    if (uid != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      orgId = snap.data()?['organizationId'] as String?;
    }
    if (!mounted) return;
    setState(() {
      _orgLoaded = true;
      if (orgId != null) {
        
        final logs = FirebaseFirestore.instance.collection('scan_logs');
        _myLogsStream = logs.where('organizationId', isEqualTo: orgId).snapshots();
        _sentToMeStream = logs.where('toOrgId', isEqualTo: orgId).snapshots();
      }
    });
  }

  Widget _centered(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !_orgLoaded
            ? const Center(child: CircularProgressIndicator())
            : _myLogsStream == null
                ? _centered('Your account is not linked to an organisation yet.')
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _myLogsStream,
                    builder: (context, mySnap) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _sentToMeStream,
                        builder: (context, inSnap) {
                          if (mySnap.connectionState == ConnectionState.waiting ||
                              inSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (mySnap.hasError || inSnap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: SelectableText('Error loading dispatches:\n${mySnap.error ?? inSnap.error}'),
                              ),
                            );
                          }

                          final mine = (mySnap.data?.docs ?? []).map(DispatchRecord.fromDoc).toList();
                          final outgoing = mine.where((d) => d.isOutgoing).toList();
                          final receipts = mine.where((d) => !d.isOutgoing).toList();

                          // A transfer sent to us is pending until we log a receipt for that batch after it.
                          final pending = <DispatchRecord>[];
                          for (final doc in inSnap.data?.docs ?? []) {
                            final status = (doc.data()['status'] as String? ?? '').toLowerCase();
                            if (status.contains('receipt')) continue;
                            final sentAt = (doc.data()['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final lot = doc.data()['lotNumber'] as String? ?? '';
                            final received = receipts.any(
                              (r) => r.batchCode == lot && (r.timestamp ?? DateTime.now()).compareTo(sentAt) >= 0,
                            );
                            if (!received) pending.add(DispatchRecord.incomingTransfer(doc, pending: true));
                          }

                          int byTime(DispatchRecord a, DispatchRecord b) =>
                              (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0));
                          outgoing.sort(byTime);
                          final incoming = [...pending, ...receipts]..sort(byTime);

                          final filtered = _showOutgoing ? outgoing : incoming;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('WAREHOUSE FLOOR',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary)),
                                              Text('Dispatches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await AuthService().signOut();
                                            if (context.mounted) context.go('/staff-login');
                                          },
                                          icon: Icon(Icons.logout_rounded, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.textSecondary.withOpacity(0.12)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(child: _ToggleButton(label: 'Outgoing', isSelected: _showOutgoing, onTap: () => setState(() => _showOutgoing = true))),
                                          Expanded(
                                            child: _ToggleButton(
                                              label: pending.isEmpty ? 'Incoming' : 'Incoming (${pending.length})',
                                              isSelected: !_showOutgoing,
                                              onTap: () => setState(() => _showOutgoing = false),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: _StatCard(label: 'Outgoing', value: '${outgoing.length}', color: AppColors.tertiary)),
                                        const SizedBox(width: 10),
                                        Expanded(child: _StatCard(label: 'Awaiting receipt', value: '${pending.length}', color: AppColors.danger)),
                                        const SizedBox(width: 10),
                                        Expanded(child: _StatCard(label: 'Received', value: '${receipts.length}', color: AppColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_showOutgoing ? 'Outgoing Dispatches' : 'Incoming Dispatches',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        TextButton.icon(
                                          onPressed: () => context.push('/staff-scan'),
                                          icon: Icon(Icons.qr_code_scanner, size: 16, color: AppColors.primary),
                                          label: Text('Start Transfer', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          _showOutgoing ? 'No outgoing dispatches yet.' : 'No incoming dispatches yet.',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _DispatchCard(record: filtered[index]),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const StaffBottomNav(currentIndex: 3),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final DispatchRecord record;

  const _DispatchCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = record.isOutgoing
        ? AppColors.tertiary
        : (record.isPending ? AppColors.danger : AppColors.primary);
    final String badge = record.isOutgoing ? 'Outgoing' : (record.isPending ? 'Awaiting receipt' : 'Received');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(record.isOutgoing ? Icons.north_east : Icons.south_west, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.productName.isEmpty ? record.batchCode : record.productName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    if (record.isPending)
                      Text(
                        '${record.batchCode} • from ${record.fromOrg.isEmpty ? 'another organisation' : record.fromOrg} • ${record.timeInfo}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      )
                    else
                      StaffNameText(
                        uid: record.staffUid,
                        prefix: '${record.batchCode} • ',
                        suffix: ' • ${record.timeInfo}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          if (record.isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/custody-transfer', extra: record.batchCode),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}