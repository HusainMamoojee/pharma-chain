import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import '../../services/gateway_service.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class ValidationSuccessScreen extends StatefulWidget {
  final String batchCode;
  final Map<String, dynamic>? batchData;

  const ValidationSuccessScreen({super.key, required this.batchCode, this.batchData});

  @override
  State<ValidationSuccessScreen> createState() => _ValidationSuccessScreenState();
}

class _ValidationSuccessScreenState extends State<ValidationSuccessScreen> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _orgFuture;

  @override
  void initState() {
    super.initState();
    final orgId = widget.batchData?['organizationId'] as String?;
    if (orgId != null && orgId.isNotEmpty) {
      _orgFuture =
          FirebaseFirestore.instance.collection('stakeholders').doc(orgId).get();
    }
  }

  void _scanAnother() {
    // The scanner is the screen underneath, so go back to it (it restarts
    // its camera). Fall back to opening it if we arrived some other way.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/patient-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.batchData?['productName'] as String? ?? 'Unknown product';
    final expiryRaw = widget.batchData?['expiryDate'] as String?;
    final orgId = widget.batchData?['organizationId'] as String?;

    // --- Expiry check (date only, so a batch is valid through its last day) ---
    final parsed = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry =
        parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
    final expired = expiry != null && today.isAfter(expiry);
    final daysLeft = expiry?.difference(today).inDays;
    final expiringSoon = !expired && daysLeft != null && daysLeft <= 30;

    final expiryText = expiry == null
        ? (expiryRaw ?? '—')
        : '${expiry.day} ${_months[expiry.month - 1]} ${expiry.year}';

    // --- Look depends on the result ---
    final Color accent = expired ? AppColors.danger : AppColors.primary;
    final IconData icon = expired ? Icons.warning_amber_rounded : Icons.check;
    final String title = expired ? 'Batch Expired' : 'Batch Verified';
    final String message = expired
        ? 'Do not use this medicine. Return it to a pharmacist.'
        : 'This batch is registered with the manufacturer.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                          child: Icon(icon, color: Colors.white, size: 44),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: expired ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Batch Code', value: widget.batchCode),
                          const Divider(height: 24),
                          _OrganizationRow(orgId: orgId, future: _orgFuture),
                          const Divider(height: 24),
                          _DetailRow(
                            label: expired ? 'Expired On' : 'Expiry Date',
                            value: expiryText,
                            valueColor: expired ? AppColors.danger : null,
                          ),
                          if (expiringSoon) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                daysLeft == 0
                                    ? 'Expires today'
                                    : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                     const SizedBox(height: 20),
                    _JourneyCard(batchCode: widget.batchCode),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _scanAnother,
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text(
                          'Scan Another Item',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.label.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}

class _OrganizationRow extends StatelessWidget {
  final String? orgId;
  final Future<DocumentSnapshot<Map<String, dynamic>>>? future;

  const _OrganizationRow({required this.orgId, required this.future});

  @override
  Widget build(BuildContext context) {
    if (orgId == null || future == null) {
      return const _DetailRow(label: 'Registered by', value: '—');
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['organizationName'] as String? ?? orgId!;
        return _DetailRow(label: 'Registered by', value: name);
      },
    );
  }
}

class _JourneyStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? txId;

  const _JourneyStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.txId,
  });

  factory _JourneyStep.fromEvent(Map<String, dynamic> e, Map<String, String> names) {
    final action = (e['action'] as String? ?? '').toLowerCase();
    final org = names[e['orgId']] ?? 'Unknown organisation';
    final toId = e['toOrgId'] as String? ?? '';
    final toOrg = toId.isEmpty ? 'another organisation' : (names[toId] ?? 'Unknown organisation');

    final d = DateTime.tryParse(e['timestamp'] as String? ?? '')?.toLocal();
    final date = d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

    final rawTx = e['txId'] ?? e['transactionId'];
    final tx = rawTx is String && rawTx.isNotEmpty ? rawTx : null;

    if (action.contains('receipt')) {
      return _JourneyStep(title: 'Received by $org', subtitle: date, icon: Icons.check_circle_outline, txId: tx);
    }
    if (action.contains('transfer')) {
      return _JourneyStep(title: '$org sent it on to $toOrg', subtitle: date, icon: Icons.local_shipping_outlined, txId: tx);
    }
    return _JourneyStep(title: 'Registered by $org', subtitle: date, icon: Icons.factory_outlined, txId: tx);
  }
}

/// The batch's recorded path from the ledger, animated in step by step.
class _JourneyCard extends StatefulWidget {
  final String batchCode;

  const _JourneyCard({required this.batchCode});

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final Future<List<_JourneyStep>> _future = _load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<_JourneyStep>> _load() async {
    final events = await GatewayService.instance.batchHistory(widget.batchCode);

    final ids = <String>{
      for (final e in events) ...[e['orgId'], e['toOrgId']].whereType<String>(),
    }..removeWhere((id) => id.isEmpty);

    final names = <String, String>{};
    await Future.wait(ids.map((id) async {
      try {
        final snap = await FirebaseFirestore.instance.collection('stakeholders').doc(id).get();
        names[id] = snap.data()?['organizationName'] as String? ?? 'Unknown organisation';
      } catch (_) {
        names[id] = 'Unknown organisation';
      }
    }));

    final steps = events.map((e) => _JourneyStep.fromEvent(e, names)).toList()
      ..add(const _JourneyStep(title: 'Scanned by you', subtitle: 'Just now', icon: Icons.qr_code_scanner));

    if (mounted) _controller.forward();
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Journey of this medicine', style: AppTextStyles.label.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            'Recorded on the PharmaChain ledger',
            style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<_JourneyStep>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
              }
              if (snapshot.hasError || (snapshot.data?.length ?? 0) <= 1) {
                return Text(
                  'The recorded journey is not available right now.',
                  style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
                );
              }

              final steps = snapshot.data!;
              return Column(
                children: List.generate(steps.length, (i) {
                  final start = (i / steps.length) * 0.7;
                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, (start + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
                      child: _JourneyTile(step: steps[i], isLast: i == steps.length - 1),
                    ),
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

class _JourneyTile extends StatelessWidget {
  final _JourneyStep step;
  final bool isLast;

  const _JourneyTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: Icon(step.icon, size: 16, color: AppColors.primary),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.primary.withOpacity(0.3))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: AppTextStyles.label.copyWith(fontSize: 14)),
                  if (step.subtitle.isNotEmpty)
                    Text(
                      step.subtitle,
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  if (step.txId != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: step.txId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction ID copied')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Tx ${step.txId!.length > 12 ? '${step.txId!.substring(0, 12)}…' : step.txId!}  ⧉',
                          style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
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