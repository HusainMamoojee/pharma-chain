import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Minimal RFC 6238 TOTP implementation (same algorithm Google
/// Authenticator, Authy, etc. use).
class Totp {
  static List<int> _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = input.toUpperCase().replaceAll('=', '');
    int bits = 0, value = 0;
    final output = <int>[];
    for (final char in clean.split('')) {
      final idx = alphabet.indexOf(char);
      if (idx == -1) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        output.add((value >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }
    return output;
  }

  static String generate(String secret, {int period = 30, int digits = 6, DateTime? time}) {
    final t = (time ?? DateTime.now().toUtc());
    final counter = t.millisecondsSinceEpoch ~/ 1000 ~/ period;

    final key = _base32Decode(secret);
    final counterBytes = ByteData(8)..setInt64(0, counter, Endian.big);
    final digest = Hmac(sha1, key).convert(counterBytes.buffer.asUint8List()).bytes;

    final offset = digest[digest.length - 1] & 0x0f;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  static bool verify(String secret, String code, {int period = 30, int digits = 6, int windowSteps = 2}) {
    final now = DateTime.now().toUtc();
    for (int i = -windowSteps; i <= windowSteps; i++) {
      final t = now.add(Duration(seconds: i * period));
      if (generate(secret, period: period, digits: digits, time: t) == code) return true;
    }
    return false;
  }
}