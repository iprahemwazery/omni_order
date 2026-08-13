import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// أدوات تشفير كلمة السر باستخدام SHA-256 مع ملح (salt) عشوائي لكل أدمن.
class PasswordUtils {
  PasswordUtils._();

  static final Random _random = Random.secure();

  /// يبني رمزًا مخزّنًا بالشكل `salt$hash`.
  static String hash(String password) {
    final salt = _generateSalt();
    return '$salt\$${_digest(salt, password)}';
  }

  /// يتحقق من صحة كلمة السر مقابل الرمز المخزّن.
  static bool verify(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length != 2) return false;
    return _digest(parts[0], password) == parts[1];
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _digest(String salt, String password) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
