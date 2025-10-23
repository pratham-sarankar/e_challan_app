package e_challan.sublimeai.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity for the e_challan app.
 * 
 * This activity provides a method channel to expose the payment app package name
 * from BuildConfig to the Flutter/Dart side, allowing the app to dynamically
 * configure the correct ICICI payment app based on the build flavor.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "payment_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPaymentAppPackage" -> {
                    // Return the payment app package name from BuildConfig
                    // This is set based on the build flavor:
                    // - development: com.icici.viz.verifone
                    // - production: com.icici.viz.pax
                    try {
                        val packageName = BuildConfig.PAYMENT_APP_PACKAGE
                        result.success(packageName)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get payment app package: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
