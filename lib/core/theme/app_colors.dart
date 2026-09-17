import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Figma design system colors
  static const Color primary = Color(0xFF7FB5A8);   // sage teal
  static const Color secondary = Color(0xFFFAF7F2);  // warm cream
  static const Color tertiary = Color(0xFFF4A896);   // coral/salmon
  static const Color neutral = Color(0xFF3A3530);    // dark warm gray

  // Derived shades for states/text
  static const Color background = secondary;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = neutral;
  static const Color textSecondary = Color(0xFF6B655D);
  static const Color danger = Color(0xFFC0392B);
}