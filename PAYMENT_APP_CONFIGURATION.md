# ICICI Payment App Configuration Guide

## Overview

This document explains how the e_challan app dynamically switches between different ICICI payment apps based on the build environment.

## Problem Statement

The app needs to use different ICICI payment applications depending on the environment:
- **Development Environment**: Uses Verifone payment app (`com.icici.viz.verifone`)
- **Production Environment**: Uses PAX payment app (`com.icici.viz.pax`)

## Solution Architecture

The solution uses Android product flavors combined with dynamic runtime configuration:

```
┌─────────────────────────────────────────────────────────────┐
│                        Build Time                            │
├─────────────────────────────────────────────────────────────┤
│  1. Android Gradle defines flavors (development/production)  │
│  2. BuildConfig.PAYMENT_APP_PACKAGE is set per flavor       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Runtime Initialization                     │
├─────────────────────────────────────────────────────────────┤
│  1. MainActivity exposes BuildConfig via method channel     │
│  2. PaymentConfig.initialize() retrieves package name       │
│  3. VizpayFlutter.setPaymentAppPackage() configures plugin  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     Transaction Time                         │
├─────────────────────────────────────────────────────────────┤
│  1. User initiates payment transaction                       │
│  2. VizpayFlutter plugin uses configured package name       │
│  3. Correct ICICI payment app is launched                    │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Details

### 1. Android Build Configuration (`android/app/build.gradle.kts`)

```kotlin
android {
    // Enable BuildConfig for accessing flavor-specific values
    buildFeatures {
        buildConfig = true
    }

    // Define product flavors
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

**Key Points:**
- Two flavors are defined: `development` and `production`
- Each flavor has a unique `PAYMENT_APP_PACKAGE` value
- Development build has `.dev` suffix to allow side-by-side installation
- BuildConfig feature must be enabled to generate the BuildConfig class

### 2. Method Channel Bridge (`MainActivity.kt`)

```kotlin
class MainActivity : FlutterActivity() {
    private val CHANNEL = "payment_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPaymentAppPackage" -> {
                        // Expose BuildConfig value to Flutter
                        result.success(BuildConfig.PAYMENT_APP_PACKAGE)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

**Key Points:**
- Creates a method channel named `payment_config`
- Exposes `BuildConfig.PAYMENT_APP_PACKAGE` to Flutter/Dart code
- This bridges the gap between Android build configuration and Flutter runtime

### 3. Flutter Configuration Utility (`lib/utils/payment_config.dart`)

```dart
class PaymentConfig {
  static const MethodChannel _channel = MethodChannel('payment_config');
  
  static Future<bool> initialize() async {
    try {
      // Get package name from native side
      final String? packageName = await _channel.invokeMethod('getPaymentAppPackage');
      
      if (packageName != null && packageName.isNotEmpty) {
        // Configure VizpayFlutter plugin
        return await VizpayFlutter.setPaymentAppPackage(packageName);
      }
      
      // Fallback to default
      return await VizpayFlutter.setPaymentAppPackage('com.icici.viz.verifone');
    } catch (e) {
      // Error handling with fallback
      return await VizpayFlutter.setPaymentAppPackage('com.icici.viz.verifone');
    }
  }
}
```

**Key Points:**
- Retrieves package name from MainActivity via method channel
- Configures the VizpayFlutter plugin with the correct package
- Has fallback to development/verifone package for safety
- Should be called once during app initialization

### 4. Vizpay Plugin Updates (`packages/vizpay_flutter`)

**Dart Side (`lib/vizpay_flutter.dart`):**
```dart
class VizpayFlutter {
  static Future<bool> setPaymentAppPackage(String packageName) async {
    try {
      final result = await _channel.invokeMethod('setPaymentAppPackage', packageName);
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
```

**Android Side (`VizpayFlutterPlugin.kt`):**
```kotlin
class VizpayFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    // Dynamic package name (default: verifone for backward compatibility)
    private var paymentAppPackageName: String = "com.icici.viz.verifone"
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setPaymentAppPackage" -> {
                val packageName = call.arguments as? String
                if (packageName != null && packageName.isNotEmpty()) {
                    paymentAppPackageName = packageName
                    result.success(true)
                }
            }
            // ... other methods
        }
    }
    
    // Use paymentAppPackageName when launching payment app
    private fun startSale(args: Map<*, *>) {
        val intent = activity!!.packageManager.getLaunchIntentForPackage(paymentAppPackageName)
        // ...
    }
}
```

**Key Points:**
- Plugin accepts dynamic package name configuration
- Default is verifone for backward compatibility
- Logs the package being used for debugging
- All payment transactions use the configured package

### 5. App Initialization (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize payment configuration
  await PaymentConfig.initialize();
  
  runApp(const MyApp());
}
```

**Key Points:**
- `WidgetsFlutterBinding.ensureInitialized()` ensures platform channels are ready
- Payment configuration happens before app starts
- Configuration is done once at startup

## Building the App

### Development Build

```bash
# Debug build
flutter run --flavor development --debug

# Release build
flutter build apk --flavor development --release

# App ID: e_challan.sublimeai.app.dev
# Payment App: com.icici.viz.verifone (Verifone)
```

### Production Build

```bash
# Debug build
flutter run --flavor production --debug

# Release build
flutter build apk --flavor production --release

# App ID: e_challan.sublimeai.app
# Payment App: com.icici.viz.pax (PAX)
```

## Testing

### 1. Verify Flavor Configuration

Check which package is being used:

```bash
# View logs during app startup
adb logcat | grep -E "(PaymentConfig|VizpayFlutter)"

# Expected output for development:
# PaymentConfig: Successfully initialized with package: com.icici.viz.verifone
# VizpayFlutter: Payment app package set to: com.icici.viz.verifone

# Expected output for production:
# PaymentConfig: Successfully initialized with package: com.icici.viz.pax
# VizpayFlutter: Payment app package set to: com.icici.viz.pax
```

### 2. Verify Payment App is Installed

```bash
# List installed ICICI apps
adb shell pm list packages | grep icici

# Check for specific package
adb shell pm list packages | grep com.icici.viz.verifone  # Development
adb shell pm list packages | grep com.icici.viz.pax       # Production
```

### 3. Test Payment Flow

1. Install the appropriate payment app
2. Build and run the app with the correct flavor
3. Initiate a payment transaction
4. Verify the correct payment app launches
5. Check logs for any errors

### 4. Side-by-Side Testing

Both flavors can be installed simultaneously:
- Development: `e_challan.sublimeai.app.dev`
- Production: `e_challan.sublimeai.app`

```bash
# Install both
flutter build apk --flavor development --release
adb install build/app/outputs/flutter-apk/app-development-release.apk

flutter build apk --flavor production --release
adb install build/app/outputs/flutter-apk/app-production-release.apk
```

## Troubleshooting

### Issue: Wrong payment app is being used

**Solution:**
1. Check which flavor was used for the build
2. Verify BuildConfig is generated correctly
3. Check logs for the package name being set

### Issue: APP_NOT_INSTALLED error

**Solution:**
1. Verify the correct ICICI payment app is installed
2. Check package name in logs matches the installed app
3. Ensure app has permission to query other packages (Android 11+)

### Issue: BuildConfig.PAYMENT_APP_PACKAGE not found

**Solution:**
1. Verify `buildFeatures { buildConfig = true }` is set
2. Clean and rebuild: `flutter clean && flutter build apk`
3. Check `app/build/generated/source/buildConfig/` for generated files

### Issue: Method channel not working

**Solution:**
1. Ensure `WidgetsFlutterBinding.ensureInitialized()` is called
2. Check MainActivity is properly configured
3. Verify method channel names match: "payment_config"

## Security Considerations

1. **Package Name Validation**: The plugin validates package names before use
2. **Error Fallback**: If configuration fails, defaults to development package
3. **App Verification**: Android verifies the payment app's signature before launching

## Maintenance Notes

### Adding a New Environment

To add a new environment (e.g., staging):

1. **Update `build.gradle.kts`:**
```kotlin
create("staging") {
    dimension = "environment"
    applicationIdSuffix = ".staging"
    versionNameSuffix = "-staging"
    buildConfigField("String", "PAYMENT_APP_PACKAGE", "\"com.icici.viz.staging\"")
}
```

2. **Build the app:**
```bash
flutter build apk --flavor staging
```

### Changing Payment App Packages

If ICICI provides new payment app packages:

1. Update the `buildConfigField` in `build.gradle.kts`
2. No code changes needed - configuration is dynamic
3. Rebuild and test

## Related Files

- `android/app/build.gradle.kts` - Flavor configuration
- `android/app/src/main/kotlin/.../MainActivity.kt` - Method channel bridge
- `lib/utils/payment_config.dart` - Flutter configuration utility
- `lib/main.dart` - App initialization
- `packages/vizpay_flutter/lib/vizpay_flutter.dart` - Plugin Dart API
- `packages/vizpay_flutter/android/src/main/kotlin/.../VizpayFlutterPlugin.kt` - Plugin Android implementation
- `packages/vizpay_flutter/README.md` - Plugin documentation

## References

- [Android Product Flavors](https://developer.android.com/studio/build/build-variants)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [BuildConfig in Android](https://developer.android.com/reference/android/BuildConfig)
