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

### android build_all_flavors

```sh
[bundle exec] fastlane android build_all_flavors
```

Build release APKs for all flavors (development and production)

### android distribute_apk

```sh
[bundle exec] fastlane android distribute_apk
```

Distribute APK using Firebase App Distribution

### android deploy_apk

```sh
[bundle exec] fastlane android deploy_apk
```

Build and distribute release APK for a specific flavor

### android deploy_all_flavors

```sh
[bundle exec] fastlane android deploy_all_flavors
```

Build and distribute APKs for all flavors

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
