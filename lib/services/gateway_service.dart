import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class GatewayException implements Exception {
  final String message;
  GatewayException(this.message);

  @override
  String toString() => message;
}

/// Talks to the PharmaChain blockchain gateway. Every call sends the
/// signed-in user's Firebase ID token; the gateway decides what they may do.
class GatewayService {
  GatewayService._();
  static final GatewayService instance = GatewayService._();

  /// Set at build time:
  ///   flutter run --dart-define=GATEWAY_URL=http://192.168.x.x:3000
  static const String baseUrl =
      String.fromEnvironment('GATEWAY_URL', defaultValue: 'http://localhost:3000');

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw GatewayException('You are not signed in.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final uri = Uri.parse('$baseUrl$path');

    http.Response response;
    try {
      response = method == 'POST'
          ? await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 30))
          : await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw GatewayException('Cannot reach the blockchain gateway. Check your connection and try again.');
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Gateway error (${response.statusCode})';
      throw GatewayException(message);
    }
    return decoded;
  }

  /// Authenticity check read from the ledger: exists, status, product, expiry, holder.
  Future<Map<String, dynamic>> verifyBatch(String batchCode) async {
    final result = await _request('GET', '/verify/${Uri.encodeComponent(batchCode)}');
    return Map<String, dynamic>.from(result as Map);
  }

  /// Every recorded custody event for a batch, oldest first.
  Future<List<Map<String, dynamic>>> batchHistory(String batchCode) async {
    final result = await _request('GET', '/batches/${Uri.encodeComponent(batchCode)}/history');
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Staff of the current holder hand the batch to another verified organisation.
  Future<Map<String, dynamic>> initiateTransfer(String batchCode, String toOrgId) async {
    final result = await _request('POST', '/batches/${Uri.encodeComponent(batchCode)}/transfer',
        body: {'toOrgId': toOrgId});
    return Map<String, dynamic>.from(result as Map);
  }

  /// Staff of the receiving organisation confirm they have the batch.
  Future<Map<String, dynamic>> confirmReceipt(String batchCode) async {
    final result = await _request('POST', '/batches/${Uri.encodeComponent(batchCode)}/receive');
    return Map<String, dynamic>.from(result as Map);
  }
}