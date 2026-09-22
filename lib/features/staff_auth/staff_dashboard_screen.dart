import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Staff Dashboard', style: AppTextStyles.headline.copyWith(fontSize: 20)),
      ),
      body: Center(
        child: Text(
          'Staff Home Dashboard — coming soon',
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}