# vizpay_flutter

A Flutter plugin for ICICI Vizpay payment integration.

## Overview

This plugin provides integration with ICICI payment apps for processing card and UPI transactions. It supports environment-specific payment app configurations based on Android build flavors.

## Features

- **SALE Transaction**: Process card payment transactions
- **UPI Transaction**: Process UPI QR code transactions
- **Multi-Environment Support**: Automatically switches between payment apps based on build flavor
  - Development: Uses `com.icici.viz.verifone` (Verifone payment app)
  - Production: Uses `com.icici.viz.pax` (PAX payment app)

## Setup

### 1. Configure Android Flavors

The main app should define product flavors in `android/app/build.gradle.kts`:

```kotlin
android {
    // Enable BuildConfig generation
    buildFeatures {
        buildConfig = true
    }
    
    // Define flavor dimensions and flavors
    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            buildConfigField("String", "PAYMENT_APP_PACKAGE", "\"com.icici.viz.verifone\"")
        }
        create("production") {
            dimension = "environment"
            buildConfigField("String", "PAYMENT_APP_PACKAGE", "\"com.icici.viz.pax\"")
        }
    }
}
```

### 2. Initialize Payment Configuration

In your app's `main.dart`, initialize the payment configuration:

```dart
import 'package:municipal_e_challan/utils/payment_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize payment configuration based on build flavor
  await PaymentConfig.initialize();
  
  runApp(const MyApp());
}
```

### 3. Expose BuildConfig via Method Channel

In your `MainActivity.kt`, add a method channel to expose the payment app package:

```kotlin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "payment_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPaymentAppPackage" -> {
                        result.success(BuildConfig.PAYMENT_APP_PACKAGE)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

## Usage

### Starting a SALE Transaction

```dart
import 'package:vizpay_flutter/vizpay_flutter.dart';

// Initiate a card payment transaction
final result = await VizpayFlutter.startSaleTransaction(
  amount: "500.00",
  billNumber: "BILL123456",
  sourceId: "MERCHANT_ID",
  tipAmount: "50.00",  // Optional
  printFlag: true,     // Optional, default: true
);

// Handle the response
if (result != null) {
  final statusCode = result['STATUS_CODE'];
  final statusMsg = result['STATUS_MSG'];
  final receiptData = result['RECEIPT_DATA'];
  
  if (statusCode == '00') {
    print('Payment successful!');
  } else {
    print('Payment failed: $statusMsg');
  }
}
```

### Starting a UPI Transaction

```dart
// Initiate a UPI QR code transaction
final result = await VizpayFlutter.startUpiTransaction(
  amount: "500.00",
  billNumber: "BILL123456",
  sourceId: "MERCHANT_ID",
  printFlag: true,
);

// Handle the response (same as SALE transaction)
```

## Building for Different Environments

### Development Build

```bash
# Build development APK
flutter build apk --flavor development

# Run development build
flutter run --flavor development
```

### Production Build

```bash
# Build production APK
flutter build apk --flavor production

# Run production build
flutter run --flavor production
```

## Payment App Requirements

Ensure the appropriate ICICI payment app is installed on the device:

- **Development**: `com.icici.viz.verifone` (Verifone app)
- **Production**: `com.icici.viz.pax` (PAX app)

If the required app is not installed, the plugin will return an `APP_NOT_INSTALLED` error.

## Response Format

Both transaction types return a map with the following structure:

```dart
{
  "RESPONSE_TYPE": "SALE" or "QR",
  "STATUS_CODE": "00",  // "00" indicates success
  "STATUS_MSG": "Approved",
  "RECEIPT_DATA": "{...}"  // JSON string with transaction details
}
```

## Error Handling

The plugin may return the following error codes:

- `NO_ACTIVITY`: Plugin not attached to an activity
- `APP_NOT_INSTALLED`: Required ICICI payment app not installed
- `SALE_ERROR`: Error during SALE transaction
- `QR_ERROR`: Error during UPI transaction
- `RESPONSE_ERROR`: Error parsing payment response

## Technical Details

### Architecture

The plugin uses a dynamic configuration approach:

1. **Build Time**: Android flavors define the payment app package in `BuildConfig`
2. **Runtime Initialization**: `PaymentConfig.initialize()` retrieves the package name via method channel
3. **Transaction Time**: The plugin uses the configured package name to launch the payment app

### Method Channels

- **payment_config**: Exposes BuildConfig values to Flutter
  - `getPaymentAppPackage`: Returns the payment app package name for current flavor

- **vizpay_flutter**: Handles payment transactions
  - `setPaymentAppPackage`: Sets the payment app package to use
  - `startSaleTransaction`: Initiates a card payment
  - `startUpiTransaction`: Initiates a UPI payment

## Troubleshooting

### Payment app not launching

1. Verify the correct payment app is installed:
   ```bash
   adb shell pm list packages | grep icici
   ```

2. Check the logs for the package being used:
   ```bash
   adb logcat | grep VizpayFlutter
   ```

3. Ensure `PaymentConfig.initialize()` is called before any transactions

### Build errors

1. Ensure flavors are correctly defined in `build.gradle.kts`
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Verify BuildConfig is generated: Check `app/build/generated/source/buildConfig/`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
