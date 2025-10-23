# Quick Start: Building with Flavors

## Overview

This app now supports different ICICI payment apps based on the build flavor:
- **Development**: Uses Verifone (`com.icici.viz.verifone`)
- **Production**: Uses PAX (`com.icici.viz.pax`)

## Building the App

### Development Build
```bash
# Debug
flutter run --flavor development

# Release APK
flutter build apk --flavor development --release

# Release App Bundle
flutter build appbundle --flavor development --release
```

### Production Build
```bash
# Debug
flutter run --flavor production

# Release APK
flutter build apk --flavor production --release

# Release App Bundle
flutter build appbundle --flavor production --release
```

## App IDs
- **Development**: `e_challan.sublimeai.app.dev`
- **Production**: `e_challan.sublimeai.app`

Both can be installed side-by-side for testing.

## Required ICICI Apps

Ensure the correct payment app is installed:
- **Development**: Install ICICI Verifone app (`com.icici.viz.verifone`)
- **Production**: Install ICICI PAX app (`com.icici.viz.pax`)

## Verification

Check which payment app will be used:
```bash
# Run the app and check logs
adb logcat | grep -E "(PaymentConfig|VizpayFlutter)"

# Expected output:
# PaymentConfig: Successfully initialized with package: com.icici.viz.verifone
# or
# PaymentConfig: Successfully initialized with package: com.icici.viz.pax
```

## Troubleshooting

### Wrong payment app is used
1. Verify the correct flavor was specified in the build command
2. Clean and rebuild: `flutter clean && flutter build apk --flavor <flavor>`
3. Check logs for the package name being used

### APP_NOT_INSTALLED error
1. Check if the required ICICI app is installed:
   ```bash
   adb shell pm list packages | grep icici
   ```
2. Install the correct payment app for your flavor

### Build errors
1. Ensure Flutter SDK is properly configured
2. Run: `flutter clean && flutter pub get`
3. Rebuild with the appropriate flavor

## Documentation

For detailed information, see:
- `IMPLEMENTATION_SUMMARY.md` - Complete overview of changes
- `PAYMENT_APP_CONFIGURATION.md` - Architecture and technical details
- `packages/vizpay_flutter/README.md` - Plugin documentation

## Testing

To test both flavors:
```bash
# Build and install both
flutter build apk --flavor development --release
adb install build/app/outputs/flutter-apk/app-development-release.apk

flutter build apk --flavor production --release
adb install build/app/outputs/flutter-apk/app-production-release.apk

# Both apps will be installed with different IDs
```

## Key Files Modified

1. `android/app/build.gradle.kts` - Flavor configuration
2. `lib/main.dart` - Payment config initialization
3. `lib/utils/payment_config.dart` - Configuration utility
4. `android/app/src/main/kotlin/.../MainActivity.kt` - Method channel
5. `packages/vizpay_flutter/*` - Plugin updates

For the complete list of changes, see `IMPLEMENTATION_SUMMARY.md`.
