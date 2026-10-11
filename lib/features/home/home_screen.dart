import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../shared/verification_status.dart';

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _verificationsStream;

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      // Same query shape as the History screen, so the existing index covers it.
      _verificationsStream = FirebaseFirestore.instance
          .collection('verifications')
          .where('userId', isEqualTo: uid)
          .orderBy('verifiedAt', descending: true)
          .limit(4)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    final String name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _blurCircle(AppColors.primary.withOpacity(0.18), 220),
          ),
          Positioned(
            bottom: -110,
            left: -60,
            child: _blurCircle(AppColors.tertiary.withOpacity(0.16), 240),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(name),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back, $name',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Verify your medicine and trace its journey.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildScanCard(context),
                  const SizedBox(height: 24),
                  _buildRecentHeader(context),
                  const SizedBox(height: 10),
                  _buildLiveSections(context),
                ],
              ),
            ),
          ),
        ],
      ),

      // Home is always the highlighted tab on this screen: the other tabs open
      // as separate screens on top, so the selection must not change here.
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        elevation: 5,
        selectedIndex: 0,
        onDestinationSelected: (int index) {
          if (index == 1) {
            context.push('/patient-verification');
          } else if (index == 2) {
            context.push('/history');
          } else if (index == 3) {
            context.push('/profile');
          }
        },
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
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

  // ---------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------

  Widget _buildTopBar(String name) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'PharmaChain',
            style: AppTextStyles.headline.copyWith(fontSize: 18),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary,
            child: Text(
              _getInitial(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // SCAN CARD
  // ---------------------------------------------------------------

  Widget _buildScanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: Icon(Icons.qr_code_2, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan Medicine Packaging',
            style: AppTextStyles.label.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Scan the code on your medicine pack to check it's genuine.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/patient-verification'),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text(
                'Start Camera Scanner',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.push('/patient-verification'),
            child: Text(
              'Enter code manually',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // RECENT VERIFICATIONS
  // ---------------------------------------------------------------

  Widget _buildRecentHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Verifications',
          style: AppTextStyles.label.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/history'),
          child: Text(
            'View all ›',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Recent verifications plus the journey of the latest real batch, both live.
  Widget _buildLiveSections(BuildContext context) {
    final stream = _verificationsStream;
    if (stream == null) {
      return _emptyMessage('Sign in to see your verifications.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText(
            'Could not load your verifications:\n${snapshot.error}',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyMessage('No verifications yet. Scan a medicine to get started.');
        }

        // Only batches that exist can have a journey, so skip unrecognised codes.
        String latestCode = '';
        String latestName = '';
        for (final d in docs) {
          final data = d.data();
          if ((data['status'] as String?) != 'Under Review') {
            latestCode = data['batchCode'] as String? ?? '';
            latestName = data['productName'] as String? ?? latestCode;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...docs.map((d) => _VerificationCard(data: d.data())),
            if (latestCode.isNotEmpty) ...[
              const SizedBox(height: 20),
              _JourneyCard(batchCode: latestCode, productName: latestName),
            ],
          ],
        );
      },
    );
  }

  Widget _emptyMessage(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty || name == 'there') return '?';
    return name[0].toUpperCase();
  }
}

// =================================================================
// VERIFICATION CARD (live data from the verifications collection)
// =================================================================

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VerificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final batchCode = data['batchCode'] as String? ?? 'Unknown';
    final name = data['productName'] as String? ?? batchCode;
    final status = data['status'] as String? ?? 'Under Review';
    final verifiedAt = (data['verifiedAt'] as Timestamp?)?.toDate();

    final authentic = status == 'Authentic';
    final color = authentic ? AppColors.primary : AppColors.danger;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/history'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                authentic ? Icons.medication_outlined : Icons.warning_amber_rounded,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Batch $batchCode • ${verifiedAt != null ? _timeAgo(verifiedAt) : 'just now'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                verificationStatusLabel(status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// JOURNEY CARD (real custody history of the latest verified batch)
// =================================================================

class _JourneyCard extends StatefulWidget {
  final String batchCode;
  final String productName;

  const _JourneyCard({required this.batchCode, required this.productName});

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    // No orderBy on purpose, so no composite index is needed; sorted on device.
    return FirebaseFirestore.instance
        .collection('custody_events')
        .where('batchCode', isEqualTo: widget.batchCode)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _stream = _buildStream();
  }

  @override
  void didUpdateWidget(covariant _JourneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batchCode != widget.batchCode) {
      _stream = _buildStream();
    }
  }

  String _friendlyAction(String action) {
    switch (action) {
      case 'Transfer initiated':
        return 'Dispatched';
      case 'Receipt confirmed':
        return 'Received';
      default:
        return action;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine Journey',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.productName} • Batch ${widget.batchCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SelectableText(
                  'Could not load the journey:\n${snapshot.error}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }

              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final ta = a.data()['timestamp'] as Timestamp?;
                final tb = b.data()['timestamp'] as Timestamp?;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return ta.compareTo(tb);
              });

              if (docs.isEmpty) {
                return Text(
                  'No hand-overs have been recorded for this batch yet.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                );
              }

              // Show the most recent four steps, oldest first.
              final shown = docs.length > 4 ? docs.sublist(docs.length - 4) : docs;

              return Column(
                children: List.generate(shown.length, (i) {
                  final data = shown[i].data();
                  return _JourneyStep(
                    label: _friendlyAction(data['action'] as String? ?? 'Event'),
                    date: _formatDate(data['timestamp'] as Timestamp?),
                    isLast: i == shown.length - 1,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  final String label;
  final String date;
  final bool isLast;

  const _JourneyStep({required this.label, required this.date, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withOpacity(0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}