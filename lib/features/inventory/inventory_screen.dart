import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

enum BatchStatus { expiringSoon, quarantined, inStock }

class InventoryBatch {
  final String lotNumber;
  final String expiryLabel;
  final String drugName;
  final String detail;
  final String orgLabel;
  final String addedLabel;
  final BatchStatus status;
  final String statusLabel;
  final IconData icon;

  const InventoryBatch({
    required this.lotNumber,
    required this.expiryLabel,
    required this.drugName,
    required this.detail,
    required this.orgLabel,
    required this.addedLabel,
    required this.status,
    required this.statusLabel,
    required this.icon,
  });

  factory InventoryBatch.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawStatus = data['status'] as String?;
    final quantity = data['quantity'];
    final expiryDate = DateTime.tryParse(data['expiryDate'] as String? ?? '');
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    int? daysLeft;
    if (expiryDate != null) {
      daysLeft = expiryDate.difference(DateTime.now()).inDays;
    }

    BatchStatus status;
    String statusLabel;
    IconData icon;

    if (rawStatus == 'quarantined' || (daysLeft != null && daysLeft < 0)) {
      status = BatchStatus.quarantined;
      statusLabel = (daysLeft != null && daysLeft < 0) ? 'Expired' : 'Quarantined';
      icon = Icons.warning_amber_rounded;
    } else if (daysLeft != null && daysLeft <= 30) {
      status = BatchStatus.expiringSoon;
      statusLabel = 'Expiring Soon';
      icon = Icons.schedule;
    } else {
      status = BatchStatus.inStock;
      statusLabel = 'In Stock';
      icon = Icons.inventory_2_outlined;
    }

    return InventoryBatch(
      lotNumber: doc.id,
      expiryLabel: expiryDate != null
          ? 'Exp: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}${daysLeft != null && daysLeft >= 0 && daysLeft <= 30 ? ' ($daysLeft days left)' : ''}'
          : 'Exp: unknown',
      drugName: data['productName'] as String? ?? doc.id,
      detail: quantity != null ? '$quantity units' : 'Quantity unknown',
      orgLabel: data['organizationId'] as String? ?? 'Unknown org',
      addedLabel: createdAt != null ? 'Added ${_timeAgo(createdAt)}' : '',
      status: status,
      statusLabel: statusLabel,
      icon: icon,
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

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeFilter = 'All Batches';

  Color _statusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.expiringSoon:
        return AppColors.tertiary;
      case BatchStatus.quarantined:
        return AppColors.danger;
      case BatchStatus.inStock:
        return AppColors.textSecondary;
    }
  }

  bool _matchesFilter(InventoryBatch batch) {
    switch (_activeFilter) {
      case 'In Stock':
        return batch.status == BatchStatus.inStock;
      case 'Expiring Soon':
        return batch.status == BatchStatus.expiringSoon;
      case 'Flagged':
        return batch.status == BatchStatus.quarantined;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('batches').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SelectableText('Error loading inventory:\n${snapshot.error}'),
                ),
              );
            }

            final allBatches = (snapshot.data?.docs ?? []).map(InventoryBatch.fromDoc).toList();
            final total = allBatches.length;
            final expiringSoonCount = allBatches.where((b) => b.status == BatchStatus.expiringSoon).length;
            final flaggedCount = allBatches.where((b) => b.status == BatchStatus.quarantined).length;
            final filtered = allBatches.where(_matchesFilter).toList();

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
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
                                  child: const Icon(Icons.devices, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WAREHOUSE FLOOR',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary),
                                      ),
                                      Text('Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Scan barcode or search batch, drug...',
                                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: ['All Batches', 'In Stock', 'Expiring Soon', 'Flagged'].map((label) {
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
                                Expanded(child: _SummaryCard(label: 'Total', value: '$total', sub: 'All batches', icon: Icons.inventory_2_outlined, color: AppColors.textPrimary)),
                                const SizedBox(width: 10),
                                Expanded(child: _SummaryCard(label: '<30 Days', value: '$expiringSoonCount', sub: 'Action needed', icon: Icons.schedule, color: AppColors.tertiary)),
                                const SizedBox(width: 10),
                                Expanded(child: _SummaryCard(label: 'Flagged', value: '$flaggedCount', sub: 'Needs review', icon: Icons.warning_amber_rounded, color: AppColors.danger)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Verified Batches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text('Showing ${filtered.length} of $total', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No batches found.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BatchCard(batch: filtered[index], statusColor: _statusColor(filtered[index].status)),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/staff-scan'),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan to Find Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: AppColors.neutral,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const StaffBottomNav(currentIndex: 1),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.sub, required this.icon, required this.color});

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
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          Text(sub, style: TextStyle(fontSize: 9, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final InventoryBatch batch;
  final Color statusColor;

  const _BatchCard({required this.batch, required this.statusColor});

  @override
  Widget build(BuildContext context) {
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
                child: Icon(batch.icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.lotNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(batch.expiryLabel, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(batch.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(batch.drugName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(batch.detail, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.business_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(batch.orgLabel, style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
              if (batch.addedLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(batch.addedLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}