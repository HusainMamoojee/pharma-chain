import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

enum BatchStatus { coldChainOk, expiringSoon, quarantined, inStock }

class InventoryBatch {
  final String lotNumber;
  final String expiry;
  final String drugName;
  final String detail;
  final String location;
  final String verifiedOn;
  final BatchStatus status;
  final String statusLabel;
  final IconData icon;

  const InventoryBatch({
    required this.lotNumber,
    required this.expiry,
    required this.drugName,
    required this.detail,
    required this.location,
    required this.verifiedOn,
    required this.status,
    required this.statusLabel,
    required this.icon,
  });
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeFilter = 'All Batches';

  // TODO: replace with a real Firestore query on a 'batches' collection,
  // filtered by depot/zone and the selected status filter.
  final List<InventoryBatch> _batches = const [
    InventoryBatch(
      lotNumber: '#LOT-ZA-99420',
      expiry: 'Exp: 14 Nov 2026',
      drugName: 'Insulin Glargine 100U/mL',
      detail: 'SoloStar Prefilled Pens • 320 cartons (3,200 pens)',
      location: 'Zone 2 Chiller (3.8°C)',
      verifiedOn: 'Verified on Hedera',
      status: BatchStatus.coldChainOk,
      statusLabel: 'Cold Chain OK',
      icon: Icons.ac_unit,
    ),
    InventoryBatch(
      lotNumber: '#LOT-ZA-88219',
      expiry: 'Exp: 28 Apr 2025 (18 Days Left)',
      drugName: 'Amoxicillin & Clavulanate',
      detail: '625mg Tablets • 85 cartons available',
      location: 'Zone 4 Ambient • Aisle 12',
      verifiedOn: 'Verified on Polygon',
      status: BatchStatus.expiringSoon,
      statusLabel: 'Expiring Soon',
      icon: Icons.medication_outlined,
    ),
    InventoryBatch(
      lotNumber: '#LOT-ZA-77103',
      expiry: 'Exp: 19 Jun 2025',
      drugName: 'Propofol 1% MCT/LCT',
      detail: '40 cartons held • Temp spike 9.2°C detected',
      location: 'Cold Chain Bay B (Quarantine)',
      verifiedOn: 'Discrepancy Log',
      status: BatchStatus.quarantined,
      statusLabel: 'Quarantined',
      icon: Icons.warning_amber_rounded,
    ),
    InventoryBatch(
      lotNumber: '#LOT-ZA-66512',
      expiry: 'Exp: 08 Dec 2026',
      drugName: 'Paracetamol IV Infusion',
      detail: '10mg/mL Solution • 540 cartons (5,400 vials)',
      location: 'Zone 1 High-Density • Rack C',
      verifiedOn: 'Verified Hash',
      status: BatchStatus.inStock,
      statusLabel: 'In Stock',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  Color _statusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.coldChainOk:
        return AppColors.primary;
      case BatchStatus.expiringSoon:
        return AppColors.tertiary;
      case BatchStatus.quarantined:
        return AppColors.danger;
      case BatchStatus.inStock:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App bar row
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

                        // Location + sync badge
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Gauteng Central Depot • Bay 4', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)),
                                  const SizedBox(width: 6),
                                  Text('SYNC LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Search bar
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

                        // Filter chips
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              'All Batches',
                              'In Stock',
                              'Expiring Soon',
                              'Cold Chain',
                              'Flagged',
                            ].map((label) {
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

                        // Summary cards
                        Row(
                          children: [
                            Expanded(child: _SummaryCard(label: 'Total', value: '1,428', sub: 'Across 8 zones', icon: Icons.inventory_2_outlined, color: AppColors.textPrimary)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryCard(label: '<30 Days', value: '14', sub: 'Action needed', icon: Icons.schedule, color: AppColors.tertiary)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryCard(label: 'Flagged', value: '3', sub: 'Quarantine bay', icon: Icons.warning_amber_rounded, color: AppColors.danger)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Verified Batches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('Showing ${_batches.length} of 1,428', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BatchCard(batch: _batches[index], statusColor: _statusColor(_batches[index].status)),
                      ),
                      childCount: _batches.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Floating scan button
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
                    Text(batch.expiry, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
              Icon(Icons.place_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(batch.location, style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text(batch.verifiedOn, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}