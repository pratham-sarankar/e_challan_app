import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vizpay_flutter/vizpay_flutter.dart';

/// Payment configuration utility for initializing the correct ICICI payment app
/// based on the build flavor.
///
/// This class handles the automatic detection of the build flavor and configures
/// the VizpayFlutter plugin to use the appropriate payment app:
/// - Development flavor: com.icici.viz.verifone
/// - Production flavor: com.icici.viz.pax
class PaymentConfig {
  static const MethodChannel _channel = MethodChannel('payment_config');

  /// Initializes the payment configuration by detecting the current build flavor
  /// and setting the appropriate payment app package in the VizpayFlutter plugin.
  ///
  /// This should be called once during app initialization, preferably in main().
  ///
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    try {
      // Get the payment app package name from native side (BuildConfig)
      final String? packageName = await _channel.invokeMethod(
        'getPaymentAppPackage',
      );

      if (packageName != null && packageName.isNotEmpty) {
        // Set the package name in VizpayFlutter plugin
        final success = await VizpayFlutter.setPaymentAppPackage(packageName);

        if (success) {
          if (kDebugMode) {
            print(
              'PaymentConfig: Successfully initialized with package: $packageName',
            );
          }
        } else {
          if (kDebugMode) {
            print('PaymentConfig: Failed to set payment app package');
          }
        }

        return success;
      } else {
        // Fallback to default (development/verifone) if not available
        if (kDebugMode) {
          print('PaymentConfig: No package name from native, using default');
        }
        return await VizpayFlutter.setPaymentAppPackage(
          'com.icici.viz.verifone',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('PaymentConfig: Error initializing payment config: $e');
      }
      // Fallback to default (development/verifone) on error
      return await VizpayFlutter.setPaymentAppPackage('com.icici.viz.verifone');
    }
  }
}
