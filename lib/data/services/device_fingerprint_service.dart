import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// استخراج بصمة الجهاز الفريدة (HWID) الموحدة عبر المنصات.
///
/// الأولوية:
/// 1. المعرّف الأصلي عبر MethodChannel (`omni_order/device_id`):
///    - Android: ANDROID_ID
///    - iOS: identifierForVendor
/// 2. معرّف احتياطي من بيانات الجهاز (سطح المكتب أو فشل القناة).
///
/// تُحسب البصمة عبر SHA-256 حتى لا يُخزَّن المعرّف الخام.
class DeviceFingerprintService {
  DeviceFingerprintService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('omni_order/device_id');

  final MethodChannel _channel;

  /// بصمة الجهاز الحالي (SHA-256 لمعرّف خام مستقر).
  Future<String> getDeviceFingerprint() async {
    // أولاً: المعرّف الأصلي المستقر (ANDROID_ID / identifierForVendor).
    // وهو الأدق لأنه ثابت عبر إعادة التثبيت ولا يتشابه بين الأجهزة المتطابقة.
    String? nativeId;
    try {
      nativeId = await _channel.invokeMethod<String>('getDeviceId');
    } catch (_) {
      nativeId = null;
    }

    final rawId = (nativeId != null && nativeId.isNotEmpty)
        ? nativeId
        : await _fallbackRawId();

    return sha256.convert(utf8.encode(rawId)).toString();
  }

  /// معرّف احتياطي من معلومات الجهاز عند غياب القناة الأصلية
  /// (أجهزة سطح المكتب، أو فشل القناة).
  Future<String> _fallbackRawId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isWindows) {
      final win = await deviceInfo.windowsInfo;
      return 'win:${win.deviceId}-${win.numberOfCores}-${win.systemMemoryInMegabytes}';
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return 'android:${android.fingerprint}-${android.device}-${android.model}';
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      return 'linux:${linux.machineId ?? linux.id}';
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      return 'mac:${mac.systemGUID ?? mac.modelName}';
    }
    return 'unknown:';
  }
}
