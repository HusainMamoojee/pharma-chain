import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Looks up a staff member's display name from users/{uid}.fullName and
/// remembers it, so each person is only fetched once per app run.
class StaffDirectory {
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _pending = {};

  static String _fallback(String uid) =>
      'Staff ${uid.length < 6 ? uid : uid.substring(0, 6)}';

  /// What we can show right now without waiting on the network.
  static String peek(String? uid) {
    if (uid == null || uid.isEmpty) return 'Unknown staff';
    return _cache[uid] ?? _fallback(uid);
  }

  static Future<String> nameFor(String? uid) {
    if (uid == null || uid.isEmpty) return Future.value('Unknown staff');
    final cached = _cache[uid];
    if (cached != null) return Future.value(cached);

    return _pending.putIfAbsent(uid, () async {
      String name;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final full = (doc.data()?['fullName'] as String?)?.trim();
        name = (full != null && full.isNotEmpty) ? full : _fallback(uid);
      } catch (_) {
        name = _fallback(uid);
      }
      _cache[uid] = name;
      _pending.remove(uid);
      return name;
    });
  }
}

/// Shows "<prefix><staff name><suffix>" and swaps in the real name once loaded.
class StaffNameText extends StatelessWidget {
  final String? uid;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  const StaffNameText({
    super.key,
    required this.uid,
    this.prefix = '',
    this.suffix = '',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: StaffDirectory.nameFor(uid),
      initialData: StaffDirectory.peek(uid),
      builder: (context, snapshot) {
        return Text('$prefix${snapshot.data}$suffix', style: style);
      },
    );
  }
}