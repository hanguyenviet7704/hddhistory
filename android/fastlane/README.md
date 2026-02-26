# Android Fastlane Guide (New Joiner)

This project uses Fastlane from `android/` to build Flutter Android artifacts, distribute to Firebase App Distribution, and deploy to Google Play.

Fastlane docs used for this setup:
- `upload_to_play_store`: https://docs.fastlane.tools/actions/upload_to_play_store/
- `supply`: https://docs.fastlane.tools/actions/supply/

## 1) First-time setup

Run from repository root:

```sh
cd android
```

Install Ruby gems:

```sh
# Recommended on macOS (Apple Silicon/Homebrew Ruby)
/opt/homebrew/opt/ruby/bin/bundle install

# If your shell already points to Homebrew Ruby, this also works
bundle install
```

Verify Fastlane:

```sh
/opt/homebrew/opt/ruby/bin/bundle exec fastlane --version
```

## 2) Required prerequisites

- Flutter + FVM installed and working.
- Android SDK installed.
- Ruby + Bundler installed.
- Play Console service account key exists at:
  - `../.info/key/fastlane_playstore_key.json`
- Firebase CLI logged in (needed for symbol upload / Firebase distribution flows):
  - `firebase login`

## 3) Common lanes

All commands below are run inside `android/`.

### Fastlane wrapper (recommended from repo root)

You can run Android fastlane via wrapper:

```sh
bash tools/macos/distribution/fastlane/android_fastlane.sh <command> [args...]
```

Wrapper global flags:
- `--dry-run`
- `--verbose`
- `--ci`
- `-h` / `--help`

Wrapper command types:
- lane aliases: `test`, `build_apk`, `build_bundle`, `beta`, `beta_bundle`, `deploy`, `deploy_alpha`, `deploy_beta`, `deploy_production`
- `lane <lane_name> [key:value ...]` for any lane
- `raw <fastlane args...>` for direct Fastlane actions (`supply`, `lanes`, ...)

Examples:

```sh
bash tools/macos/distribution/fastlane/android_fastlane.sh lanes --ci
bash tools/macos/distribution/fastlane/android_fastlane.sh build_apk flavor:dev
bash tools/macos/distribution/fastlane/android_fastlane.sh deploy --dry-run flavor:prod track:internal
bash tools/macos/distribution/fastlane/android_fastlane.sh raw supply init --package_name com.eup.meup
```

### Build

```sh
bundle exec fastlane build_apk flavor:dev
bundle exec fastlane build_apk flavor:stg
bundle exec fastlane build_apk flavor:prod

bundle exec fastlane build_bundle flavor:dev
bundle exec fastlane build_bundle flavor:stg
bundle exec fastlane build_bundle flavor:prod
```

### Firebase distribution

```sh
bundle exec fastlane beta flavor:dev
bundle exec fastlane beta_bundle flavor:dev
```

Optional plugin path:

```sh
bundle exec fastlane beta flavor:dev use_plugin:true
bundle exec fastlane beta_bundle flavor:dev use_plugin:true
```

### Play Store deploy

Default deploy:
- flavor: `prod`
- track: `internal`
- changelog upload: enabled
- metadata/images/screenshots upload: disabled

```sh
bundle exec fastlane deploy
bundle exec fastlane deploy flavor:prod track:internal
bundle exec fastlane deploy_alpha flavor:stg
bundle exec fastlane deploy_beta flavor:stg
bundle exec fastlane deploy_production flavor:prod
```

Enable metadata uploads when needed:

```sh
bundle exec fastlane deploy flavor:prod track:internal upload_metadata:true
bundle exec fastlane deploy flavor:prod track:internal upload_images:true
bundle exec fastlane deploy flavor:prod track:internal upload_screenshots:true
bundle exec fastlane deploy flavor:prod track:internal upload_all_metadata:true
```

## 4) Metadata workflow

Play Store text/assets are read from:

```text
android/fastlane/metadata/android/<locale>/
```

Examples:
- `android/fastlane/metadata/android/en-US/title.txt`
- `android/fastlane/metadata/android/en-US/short_description.txt`
- `android/fastlane/metadata/android/en-US/full_description.txt`
- `android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`

### Pull metadata from Google Play

```sh
cd android

# Pull metadata + images + screenshots from Play Console
bundle exec fastlane supply init
```

For flavor-specific package names (if needed), pull explicitly:

```sh
bundle exec fastlane supply init --package_name com.eup.meup.dev
bundle exec fastlane supply init --package_name com.eup.meup.stg
bundle exec fastlane supply init --package_name com.eup.meup
```

### Push metadata only (no AAB/APK upload)

```sh
cd android
bundle exec fastlane supply --skip_upload_aab true --skip_upload_apk true --skip_upload_metadata false --skip_upload_images true --skip_upload_screenshots true
```

Push screenshots/images only:

```sh
bundle exec fastlane supply --skip_upload_aab true --skip_upload_apk true --skip_upload_metadata true --skip_upload_images false --skip_upload_screenshots false
```

### With deploy lane

`bundle exec fastlane deploy flavor:prod track:internal upload_metadata:true` uploads metadata from default path `android/fastlane/metadata/android`.

## 5) Notes

- Android build/distribution uses project scripts under `tools/<os>/`.
- `deploy` maps metadata flags to `upload_to_play_store` skip flags.
- Running `bundle exec fastlane lanes` may regenerate `android/fastlane/README.md` depending on Fastlane commands used.

## 6) New joiner release checklist

1. Pull latest code.
2. Update app metadata and changelog file for the target version code.
3. Run a build lane (`build_apk` or `build_bundle`) for target flavor.
4. Test artifact locally or via Firebase distribution.
5. Deploy to Play internal/alpha/beta before production.

## 7) Troubleshooting

`cannot load such file -- ostruct`
- Run in `android/`:
```sh
/opt/homebrew/opt/ruby/bin/bundle install
```

`Could not find 'bundler (2.7.2)'`
- Your shell is using system Ruby (`/usr/bin/bundle`).
- Use Homebrew Bundler explicitly:
```sh
/opt/homebrew/opt/ruby/bin/bundle install
/opt/homebrew/opt/ruby/bin/bundle exec fastlane build_apk flavor:dev
```

`Top level ::CompositeIO is deprecated` warning
- Warning only, not a blocker.
