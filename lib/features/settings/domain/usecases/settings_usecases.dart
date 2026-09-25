import '../../../../domain/models/store_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettingUseCase {
  const GetSettingUseCase(this._repository);

  final SettingsRepository _repository;

  Future<String?> call(String key) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Cannot be empty');
    }
    return _repository.getSetting(normalizedKey);
  }
}

class SetSettingUseCase {
  const SetSettingUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call({required String key, required String value}) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Cannot be empty');
    }
    return _repository.setSetting(normalizedKey, value);
  }
}

class GetSettingsUseCase {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<StoreSettings> call() => _repository.getSettings();
}

class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(StoreSettings settings) async {
    if (settings.storeName.trim().isEmpty) {
      throw ArgumentError.value(
        settings.storeName,
        'storeName',
        'Cannot be empty',
      );
    }
    if (settings.currency.trim().isEmpty) {
      throw ArgumentError.value(
        settings.currency,
        'currency',
        'Cannot be empty',
      );
    }
    if (!settings.fontScale.isFinite || settings.fontScale <= 0) {
      throw ArgumentError.value(
        settings.fontScale,
        'fontScale',
        'Must be positive',
      );
    }
    if (!settings.taxRate.isFinite || settings.taxRate < 0) {
      throw ArgumentError.value(
        settings.taxRate,
        'taxRate',
        'Cannot be negative',
      );
    }
    await _repository.saveSettings(
      settings.copyWith(
        storeName: settings.storeName.trim(),
        phone: settings.phone.trim(),
        currency: settings.currency.trim(),
      ),
    );
  }
}
