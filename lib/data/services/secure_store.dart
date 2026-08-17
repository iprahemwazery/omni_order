import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// واجهة تخزين آمن (Key-Value) — يسمح بتبديل التطبيق التنفيذي
/// (flutter_secure_storage) بواجهة ذاكرة في الاختبارات.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// تطبيق فعلي يعتمد flutter_secure_storage (Android Keystore / iOS Keychain).
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
