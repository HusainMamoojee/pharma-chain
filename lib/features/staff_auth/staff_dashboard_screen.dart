import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/staff_bottom_nav.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final String name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : 'Staff';

    return Scaffold(
      backgroundColor: AppColors.background,

      // 1. CUSTOM APP BAR WITH LOGOUT
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.devices, color: AppColors.textPrimary),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAREHOUSE FLOOR',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            Text(
              'Staff Dashboard',
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
            tooltip: 'Log Out',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/staff-login');
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: AppColors.surface),
            ),
          ),
        ],
      ),

      // 2. MAIN SCROLLABLE BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeSection(name: name),
            const SizedBox(height: 16),
            const _StatsRow(),
            const SizedBox(height: 24),
            const _ScanCtaCard(),
            const SizedBox(height: 24),
            const _RecentScansSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // 3. CUSTOM BOTTOM NAVIGATION
      bottomNavigationBar: const StaffBottomNav(currentIndex: 0),
    );
  }
}

// ==========================================
// 1. WELCOME SECTION
// ==========================================
class _WelcomeSection extends StatelessWidget {
  final String name;

  const _WelcomeSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.neutral.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Node #041-ZA • Online & Synced',
                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text('Hello, $name', style: const TextStyle(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.store, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Logistics • Bay 4 (Gauteng Central Depot)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Shift Target', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('86 / 100 Verified (86%)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.86,
            backgroundColor: AppColors.background,
            color: AppColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. STATS ROW SECTION (Firestore-driven, with graceful fallback)
// ==========================================
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('staff_stats')
          .doc('today')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final pendingCount = data?['pendingChecks']?.toString() ?? '—';
        final alertsCount = data?['recentAlerts']?.toString() ?? '—';

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Pending Checks',
                count: pendingCount,
                description: 'packages waiting',
                headerIcon: Icons.schedule,
                themeColor: AppColors.primary,
                bgColor: AppColors.primary.withOpacity(0.15),
                footerIcon: Icons.alarm,
                footerText: 'Due next 2h',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Recent Alerts',
                count: alertsCount,
                description: '1 temp, 1 seal flag',
                headerIcon: Icons.warning_amber_rounded,
                themeColor: AppColors.danger,
                bgColor: AppColors.danger.withOpacity(0.1),
                footerIcon: Icons.assignment_late_outlined,
                footerText: 'Supervisor Review',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String description;
  final IconData headerIcon;
  final Color themeColor;
  final Color bgColor;
  final IconData footerIcon;
  final String footerText;

  const _StatCard({
    required this.title,
    required this.count,
    required this.description,
    required this.headerIcon,
    required this.themeColor,
    required this.bgColor,
    required this.footerIcon,
    required this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
                child: Icon(headerIcon, size: 16, color: themeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 28, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(footerIcon, size: 14, color: themeColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(footerText, style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. MAIN SCAN CTA CARD
// ==========================================
class _ScanCtaCard extends StatelessWidget {
  const _ScanCtaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(Icons.qr_code_scanner, color: AppColors.surface, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('High-Speed Floor Scan', style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Aim at master carton GS1 DataMatrix or\nindividual vial tamper seal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/staff-scan');
              },
              icon: const Icon(Icons.barcode_reader, color: AppColors.textPrimary),
              label: const Text('Scan Package Now', style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScansSection extends StatelessWidget {
  const _RecentScansSection();

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.history, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text('Recent Floor Scans', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/history'),
              child: const Text('View Log', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('scan_logs')
              .orderBy('scannedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No scans logged yet today.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final scannedAt = (data['scannedAt'] as Timestamp?)?.toDate();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScanLogCard(
                    title: data['productName'] as String? ?? 'Unknown item',
                    subtitle: 'Lot #${data['lotNumber'] ?? '—'}  •  ${scannedAt != null ? _timeAgo(scannedAt) : '—'}',
                    status: data['status'] as String? ?? 'Logged',
                    location: data['location'] as String? ?? '—',
                    statusColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.15),
                    icon: Icons.check_circle_outline,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ScanLogCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String location;
  final Color statusColor;
  final Color bgColor;
  final IconData icon;

  const _ScanLogCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.location,
    required this.statusColor,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vaccines, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(icon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 5. CUSTOM BOTTOM NAVIGATION (now fully interactive)
// ==========================================
class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav();

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.neutral.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _NavItem(
            icon: Icons.grid_view,
            label: 'Dashboard',
            isActive: true,
            onTap: () {
              // Already on the dashboard — no-op.
            },
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: () => _showComingSoon(context, 'Inventory'),
          ),

          GestureDetector(
            onTap: () => context.push('/staff-scan'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.surface, size: 24),
                ),
                const SizedBox(height: 4),
                const Text('Quick Scan', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          _NavItem(
            icon: Icons.local_shipping_outlined,
            label: 'Dispatches',
            onTap: () => _showComingSoon(context, 'Dispatches'),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Audit',
            onTap: () => _showComingSoon(context, 'Audit'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}