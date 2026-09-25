import '../../../../domain/models/store_settings.dart';

abstract interface class SettingsRepository {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<StoreSettings> getSettings();
  Future<void> saveSettings(StoreSettings settings);
}
