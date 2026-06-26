# Hướng dẫn Deploy — Google Play & TestFlight

## Chuẩn bị môi trường (chỉ cần làm 1 lần)

Thêm Flutter vào PATH (mở terminal mới thì cần chạy lại):

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

---

## Trước mỗi lần build

### 1. Tăng version trong `pubspec.yaml`

Store sẽ **reject** nếu build number trùng với bản đã upload.

```yaml
# pubspec.yaml
version: 1.2.1+32   # tăng số sau dấu + mỗi lần upload
```

> Quy tắc: `x.y.z` thay đổi khi release tính năng mới cho user. `+build` tăng mỗi lần upload (kể cả upload lại cùng version).

### 2. Kiểm tra code

```bash
cd ~/Source/Meup/meup-flutter

flutter analyze        # phải sạch, không có error
flutter test           # chạy unit tests
```

### 3. Nếu có thay đổi model / API / DI / freezed

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Build & Deploy iOS → TestFlight

### Bước 1 — Build IPA

```bash
cd ~/Source/Meup/meup-flutter
./tools/macos/build/build_ipa.sh prod
```

Script tự động:
- Build với flavor `prod`, obfuscate code, split debug info
- Upload dSYM lên Firebase Crashlytics
- Mở thư mục output trong Finder

Output IPA nằm ở đường dẫn được in ra cuối log, ví dụ:
```
build/ios/ipa/meup.ipa
```

### Bước 2 — Upload lên TestFlight (tự động)

```bash
./tools/macos/distribution/upload_appstore.sh
```

Script dùng App Store Connect API key tại `.info/key/AuthKey_697CNSDLVW.p8` để upload tự động.

Hoặc chỉ định file IPA cụ thể:

```bash
./tools/macos/distribution/upload_appstore.sh --file "build/ios/ipa/meup.ipa" --distribution testflight
```

### Bước 2 (thay thế) — Upload thủ công qua Xcode

1. Mở **Xcode → Window → Organizer**
2. Chọn bản archive vừa build
3. Click **Distribute App → App Store Connect → Upload**

### Bước 3 — Kiểm tra trên App Store Connect

1. Vào [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Chọn app → **TestFlight**
3. Đợi Apple xử lý build (~5–15 phút)
4. Thêm tester nếu cần và gửi invite

---

## Build & Deploy Android → Google Play

### Bước 1 — Build App Bundle

```bash
cd ~/Source/Meup/meup-flutter
./tools/macos/build/build_appbundle.sh prod
```

Script tự động:
- Build `.aab` với flavor `prod`, obfuscate code
- Upload debug symbols lên Firebase Crashlytics
- Mở thư mục output trong Finder

Output `.aab` nằm ở đường dẫn được in ra cuối log, ví dụ:
```
build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Bước 2 — Upload lên Google Play Console (thủ công)

1. Vào [play.google.com/console](https://play.google.com/console)
2. Chọn app → **Testing → Internal testing** (hoặc track khác)
3. Click **Create new release**
4. Upload file `.aab`
5. Điền release notes → **Save → Review → Rollout**

---

## Lưu ý quan trọng

| | Android | iOS |
|---|---|---|
| File output | `.aab` (App Bundle) | `.ipa` |
| Upload tool | Google Play Console (web) | `upload_appstore.sh` hoặc Xcode |
| API key | `.info/key/fastlane_playstore_key.json` | `.info/key/AuthKey_697CNSDLVW.p8` |
| Signing | Keystore trong `android/app/` | Certificate trong Keychain |
| Version source | `pubspec.yaml` | `pubspec.yaml` |

### Nếu build bị lỗi signing

- **iOS:** Mở Xcode → Targets → Runner → Signing & Capabilities → kiểm tra Team và Certificate
- **Android:** Kiểm tra `android/key.properties` và file keystore

### Nếu upload bị lỗi "Invalid build number"

Tăng số `+build` trong `pubspec.yaml` và build lại.

---

## Lệnh tóm tắt nhanh

```bash
# Setup PATH (mỗi terminal mới)
export PATH="$HOME/development/flutter/bin:$PATH"
cd ~/Source/Meup/meup-flutter

# 1. Tăng version trong pubspec.yaml trước

# iOS → TestFlight
./tools/macos/build/build_ipa.sh prod
./tools/macos/distribution/upload_appstore.sh

# Android → Google Play
./tools/macos/build/build_appbundle.sh prod
# → Upload .aab thủ công lên Play Console
```
