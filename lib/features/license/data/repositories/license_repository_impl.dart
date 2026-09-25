import '../../../../domain/models/license.dart';
import '../../../../domain/repositories/license_repository.dart'
    as root_repository;
import '../../domain/repositories/license_repository.dart';

class LicenseRepositoryImpl implements LicenseRepository {
  const LicenseRepositoryImpl(this._repository);

  final root_repository.LicenseRepository _repository;

  @override
  Future<LicenseResult> activateOrVerify({
    required String licenseKey,
    required String deviceId,
  }) =>
      _repository.activateOrVerify(licenseKey: licenseKey, deviceId: deviceId);

  @override
  Future<LicenseResult> checkStoredActivation(String deviceId) =>
      _repository.checkStoredActivation(deviceId);

  @override
  Future<void> storeActivation(License license) =>
      _repository.storeActivation(license);

  @override
  Future<void> clearStoredActivation() => _repository.clearStoredActivation();
}
