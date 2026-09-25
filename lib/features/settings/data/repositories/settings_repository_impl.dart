import '../../../../domain/models/store_settings.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<String?> getSetting(String key) => _storeRepository.getSetting(key);

  @override
  Future<void> setSetting(String key, String value) =>
      _storeRepository.setSetting(key, value);

  @override
  Future<StoreSettings> getSettings() => _storeRepository.getSettings();

  @override
  Future<void> saveSettings(StoreSettings settings) =>
      _storeRepository.saveSettings(settings);
}
