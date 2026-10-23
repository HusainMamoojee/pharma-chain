import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';
import '../../shared/widgets/staff_name_text.dart';

enum AuditType { transfer, receipt }

class AuditEntry {
  final AuditType type;
  final String title;
  final String productName;
  final String batchCode;
  final String? staffUid;
  final DateTime? timestamp;

  const AuditEntry({
    required this.type,
    required this.title,
    required this.productName,
    required this.batchCode,
    required this.staffUid,
    required this.timestamp,
  });

  factory AuditEntry.fromScanLog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] as String? ?? '').toLowerCase();
    final isReceipt = status.contains('receipt');
    return AuditEntry(
      type: isReceipt ? AuditType.receipt : AuditType.transfer,
      title: isReceipt ? 'Receipt confirmed' : 'Transfer initiated',
      productName: data['productName'] as String? ?? '',
      batchCode: data['lotNumber'] as String? ?? 'Unknown',
      staffUid: data['scannedBy'] as String?,
      timestamp: (data['scannedAt'] as Timestamp?)?.toDate(),
    );
  }

  String get dayLabel {
    if (timestamp == null) return 'Unknown date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(timestamp!.year, timestamp!.month, timestamp!.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${timestamp!.day}/${timestamp!.month}/${timestamp!.year}';
  }

  String get timeLabel {
    if (timestamp == null) return '—';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String _activeFilter = 'All';
  bool _orgLoaded = false;
  String? _orgId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _logsStream;

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
      _orgId = orgId;
      _orgLoaded = true;
      if (orgId != null) {
       
        _logsStream = FirebaseFirestore.instance
            .collection('scan_logs')
            .where('organizationId', isEqualTo: orgId)
            .snapshots();
      }
    });
  }

  bool _matchesFilter(AuditEntry entry) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Transfers') return entry.type == AuditType.transfer;
    if (_activeFilter == 'Receipts') return entry.type == AuditType.receipt;
    return true;
  }

  IconData _iconFor(AuditType type) =>
      type == AuditType.transfer ? Icons.swap_horiz : Icons.inventory_2_outlined;

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  Future<void> _export(List<AuditEntry> entries) async {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export yet.')),
      );
      return;
    }

    final buffer = StringBuffer('Date,Time,Type,Event,Product,Batch,Staff UID\n');
    for (final e in entries) {
      final t = e.timestamp;
      final date = t == null ? '' : t.toIso8601String().substring(0, 10);
      final time = t == null ? '' : t.toIso8601String().substring(11, 19);
      buffer.writeln([
        date,
        time,
        e.type == AuditType.transfer ? 'Transfer' : 'Receipt',
        e.title,
        e.productName,
        e.batchCode,
        e.staffUid ?? '',
      ].map(_csv).join(','));
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/pharmachain-audit-$stamp.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'PharmaChain audit log'),
    );
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
            : _logsStream == null
                ? _centered('Your account is not linked to an organisation yet.')
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _logsStream,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SelectableText('Error loading audit log:\n${snap.error}'),
                          ),
                        );
                      }

                      final entries = (snap.data?.docs ?? []).map(AuditEntry.fromScanLog).toList()
                        ..sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));

                      final todayCount = entries.where((e) => e.dayLabel == 'Today').length;
                      final transferCount = entries.where((e) => e.type == AuditType.transfer).length;
                      final receiptCount = entries.where((e) => e.type == AuditType.receipt).length;
                      final filtered = entries.where(_matchesFilter).toList();
                      final days = filtered.map((e) => e.dayLabel).toSet().toList();

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
                                      child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('WAREHOUSE FLOOR',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary)),
                                          Text('Audit Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _export(filtered),
                                      icon: Icon(Icons.ios_share, size: 16, color: AppColors.primary),
                                      label: Text('Export', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                                Text('Every custody transfer and receipt for your organisation',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 36,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: ['All', 'Transfers', 'Receipts'].map((label) {
                                      final isSelected = _activeFilter == label;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          backgroundColor: AppColors.surface,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: AppColors.textSecondary.withOpacity(0.15)),
                                          ),
                                          onSelected: (_) => setState(() => _activeFilter = label),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _StatCard(label: 'Entries Today', value: '$todayCount', color: AppColors.textPrimary)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _StatCard(label: 'Transfers', value: '$transferCount', color: AppColors.tertiary)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _StatCard(label: 'Receipts', value: '$receiptCount', color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(child: Text('No activity yet.', style: TextStyle(color: AppColors.textSecondary)))
                                : ListView(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    children: [
                                      for (final day in days) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                        ),
                                        ...filtered.where((e) => e.dayLabel == day).map((entry) => Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: _AuditCard(entry: entry, icon: _iconFor(entry.type), color: AppColors.primary),
                                            )),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const StaffBottomNav(currentIndex: 4),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditEntry entry;
  final IconData icon;
  final Color color;

  const _AuditCard({required this.entry, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.productName.isEmpty ? entry.title : '${entry.title} — ${entry.productName}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                StaffNameText(
                  uid: entry.staffUid,
                  prefix: '${entry.batchCode} • ',
                  suffix: ' • ${entry.timeLabel}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}