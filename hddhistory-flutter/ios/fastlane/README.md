fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Runs Flutter tests

### ios build_ios

```sh
[bundle exec] fastlane ios build_ios
```

Build iOS app for specified flavor

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build IPA for specified flavor

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Submit a new Beta Build to Firebase App Distribution

### ios beta_ipa

```sh
[bundle exec] fastlane ios beta_ipa
```

Submit a new Beta Build to TestFlight

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy a new version for iOS

### ios deploy_alpha

```sh
[bundle exec] fastlane ios deploy_alpha
```

Deploy to iOS Alpha equivalent (Firebase)

### ios deploy_beta

```sh
[bundle exec] fastlane ios deploy_beta
```

Deploy to iOS Beta equivalent (Firebase + TestFlight)

### ios deploy_production

```sh
[bundle exec] fastlane ios deploy_production
```

Deploy to iOS Production (App Store Connect)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
