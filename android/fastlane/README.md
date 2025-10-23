fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_release

```sh
[bundle exec] fastlane android build_release
```

Build release APK for a specific flavor

**Options:**
- `flavor`: Specify the flavor to build (development or production). Default: production

**Examples:**
```sh
# Build production flavor (default)
fastlane android build_release

# Build development flavor
fastlane android build_release flavor:development

# Build production flavor explicitly
fastlane android build_release flavor:production
```

### android build_all_flavors

```sh
[bundle exec] fastlane android build_all_flavors
```

Build release APKs for all flavors (development and production)

This lane builds APKs for both flavors:
- Development: `build/app/outputs/flutter-apk/app-development-release.apk`
- Production: `build/app/outputs/flutter-apk/app-production-release.apk`

### android distribute_apk

```sh
[bundle exec] fastlane android distribute_apk
```

Distribute APK using Firebase App Distribution

**Options:**
- `flavor`: Specify the flavor to distribute (development or production). Default: production

**Examples:**
```sh
# Distribute production flavor (default)
fastlane android distribute_apk

# Distribute development flavor
fastlane android distribute_apk flavor:development
```

### android deploy_apk

```sh
[bundle exec] fastlane android deploy_apk
```

Build and distribute release APK for a specific flavor

**Options:**
- `flavor`: Specify the flavor to deploy (development or production). Default: production

### android deploy_all_flavors

```sh
[bundle exec] fastlane android deploy_all_flavors
```

Build and distribute APKs for all flavors

----

## Product Flavors

The project supports two product flavors:

1. **Development** (`development`):
   - Application ID: `e_challan.sublimeai.app.dev`
   - Version suffix: `-dev`
   - Used for internal testing and development builds

2. **Production** (`production`):
   - Application ID: `e_challan.sublimeai.app`
   - Used for release builds to end users

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
