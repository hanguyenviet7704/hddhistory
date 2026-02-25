# Android Fastlane Guide (New Joiner)

This project uses Fastlane from `android/` to build Flutter Android artifacts, distribute to Firebase App Distribution, and deploy to Google Play.

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

## 4) Metadata structure

Play Store text/assets are read from:

```text
android/fastlane/metadata/android/<locale>/
```

Examples:
- `android/fastlane/metadata/android/en-US/title.txt`
- `android/fastlane/metadata/android/en-US/short_description.txt`
- `android/fastlane/metadata/android/en-US/full_description.txt`
- `android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`

## 5) New joiner release checklist

1. Pull latest code.
2. Update app metadata and changelog file for the target version code.
3. Run a build lane (`build_apk` or `build_bundle`) for target flavor.
4. Test artifact locally or via Firebase distribution.
5. Deploy to Play internal/alpha/beta before production.

## 6) Troubleshooting

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
