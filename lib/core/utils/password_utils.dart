import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// أدوات تشفير كلمة السر باستخدام PBKDF2-HMAC-SHA256 مع ملح (salt)
/// عشوائي لكل أدمن، مع توافق مع النسخ القديمة المخزّنة بصيغة SHA-256.
///
/// الرمز المخزّن الجديد بالشكل:
/// `pbkdf2_sha256$<iterations>$<salt-base64url>$<key-base64url>`
/// والقديم بالشكل `salt$sha256Hash` (يُتحقق منه وتُرحَّل كلماته تلقائيًا).
class PasswordUtils {
  PasswordUtils._();

  static final Random _random = Random.secure();

  /// عدد تكرارات PBKDF2 (موصى به 100k فأكثر).
  static const int iterations = 100000;

  /// طول المفتاح المشتق بالبايت (256 بت).
  static const int keyLength = 32;

  static const String _algorithmPrefix = 'pbkdf2_sha256';

  /// يبني رمزًا مخزّنًا بالصيغة الجديدة PBKDF2.
  static String hash(String password) {
    final salt = _generateSalt();
    final key = _pbkdf2(password, salt, iterations);
    return '$_algorithmPrefix\$$iterations\$${_encode(salt)}\$${_encode(key)}';
  }

  /// يتحقق من صحة كلمة السر مقابل الرمز المخزّن (قديم أو جديد).
  static bool verify(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length == 4 && parts[0] == _algorithmPrefix) {
      final storedIterations = int.tryParse(parts[1]);
      if (storedIterations == null || storedIterations < 1) return false;
      final salt = _decode(parts[2]);
      final expected = _decode(parts[3]);
      if (salt.isEmpty || expected.isEmpty) return false;
      final actual = _pbkdf2(password, salt, storedIterations);
      return _constantTimeEquals(actual, expected);
    }
    // الصيغة القديمة: salt$sha256(salt:password)
    if (parts.length != 2) return false;
    final bytes = utf8.encode('${parts[0]}:$password');
    return _constantTimeStringEquals(
      sha256.convert(bytes).toString(),
      parts[1],
    );
  }

  /// هل الرمز المخزّن قديم (SHA-256) أو بتكرارات أقل من الموصى بها؟
  /// عند true يُنصح بإعادة تشفير كلمة السر عند تسجيل الدخول.
  static bool needsRehash(String stored) {
    final parts = stored.split('\$');
    if (parts.length == 4 && parts[0] == _algorithmPrefix) {
      final storedIterations = int.tryParse(parts[1]);
      return storedIterations == null || storedIterations < iterations;
    }
    return true;
  }

  static List<int> _generateSalt() =>
      List<int>.generate(16, (_) => _random.nextInt(256));

  /// تنفيذ PBKDF2-HMAC-SHA256 وفق RFC 2898.
  static List<int> _pbkdf2(
    String password,
    List<int> salt,
    int iterations,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (keyLength + 31) ~/ 32;
    final derived = <int>[];
    for (var block = 1; block <= blockCount; block++) {
      final blockIndex = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      var t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derived.addAll(t);
    }
    return derived.sublist(0, keyLength);
  }

  static String _encode(List<int> bytes) => base64Url.encode(bytes);

  static List<int> _decode(String value) {
    try {
      return base64Url.decode(value);
    } on FormatException {
      return const [];
    }
  }

  /// مقارنة ثابتة الزمن لمنع هجمات التوقيت.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static bool _constantTimeStringEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
