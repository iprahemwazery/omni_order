import '../../../../domain/models/license.dart';

abstract interface class LicenseRepository {
  Future<LicenseResult> activateOrVerify({
    required String licenseKey,
    required String deviceId,
  });

  Future<LicenseResult> checkStoredActivation(String deviceId);

  Future<void> storeActivation(License license);

  Future<void> clearStoredActivation();
}
