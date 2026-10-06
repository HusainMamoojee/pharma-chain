import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

enum AuditType { scan, transfer }

class AuditEntry {
  final AuditType type;
  final String title;
  final String batchCode;
  final String staffLabel;
  final DateTime? timestamp;

  const AuditEntry({
    required this.type,
    required this.title,
    required this.batchCode,
    required this.staffLabel,
    required this.timestamp,
  });

  factory AuditEntry.fromScanLog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AuditEntry(
      type: AuditType.scan,
      title: 'Package scanned — ${data['status'] ?? 'Logged'}',
      batchCode: data['lotNumber'] as String? ?? 'Unknown',
      staffLabel: _shortUid(data['scannedBy'] as String?),
      timestamp: (data['scannedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AuditEntry.fromCustodyEvent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AuditEntry(
      type: AuditType.transfer,
      title: data['action'] as String? ?? 'Custody event',
      batchCode: data['batchCode'] as String? ?? 'Unknown',
      staffLabel: _shortUid(data['staffUid'] as String?),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  static String _shortUid(String? uid) {
    if (uid == null || uid.isEmpty) return 'Unknown staff';
    return 'Staff #${uid.substring(0, uid.length < 6 ? uid.length : 6)}';
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

  bool _matchesFilter(AuditEntry entry) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Scans') return entry.type == AuditType.scan;
    if (_activeFilter == 'Transfers') return entry.type == AuditType.transfer;
    return true;
  }

  IconData _iconFor(AuditType type) => type == AuditType.scan ? Icons.qr_code_scanner : Icons.swap_horiz;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('scan_logs').snapshots(),
          builder: (context, scanSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('custody_events').snapshots(),
              builder: (context, custodySnap) {
                if (scanSnap.connectionState == ConnectionState.waiting ||
                    custodySnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (scanSnap.hasError || custodySnap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SelectableText('Error loading audit log:\n${scanSnap.error ?? custodySnap.error}'),
                    ),
                  );
                }

                final entries = <AuditEntry>[
                  ...(scanSnap.data?.docs ?? []).map(AuditEntry.fromScanLog),
                  ...(custodySnap.data?.docs ?? []).map(AuditEntry.fromCustodyEvent),
                ]..sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));

                final todayCount = entries.where((e) => e.dayLabel == 'Today').length;
                final scanCount = entries.where((e) => e.type == AuditType.scan).length;
                final transferCount = entries.where((e) => e.type == AuditType.transfer).length;
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
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Export — coming soon')),
                                  );
                                },
                                child: Text('Export', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                          Text('Every scan and transfer recorded', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: ['All', 'Scans', 'Transfers'].map((label) {
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
                              Expanded(child: _StatCard(label: 'Scans', value: '$scanCount', color: AppColors.tertiary)),
                              const SizedBox(width: 10),
                              Expanded(child: _StatCard(label: 'Transfers', value: '$transferCount', color: AppColors.primary)),
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
                Text(entry.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${entry.batchCode} • ${entry.staffLabel} • ${entry.timeLabel}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}