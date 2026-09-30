import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

enum AuditType { scan, transfer, alert }

class AuditEntry {
  final AuditType type;
  final String title;
  final String batchCode;
  final String staffName;
  final String time;
  final String txHash;
  final String day; // 'Today' or 'Yesterday'

  const AuditEntry({
    required this.type,
    required this.title,
    required this.batchCode,
    required this.staffName,
    required this.time,
    required this.txHash,
    required this.day,
  });
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String _activeFilter = 'All';

  // TODO: replace with a real Firestore query on an 'audit_log' collection,
  // ordered by timestamp descending, filtered by type and depot.
  final List<AuditEntry> _entries = const [
    AuditEntry(
      type: AuditType.transfer,
      title: 'Custody transfer confirmed',
      batchCode: 'LOT-ZA-99420',
      staffName: 'Husain M.',
      time: '10m ago',
      txHash: '0x8f3a…c21d',
      day: 'Today',
    ),
    AuditEntry(
      type: AuditType.scan,
      title: 'Package scanned',
      batchCode: 'LOT-ZA-88219',
      staffName: 'Husain M.',
      time: '42m ago',
      txHash: '0x2b91…7fa4',
      day: 'Today',
    ),
    AuditEntry(
      type: AuditType.alert,
      title: 'Temperature alert flagged',
      batchCode: 'LOT-ZA-77103',
      staffName: 'System',
      time: '1h ago',
      txHash: '0x91cd…3e0b',
      day: 'Today',
    ),
    AuditEntry(
      type: AuditType.transfer,
      title: 'Batch dispatched',
      batchCode: 'DSP-20902',
      staffName: 'Sipho N.',
      time: '5:12 PM',
      txHash: '0x44aa…19f2',
      day: 'Yesterday',
    ),
  ];

  IconData _iconFor(AuditType type) {
    switch (type) {
      case AuditType.scan:
        return Icons.qr_code_scanner;
      case AuditType.transfer:
        return Icons.swap_horiz;
      case AuditType.alert:
        return Icons.warning_amber_rounded;
    }
  }

  Color _colorFor(AuditType type) {
    return type == AuditType.alert ? AppColors.danger : AppColors.primary;
  }

  bool _matchesFilter(AuditEntry entry) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Scans') return entry.type == AuditType.scan;
    if (_activeFilter == 'Transfers') return entry.type == AuditType.transfer;
    if (_activeFilter == 'Alerts') return entry.type == AuditType.alert;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entries.where(_matchesFilter).toList();
    final days = filtered.map((e) => e.day).toSet().toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                          // TODO: export audit report once backend exists.
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
                  Text('Every action recorded on the ledger', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Scans', 'Transfers', 'Alerts'].map((label) {
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
                      Expanded(child: _StatCard(label: 'Entries Today', value: '${_entries.where((e) => e.day == 'Today').length}', color: AppColors.textPrimary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Flagged', value: '${_entries.where((e) => e.type == AuditType.alert).length}', color: AppColors.danger)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Synced to Ledger', value: '${_entries.length}', color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final day in days) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                    ...filtered.where((e) => e.day == day).map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AuditCard(entry: entry, icon: _iconFor(entry.type), color: _colorFor(entry.type)),
                        )),
                  ],
                ],
              ),
            ),
          ],
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
                Text('${entry.batchCode} • ${entry.staffName} • ${entry.time}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(entry.txHash, style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 10, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text('Verified on Hedera', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}