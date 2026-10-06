import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

class DispatchRecord {
  final String batchCode;
  final String action;
  final bool isOutgoing;
  final String timeInfo;

  const DispatchRecord({
    required this.batchCode,
    required this.action,
    required this.isOutgoing,
    required this.timeInfo,
  });

  factory DispatchRecord.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final action = data['action'] as String? ?? 'Unknown action';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    return DispatchRecord(
      batchCode: data['batchCode'] as String? ?? 'Unknown batch',
      action: action,
      isOutgoing: action == 'Transfer initiated',
      timeInfo: timestamp != null ? _timeAgo(timestamp) : '—',
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('custody_events')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SelectableText('Error loading dispatches:\n${snapshot.error}'),
                ),
              );
            }

            final all = (snapshot.data?.docs ?? []).map(DispatchRecord.fromDoc).toList();
            final outgoingCount = all.where((d) => d.isOutgoing).length;
            final incomingCount = all.length - outgoingCount;
            final filtered = all.where((d) => d.isOutgoing == _showOutgoing).toList();

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
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 16,
                            child: const Icon(Icons.person, size: 18, color: AppColors.surface),
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
                            Expanded(child: _ToggleButton(label: 'Incoming', isSelected: !_showOutgoing, onTap: () => setState(() => _showOutgoing = false))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Total', value: '${all.length}', color: AppColors.textPrimary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(label: 'Outgoing', value: '$outgoingCount', color: AppColors.tertiary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(label: 'Incoming', value: '$incomingCount', color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_showOutgoing ? 'Outgoing Dispatches' : 'Incoming Dispatches',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: open a new dispatch creation flow once minting exists.
                            },
                            icon: Icon(Icons.add, size: 16, color: AppColors.primary),
                            label: Text('New Dispatch', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
    final statusColor = record.isOutgoing ? AppColors.tertiary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.local_shipping_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch #${record.batchCode}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${record.action} • ${record.timeInfo}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Text(record.isOutgoing ? 'Outgoing' : 'Incoming', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
    );
  }
}