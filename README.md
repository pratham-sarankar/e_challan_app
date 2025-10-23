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

## Product Flavors

This project uses Android product flavors to support different build variants:

### Available Flavors

1. **Development** (`development`)
   - Application ID: `e_challan.sublimeai.app.dev`
   - Version suffix: `-dev`
   - Purpose: Internal testing and development builds
   - APK Output: `app-development-release.apk`

2. **Production** (`production`)
   - Application ID: `e_challan.sublimeai.app`
   - Purpose: Production releases for end users
   - APK Output: `app-production-release.apk`

### Building APKs with Flavors

#### Using Flutter CLI
```bash
# Build development flavor
flutter build apk --release --flavor development

# Build production flavor
flutter build apk --release --flavor production
```

#### Using Fastlane
```bash
cd android

# Build a specific flavor
fastlane build_release flavor:development
fastlane build_release flavor:production

# Build all flavors at once
fastlane build_all_flavors
```

For more Fastlane commands and options, see [android/fastlane/README.md](android/fastlane/README.md).

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration and delivery.

### Workflow: Flutter Release Build

**Trigger:** Push tags starting with `v*` (e.g., `v1.0.0`, `v1.2.3`)

**What it does:**
1. Sets up Flutter and Ruby/Fastlane environment
2. Restores signing keys and service account credentials from GitHub Secrets
3. Builds APKs for **both** development and production flavors using `fastlane build_all_flavors`
4. Creates a GitHub Release with both APK files attached as artifacts

**Artifacts:**
- `app-development-release.apk` - Development build
- `app-production-release.apk` - Production build

### Triggering a Release

To trigger a new release build:

```bash
# Tag the commit
git tag v1.0.0

# Push the tag to GitHub
git push origin v1.0.0
```

The workflow will automatically:
- Build APKs for both flavors
- Attach them to the GitHub Release for the tag

### Required GitHub Secrets

The following secrets must be configured in the repository settings:

- `KEY_JKS_BASE64`: Base64-encoded Android signing keystore
- `KEY_PROPERTIES`: Base64-encoded key.properties file
- `SERVICE_ACCOUNT_KEY`: Base64-encoded Firebase service account key
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
