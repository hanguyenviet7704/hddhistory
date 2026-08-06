# Khôi phục Force Update — Design

**Ngày:** 2026-08-04
**Repo:** meup-flutter
**Trạng thái:** chờ review

## Vấn đề

Commit `68842531` (2026-07-28, `chore/MEUP: accumulated app fixes and upkeep`) đã xoá toàn bộ cơ chế force update, đồng thời bump version `1.4.2+80` → `1.4.3+83` trong cùng commit đó. Hệ quả:

- Bản **≤ 1.4.2** vẫn mang code gate trong app nên vẫn bị chặn thật.
- Bản **1.4.3 / 1.4.4** không còn gate. Cờ `forceUserUpdate` trong Remote Config bị phớt lờ hoàn toàn — bật `true` cũng không chặn được ai.
- Chỉ còn banner soft update trên Home, dismiss được, không persist.

Việc xoá có chủ đích ở mức code (comment giải thích và test đều được viết trong cùng commit), nhưng nằm lẫn trong một commit 38 file nên không phải quyết định ở tầng sản phẩm.

Trạng thái Remote Config lúc viết spec (project `meup-bf64f`, dùng chung cho cả dev/stg/prod):

```json
{ "forceUserUpdate": true, "latestAndroidVersion": "1.4.3", "latestIosVersion": "1.4.3" }
```

App Store live: `1.4.3`. `1.4.4+102` trong pubspec chỉ là bản đang dev, chưa release.

## Mục tiêu

Khôi phục force update **đúng hành vi bản 1.4.2**, kèm hai điều chỉnh đã được chốt: i18n hoá nội dung dialog, và chặn hẳn đường thoát bằng nút back.

Ngoài phạm vi: không thêm `minSupportedVersion`, không đổi schema Remote Config, không refactor sang enum, không hạ `_minimumFetchInterval`, không check lại khi app resume từ background.

## Giới hạn cần biết trước

Force update là cơ chế **nằm trong app**, không phải ở server. Bản restore này chỉ có tác dụng từ version ship kèm nó trở đi — tức **1.4.4**, bản đang dev và chưa lên store (App Store hiện live 1.4.3).

Nhóm **1.4.3 đã ngoài thị trường vẫn không ép được**: bản đó không mang code gate. Với họ chỉ còn banner, hoặc phải gate từ phía API. Nhóm ≤1.4.2 thì ép được ngay vì bản của họ còn gate cũ.

## Kiến trúc

Giữ nguyên schema Remote Config `app_version_config`:

| Field | Vai trò |
|---|---|
| `forceUserUpdate` | Bật/tắt chế độ chặn cứng. Cũng là kill switch: tắt là thoát ngay nếu chặn sai |
| `latestAndroidVersion` | Version mới nhất trên Play. Set riêng, độc lập với iOS |
| `latestIosVersion` | Version mới nhất trên App Store |

Hai đường quyết định, loại trừ nhau:

```
shouldForceUpdate()        ⟸ forceUserUpdate == true
                              && latestVersion[platform] khác rỗng
                              && version cài < latestVersion[platform]

optionalUpdateAvailable()  ⟸ forceUserUpdate == false
                              && latestVersion[platform] khác rỗng
                              && version cài < latestVersion[platform]
```

`optionalUpdateAvailable()` mở đầu bằng `if (config.forceUserUpdate) return false` — đây là guard đã có trong bản 1.4.2, nhờ nó banner không bao giờ hiện chồng dialog. Không cần thêm cơ chế nào khác.

So sánh version chỉ lấy major/minor/patch, bỏ build number (`isVersionLowerThan` hiện có). Field rỗng luôn nghĩa là "bỏ qua nhánh này", để config thiếu không chặn oan ai.

## Các thay đổi

### 1. `lib/config/services/remote_config/i_remote_config.dart`

Tách `updateAvailable()` thành hai method: `shouldForceUpdate()` và `optionalUpdateAvailable()`.

### 2. `lib/config/services/remote_config/firebase_remote_config_service.dart`

Restore hai method, mỗi method `await _waitForStartupFetch()` rồi uỷ quyền cho một hàm pure top-level `@visibleForTesting`. Giữ dạng pure như code hiện tại đang làm với `shouldShowUpdateBanner` — hành vi y hệt 1.4.2 nhưng test không phải mock `Platform`.

Hai hàm pure, cùng chữ ký `(AppVersionConfigEntity config, {required bool isIOS, required bool Function(String) isInstalledOlderThan})`:

| Method trong class (async) | Hàm pure top-level |
|---|---|
| `shouldForceUpdate()` | `shouldBlockForForcedUpdate(...)` |
| `optionalUpdateAvailable()` | `shouldShowUpdateBanner(...)` — thêm guard `forceUserUpdate` |

Tên hàm pure **phải khác** tên method. Nếu đặt trùng (`shouldForceUpdate` cho cả hai) thì lời gọi bên trong class sẽ resolve về method của chính nó thay vì hàm top-level, gây đệ quy vô hạn.

### 3. `lib/src/onboard/presentation/widgets/force_update_content.dart`

Restore file từ `68842531^`, thêm lại dòng `part` vào `lib/src/onboard/onboard.dart`. Asset `assets/images/app/force_update_decor.png` đang mồ côi sẽ có consumer lại.

Thay ba string hardcode bằng key l10n (mục 6). Giữ nguyên layout, spacing, `AppStyle`, `AppCustomColor` như bản cũ.

### 4. `lib/src/onboard/presentation/pages/splash_page.dart`

Restore gate:

- Field `late final Future<bool> _shouldForceUpdate`, khởi tạo trong `initState` để fetch chạy song song với các bước khởi động khác.
- `_resolveShouldForceUpdate()` — gọi service, mọi lỗi trả `false`.
- Trong `_initScreen`, trước khi xử lý deeplink: `await _shouldForceUpdate.timeout(Duration(milliseconds: 1500), onTimeout: () => false)`. Nếu `true` thì `_showUpdateDialog()` rồi `return`.
- `_showUpdateDialog()` — track `TrackingKey.alertUpdateView`, gọi `showDDialog` với `ForceUpdateContent`.
- `_handleUpdatePressed()` — track `TrackingKey.alertUpdateConfirm`, mở store URL. **Không** đóng dialog.

Timeout 1.5s là fallback an toàn: Remote Config chậm hay lỗi mạng thì coi như không có force update, splash không bị treo.

### 5. Chặn hẳn đường thoát

Bản 1.4.2 dùng `showDDialog` → `showGeneralDialog` không set `barrierDismissible` (mặc định `false`, nên tap ngoài đã không đóng), nhưng **nút back trên Android vẫn pop được route dialog** và vào app bình thường.

Bọc thân `ForceUpdateContent` trong `PopScope(canPop: false)`. Sau đó: tap ngoài không đóng, back không đóng, chỉ còn hai lựa chọn là bấm nút update hoặc kill app.

Đặt `PopScope` trong `ForceUpdateContent` chứ không sửa `showDDialog` — `showDDialog` là helper dùng chung cho nhiều dialog khác, đổi nó sẽ khiến mọi dialog trong app không đóng được bằng back.

### 6. i18n — `assets/i18n/<locale>/common.yaml`

Ba key mới, đặt ở `common.yaml` vì dialog chặn toàn app và không thuộc feature nào. Key không prefix module, đúng convention của file này.

| Key | en | vi |
|---|---|---|
| `forceUpdateTitle` | We're getting better! | MeUp vừa tốt hơn rồi! |
| `forceUpdateMessage` | Update to unlock new features and a smoother experience. | Cập nhật để dùng tính năng mới và trải nghiệm mượt hơn. |
| `forceUpdateAction` | Go to Update | Cập nhật ngay |

| Key | zh | ja | ko |
|---|---|---|---|
| `forceUpdateTitle` | 我们又变得更好了！ | アプリがさらに進化しました！ | 더 좋아졌어요! |
| `forceUpdateMessage` | 更新应用即可体验全新功能，享受更流畅的使用体验。 | 新機能と快適な操作をご利用いただくため、アプリを更新してください。 | 새로운 기능과 더 나은 경험을 위해 앱을 업데이트해 주세요. |
| `forceUpdateAction` | 前往更新 | アップデートする | 업데이트하기 |

Cả năm locale bắt buộc phải có, nếu thiếu sẽ âm thầm fallback về `en`. Sau khi sửa YAML phải chạy `dart run slang`.

Bản cũ có `\n` cứng giữa câu message. Bỏ, để text tự wrap — chiều rộng máy khác nhau, ngắt dòng cứng gây lệch trên máy nhỏ.

### 7. `lib/src/home/presentation/cubits/home_cubit.dart`

`checkOptionalUpdate()` gọi `optionalUpdateAvailable()` thay cho `updateAvailable()`.

Ba comment hiện đang mô tả sai (`home_cubit.dart:231`, `home_page.dart:70`, `splash_page.dart:73` — đều nói force update được xử lý ở splash dialog) sẽ tự đúng lại, không cần sửa chữ.

### 8. Version

Giữ version name `1.4.4` — bản này chưa lên store nên force update đi kèm ngay trong nó, không cần mở version mới. Chỉ bump build number: `1.4.4+102` → `1.4.4+103`.

## Testing

Không chạy full suite trên máy dev (hết RAM). Gate chính là `flutter analyze`, cộng các file test chạy riêng lẻ.

**`test/unit/config/services/remote_config/firebase_remote_config_service_test.dart`** — sửa case hiện có *"STILL shows the banner when forceUserUpdate is set"* thành ngược lại, và thêm ma trận:

| forceUserUpdate | version cài vs latest | shouldForceUpdate | shouldShowUpdateBanner |
|---|---|---|---|
| true | thấp hơn | true | false |
| true | bằng | false | false |
| true | cao hơn | false | false |
| false | thấp hơn | false | true |
| false | bằng | false | false |
| true | latest rỗng | false | false |

Thêm case phân biệt platform: `latestIosVersion` thấp mà `latestAndroidVersion` cao thì trên iOS phải ra kết quả theo field iOS.

**`test/unit/onboard/presentation/widgets/force_update_content_test.dart`** — restore từ `68842531^`, cập nhật assert sang key l10n thay string hardcode, thêm case `PopScope` có `canPop == false`.

Không test bằng cách render từng locale. Non-base locale được khai báo deferred, và deferred loading **không hoạt động dưới `flutter test`**: `setLocaleSync` ném `_DeferredNotLoadedError`, còn `setLocale` async thì không bao giờ hoàn thành (thực đo: treo tới timeout 10 phút). Thay bằng assert trực tiếp trên YAML — đủ năm locale phải có cả ba key, giá trị không rỗng, và bản `vi` không được còn tiền tố `(VI) ` (phần lớn `vi/common.yaml` vẫn đang là placeholder chưa dịch, dialog chặn app là chỗ tệ nhất để lọt một cái).

## Rollout

Thứ tự bắt buộc, không được đảo:

1. Ship 1.4.4 lên App Store và Play Store, chờ live.
2. Xác nhận đã live: `curl "https://itunes.apple.com/lookup?id=6755175330"` phải trả `version: 1.4.4`. Play Store kiểm tay.
3. **Mới** nâng Remote Config `latestIosVersion` / `latestAndroidVersion` lên `1.4.4`.
4. Chờ tối đa 30 phút (`_minimumFetchInterval`) để client fetch được.

Kết quả sau bước 3, với `forceUserUpdate: true` và `latestVersion: 1.4.4`:

| Version user đang cài | Có code gate? | Kết quả |
|---|---|---|
| ≤ 1.4.2 | có (gate cũ) | **Chặn cứng**, và update lên 1.4.4 là thoát được |
| 1.4.3 | không | Chỉ banner, dismiss được |
| 1.4.4 | có (gate mới) | Không thấy gì — đã bằng ngưỡng |

Đây là lý do thứ tự trên quan trọng: ngưỡng `1.4.4` chỉ an toàn khi 1.4.4 thực sự tải được từ store, nếu không nhóm ≤1.4.2 bị chặn mà không có bản nào để update lên.

Nâng `latestVersion` lên một bản chưa có trên store sẽ làm user bị **kẹt vĩnh viễn**: dialog chặn họ, mà update thì chỉ lên được bản đang live, vẫn thấp hơn ngưỡng nên vẫn bị chặn. Đường ra duy nhất là hạ Remote Config lại và chờ hết fetch interval.

Vì `latestIosVersion` và `latestAndroidVersion` độc lập, khi Play đã live mà Apple còn review thì nâng riêng Android trước.

Kill switch khi có sự cố: set `forceUserUpdate: false`. Toàn bộ user thoát khỏi dialog ở lần fetch kế tiếp, không cần tính toán lại version.

## Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Set `latestVersion` cao hơn bản live → user kẹt | Quy trình rollout 4 bước ở trên; kill switch `forceUserUpdate: false` |
| Remote Config chậm → splash treo | Timeout 1.5s, coi như không force |
| Dev/stg/prod dùng chung Remote Config | Mọi thay đổi ảnh hưởng prod ngay. Test bằng cách sửa default trong code trên máy dev, không sửa Console |
| Thiếu locale → hiện tiếng Anh | Thêm đủ 5 locale, `flutter analyze` sau `dart run slang` |
