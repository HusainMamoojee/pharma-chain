import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;
    final String name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : 'there';
    final String email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: AppTextStyles.headline.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(email, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _ProfileTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {
                context.push('/edit-profile');
              },
            ),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                context.push('/notification-settings');
              },
            ),
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy & Security',
              onTap: () {
                context.push('/privacy-security');
              },
            ),
            _ProfileTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {
                context.push('/help-support');
              },
            ),
            _ProfileTile(
              icon: Icons.fact_check_outlined,
              label: 'My Reports',
              onTap: () {
                context.go('/my-reports');
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: Icon(Icons.logout, color: AppColors.danger),
                label: Text('Log Out', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppTextStyles.label)),
                Icon(Icons.chevron_right, color: AppColors.textSecondary.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}