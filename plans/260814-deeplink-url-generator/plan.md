# Link dẫn vào từng màn của app — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Marketer tự lấy được URL dẫn thẳng vào một màn cụ thể của app từ trang admin, và app mở đúng màn đó.

**Architecture:** Link mang **khoá tượng trưng** (`https://meup.training/open/<key>`), không mang route path. Flutter giải khoá ngay tại máy bằng một registry đóng — không round-trip, không phụ thuộc mạng. API phục vụ danh mục khoá (một hằng số tĩnh, không DB) để admin dựng dropdown và để giai đoạn 2 validate. Admin dựng URL phía client.

**Tech Stack:** Flutter (go_router typed routes, BLoC, get_it) · NestJS 9 · React 19 + CRA + MUI/Tailwind · nginx + HTML tĩnh

**Spec:** [`design.md`](./design.md) — đọc cùng plan này.

## Global Constraints

- **17 khoá đích. Giá trị chuỗi phải khớp TỪNG KÝ TỰ giữa cả 3 stack:** `home`, `explore`, `habit`, `profile`, `library`, `course-roadmap`, `lesson`, `skillset-courses`, `paywall`, `manage-subscription`, `daily-warm-up`, `learning-streak`, `daily-check-in`, `my-lessons`, `import-lesson`, `notification-setting`, `change-language`.
- Base URL: `https://meup.training/open` (web) và `hddhistory://open` (in-app). **Host không được đổi** — entitlement iOS là `applinks:meup.training` không wildcard.
- Ba dạng cũ phải tiếp tục chạy: `hddhistory://`, `hddhistory://paywall`, `hddhistory://course-roadmap?...`.
- **Không chạy full test suite** — `npm test` không tham số và `flutter test` không tham số làm hết RAM máy này. Chỉ chạy file đơn lẻ.
- Flutter SDK **không nằm trên PATH**: dùng `/Users/nguyenvietha/development/flutter/bin/flutter`. Không dùng fvm (cache 3.35.5 quá cũ cho pubspec).
- **Không bao giờ `git checkout --`** trong repo HDDhistory — cây làm việc đang có hàng chục file WIP chưa commit của việc khác.
- Commit thẳng vào `develop` từng repo (branch protection đã bỏ 2026-08-05). Message `type: subject`, chữ thường, imperative. Tách commit theo chủ đề.
- Không sửa file generated: `*.g.dart`, `*.freezed.dart`, `*.config.dart`.
- **Không thêm key l10n nào** — thiết kế này không thêm màn mới.
- Mọi đích đổi branch phải gọi `PageCubit.setCurrentRouteName(...)` **trước** `.go()`.
- Không bao giờ vượt gate lock/paywall. Deeplink là đường đi, không phải chìa khoá.
- `minAppBuild`: bản hiện tại là `1.5.2+129`. `home` và `paywall` đã chạy được trong bản này → `129`. **13 khoá còn lại → `130`.**

---

### Task 1: Flutter — enum đích + parser (thuần, có test)

**Files:**
- Create: `hddhistory-flutter/lib/src/common/domain/entities/deeplink_target.dart`
- Modify: `hddhistory-flutter/lib/src/common/common.dart` (thêm một dòng `part`, sau `part 'domain/entities/course_config_entity.dart';` ở dòng 18 — thứ tự alphabet)
- Test: `hddhistory-flutter/test/unit/common/presentation/cubits/deeplink_cubit_test.dart` (thêm group vào file đã có)

**Interfaces:**
- Consumes: `HomeWidgetDeeplinkTarget.sourceQueryKey` / `.sourceValue`, `LiveActivityDeeplink.sourceValue` (đã tồn tại, đã dùng trong `deeplink_cubit.dart`)
- Produces:
  - `enum DeeplinkDestination` — 16 giá trị, mỗi cái có `String get value`; `static DeeplinkDestination? tryFromValue(String raw)`
  - `class DeeplinkTarget` — `DeeplinkDestination? destination`, `String rawKey`, `Map<String, String> params`, `String get campaign`, `Map<String, dynamic> get trackingParams`, `static DeeplinkTarget? tryParse(Uri uri)`, `static const String pathPrefix = 'open'`

- [ ] **Step 1: Viết test thất bại**

Thêm vào cuối `test/unit/common/presentation/cubits/deeplink_cubit_test.dart`, **trong** `void main()`:

```dart
  group('DeeplinkTarget.tryParse', () {
    test('parses the canonical /open/<key> web link', () {
      final target = DeeplinkTarget.tryParse(
        Uri.parse('https://meup.training/open/paywall?variant=full&c=tet-2027'),
      );

      expect(target?.destination, DeeplinkDestination.paywall);
      expect(target?.params['variant'], 'full');
      expect(target?.campaign, 'tet-2027');
    });

    test('parses the in-app hddhistory://open/<key> form', () {
      final target = DeeplinkTarget.tryParse(Uri.parse('hddhistory://open/course-roadmap?courseId=c1'));

      expect(target?.destination, DeeplinkDestination.courseRoadmap);
      expect(target?.params['courseId'], 'c1');
    });

    test('keeps the legacy prefix-less forms working', () {
      expect(DeeplinkTarget.tryParse(Uri.parse('hddhistory://paywall'))?.destination, DeeplinkDestination.paywall);
      expect(DeeplinkTarget.tryParse(Uri.parse('hddhistory://'))?.destination, DeeplinkDestination.home);
      expect(DeeplinkTarget.tryParse(Uri.parse('https://meup.training/'))?.destination, DeeplinkDestination.home);
      expect(DeeplinkTarget.tryParse(Uri.parse('hddhistory://open'))?.destination, DeeplinkDestination.home);
    });

    test('reports an unknown key instead of dropping it', () {
      final target = DeeplinkTarget.tryParse(Uri.parse('hddhistory://open/does-not-exist'));

      expect(target?.destination, isNull);
      expect(target?.rawKey, 'does-not-exist');
    });

    test('leaves home-widget and live-activity links to their own handlers', () {
      expect(
        DeeplinkTarget.tryParse(Uri.parse('hddhistory://course-roadmap?source=home_widget&widgetType=suggest_course')),
        isNull,
      );
      expect(
        DeeplinkTarget.tryParse(Uri.parse('hddhistory://course-roadmap?courseId=c1&source=live_activity')),
        isNull,
      );
    });

    test('exposes every destination key exactly once', () {
      final values = DeeplinkDestination.values.map((destination) => destination.value).toList();

      expect(values.toSet().length, values.length);
      expect(values.length, 16);
    });
  });
```

- [ ] **Step 2: Chạy test để chắc chắn nó FAIL**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter test test/unit/common/presentation/cubits/deeplink_cubit_test.dart
```

Expected: FAIL — `Undefined name 'DeeplinkTarget'` / `Undefined name 'DeeplinkDestination'`.

- [ ] **Step 3: Viết implementation tối thiểu**

Tạo `hddhistory-flutter/lib/src/common/domain/entities/deeplink_target.dart`:

```dart
part of '../../../common.dart';

/// Một đích deeplink mà app biết mở.
///
/// Giá trị chuỗi ở đây là HỢP ĐỒNG CÔNG KHAI: nó nằm trong link đã gửi push, đã
/// in QR, đã dán vào bài Zalo — những thứ không rút lại được. Đổi tên route bên
/// trong app không được đổi những giá trị này. Thêm khoá mới thì được; đổi hoặc
/// xoá khoá cũ là làm chết link đã phát ra.
enum DeeplinkDestination {
  home('home'),
  explore('explore'),
  habit('habit'),
  profile('profile'),
  courseRoadmap('course-roadmap'),
  lesson('lesson'),
  skillsetCourses('skillset-courses'),
  paywall('paywall'),
  manageSubscription('manage-subscription'),
  dailyWarmUp('daily-warm-up'),
  learningStreak('learning-streak'),
  dailyCheckIn('daily-check-in'),
  myLessons('my-lessons'),
  importLesson('import-lesson'),
  notificationSetting('notification-setting'),
  changeLanguage('change-language');

  const DeeplinkDestination(this.value);

  final String value;

  static DeeplinkDestination? tryFromValue(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final destination in DeeplinkDestination.values) {
      if (destination.value == normalized) return destination;
    }
    return null;
  }
}

/// Một link vào màn đã được phân tích: khoá đích + tham số của nó.
class DeeplinkTarget {
  const DeeplinkTarget({
    required this.destination,
    required this.rawKey,
    required this.params,
  });

  /// `null` = link đúng dạng của mình, nhưng bản app này chưa hiểu khoá đó.
  /// Giữ [rawKey] để event tracking nói được bản cũ đang nhận khoá gì.
  final DeeplinkDestination? destination;
  final String rawKey;
  final Map<String, String> params;

  static const String pathPrefix = 'open';
  static const String campaignQueryKey = 'c';
  static const String _webHost = 'meup.training';

  /// Nguồn của những link mang analytics riêng — home widget và Live Activity
  /// có handler riêng, và chúng phải giữ quyền xử lý link của mình. Chặn ở đây
  /// để mỗi parser sở hữu đúng vùng URL của nó, không phụ thuộc thứ tự gọi.
  static const Set<String> _reservedSources = {
    HomeWidgetDeeplinkTarget.sourceValue,
    LiveActivityDeeplink.sourceValue,
  };

  String get campaign => params[campaignQueryKey]?.trim() ?? '';

  Map<String, dynamic> get trackingParams => {
    'destination': destination?.value ?? rawKey,
    if (campaign.isNotEmpty) 'campaign': campaign,
  };

  static DeeplinkTarget? tryParse(Uri uri) {
    final params = uri.queryParameters;
    if (_reservedSources.contains(params[HomeWidgetDeeplinkTarget.sourceQueryKey])) return null;

    final key = _extractKey(uri);
    return DeeplinkTarget(
      destination: DeeplinkDestination.tryFromValue(key),
      rawKey: key,
      params: params,
    );
  }

  /// `https://meup.training/open/paywall` → `paywall`
  /// `hddhistory://open/course-roadmap`         → `course-roadmap` (authority là `open`)
  /// `hddhistory://paywall`                      → `paywall`      (dạng cũ, khoá ở host)
  /// `hddhistory://` · `https://meup.training/`  → `home`
  static String _extractKey(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();

    if (segments.isEmpty) {
      final host = uri.host.trim().toLowerCase();
      if (host.isEmpty || host == _webHost || host == pathPrefix) {
        return DeeplinkDestination.home.value;
      }
      return host;
    }

    if (segments.first.toLowerCase() == pathPrefix) {
      return segments.length > 1 ? segments[1].toLowerCase() : DeeplinkDestination.home.value;
    }

    return segments.first.toLowerCase();
  }
}
```

Thêm vào `hddhistory-flutter/lib/src/common/common.dart`, ngay sau dòng 18:

```dart
part 'domain/entities/deeplink_target.dart';
```

- [ ] **Step 4: Chạy test để chắc chắn PASS**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter test test/unit/common/presentation/cubits/deeplink_cubit_test.dart
```

Expected: PASS, toàn bộ file (kể cả các group cũ về `normalizeDeeplinkPath` / `HomeWidgetDeeplinkTarget`).

- [ ] **Step 5: analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common test/unit/common
```

Expected: `No issues found!`. Nếu báo lỗi về `part`, chạy `dart run build_runner build --delete-conflicting-outputs` rồi analyze lại.

- [ ] **Step 6: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/domain/entities/deeplink_target.dart lib/src/common/common.dart test/unit/common/presentation/cubits/deeplink_cubit_test.dart && \
git commit -m "feat: thêm enum đích deeplink và parser cho link /open/<key>"
```

---

### Task 2: Flutter — khung `_handleDestination`, guard onboarding, event, và hai đích đã có (`home`, `paywall`)

Task này là refactor giữ nguyên hành vi + thêm event + thêm guard. **Chưa** thêm đích mới.

**Files:**
- Modify: `hddhistory-flutter/lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart` (thay `_handleNormalRoute` ở dòng 117-156; thêm field và helper)
- Modify: `hddhistory-flutter/lib/core/constants/manual/tracking_key.dart` (thêm 1 hằng số cạnh `notiTap` ở dòng 554)
- Test: `hddhistory-flutter/test/unit/common/presentation/cubits/deeplink_cubit_test.dart` (sửa 1 test đã có)

**Interfaces:**
- Consumes: `DeeplinkTarget`, `DeeplinkDestination` (Task 1); `AppConfig.instance.context`; `AppDI.injector`; `PageCubit.setCurrentRouteName`; `IapCubit.setPaywallEntryPoint` / `.forcePaywallVariant`; `HomeRoute`, `PaywallRoute`
- Produces:
  - `TrackingKey.deeplinkOpen == 'deeplink_open'`
  - `bool DeeplinkCubit._handleDestination()`
  - `bool DeeplinkCubit._navigateToDestination(BuildContext navContext, DeeplinkDestination destination, DeeplinkTarget target)` — Task 3/4/5 chỉ thêm `case` vào đúng hàm này
  - `void DeeplinkCubit._trackDeeplinkOpen(DeeplinkTarget target, {required bool resolved, String reason = ''})`
  - `bool DeeplinkCubit._shouldDeferForOnboarding()`
  - field `DeeplinkTarget? _pendingTarget`

- [ ] **Step 1: Sửa test đã có để nó nói đúng ý**

Trong `test/unit/common/presentation/cubits/deeplink_cubit_test.dart`, group `DeeplinkCubit.initialLink`, đổi test đầu tiên. Lý do: `/profile` sắp trở thành một đích **hợp lệ**, nên dùng nó làm ví dụ "unsupported" sẽ khiến test đúng vì lý do sai (trong unit test không có navigator context nên vẫn `false`).

```dart
    test('returns false for unknown destinations so splash can continue', () async {
      service.initialUri = Uri.parse('https://meup.training/open/no-such-screen');
      cubit.setIsPassSplashScreen(true);

      final isHandled = await cubit.initialLink();

      expect(isHandled, isFalse);
    });
```

- [ ] **Step 2: Chạy test để xem trạng thái trước khi sửa code**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter test test/unit/common/presentation/cubits/deeplink_cubit_test.dart
```

Expected: PASS (chưa có context nên vẫn `false`). Test này là lưới an toàn cho refactor, không phải test dẫn đường — hàm điều hướng cần `BuildContext` nên không unit-test được; kiểm chứng thật ở Step 6.

- [ ] **Step 3: Thêm tracking key**

Trong `hddhistory-flutter/lib/core/constants/manual/tracking_key.dart`, thêm ngay dưới dòng 554 (`notiTap`):

```dart
  /// Mở app từ một link vào màn (`/open/<key>`). Đây là cách DUY NHẤT đếm được
  /// click của người ĐÃ cài app: Universal Link bị OS chặn và giao thẳng cho
  /// app, server không bao giờ thấy request đó.
  static const String deeplinkOpen = 'deeplink_open';
```

- [ ] **Step 4: Thay `_handleNormalRoute` bằng khung mới**

Trong `deeplink_cubit.dart`:

**4a.** Thêm field cạnh `Map<String, String> _serviceRouteQuery = {};` (dòng 15):

```dart
  DeeplinkTarget? _pendingTarget;
```

**4b.** Trong `resetServiceRouteData()`, thêm dòng cuối:

```dart
    _pendingTarget = null;
```

**4c.** Trong `_resolveServiceLink(Uri uri)`, thêm ngay sau `_serviceRouteQuery = queryParameters;`:

```dart
    _pendingTarget = DeeplinkTarget.tryParse(uri);
```

**4d.** Trong `handleRoute()`, đổi dòng gọi chuỗi handler:

```dart
    final isHandled = _handleLiveActivityRoute() || _handleShellRoute() || _handleDestination();
```

**4e.** Xoá toàn bộ `_handleNormalRoute()` (dòng 117-156) và thay bằng:

```dart
  /// Điều hướng theo bảng đích. Chạy SAU live-activity và home-widget: hai
  /// handler đó khoá theo `source=` và mang analytics riêng của chúng.
  bool _handleDestination() {
    final target = _pendingTarget;
    if (target == null) return false;

    // Deeplink không được vượt lên trước onboarding. Trả false để splash tự
    // quyết đi đâu — nó dùng đúng giá trị này để biết deeplink có chiếm quyền
    // điều hướng hay không (xem splash_page.dart:109-114).
    if (_shouldDeferForOnboarding()) {
      LogDev.info('Deferring deeplink until onboarding finishes: ${target.rawKey}');
      _trackDeeplinkOpen(target, resolved: false, reason: 'pre_auth_deferred');
      return false;
    }

    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring deeplink because navigator context is unavailable');
      _trackDeeplinkOpen(target, resolved: false, reason: 'missing_context');
      return false;
    }

    final destination = target.destination;
    if (destination == null) {
      // Bản app cũ nhận một khoá mới. Về Home thì sai ít hơn là treo tại chỗ
      // người dùng đang đứng — đó là hành vi cũ và không ai nhận ra nó hỏng.
      LogDev.warning('Unknown deeplink destination: ${target.rawKey}');
      _trackDeeplinkOpen(target, resolved: false, reason: 'unknown_destination');
      HomeRoute().go(navContext);
      return true;
    }

    final isHandled = _navigateToDestination(navContext, destination, target);
    _trackDeeplinkOpen(target, resolved: isHandled, reason: isHandled ? '' : 'navigation_failed');
    return isHandled;
  }

  /// True khi người dùng lẽ ra sẽ bị đưa vào auth/onboarding chứ không vào app.
  ///
  /// KHÔNG kiểm theo tên route: splash gọi `initialLink()` trong lúc còn đứng
  /// TRÊN splash, nên một guard theo tên route sẽ chặn luôn mọi deeplink
  /// cold-start — kể cả những cái đang chạy tốt hôm nay. Dùng lại đúng vị từ mà
  /// splash dùng để quyết định vào Home hay vào onboarding.
  ///
  /// Lưu ý tên field bị đặt ngược: `isUserPassOnboarding == true` nghĩa là người
  /// này CÒN PHẢI onboard (mặc định `true` cho máy vừa cài).
  bool _shouldDeferForOnboarding() {
    try {
      final userState = AppDI.injector.get<UserCubit>().state;
      return AppGlobalValue.accessToken.isEmpty || userState.isUserPassOnboarding;
    } catch (error) {
      // Không đọc được trạng thái user thì coi như chưa an toàn để điều hướng.
      LogDev.warning('Could not read onboarding state for deeplink: $error');
      return true;
    }
  }

  /// Bảng đích. Task sau chỉ thêm `case` vào đây.
  bool _navigateToDestination(
    BuildContext navContext,
    DeeplinkDestination destination,
    DeeplinkTarget target,
  ) {
    switch (destination) {
      case DeeplinkDestination.home:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        HomeRoute().go(navContext);
        return true;

      // `?variant=full` / `?variant=compact` cho LINK quyền gọi tên bề mặt,
      // đè lên bảng entry-point của admin — một chiến dịch và cái nó dẫn tới
      // thành một quyết định ở một chỗ. Không có (hoặc không nhận ra) variant
      // thì rơi về bảng cũ, đúng như link trần trước đây.
      case DeeplinkDestination.paywall:
        final iapCubit = AppDI.injector.get<IapCubit>();
        iapCubit.setPaywallEntryPoint(PaywallEntryPoint.other);
        switch (target.params['variant']?.trim().toLowerCase()) {
          case 'full':
            iapCubit.forcePaywallVariant(PaywallProductVariant.full);
          case 'compact':
            iapCubit.forcePaywallVariant(PaywallProductVariant.compact);
        }
        // Push, không go: link là một lời đề nghị, không phải một cuộc di dời.
        unawaited(const PaywallRoute().push(navContext));
        return true;

      default:
        LogDev.warning('Destination not wired yet: ${destination.value}');
        return false;
    }
  }

  void _trackDeeplinkOpen(DeeplinkTarget target, {required bool resolved, String reason = ''}) {
    unawaited(
      AppService.instance.appTrackingService.trackEvent(
        TrackingKey.deeplinkOpen,
        parameters: {
          ...target.trackingParams,
          'resolved': resolved,
          if (reason.isNotEmpty) 'reason': reason,
        },
      ).catchError((_) {}),
    );
  }
```

- [ ] **Step 5: Chạy test + analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
/Users/nguyenvietha/development/flutter/bin/flutter test test/unit/common/presentation/cubits/deeplink_cubit_test.dart && \
/Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common lib/core/constants
```

Expected: test PASS, analyze `No issues found!`.

- [ ] **Step 6: Kiểm chứng trên simulator (đây mới là gate thật)**

Build và chạy app dev, đăng nhập tới Home, rồi:

```bash
xcrun simctl openurl booted "hddhistory://paywall"
xcrun simctl openurl booted "hddhistory://open/paywall?variant=compact"
xcrun simctl openurl booted "hddhistory://open/no-such-screen"
xcrun simctl openurl booted "hddhistory://"
```

Expected: paywall mở (lần 2 ở dạng compact); khoá lạ đưa về Home; `hddhistory://` về Home. Kiểm tra log có `deeplink_open`.

Trước mỗi lần bấm/chụp, xác nhận Simulator đang là app frontmost — người dùng có thể đang dùng máy này. Dùng skill `sim-test`.

- [ ] **Step 7: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart lib/core/constants/manual/tracking_key.dart test/unit/common/presentation/cubits/deeplink_cubit_test.dart && \
git commit -m "feat: thay bảng deeplink 3 nhánh bằng registry đích có event và guard onboarding"
```

---

### Task 3: Flutter — bốn đích tab (`explore`, `habit`, `profile`) và `course-roadmap`

**Files:**
- Modify: `hddhistory-flutter/lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart` (thêm `case` vào `_navigateToDestination`)

**Interfaces:**
- Consumes: `_navigateToDestination` (Task 2); `_openCourseRoadmap(BuildContext, String?, String)` — đã có ở dòng 189; `CourseCubit.setAllCourseSource(String)`, `CourseCubit.jumpToSkillset(int)`, `HomeCubit.state.selectedSkillsetIndex`
- Produces: `static const String DeeplinkCubit.deeplinkRoadmapSource = 'deeplink'`

- [ ] **Step 1: Thêm hằng số source**

Cạnh `_newCourseRoadmapSource` (dòng 333) trong `deeplink_cubit.dart`:

```dart
  /// Nhãn source cho roadmap/explore mở từ một link marketing. Không nằm trong
  /// `remapRoadmapSource`, nên nó rơi vào nhóm explore chung — đúng, vì đây
  /// không phải một trong các bề mặt Home mà hàm đó phân biệt.
  static const String deeplinkRoadmapSource = 'deeplink';
```

- [ ] **Step 2: Thêm bốn `case` vào `_navigateToDestination`, ngay trước `default:`**

```dart
      case DeeplinkDestination.explore:
        // Đúng chuỗi mà một cú bấm tab "Khám phá" chạy (xem
        // PageCubit.handleShellRouteNavigation case 3): mở Explore đã cuộn tới
        // course đang học, không reset về đầu danh sách.
        final selectedSkillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
        AppDI.injector.get<CourseCubit>()
          ..setAllCourseSource(deeplinkRoadmapSource)
          ..jumpToSkillset(selectedSkillsetIndex);
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.course);
        CourseRoute().go(navContext);
        return true;

      case DeeplinkDestination.habit:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
        HabitRoute().go(navContext);
        return true;

      case DeeplinkDestination.profile:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ProfileRoute().go(navContext);
        return true;

      // `courseId` là tuỳ chọn: không truyền thì mở roadmap của course đang
      // chọn. Course không chọn được (đã unpublish sau khi link phát ra) thì về
      // Home — giống hệt nhánh `course_not_found` của luồng home widget.
      case DeeplinkDestination.courseRoadmap:
        final courseId = target.params['courseId']?.trim() ?? '';
        if (_openCourseRoadmap(navContext, courseId, deeplinkRoadmapSource)) return true;
        HomeRoute().go(navContext);
        _trackDeeplinkOpen(target, resolved: false, reason: 'entity_not_found');
        return true;
```

**Lưu ý về `setCurrentRouteName` trước `.go()`:** `.go()` sang một branch mà branch đó đã dựng sẵn thì **không** phát `didPush`, nên router observer không chạy và `currentIndex`/`currentRouteName` đứng lại ở tab cũ — nav nổi sẽ hiện sai tab. Đây là cùng một cái bẫy mà `_openCourseRoadmap` và `course_card.dart` đã phải chống.

- [ ] **Step 3: analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common
```

Expected: `No issues found!`.

- [ ] **Step 4: Kiểm chứng trên simulator**

```bash
xcrun simctl openurl booted "hddhistory://open/explore"
xcrun simctl openurl booted "hddhistory://open/habit"
xcrun simctl openurl booted "hddhistory://open/profile"
xcrun simctl openurl booted "hddhistory://open/course-roadmap"
xcrun simctl openurl booted "hddhistory://open/course-roadmap?courseId=<id-thật-từ-admin>"
xcrun simctl openurl booted "hddhistory://open/course-roadmap?courseId=khong-ton-tai"
```

Expected: mỗi lệnh mở đúng tab **và nav nổi dưới sáng đúng tab đó** (đây là phần dễ hỏng nhất). `courseId` không tồn tại → về Home.

- [ ] **Step 5: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart && \
git commit -m "feat: nối đích deeplink cho explore, habit, profile và course roadmap"
```

---

### Task 4: Flutter — hai đích cần tham số (`lesson`, `skillset-courses`)

**Files:**
- Modify: `hddhistory-flutter/lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart`

**Interfaces:**
- Consumes: `CourseRoadmapCubit.setPendingResumeKeypointId(String)`, `.clearPendingResumeKeypointId()`; `_openCourseRoadmap`; `SkillsetCoursesRoute({required String skillsetId})`; `deeplinkRoadmapSource` (Task 3)

- [ ] **Step 1: Thêm hai `case`, ngay trước `default:`**

```dart
      // Không có đường mở thẳng một lesson: `LessonRoute` không nhận id, nội
      // dung bài do CourseLessonCubit giữ và roadmap là màn nạp dữ liệu course.
      // Nên đi đúng cơ chế mà Live Activity đã dùng: giao keypoint cho roadmap
      // và để nó mở bài khi đã resolve được id.
      //
      // Bài bị khoá/chưa mua thì roadmap tự xử theo gate sẵn có. Deeplink là
      // đường đi, không phải chìa khoá.
      case DeeplinkDestination.lesson:
        final courseId = target.params['courseId']?.trim() ?? '';
        if (courseId.isEmpty) {
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'missing_param');
          return true;
        }

        final keypointId = target.params['keypointId']?.trim() ?? '';
        final roadmapCubit = AppDI.injector.get<CourseRoadmapCubit>();
        if (keypointId.isNotEmpty) roadmapCubit.setPendingResumeKeypointId(keypointId);

        if (!_openCourseRoadmap(navContext, courseId, deeplinkRoadmapSource)) {
          // Không có roadmap để đứng thì cũng không có ai tiêu thụ yêu cầu này.
          roadmapCubit.clearPendingResumeKeypointId();
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'entity_not_found');
        }
        return true;

      case DeeplinkDestination.skillsetCourses:
        final skillsetId = target.params['skillsetId']?.trim() ?? '';
        if (skillsetId.isEmpty) {
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'missing_param');
          return true;
        }
        // Claim branch 1 trước, rồi push trang con: cú push trong branch có
        // didPush nên trang con tự nhận tên của mình qua route observer.
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
        SkillsetCoursesRoute(skillsetId: skillsetId).go(navContext);
        return true;
```

- [ ] **Step 2: analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common
```

Expected: `No issues found!`.

- [ ] **Step 3: Kiểm chứng trên simulator**

Lấy `courseId`, `keypointId`, `skillsetId` thật từ admin trước.

```bash
xcrun simctl openurl booted "hddhistory://open/lesson?courseId=<id>&keypointId=<id>"
xcrun simctl openurl booted "hddhistory://open/lesson?courseId=<id>"
xcrun simctl openurl booted "hddhistory://open/lesson"
xcrun simctl openurl booted "hddhistory://open/skillset-courses?skillsetId=<id>"
xcrun simctl openurl booted "hddhistory://open/skillset-courses"
```

Expected: có keypointId → mở đúng bài; chỉ courseId → dừng ở roadmap; thiếu param → Home. Thử thêm một keypoint **premium** với tài khoản free: phải thấy lock/paywall, **không** được vào bài.

- [ ] **Step 4: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart && \
git commit -m "feat: nối đích deeplink cho lesson theo keypoint và grid skillset"
```

---

### Task 5: Flutter — tám đích lồng dưới tab

**Files:**
- Modify: `hddhistory-flutter/lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart`

**Interfaces:**
- Consumes: `DailyWarmUpRoute`, `HomeLearningStreakRoute`, `DailyCheckInRoute`, `MyLessonsRoute`, `ImportLessonRoute`, `NotificationRoute`, `ChangeLanguageRoute`, `ManageSubscriptionRoute` — tất cả đã tồn tại trong `lib/config/routes/data/`

- [ ] **Step 1: Thêm tám `case`, ngay trước `default:`**

Mỗi đích claim tên của **branch** nó nằm trong trước khi `.go()`; trang con tự nhận tên riêng khi push.

```dart
      case DeeplinkDestination.dailyWarmUp:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        DailyWarmUpRoute().go(navContext);
        return true;

      case DeeplinkDestination.learningStreak:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        HomeLearningStreakRoute().go(navContext);
        return true;

      case DeeplinkDestination.dailyCheckIn:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
        DailyCheckInRoute().go(navContext);
        return true;

      case DeeplinkDestination.myLessons:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        MyLessonsRoute().go(navContext);
        return true;

      // ImportLessonRoute khai trong routes_shell_setting_data.dart nhưng LẮP
      // dưới branch Explore (xem routes_shell.dart) — nên claim tên Explore,
      // không phải Profile.
      case DeeplinkDestination.importLesson:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.course);
        ImportLessonRoute().go(navContext);
        return true;

      case DeeplinkDestination.notificationSetting:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        NotificationRoute().go(navContext);
        return true;

      case DeeplinkDestination.changeLanguage:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ChangeLanguageRoute().go(navContext);
        return true;

      case DeeplinkDestination.manageSubscription:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ManageSubscriptionRoute().go(navContext);
        return true;
```

- [ ] **Step 2: Xoá nhánh `default:`**

Sau task này cả 16 khoá đã có `case`, nên `default:` thành code chết và nó che mất lỗi thiếu case của khoá thêm sau. Xoá đi để analyzer tự bắt: thêm một giá trị vào enum mà quên `case` sẽ thành lỗi biên dịch ngay.

- [ ] **Step 3: analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common
```

Expected: `No issues found!`. Nếu báo `switch` không exhaustive thì đúng là còn thiếu `case` — thêm cho đủ 16, đừng thêm `default:` lại.

- [ ] **Step 4: Kiểm chứng trên simulator — cả tám**

```bash
for key in daily-warm-up learning-streak daily-check-in my-lessons import-lesson notification-setting change-language manage-subscription; do
  echo "== $key"; xcrun simctl openurl booted "hddhistory://open/$key"; sleep 3
done
```

Expected: từng màn mở đúng, và khi back ra thì về đúng tab cha của nó (Home / Habit / Explore / Profile).

- [ ] **Step 5: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart && \
git commit -m "feat: nối tám đích deeplink lồng dưới tab và bỏ nhánh default"
```

---

### Task 6: Flutter — giữ link lại khi chưa qua onboarding, replay sau

Task 2 đã trả `false` khi chưa qua onboarding, nhưng `handleRoute()` **reset** state ở cuối nên link bị mất. Task này giữ nó lại và chạy lại khi người dùng vào được app.

**Files:**
- Modify: `hddhistory-flutter/lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart`

**Interfaces:**
- Consumes: `UserCubit` (qua `AppDI.injector`), `_shouldDeferForOnboarding()` (Task 2)
- Produces: field `StreamSubscription<UserState>? _onboardingExitSubscription`; `void _ensureOnboardingWatch()`

- [ ] **Step 1: Thêm field và subscription**

Cạnh `_notificationInteractionSubscription` (dòng 11):

```dart
  StreamSubscription<UserState>? _onboardingExitSubscription;
```

- [ ] **Step 2: Không reset khi đang hoãn**

Trong `handleRoute()`, đổi phần cuối. Hiện tại:

```dart
    if (!isHandled) {
      LogDev.warning('Ignoring unsupported deeplink route: $_serviceRoutePath');
    }
    resetServiceRouteData();
    return isHandled;
```

Thành:

```dart
    if (!isHandled) {
      LogDev.warning('Ignoring unsupported deeplink route: $_serviceRoutePath');
    }
    // Chưa qua onboarding thì GIỮ link lại và chạy lại khi vào được app. Đây là
    // lần duy nhất không reset: mọi lối ra khác đều đã dùng xong hoặc đã bỏ link.
    if (!isHandled && _pendingTarget != null && _shouldDeferForOnboarding()) {
      _ensureOnboardingWatch();
      return false;
    }
    resetServiceRouteData();
    return isHandled;
```

- [ ] **Step 3: Thêm watcher**

Đặt ngay dưới `_shouldDeferForOnboarding()`:

```dart
  /// Lắng `UserCubit` để chạy lại link đang treo ngay khi người dùng qua được
  /// onboarding/đăng nhập.
  ///
  /// Đăng ký LÚC CẦN chứ không trong `init()`: `DeeplinkCubit` được dựng rất
  /// sớm và việc resolve `UserCubit` ngay trong constructor là một thứ tự khởi
  /// tạo không cần phải đánh cược. Không có link treo thì cũng chẳng có gì để
  /// lắng.
  void _ensureOnboardingWatch() {
    if (_onboardingExitSubscription != null) return;
    try {
      _onboardingExitSubscription = AppDI.injector.get<UserCubit>().stream.listen(
        (_) {
          if (_pendingTarget == null || _shouldDeferForOnboarding()) return;
          unawaited(_onboardingExitSubscription?.cancel());
          _onboardingExitSubscription = null;
          LogDev.info('Replaying deferred deeplink: ${_pendingTarget?.rawKey}');
          handleRoute();
        },
        onError: (error, stackTrace) => LogDev.one('onboardingExit error: $error, stackTrace: $stackTrace'),
      );
    } catch (error) {
      LogDev.warning('Could not watch onboarding exit for deferred deeplink: $error');
    }
  }
```

- [ ] **Step 4: Huỷ subscription trong `close()`**

Trong `close()`, thêm trước `return super.close();`:

```dart
    await _onboardingExitSubscription?.cancel();
```

- [ ] **Step 5: test + analyze**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
/Users/nguyenvietha/development/flutter/bin/flutter test test/unit/common/presentation/cubits/deeplink_cubit_test.dart && \
/Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/common
```

Expected: PASS + `No issues found!`.

- [ ] **Step 6: Kiểm chứng trên simulator — đây là ca hồi quy quan trọng nhất của cả plan**

1. Xoá app khỏi simulator, cài lại (máy mới, chưa onboard).
2. `xcrun simctl openurl booted "hddhistory://open/paywall"` — app phải mở vào **onboarding**, KHÔNG nhảy vào paywall.
3. Đi hết onboarding cho tới khi vào app.
4. Paywall phải tự mở ngay lúc đó (link treo được replay).
5. Rồi kiểm chứng lại đường cũ không hỏng: với tài khoản đã onboard, `hddhistory://open/paywall` mở paywall ngay.

Theo yêu cầu, chạy lại app đầy đủ sau mỗi thay đổi code thay vì hot reload.

- [ ] **Step 7: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
git add lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart && \
git commit -m "feat: giữ deeplink lại khi chưa qua onboarding và chạy lại sau khi vào app"
```

---

### Task 7: API — module `deeplink` phục vụ danh mục đích

**Files:**
- Create: `hddhistory-api/src/modules/deeplink/deeplink.catalog.ts`
- Create: `hddhistory-api/src/modules/deeplink/deeplink.controller.ts`
- Create: `hddhistory-api/src/modules/deeplink/deeplink.module.ts`
- Modify: `hddhistory-api/src/app.module.ts` (thêm `DeeplinkModule` vào `imports`, cạnh `DownloadLinkModule` ở dòng 61)
- Test: `hddhistory-api/src/modules/deeplink/deeplink.catalog.spec.ts`

**Interfaces:**
- Produces:
  - `enum DeeplinkParamPicker { COURSE='course', SKILLSET='skillset', KEYPOINT='keypoint', SELECT='select', TEXT='text' }`
  - `interface DeeplinkParamDef { name: string; required: boolean; picker: DeeplinkParamPicker; options?: string[] }`
  - `interface DeeplinkDestinationDef { key: string; label: string; group: string; minAppBuild: number; note?: string; params: DeeplinkParamDef[] }`
  - `const DEEPLINK_DESTINATIONS: DeeplinkDestinationDef[]` — 16 phần tử
  - `GET /api/v1/deeplink/destinations` → `DeeplinkDestinationDef[]`

- [ ] **Step 1: Viết test thất bại**

Tạo `hddhistory-api/src/modules/deeplink/deeplink.catalog.spec.ts`:

```ts
import {
  DEEPLINK_DESTINATIONS,
  DeeplinkParamPicker,
} from './deeplink.catalog';

/**
 * Danh mục này là hợp đồng giữa 3 stack: enum trong Flutter, dropdown trong
 * admin, và validate của giai đoạn 2. Một khoá gõ sai ở đây sinh ra link chết
 * mà không có gì báo lỗi, nên nó xứng đáng có test riêng.
 */
describe('DEEPLINK_DESTINATIONS', () => {
  const EXPECTED_KEYS = [
    'home',
    'explore',
    'habit',
    'profile',
    'course-roadmap',
    'lesson',
    'skillset-courses',
    'paywall',
    'manage-subscription',
    'daily-warm-up',
    'learning-streak',
    'daily-check-in',
    'my-lessons',
    'import-lesson',
    'notification-setting',
    'change-language',
  ];

  it('khai đúng 16 khoá, không trùng', () => {
    const keys = DEEPLINK_DESTINATIONS.map((d) => d.key);
    expect(keys).toHaveLength(16);
    expect(new Set(keys).size).toBe(16);
  });

  it('khớp từng ký tự với enum DeeplinkDestination bên Flutter', () => {
    expect(DEEPLINK_DESTINATIONS.map((d) => d.key).sort()).toEqual(
      [...EXPECTED_KEYS].sort(),
    );
  });

  it('mọi đích đều có label, group và minAppBuild', () => {
    for (const destination of DEEPLINK_DESTINATIONS) {
      expect(destination.label.trim().length).toBeGreaterThan(0);
      expect(destination.group.trim().length).toBeGreaterThan(0);
      expect(destination.minAppBuild).toBeGreaterThan(0);
    }
  });

  it('param dạng select luôn mang sẵn options', () => {
    const selects = DEEPLINK_DESTINATIONS.flatMap((d) => d.params).filter(
      (p) => p.picker === DeeplinkParamPicker.SELECT,
    );

    expect(selects.length).toBeGreaterThan(0);
    for (const param of selects) {
      expect(param.options?.length).toBeGreaterThan(0);
    }
  });

  it('lesson cần courseId và nhận keypointId tuỳ chọn', () => {
    const lesson = DEEPLINK_DESTINATIONS.find((d) => d.key === 'lesson');
    const courseId = lesson?.params.find((p) => p.name === 'courseId');
    const keypointId = lesson?.params.find((p) => p.name === 'keypointId');

    expect(courseId?.required).toBe(true);
    expect(keypointId?.required).toBe(false);
  });
});
```

- [ ] **Step 2: Chạy test để chắc chắn FAIL**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && npm test -- src/modules/deeplink/deeplink.catalog.spec.ts
```

Expected: FAIL — không tìm thấy module `./deeplink.catalog`.

- [ ] **Step 3: Viết danh mục**

Tạo `hddhistory-api/src/modules/deeplink/deeplink.catalog.ts`:

```ts
/**
 * Danh mục màn mà một link `https://meup.training/open/<key>` có thể dẫn tới.
 *
 * Một HẰNG SỐ phục vụ qua HTTP: không entity, không repository, không migration.
 * Đặt ở API chứ không hardcode trong admin vì API được deploy dày hơn admin
 * nhiều -- thêm một màn không phải chờ release admin -- và vì giai đoạn 2 (đích
 * cho `/r/<slug>`) sẽ validate bằng đúng danh mục này. Một nguồn sự thật.
 *
 * `key` là hợp đồng công khai: nó nằm trong link đã gửi push, đã in QR. Phải
 * khớp TỪNG KÝ TỰ với `enum DeeplinkDestination` bên hddhistory-flutter. Thêm khoá
 * thì được; đổi hoặc xoá khoá cũ là làm chết link đã phát ra.
 */
export enum DeeplinkParamPicker {
  COURSE = 'course',
  SKILLSET = 'skillset',
  KEYPOINT = 'keypoint',
  SELECT = 'select',
  TEXT = 'text',
}

export interface DeeplinkParamDef {
  name: string;
  required: boolean;
  picker: DeeplinkParamPicker;
  /** Chỉ có với picker SELECT. */
  options?: string[];
}

export interface DeeplinkDestinationDef {
  key: string;
  label: string;
  group: string;
  /**
   * Build number nhỏ nhất của app hiểu được khoá này.
   *
   * Không phải trang trí: thiếu nó thì marketer gửi link tới màn mới cho phần
   * lớn người đang dùng bản cũ, tất cả rơi về Home, và không ai hiểu tại sao.
   * `home` và `paywall` đã chạy từ 1.5.2+129; mọi khoá còn lại cần bản 130.
   */
  minAppBuild: number;
  note?: string;
  params: DeeplinkParamDef[];
}

const NO_PARAMS: DeeplinkParamDef[] = [];

export const DEEPLINK_DESTINATIONS: DeeplinkDestinationDef[] = [
  { key: 'home', label: 'Trang chủ', group: 'Tab', minAppBuild: 129, params: NO_PARAMS },
  { key: 'explore', label: 'Khám phá', group: 'Tab', minAppBuild: 130, params: NO_PARAMS },
  { key: 'habit', label: 'Thói quen', group: 'Tab', minAppBuild: 130, params: NO_PARAMS },
  { key: 'profile', label: 'Trang cá nhân', group: 'Tab', minAppBuild: 130, params: NO_PARAMS },
  {
    key: 'course-roadmap',
    label: 'Lộ trình khoá học',
    group: 'Học',
    minAppBuild: 130,
    note: 'Không chọn khoá học thì mở lộ trình của khoá người dùng đang học.',
    params: [{ name: 'courseId', required: false, picker: DeeplinkParamPicker.COURSE }],
  },
  {
    key: 'lesson',
    label: 'Bài học cụ thể',
    group: 'Học',
    minAppBuild: 130,
    note: 'Đi qua lộ trình rồi mở bài. Bài premium vẫn hiện khoá/paywall như bình thường.',
    params: [
      { name: 'courseId', required: true, picker: DeeplinkParamPicker.COURSE },
      { name: 'keypointId', required: false, picker: DeeplinkParamPicker.KEYPOINT },
    ],
  },
  {
    key: 'skillset-courses',
    label: 'Tất cả khoá của một kỹ năng',
    group: 'Học',
    minAppBuild: 130,
    params: [{ name: 'skillsetId', required: true, picker: DeeplinkParamPicker.SKILLSET }],
  },
  {
    key: 'paywall',
    label: 'Màn mua gói',
    group: 'Tiền',
    minAppBuild: 129,
    note: 'Không chọn biến thể thì dùng bảng entry-point trong Cấu hình paywall.',
    params: [
      {
        name: 'variant',
        required: false,
        picker: DeeplinkParamPicker.SELECT,
        options: ['full', 'compact'],
      },
    ],
  },
  { key: 'manage-subscription', label: 'Quản lý gói đăng ký', group: 'Tiền', minAppBuild: 130, params: NO_PARAMS },
  { key: 'daily-warm-up', label: 'Khởi động mỗi ngày', group: 'Engagement', minAppBuild: 130, params: NO_PARAMS },
  { key: 'learning-streak', label: 'Chuỗi ngày học', group: 'Engagement', minAppBuild: 130, params: NO_PARAMS },
  { key: 'daily-check-in', label: 'Điểm danh thói quen', group: 'Engagement', minAppBuild: 130, params: NO_PARAMS },
  { key: 'my-lessons', label: 'Bài của tôi', group: 'Nội dung riêng', minAppBuild: 130, params: NO_PARAMS },
  { key: 'import-lesson', label: 'Tạo bài học từ tài liệu', group: 'Nội dung riêng', minAppBuild: 130, params: NO_PARAMS },
  { key: 'notification-setting', label: 'Cài đặt thông báo', group: 'Cài đặt', minAppBuild: 130, params: NO_PARAMS },
  { key: 'change-language', label: 'Đổi ngôn ngữ', group: 'Cài đặt', minAppBuild: 130, params: NO_PARAMS },
];
```

- [ ] **Step 4: Chạy test để chắc chắn PASS**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && npm test -- src/modules/deeplink/deeplink.catalog.spec.ts
```

Expected: PASS, 5 test.

- [ ] **Step 5: Thêm controller và module**

Tạo `hddhistory-api/src/modules/deeplink/deeplink.controller.ts`:

```ts
import { Controller, Get, Header, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  DEEPLINK_DESTINATIONS,
  DeeplinkDestinationDef,
} from './deeplink.catalog';

/**
 * Danh mục màn cho trang "Link vào màn" của admin.
 *
 * Không dựng URL ở đây: admin dựng, giống `buildDownloadLinkUrl` -- entitlement
 * iOS là `applinks:meup.training` không wildcard, nên chỉ có một host được phép
 * xuất hiện và nó thuộc về phía client dựng link.
 */
@ApiTags('DEEPLINK')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'deeplink', version: '1' })
export class DeeplinkController {
  // Hằng số, nên cache được. 5 phút: thêm một màn thì admin thấy trong vòng
  // một lần refresh, mà không phải mỗi lần mở trang một request.
  @Get('destinations')
  @Header('Cache-Control', 'private, max-age=300')
  getDestinations(): DeeplinkDestinationDef[] {
    return DEEPLINK_DESTINATIONS;
  }
}
```

Tạo `hddhistory-api/src/modules/deeplink/deeplink.module.ts`:

```ts
import { forwardRef, Module } from '@nestjs/common';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { DeeplinkController } from './deeplink.controller';

/**
 * `forwardRef(() => AuthModule)` là BẮT BUỘC, không phải phong cách:
 * `@UseGuards(AuthGuard)` trong một module chưa import AuthModule làm app
 * crash-loop lúc boot, và cả `tsc --noEmit` lẫn `nest build` đều không thấy.
 * Cùng khuôn với `streak-config.module.ts`.
 */
@Module({
  imports: [forwardRef(() => AuthModule)],
  controllers: [DeeplinkController],
})
export class DeeplinkModule {}
```

Trong `hddhistory-api/src/app.module.ts`: thêm `import { DeeplinkModule } from './modules/deeplink/deeplink.module';` theo đúng nhóm import của ESLint, và thêm `DeeplinkModule,` vào `imports` ngay sau `DownloadLinkModule,`.

- [ ] **Step 6: Type-check và boot thật**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && npx tsc --noEmit
```

Expected: không lỗi.

Rồi **phải boot thật** — đây là cách duy nhất phát hiện lỗi DI của guard:

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && npm run start:dev
```

Expected: log có `DeeplinkController {/api/v1/deeplink}` và route `destinations`. Không có `UnknownDependenciesException`. Rồi:

```bash
curl -s -i "http://localhost:4000/api/v1/deeplink/destinations" | head -5
curl -s "http://localhost:4000/api/v1/deeplink/destinations" -H "Authorization: Bearer <token-admin>" | head -40
```

Expected: không token → 401; có token → JSON 16 phần tử.

- [ ] **Step 7: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && \
git add src/modules/deeplink src/app.module.ts && \
git commit -m "feat: thêm endpoint danh mục đích deeplink cho admin"
```

---

### Task 8: Admin — types, service, và hàm dựng URL (có test)

**Files:**
- Create: `hddhistory-admin/src/types/interface/deeplink.interface.ts`
- Create: `hddhistory-admin/src/services/deeplinkService.ts`
- Create: `hddhistory-admin/src/utils/deeplinkUrl.ts`
- Test: `hddhistory-admin/src/utils/deeplinkUrl.test.ts`

**Interfaces:**
- Consumes: `GET /api/v1/deeplink/destinations` (Task 7); `axiosClient` từ `src/services/axiosClient`
- Produces:
  - `type DeeplinkParamPicker = "course" | "skillset" | "keypoint" | "select" | "text"`
  - `interface IDeeplinkParam { name: string; required: boolean; picker: DeeplinkParamPicker; options?: string[] }`
  - `interface IDeeplinkDestination { key: string; label: string; group: string; minAppBuild: number; note?: string; params: IDeeplinkParam[] }`
  - `deeplinkService.getDestinations(): Promise<IDeeplinkDestination[]>`
  - `DEEPLINK_WEB_BASE`, `DEEPLINK_APP_BASE`, `buildDeeplinkUrl(base: string, key: string, params: Record<string, string>, campaign?: string): string`

- [ ] **Step 1: Viết test thất bại**

Tạo `hddhistory-admin/src/utils/deeplinkUrl.test.ts`:

```ts
import {
  DEEPLINK_APP_BASE,
  DEEPLINK_WEB_BASE,
  buildDeeplinkUrl,
} from "./deeplinkUrl";

describe("buildDeeplinkUrl", () => {
  it("dựng link web cho màn không tham số", () => {
    expect(buildDeeplinkUrl(DEEPLINK_WEB_BASE, "habit", {})).toBe(
      "https://meup.training/open/habit"
    );
  });

  it("dựng link trong app cùng một khoá", () => {
    expect(buildDeeplinkUrl(DEEPLINK_APP_BASE, "habit", {})).toBe(
      "hddhistory://open/habit"
    );
  });

  it("gắn tham số và nhãn campaign", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "paywall", { variant: "full" }, "tet-2027")
    ).toBe("https://meup.training/open/paywall?variant=full&c=tet-2027");
  });

  it("bỏ tham số rỗng thay vì gửi khoá trống", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "course-roadmap", { courseId: "  " })
    ).toBe("https://meup.training/open/course-roadmap");
  });

  it("encode giá trị có ký tự đặc biệt", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "paywall", {}, "hè & thu")
    ).toBe("https://meup.training/open/paywall?c=h%C3%A8%20%26%20thu");
  });
});
```

- [ ] **Step 2: Chạy test để chắc chắn FAIL**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && CI=true npx react-scripts test --testPathPattern deeplinkUrl --watchAll=false
```

Expected: FAIL — không tìm thấy `./deeplinkUrl`.

- [ ] **Step 3: Viết implementation**

Tạo `hddhistory-admin/src/utils/deeplinkUrl.ts`:

```ts
/**
 * Link vào màn được dựng ở phía client, không phải do API trả về -- cùng lý do
 * đã ghi trong `downloadLinkService`: entitlement iOS là `applinks:meup.training`
 * không wildcard, nên admin không được phép hiện một host mà app chưa claim.
 */
export const DEEPLINK_WEB_BASE = "https://meup.training/open";
export const DEEPLINK_APP_BASE = "hddhistory://open";

/** Nhãn campaign. Chỉ đi vào event tracking; app không đọc để điều hướng. */
export const DEEPLINK_CAMPAIGN_KEY = "c";

export const buildDeeplinkUrl = (
  base: string,
  key: string,
  params: Record<string, string>,
  campaign?: string
): string => {
  const query = new URLSearchParams();

  Object.entries(params).forEach(([name, value]) => {
    const trimmed = (value ?? "").trim();
    // Một khoá rỗng trong link đọc như "có truyền nhưng bỏ trống", và app sẽ
    // coi đó là thiếu tham số. Bỏ hẳn đi thì đúng nghĩa "không truyền".
    if (trimmed) query.set(name, trimmed);
  });

  const trimmedCampaign = (campaign ?? "").trim();
  if (trimmedCampaign) query.set(DEEPLINK_CAMPAIGN_KEY, trimmedCampaign);

  const suffix = query.toString();
  // URLSearchParams encode dấu cách thành '+', đúng cho form nhưng không phải
  // cho một URL sẽ được dán vào push và chat -- '%20' đi qua mọi chỗ đó lành.
  const normalized = suffix.replace(/\+/g, "%20");

  return normalized ? `${base}/${key}?${normalized}` : `${base}/${key}`;
};
```

Tạo `hddhistory-admin/src/types/interface/deeplink.interface.ts`:

```ts
/** Picker mà admin render cho một tham số. Khớp `DeeplinkParamPicker` ở API. */
export type DeeplinkParamPicker =
  | "course"
  | "skillset"
  | "keypoint"
  | "select"
  | "text";

export interface IDeeplinkParam {
  name: string;
  required: boolean;
  picker: DeeplinkParamPicker;
  /** Chỉ có với picker "select". */
  options?: string[];
}

export interface IDeeplinkDestination {
  key: string;
  label: string;
  group: string;
  /** Build app nhỏ nhất hiểu được khoá này — hiện dưới dạng chú thích. */
  minAppBuild: number;
  note?: string;
  params: IDeeplinkParam[];
}
```

Tạo `hddhistory-admin/src/services/deeplinkService.ts`:

```ts
import { IDeeplinkDestination } from "../types/interface/deeplink.interface";
import axiosClient from "./axiosClient";

export const deeplinkService = {
  async getDestinations(): Promise<IDeeplinkDestination[]> {
    const res = await axiosClient.get("/deeplink/destinations");
    return res.data;
  },
};
```

- [ ] **Step 4: Chạy test + type-check**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && \
CI=true npx react-scripts test --testPathPattern deeplinkUrl --watchAll=false && \
npx tsc --noEmit
```

Expected: 5 test PASS, tsc không lỗi.

- [ ] **Step 5: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && \
git add src/utils/deeplinkUrl.ts src/utils/deeplinkUrl.test.ts src/types/interface/deeplink.interface.ts src/services/deeplinkService.ts && \
git commit -m "feat: thêm service danh mục đích và hàm dựng link vào màn"
```

---

### Task 9: Admin — trang "Link vào màn"

**Files:**
- Create: `hddhistory-admin/src/pages/deeplinks/DeeplinkGenerator.tsx`
- Modify: `hddhistory-admin/src/routes/index.tsx` (thêm import + `<Route path="deeplinks" .../>` cạnh `download-links` ở dòng 96)
- Modify: `hddhistory-admin/src/components/layout/Sidebar.tsx` (thêm một item vào nhóm `Operations`, ngay dưới `"Link tải app"`)

**Interfaces:**
- Consumes: `deeplinkService.getDestinations()`, `buildDeeplinkUrl`, `DEEPLINK_WEB_BASE`, `DEEPLINK_APP_BASE`, `IDeeplinkDestination`, `IDeeplinkParam` (Task 8); `courseService.getList({ isAll: true })`, `courseService.getRoadmap(courseId)`, `skillsetService.getList()`, `lessonService.getById(lessonId)`

**Hình dạng dữ liệu cho picker — đã xác minh từng cái trong repo, dùng đúng như đây:**

| Nguồn | Gọi | Lấy dữ liệu ra | Field |
|---|---|---|---|
| Course | `courseService.getList({ isAll: true, take: 1000 })` | `response.data.items` | `ICourse._id`, `title: ITranslation` |
| Skillset | `skillsetService.getList({ isAll: true, take: 1000 })` | `response.data.items` | `ISkillset._id`, `title: ITranslation` |
| Lesson | `courseService.getRoadmap(courseId)` | `res.data?.data \|\| res.data` → `IRoadmap` | `levels[].nodes[].lessons?: ILessonBrief[]`, `ILessonBrief._id` |
| Keypoint | `lessonService.getById(lessonId)` | `res.data?.data ?? res.data` | `keypoints: IKeypoint[]`, `IKeypoint._id` |

`ITranslation { en?, vi?, zh?, ja?, ko? }` — **không có helper nào trong repo**, hiện tên bằng `title.vi || title.en || "(chưa có tên)"`.

Picker `keypoint` vì thế là chuỗi 3 bước: chọn course → nạp roadmap → chọn lesson (phẳng hoá `levels[].nodes[].lessons`) → nạp lesson → chọn keypoint. **Chỉ `keypointId` đi vào URL**; `lessonId` là state trung gian, không phải tham số của link.

- [ ] **Step 1: Viết phần logic của trang**

Tạo `hddhistory-admin/src/pages/deeplinks/DeeplinkGenerator.tsx`. Đây là phần logic — đúng chỗ dễ sai. Phần trình bày (MUI + Tailwind) theo khuôn `src/pages/home-popup/HomePopupPage.tsx`; **đọc file đó trước khi viết JSX**.

```tsx
import { useCallback, useEffect, useMemo, useState } from "react";

import { courseService } from "../../services/courseService";
import { deeplinkService } from "../../services/deeplinkService";
import { lessonService } from "../../services/lessonService";
import { skillsetService } from "../../services/skillsetService";
import {
  IDeeplinkDestination,
  IDeeplinkParam,
} from "../../types/interface/deeplink.interface";
import { IRoadmap } from "../../types/interface/course.interface";
import { ITranslation } from "../../utils/translate";
import {
  DEEPLINK_APP_BASE,
  DEEPLINK_WEB_BASE,
  buildDeeplinkUrl,
} from "../../utils/deeplinkUrl";

interface Option {
  id: string;
  label: string;
}

const labelOf = (title?: ITranslation): string =>
  title?.vi || title?.en || "(chưa có tên)";

export default function DeeplinkGenerator() {
  const [destinations, setDestinations] = useState<IDeeplinkDestination[]>([]);
  const [isLoadingCatalog, setIsLoadingCatalog] = useState(true);
  const [catalogError, setCatalogError] = useState("");

  const [selectedKey, setSelectedKey] = useState("");
  const [paramValues, setParamValues] = useState<Record<string, string>>({});
  const [campaign, setCampaign] = useState("");

  const [courses, setCourses] = useState<Option[]>([]);
  const [skillsets, setSkillsets] = useState<Option[]>([]);
  const [lessons, setLessons] = useState<Option[]>([]);
  const [keypoints, setKeypoints] = useState<Option[]>([]);
  // Bước trung gian của picker keypoint. KHÔNG phải tham số của link.
  const [lessonId, setLessonId] = useState("");

  const loadCatalog = useCallback(async () => {
    setIsLoadingCatalog(true);
    setCatalogError("");
    try {
      setDestinations(await deeplinkService.getDestinations());
    } catch (error) {
      console.error("Failed to load deeplink destinations", error);
      setCatalogError("Không tải được danh mục màn. Thử lại nhé.");
    } finally {
      setIsLoadingCatalog(false);
    }
  }, []);

  useEffect(() => {
    loadCatalog();
  }, [loadCatalog]);

  const selected = useMemo(
    () => destinations.find((destination) => destination.key === selectedKey),
    [destinations, selectedKey]
  );

  // Đổi màn thì xoá hết giá trị cũ: giữ lại một courseId của màn trước sẽ sinh
  // ra link trông hợp lệ mà trỏ vào tham số của màn khác.
  const handleSelectDestination = (key: string) => {
    setSelectedKey(key);
    setParamValues({});
    setLessonId("");
    setLessons([]);
    setKeypoints([]);
  };

  const needsPicker = useCallback(
    (picker: IDeeplinkParam["picker"]) =>
      selected?.params.some((param) => param.picker === picker) ?? false,
    [selected]
  );

  useEffect(() => {
    if (!needsPicker("course") && !needsPicker("keypoint")) return;
    let isActive = true;
    (async () => {
      try {
        const response = await courseService.getList({ isAll: true, take: 1000 });
        if (!isActive) return;
        setCourses(
          (response.data.items ?? []).map((course: any) => ({
            id: course._id,
            label: labelOf(course.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load courses", error);
      }
    })();
    return () => {
      isActive = false;
    };
  }, [needsPicker]);

  useEffect(() => {
    if (!needsPicker("skillset")) return;
    let isActive = true;
    (async () => {
      try {
        const response = await skillsetService.getList({ isAll: true, take: 1000 });
        if (!isActive) return;
        setSkillsets(
          (response.data.items ?? []).map((skillset: any) => ({
            id: skillset._id,
            label: labelOf(skillset.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load skillsets", error);
      }
    })();
    return () => {
      isActive = false;
    };
  }, [needsPicker]);

  // Course đổi -> nạp lại danh sách bài từ roadmap, và bỏ keypoint đã chọn:
  // keypoint của course cũ không còn nghĩa gì ở course mới.
  const courseId = paramValues.courseId ?? "";
  useEffect(() => {
    if (!needsPicker("keypoint") || !courseId) {
      setLessons([]);
      return;
    }
    let isActive = true;
    (async () => {
      try {
        const res = await courseService.getRoadmap(courseId);
        const roadmap: IRoadmap = res.data?.data || res.data;
        if (!isActive) return;
        const flattened = (roadmap?.levels ?? []).flatMap((level) =>
          (level.nodes ?? []).flatMap((node) =>
            (node.lessons ?? []).map((lesson) => ({
              id: lesson._id,
              label: labelOf(lesson.title),
            }))
          )
        );
        setLessons(flattened);
      } catch (error) {
        console.error("Failed to load roadmap lessons", error);
        setLessons([]);
      }
    })();
    setLessonId("");
    setKeypoints([]);
    setParamValues((previous) => ({ ...previous, keypointId: "" }));
    return () => {
      isActive = false;
    };
  }, [courseId, needsPicker]);

  useEffect(() => {
    if (!lessonId) {
      setKeypoints([]);
      return;
    }
    let isActive = true;
    (async () => {
      try {
        const res = await lessonService.getById(lessonId);
        const lesson = res.data?.data ?? res.data;
        if (!isActive) return;
        setKeypoints(
          (lesson?.keypoints ?? []).map((keypoint: any) => ({
            id: keypoint._id,
            label: labelOf(keypoint.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load keypoints", error);
        setKeypoints([]);
      }
    })();
    return () => {
      isActive = false;
    };
  }, [lessonId]);

  const missingRequired = useMemo(
    () =>
      (selected?.params ?? []).filter(
        (param) => param.required && !(paramValues[param.name] ?? "").trim()
      ),
    [selected, paramValues]
  );

  const canCopy = Boolean(selected) && missingRequired.length === 0;

  const webUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_WEB_BASE, selected.key, paramValues, campaign)
    : "";
  const appUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_APP_BASE, selected.key, paramValues, campaign)
    : "";

  const groups = useMemo(() => {
    const byGroup = new Map<string, IDeeplinkDestination[]>();
    destinations.forEach((destination) => {
      byGroup.set(destination.group, [
        ...(byGroup.get(destination.group) ?? []),
        destination,
      ]);
    });
    return [...byGroup.entries()];
  }, [destinations]);

  const quickPicks = useMemo(
    () => destinations.filter((destination) => destination.params.length === 0),
    [destinations]
  );

  const copy = async (value: string) => {
    await navigator.clipboard.writeText(value);
  };

  // ... JSX theo khuôn HomePopupPage.tsx, xem yêu cầu bên dưới
}
```

- [ ] **Step 2: Viết JSX — những thứ sau là bắt buộc, không phải gợi ý**

1. **Bảng "Màn phổ biến"** ở trên cùng, đổ từ `quickPicks` — mỗi dòng: `label`, `key` dạng mono, và nút Copy link web. Đây là ca dùng thường gặp nhất và nó không được bắt ai mở form nào. (Đúng phần "GIẢI PHÁP NGẮN HẠN" trong sheet gốc.)
2. **Form sinh link** ở dưới: `Select` chọn màn với option group theo `groups` → form param dựng động theo `param.picker` (`course`/`skillset` → Select từ `courses`/`skillsets`; `keypoint` → hai Select nối tiếp `lessons` rồi `keypoints`, chỉ `keypointId` ghi vào `paramValues`; `select` → Select từ `param.options`; `text` → TextField) → TextField nhãn campaign → **hai** TextField read-only kèm nút Copy: `webUrl` và `appUrl`.
3. **Chú thích `minAppBuild`** của màn đang chọn, nguyên văn: `Chỉ hoạt động trên bản app build ≥ {selected.minAppBuild}. Người dùng bản cũ hơn sẽ về Trang chủ.`
4. Hiện `selected.note` khi có.
5. **Trạng thái không được bỏ:** `isLoadingCatalog` (spinner/skeleton) · `catalogError` (kèm nút Thử lại gọi `loadCatalog`) · chưa chọn màn (empty state) · `missingRequired` không rỗng (**disable cả hai nút Copy** + `helperText` "Bắt buộc" tại đúng ô thiếu) · picker rỗng (ví dụ course chưa có bài nào → "Khoá học này chưa có bài học").
6. `aria-label` cho mọi icon button; nút Copy hiện xác nhận đã copy (Snackbar hoặc đổi icon).

- [ ] **Step 3: Đăng ký route**

Trong `hddhistory-admin/src/routes/index.tsx`: thêm `import DeeplinkGenerator from "../pages/deeplinks/DeeplinkGenerator";` cạnh import `DownloadLinkList` (dòng 37), và thêm trong cùng `ProtectedRoute` với `download-links`:

```tsx
              <Route path="deeplinks" element={<DeeplinkGenerator />} />
```

- [ ] **Step 4: Thêm vào sidebar**

Trong `hddhistory-admin/src/components/layout/Sidebar.tsx`, nhóm `Operations`, ngay **dưới** dòng `"Link tải app"`:

```tsx
      { name: "Link vào màn", icon: LinkIcon, path: "/deeplinks" },
```

Đặt cạnh nhau là có chủ đích: hai việc khác nhau (link tải app vs link vào màn) mà tên gần nhau thì marketer thấy được sự khác biệt ngay tại chỗ chọn.

- [ ] **Step 5: Type-check và chạy thử**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && npx tsc --noEmit
```

Expected: không lỗi.

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && npm start
```

Mở `http://localhost:3000/deeplinks` và kiểm:
- bảng màn phổ biến hiện đủ các màn không tham số, Copy ra đúng `https://meup.training/open/<key>`
- chọn `paywall` → select variant có `full`/`compact`
- chọn `lesson` → chuỗi course → lesson → keypoint chạy đúng, URL ra `?courseId=…&keypointId=…`
- bỏ trống param bắt buộc → hai nút Copy bị disable
- tắt API (Ctrl-C dev server của hddhistory-api) rồi refresh → hiện trạng thái lỗi kèm Thử lại, không trắng trang

- [ ] **Step 6: Kiểm chứng đầu-cuối, cả hai dạng link**

Copy một link web từ trang admin, dán vào Notes trên simulator rồi bấm. Copy link `hddhistory://` và:

```bash
xcrun simctl openurl booted "<link hddhistory:// vừa copy>"
```

Expected: cả hai mở đúng màn. Đây là lần đầu tiên toàn chuỗi admin → app được đi thật.

- [ ] **Step 7: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin && \
git add src/pages/deeplinks/DeeplinkGenerator.tsx src/routes/index.tsx src/components/layout/Sidebar.tsx && \
git commit -m "feat: thêm trang admin sinh link vào từng màn của app"
```

---

### Task 10: web-download-link — thử `hddhistory://` trong webview trước khi ra store

**Files:**
- Modify: `web-download-link/index.html` (inline script ở đầu `<head>`, dòng 11-32)

**Interfaces:**
- Consumes: `DeeplinkTarget.pathPrefix` = `open` (hợp đồng URL, không phải import)

Không sửa `nginx.conf.template`: catch-all `try_files $uri /index.html` đã phục vụ `/open/<key>` rồi. **Đừng thêm `location` nào chen trước hai block `location =` của `.well-known`** — làm thế là làm chết Universal Link mà không có gì báo lỗi.

- [ ] **Step 1: Sửa inline script**

Trong `web-download-link/index.html`, thay phần từ `var target = isIOS ...` tới `if (target) window.location.replace(target);` (dòng 27-30) bằng:

```javascript
  // Link vào màn (/open/<key>) khác link tải: người bấm nó CÓ THỂ đã cài app.
  // Trong webview Zalo/Facebook, Universal Link thường không nổ, nên trang này
  // chính là chỗ người đã cài app rơi vào -- đẩy họ ra store là sai đích.
  //
  // Chỉ thử scheme TRONG webview là có chủ đích: ở Safari thật thì Universal
  // Link CÓ nổ, nên đến được đây nghĩa là app chưa cài, và thử scheme ở đó chỉ
  // đổi lấy hộp thoại "Safari cannot open the page" cho đúng nhóm người lẽ ra
  // nên ra store ngay.
  var isInAppWebview = /FBAN|FBAV|Instagram|Zalo|Line\//i.test(ua);
  var openPrefix = '/open/';
  var isScreenLink = window.location.pathname.indexOf(openPrefix) === 0;

  var target = isIOS ? 'https://apps.apple.com/app/id6755175330'
                     : (isAndroid ? playUrl : null);

  if (target && isScreenLink && isInAppWebview) {
    var rest = window.location.pathname.slice(openPrefix.length);
    window.location.href = 'hddhistory://open/' + rest + window.location.search;
    // App đã cài thì trang này bị đóng băng lúc chuyển sang app và timeout
    // không bao giờ chạy. Chưa cài thì 1.2s sau ra store như thường.
    window.setTimeout(function () {
      window.location.replace(target);
    }, 1200);
  } else if (target) {
    // replace() để nút Back không kẹt vòng lặp quay lại trang trung gian.
    window.location.replace(target);
  }
```

- [ ] **Step 2: Chạy thử local**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/web-download-link && python3 -m http.server 8080
```

Mở `http://localhost:8080/open/paywall` trên desktop Chrome: phải **ở lại** trang tải (desktop không có target) — không chuyển hướng, không lỗi JS trong console.

- [ ] **Step 3: Kiểm chứng trên máy thật — bước quyết định giữ hay bỏ**

Build image, deploy lên staging của meup.training (hoặc trỏ hosts tạm), rồi với **máy thật đã cài app**, gửi `https://meup.training/open/habit` qua:
1. Zalo → bấm trong webview Zalo
2. Messenger → bấm trong webview FB
3. Safari (dán vào address bar)
4. Ghi chú/iMessage (Universal Link chuẩn)

Expected: (1) và (2) mở app vào tab Thói quen. (3) và (4) mở app trực tiếp.

Rồi lặp lại với **máy chưa cài app**: cả 4 đều phải ra store, không hộp thoại lỗi nào.

**Nếu (1) hoặc (2) hiện hộp thoại lỗi hoặc treo, BỎ task này** — revert `index.html` về đúng như cũ và ghi lại kết quả trong `design.md`. Hành vi rơi về đúng hôm nay, và không có gì khác trong plan phụ thuộc vào nó.

- [ ] **Step 4: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/web-download-link && \
git add index.html && \
git commit -m "feat: thử mở app bằng scheme trước khi ra store cho link vào màn"
```

---

## Thứ tự ship

Task 1-6 (Flutter) → **release một bản build ≥ 130** → Task 7 (API, deploy được độc lập) → Task 9 (Admin, **không** ship trước khi bản app kia đã live) → Task 10 (web, sau khi verify trong webview thật).

Task 8 không có tác dụng phụ nên ship lúc nào cũng được.

## Còn nợ sau plan này

- Thêm `deeplink_open` vào sheet "[HDDhistory] Event Tracking" — tên event mới phải khớp với sheet.
- Giai đoạn 2: đích cho `/r/<slug>` (thống kê server-side, đổi đích sau khi gửi, OG card riêng, link ngắn để in QR). Xem "Ngoài phạm vi" trong `design.md`.
