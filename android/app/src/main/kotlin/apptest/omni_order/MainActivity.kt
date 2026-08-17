package apptest.omni_order

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDeviceId") {
                    // ANDROID_ID: معرف مستقر لكل (تثبيت × حساب × توقيع) على الجهاز.
                    val id = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID,
                    )
                    if (id.isNullOrEmpty()) {
                        result.error("UNAVAILABLE", "ANDROID_ID unavailable", null)
                    } else {
                        result.success(id)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "omni_order/device_id"
    }
}
