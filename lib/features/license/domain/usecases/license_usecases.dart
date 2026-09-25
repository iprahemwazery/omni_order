import '../../../../domain/models/license.dart';
import '../repositories/license_repository.dart';

class ActivateLicenseUseCase {
  const ActivateLicenseUseCase(this._repository);

  final LicenseRepository _repository;

  Future<LicenseResult> call({
    required String licenseKey,
    required String deviceId,
  }) async {
    final key = licenseKey.trim();
    final device = deviceId.trim();
    if (key.isEmpty) {
      return LicenseResult.failure(
        LicenseResultStatus.error,
        'مفتاح الترخيص مطلوب.',
      );
    }
    if (device.isEmpty) {
      return LicenseResult.failure(
        LicenseResultStatus.error,
        'معرف الجهاز مطلوب.',
      );
    }
    return _repository.activateOrVerify(licenseKey: key, deviceId: device);
  }
}

class CheckStoredLicenseUseCase {
  const CheckStoredLicenseUseCase(this._repository);

  final LicenseRepository _repository;

  Future<LicenseResult> call(String deviceId) {
    final device = deviceId.trim();
    if (device.isEmpty) {
      return Future.value(
        LicenseResult.failure(LicenseResultStatus.error, 'معرف الجهاز مطلوب.'),
      );
    }
    return _repository.checkStoredActivation(device);
  }
}

class StoreLicenseActivationUseCase {
  const StoreLicenseActivationUseCase(this._repository);

  final LicenseRepository _repository;

  Future<void> call(License license) {
    if (license.licenseKey.trim().isEmpty) {
      throw ArgumentError('مفتاح الترخيص مطلوب.');
    }
    if (license.deviceId.trim().isEmpty) {
      throw ArgumentError('معرف الجهاز مطلوب.');
    }
    return _repository.storeActivation(license);
  }
}

class ClearLicenseActivationUseCase {
  const ClearLicenseActivationUseCase(this._repository);

  final LicenseRepository _repository;

  Future<void> call() => _repository.clearStoredActivation();
}
