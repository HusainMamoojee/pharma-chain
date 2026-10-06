import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _defaults = {
    'verificationResults': true,
    'reportUpdates': true,
    'safetyAlerts': true,
  };

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> _setPref(String key, bool value) async {
    try {
      await _userRef?.set({
        'notificationPrefs': {key: value},
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save preference. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _userRef;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headline.copyWith(fontSize: 18)),
      ),
      body: ref == null
          ? Center(child: Text('Please log in.', style: AppTextStyles.body))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: ref.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final saved = (snapshot.data?.data()?['notificationPrefs'] as Map<String, dynamic>?) ?? {};
                bool valueFor(String key) => saved[key] as bool? ?? _defaults[key]!;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _PrefTile(
                      title: 'Verification results',
                      subtitle: 'Updates about medicines you have scanned',
                      value: valueFor('verificationResults'),
                      onChanged: (v) => _setPref('verificationResults', v),
                    ),
                    _PrefTile(
                      title: 'Report updates',
                      subtitle: 'Status changes on counterfeit reports you submitted',
                      value: valueFor('reportUpdates'),
                      onChanged: (v) => _setPref('reportUpdates', v),
                    ),
                    _PrefTile(
                      title: 'Safety alerts',
                      subtitle: 'Recalls and warnings about batches you have checked',
                      value: valueFor('safetyAlerts'),
                      onChanged: (v) => _setPref('safetyAlerts', v),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your preferences are saved to your account. Push notifications are not switched on in this version of the app yet.',
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(title, style: AppTextStyles.label),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
        ),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}