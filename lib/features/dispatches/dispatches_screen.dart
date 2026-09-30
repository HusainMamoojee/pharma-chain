import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

enum DispatchStatus { pendingPickup, inTransit, delivered, awaitingReceipt }

class DispatchRecord {
  final String dispatchId;
  final String partyName;
  final String cartons;
  final String timeInfo;
  final String tempStatus;
  final DispatchStatus status;
  final bool isOutgoing;
  final int progressStep; // 0, 1, 2 for the 3-step tracker; -1 if not applicable

  const DispatchRecord({
    required this.dispatchId,
    required this.partyName,
    required this.cartons,
    required this.timeInfo,
    required this.tempStatus,
    required this.status,
    required this.isOutgoing,
    this.progressStep = -1,
  });
}

class DispatchesScreen extends StatefulWidget {
  const DispatchesScreen({super.key});

  @override
  State<DispatchesScreen> createState() => _DispatchesScreenState();
}

class _DispatchesScreenState extends State<DispatchesScreen> {
  bool _showOutgoing = true;

  // TODO: replace with a real Firestore query on a 'dispatches' collection,
  // filtered by outgoing/incoming and the logged-in staff's depot.
  final List<DispatchRecord> _dispatches = const [
    DispatchRecord(
      dispatchId: 'DSP-20931',
      partyName: 'Dis-Chem Sandton',
      cartons: '48 cartons',
      timeInfo: 'ETA 2h 15m',
      tempStatus: '2.8°C Steady',
      status: DispatchStatus.inTransit,
      isOutgoing: true,
      progressStep: 1,
    ),
    DispatchRecord(
      dispatchId: 'DSP-20928',
      partyName: 'Clicks Distribution Centre',
      cartons: '120 cartons',
      timeInfo: 'Awaiting pickup',
      tempStatus: 'Ambient',
      status: DispatchStatus.pendingPickup,
      isOutgoing: true,
    ),
    DispatchRecord(
      dispatchId: 'DSP-20915',
      partyName: 'Aspen Pharmacare — Depot',
      cartons: '300 cartons',
      timeInfo: 'Arrived 12m ago',
      tempStatus: '3.1°C Steady',
      status: DispatchStatus.awaitingReceipt,
      isOutgoing: false,
    ),
    DispatchRecord(
      dispatchId: 'DSP-20902',
      partyName: 'CPT Depot',
      cartons: '75 cartons',
      timeInfo: 'Delivered yesterday',
      tempStatus: 'Ambient',
      status: DispatchStatus.delivered,
      isOutgoing: false,
    ),
  ];

  Color _statusColor(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.pendingPickup:
        return AppColors.textSecondary;
      case DispatchStatus.inTransit:
        return AppColors.tertiary;
      case DispatchStatus.delivered:
        return AppColors.primary;
      case DispatchStatus.awaitingReceipt:
        return AppColors.danger;
    }
  }

  String _statusLabel(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.pendingPickup:
        return 'Pending Pickup';
      case DispatchStatus.inTransit:
        return 'In Transit';
      case DispatchStatus.delivered:
        return 'Delivered';
      case DispatchStatus.awaitingReceipt:
        return 'Awaiting Receipt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _dispatches.where((d) => d.isOutgoing == _showOutgoing).toList();

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

                  // Outgoing / Incoming toggle
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

                  // Summary strip
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Pending', value: '2', color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'In Transit', value: '5', color: AppColors.tertiary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Awaiting Receipt', value: '1', color: AppColors.danger)),
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DispatchCard(
                    record: filtered[index],
                    statusColor: _statusColor(filtered[index].status),
                    statusLabel: _statusLabel(filtered[index].status),
                  ),
                ),
              ),
            ),
          ],
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
  final Color statusColor;
  final String statusLabel;

  const _DispatchCard({required this.record, required this.statusColor, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final needsAction = record.status == DispatchStatus.pendingPickup || record.status == DispatchStatus.awaitingReceipt;
    final actionLabel = record.isOutgoing ? 'Initiate Transfer' : 'Confirm Receipt';

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
                child: Icon(Icons.local_shipping_outlined, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.dispatchId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(record.partyName, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(record.cartons, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(record.timeInfo, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text(record.tempStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
            ],
          ),
          if (record.progressStep >= 0) ...[
            const SizedBox(height: 12),
            _MiniProgress(step: record.progressStep),
          ],
          if (needsAction) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/custody-transfer', extra: record.dispatchId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.neutral,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final int step; // 0 = Dispatched, 1 = In Transit, 2 = Received

  const _MiniProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = ['Dispatched', 'In Transit', 'Received'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isDone = i <= step;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
                ),
                child: isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < step ? AppColors.primary.withOpacity(0.4) : AppColors.textSecondary.withOpacity(0.15),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}