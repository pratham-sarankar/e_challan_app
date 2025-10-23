# municipal_e_challan

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Build Flavors

The Android app is configured with two product flavors to support different environments:

### Development Flavor
- **Application ID**: `e_challan.sublimeai.app.dev`
- **Version Suffix**: `-dev`
- **Purpose**: Used for development and testing with environment-specific configurations

**Build commands:**
```bash
# Debug build
flutter build apk --flavor development --debug

# Release build
flutter build apk --flavor development --release
```

### Production Flavor
- **Application ID**: `e_challan.sublimeai.app`
- **Purpose**: Used for production releases

**Build commands:**
```bash
# Debug build
flutter build apk --flavor production --debug

# Release build
flutter build apk --flavor production --release
```

### Flavor Configuration

The flavors are configured in `android/app/build.gradle.kts`:
- **Flavor Dimension**: `environment`
- **Development**: Includes `.dev` suffix for application ID and version name
- **Production**: Uses the base application ID without modifications

These flavors enable environment-specific features such as different payment gateway configurations in the vizpay package.
