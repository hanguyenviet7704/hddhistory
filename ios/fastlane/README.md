# iOS Fastlane Guide (New Joiner)

This iOS Fastlane setup mirrors Android lane intent:
- test
- build
- beta distribution
- deploy + deploy aliases

Fastlane docs used for this setup:
- `upload_to_app_store`: https://docs.fastlane.tools/actions/upload_to_app_store/
- `upload_to_testflight`: https://docs.fastlane.tools/actions/upload_to_testflight/
- `app_store_connect_api_key`: https://docs.fastlane.tools/actions/app_store_connect_api_key/
- `deliver`: https://docs.fastlane.tools/actions/appstore/

## 1) First-time setup

From repo root:

```sh
cd ios
bundle install
bundle exec fastlane --version
```

If `bundle` points to system Ruby and fails, run with Homebrew Ruby:

```sh
/opt/homebrew/opt/ruby/bin/bundle install
/opt/homebrew/opt/ruby/bin/bundle exec fastlane --version
```

## 2) Prerequisites

- macOS + Xcode installed.
- Flutter + FVM installed.
- CocoaPods installed (`pod install` in `ios/` when needed).
- App Store Connect API key configured in `.info/app/app.json`.
- App Store Connect team configured in `ios/fastlane/Appfile` (`itc_team_id`).
- Firebase CLI logged in (for Firebase distribution).

## 3) Lane commands

Run all commands from `ios/`.

### Test

```sh
bundle exec fastlane test
```

### Build

```sh
bundle exec fastlane build_ios flavor:dev
bundle exec fastlane build_ios flavor:stg
bundle exec fastlane build_ios flavor:prod

bundle exec fastlane build_ipa flavor:dev
bundle exec fastlane build_ipa flavor:stg
bundle exec fastlane build_ipa flavor:prod
bundle exec fastlane build_ipa flavor:prod export_method:app-store
```

### Beta distribution

```sh
# Firebase App Distribution
bundle exec fastlane beta flavor:dev

# TestFlight
# Default flavor for beta_ipa is prod
bundle exec fastlane beta_ipa
bundle exec fastlane beta_ipa flavor:prod
bundle exec fastlane beta_ipa flavor:stg changelog:"Build notes"
bundle exec fastlane beta_ipa flavor:dev distribute_external:true groups:"qa-team"
```

When `distribute_external:true`, `groups` is required and `skip_waiting_for_build_processing` must be `false`.

### Deploy (Android-like API)

```sh
# Default: flavor=prod, track=internal -> method=testflight
bundle exec fastlane deploy

bundle exec fastlane deploy flavor:prod track:internal
bundle exec fastlane deploy flavor:stg track:alpha
bundle exec fastlane deploy flavor:prod track:beta
bundle exec fastlane deploy flavor:prod track:production
```

Direct method override:

```sh
bundle exec fastlane deploy flavor:prod method:firebase
bundle exec fastlane deploy flavor:prod method:testflight
bundle exec fastlane deploy flavor:prod method:both
bundle exec fastlane deploy flavor:prod method:appstore
```

App Store metadata/screenshot upload flags:

```sh
bundle exec fastlane deploy flavor:prod track:production upload_metadata:true
bundle exec fastlane deploy flavor:prod track:production upload_screenshots:true
bundle exec fastlane deploy flavor:prod track:production upload_all_metadata:true
```

Track mapping:
- `internal` -> `testflight`
- `alpha` -> `firebase`
- `beta` -> `both` (Firebase + TestFlight)
- `production` -> `appstore`

Alias lanes:

```sh
bundle exec fastlane deploy_alpha flavor:stg
bundle exec fastlane deploy_beta flavor:stg
bundle exec fastlane deploy_production flavor:prod
```

## 4) Metadata workflow (same idea as Android)

Android uses:

```text
android/fastlane/metadata/android/<locale>/
```

iOS equivalent is:

```text
ios/fastlane/metadata/<locale>/
```

Examples:
- `ios/fastlane/metadata/en-US/name.txt`
- `ios/fastlane/metadata/en-US/subtitle.txt`
- `ios/fastlane/metadata/en-US/description.txt`
- `ios/fastlane/metadata/en-US/release_notes.txt`

### Pull metadata from App Store Connect

```sh
cd ios

# Prod app metadata -> ios/fastlane/metadata
bundle exec fastlane deliver download_metadata --app_identifier com.eup.meup --metadata_path fastlane/metadata

# Optional: screenshots -> ios/fastlane/screenshots
bundle exec fastlane deliver download_screenshots --app_identifier com.eup.meup --screenshots_path fastlane/screenshots
```

For dev/stg apps (if they exist in App Store Connect), use custom folders:

```sh
bundle exec fastlane deliver download_metadata --app_identifier com.eup.meup.dev --metadata_path fastlane/metadata/dev
bundle exec fastlane deliver download_metadata --app_identifier com.eup.meup.stg --metadata_path fastlane/metadata/stg
```

### Push metadata only (no binary upload)

```sh
cd ios
bundle exec fastlane deliver --app_identifier com.eup.meup --metadata_path fastlane/metadata --skip_binary_upload true --skip_screenshots true
```

Push screenshots only:

```sh
bundle exec fastlane deliver --app_identifier com.eup.meup --screenshots_path fastlane/screenshots --skip_binary_upload true --skip_metadata true
```

### With deploy lane

`bundle exec fastlane deploy flavor:prod track:production upload_metadata:true` uses `upload_to_app_store` and uploads metadata from default Fastlane path (`ios/fastlane/metadata`) unless you override paths in Fastlane config.

## 5) Notes

- iOS build is delegated to `tools/macos/build/*`.
- `beta` uses `tools/macos/distribution/distribute_ios.sh` for Firebase.
- `beta_ipa` uses `upload_to_testflight`.
- `deploy` with `method:appstore` (or `track:production`) uses `upload_to_app_store`.
- `itc_provider` for uploads resolves in this order:
  1) `itc_team_id` in `ios/fastlane/Appfile`
  2) fallback: `.info/app/app.json` -> `ios.contentProviderId`
- Metadata flag mapping for App Store deploy: `upload_metadata` or `upload_all_metadata` enables metadata upload, and `upload_screenshots`/`upload_images`/`upload_all_metadata` enables screenshot upload.
- Running `bundle exec fastlane lanes` may regenerate this README automatically.
