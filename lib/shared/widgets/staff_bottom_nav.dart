import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';



class StaffBottomNav extends StatelessWidget {
  final int currentIndex;  //0 = Dashboard, 1 = Inventory, 3 = Dispatches, 4 = Audit

  const StaffBottomNav({super.key, required this.currentIndex});

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
            isActive: currentIndex == 0,
            onTap: () {
              if (currentIndex != 0) context.go('/staff-dashboard');
            },
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            isActive: currentIndex == 1,
            onTap: () {
              if (currentIndex != 1) context.go('/inventory');
            },
          ),
          GestureDetector(
            onTap: () => context.push('/staff-scan'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
            isActive: currentIndex == 3,
            onTap: () {
              if (currentIndex != 3) context.go('/dispatches');
            }
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Audit',
            isActive: currentIndex == 4,
            onTap: () {
              if (currentIndex != 4) context.go('/audit');
            }
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

  const _NavItem({required this.icon, required this.label, required this.onTap, this.isActive = false});

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