
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    // Firebase user's display name.
    final String name =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [
          // =====================================================
          // BACKGROUND DECORATION
          // =====================================================

          Positioned(
            top: -90,
            right: -70,
            child: _blurCircle(
              AppColors.primary.withOpacity(0.18),
              220,
            ),
          ),

          Positioned(
            bottom: -110,
            left: -60,
            child: _blurCircle(
              AppColors.tertiary.withOpacity(0.16),
              240,
            ),
          ),

          // =====================================================
          // MAIN CONTENT
          // =====================================================

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TOP BAR
                  // =================================================

                  _buildTopBar(name),

                  const SizedBox(height: 16),

                  // =================================================
                  // STATUS BADGE
                  // =================================================

                  _buildStatusBadge(),

                  const SizedBox(height: 16),

                  // =================================================
                  // WELCOME MESSAGE
                  // =================================================

                  Text(
                    'Welcome back, $name',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Verify your medicine authenticity and '
                    'trace safe batches instantly.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // SCAN MEDICINE CARD
                  // =================================================

                  _buildScanCard(),

                  const SizedBox(height: 20),

                  // =================================================
                  // RECENT VERIFICATIONS HEADER
                  // =================================================

                  _buildRecentHeader(),

                  const SizedBox(height: 9),

                  // =================================================
                  // RECENT VERIFICATIONS
                  // =================================================

                  const _VerificationCard(
                    medicineName: 'Amoxicillin 500mg',
                    batchNumber: 'Batch #RX-881',
                    time: '10m ago',
                    status: 'Authentic',
                  ),

                  const _VerificationCard(
                    medicineName: 'Lipitor 20mg',
                    batchNumber: 'Batch #LP-429',
                    time: 'Yesterday',
                    status: 'Authentic',
                  ),

                  const _VerificationCard(
                    medicineName: 'Augmentin 625mg',
                    batchNumber: 'Batch #AUG-991',
                    time: '3 days ago',
                    status: 'Under Review',
                    warning: true,
                  ),

                  const _VerificationCard(
                    medicineName: 'Panado Paracetamol',
                    batchNumber: 'Batch #PA-0129',
                    time: '1 week ago',
                    status: 'Authentic',
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // MEDICINE JOURNEY
                  // =================================================

                  _buildMedicineJourney(),

                  const SizedBox(height: 14),

                  // =================================================
                  // SECURITY
                  // =================================================

                  _buildSecurityCard(),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),

      // ===========================================================
      // BOTTOM NAVIGATION
      // ===========================================================

      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        elevation: 5,
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        indicatorColor:
            AppColors.primary.withOpacity(0.12),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.qr_code_scanner_outlined,
            ),
            selectedIcon: Icon(
              Icons.qr_code_scanner,
            ),
            label: 'Scan',
          ),

          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TOP BAR
  // =============================================================

  Widget _buildTopBar(String name) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.local_pharmacy_outlined,
            color: AppColors.primary,
            size: 23,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'PHARMACHAIN',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 1),

              Text(
                'Home',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Profile button
        GestureDetector(
          onTap: () {
            // Profile navigation can be connected later.
          },
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary,
            child: Text(
              _getInitial(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STATUS BADGE
  // =============================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4C8277),
            ),
          ),

          const SizedBox(width: 7),

          Text(
            'Ledger Synced • SAHPRA Aligned',
            style: AppTextStyles.body.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SCAN CARD
  // =============================================================

  Widget _buildScanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR icon
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  AppColors.primary.withOpacity(0.10),
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.07),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          Text(
            'Scan Medicine Packaging',
            style: AppTextStyles.label.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Point your camera at the QR code, DataMatrix, '
            'or 2D barcode on any pill bottle, box, '
            'or blister pack.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          // Camera button
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO:
                // Navigate to scanner screen later.
              },
              icon: const Icon(
                Icons.camera_alt_outlined,
                size: 17,
              ),
              label: const Text(
                'Start Camera Scanner',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Manual entry
          GestureDetector(
            onTap: () {
              // TODO:
              // Navigate to manual verification.
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 14,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 5),

                Text(
                  'Enter Code Manually',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // RECENT VERIFICATIONS HEADER
  // =============================================================

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Recent Verifications',
              style: AppTextStyles.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                '4 today',
                style: AppTextStyles.body.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () {
            // TODO: Navigate to history.
          },
          child: Text(
            'View all ›',
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // MEDICINE JOURNEY
  // =============================================================

  Widget _buildMedicineJourney() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.alt_route,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Medicine Journey',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF444444),
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Cold Chain #SA-8832',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F0EA),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Text(
                  '2.8°C Steady',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF48796F),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Timeline
          Row(
            children: [
              _timelinePoint(
                'CPT Depot',
                'Inspected',
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color: AppColors.primary
                      .withOpacity(0.65),
                ),
              ),

              _timelinePoint(
                'Dispatch',
                'Temp OK',
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color: AppColors.primary
                      .withOpacity(0.65),
                ),
              ),

              _timelinePoint(
                'Dis-Chem',
                'Ready for Pickup',
                active: false,
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Text(
            'Explore the tamper-proof blockchain journey '
            'and cold-chain temperature history of your '
            'prescribed medicine.',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF777777),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Explore Supply Route →',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SECURITY CARD
  // =============================================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 16,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Knowledge Security',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Your personal medical details remain '
                  'completely private and encrypted.',
                  style: TextStyle(
                    fontSize: 7,
                    color: Color(0xFF888888),
                  ),
                ),

                Text(
                  'Only cryptographic batch fingerprints '
                  'are checked on-chain.',
                  style: TextStyle(
                    fontSize: 7,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TIMELINE POINT
  // =============================================================

  Widget _timelinePoint(
    String title,
    String subtitle, {
    bool active = true,
  }) {
    return Column(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.primary
                : const Color(0xFFE0DDD9),
          ),
          child: active
              ? const Icon(
                  Icons.check,
                  size: 9,
                  color: Colors.white,
                )
              : null,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 6,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // BLUR CIRCLE
  // =============================================================

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // =============================================================
  // USER INITIAL
  // =============================================================

  String _getInitial(String name) {
    if (name.isEmpty || name == 'there') {
      return '?';
    }

    return name[0].toUpperCase();
  }
}


// =================================================================
// VERIFICATION CARD
// =================================================================

class _VerificationCard extends StatelessWidget {
  final String medicineName;
  final String batchNumber;
  final String time;
  final String status;
  final bool warning;

  const _VerificationCard({
    required this.medicineName,
    required this.batchNumber,
    required this.time,
    required this.status,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool authentic = !warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: authentic
                  ? const Color(0xFFEAF3F0)
                  : const Color(0xFFFCE7E4),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              authentic
                  ? Icons.medication_outlined
                  : Icons.warning_amber_rounded,
              size: 17,
              color: authentic
                  ? const Color(0xFF5D857D)
                  : const Color(0xFFC8756B),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$batchNumber • $time',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: authentic
                  ? const Color(0xFFE1F1ED)
                  : const Color(0xFFF9E5E2),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  authentic
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 10,
                  color: authentic
                      ? const Color(0xFF4C8076)
                      : const Color(0xFFB76157),
                ),

                const SizedBox(width: 3),

                Text(
                  status,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: authentic
                        ? const Color(0xFF4C8076)
                        : const Color(0xFFB76157),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.chevron_right,
            size: 17,
            color: Color(0xFFAAAAAA),
          ),
        ],
      ),
    );
  }
}