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

### android test

```sh
[bundle exec] fastlane android test
```

Runs all the tests

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build APK for specified flavor

### android build_bundle

```sh
[bundle exec] fastlane android build_bundle
```

Build App Bundle for specified flavor

### android beta

```sh
[bundle exec] fastlane android beta
```

Submit a new Beta Build to Firebase App Distribution

### android beta_bundle

```sh
[bundle exec] fastlane android beta_bundle
```

Submit a new Beta Build using App Bundle to Firebase App Distribution

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy a new version to the Google Play Store

### android deploy_alpha

```sh
[bundle exec] fastlane android deploy_alpha
```

Deploy to Play Store Alpha track

### android deploy_beta

```sh
[bundle exec] fastlane android deploy_beta
```

Deploy to Play Store Beta track

### android deploy_production

```sh
[bundle exec] fastlane android deploy_production
```

Deploy to Play Store Production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
