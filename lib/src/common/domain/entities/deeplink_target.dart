part of '../../common.dart';

/// Một đích deeplink mà app biết mở.
///
/// Giá trị chuỗi ở đây là HỢP ĐỒNG CÔNG KHAI: nó nằm trong link đã gửi push, đã
/// in QR, đã dán vào bài Zalo — những thứ không rút lại được. Đổi tên route bên
/// trong app không được đổi những giá trị này. Thêm khoá mới thì được; đổi hoặc
/// xoá khoá cũ là làm chết link đã phát ra.
///
/// Cùng danh sách này được khai ở `hddhistory-api/src/modules/deeplink/deeplink.catalog.ts`
/// để admin dựng dropdown. Hai bên phải khớp từng ký tự.
enum DeeplinkDestination {
  home('home'),
  explore('explore'),
  habit('habit'),
  profile('profile'),
  library('library'),
  courseRoadmap('course-roadmap'),
  lesson('lesson'),
  categoryCourses('category-courses'),
  paywall('paywall'),
  manageSubscription('manage-subscription'),
  dailyWarmUp('daily-warm-up'),
  learningStreak('learning-streak'),
  dailyCheckIn('daily-check-in'),
  myLessons('my-lessons'),
  importLesson('import-lesson'),
  notificationSetting('notification-setting'),
  changeLanguage('change-language'),
  community('community'),
  communityPost('community-post'),
  /// `hddhistory://community-chat?room=<slug>` — a discussion room (the weekly
  /// question). Where the "someone answered" push lands.
  communityChat('community-chat'),

  /// `hddhistory://coach` — Home underneath, the AI Coach sheet on top. The same
  /// landing the commitment-reminder push uses; the server decides the door.
  coach('coach');

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
  static const String utmCampaignQueryKey = 'utm_campaign';
  static const String _webHost = 'meup.training';

  /// Nguồn của những link mang analytics riêng — home widget và Live Activity
  /// có handler riêng, và chúng phải giữ quyền xử lý link của mình. Chặn ở đây
  /// để mỗi parser sở hữu đúng vùng URL của nó, không phụ thuộc thứ tự gọi.
  static const Set<String> _reservedSources = {
    HomeWidgetDeeplinkTarget.sourceValue,
    LiveActivityDeeplink.sourceValue,
  };

  /// Nhãn chiến dịch cho event tracking.
  ///
  /// `c=` trước, `utm_campaign=` sau. Trang Link Builder trong admin phát ra
  /// `utm_campaign` (cùng một field vừa dùng cho quy kênh khi CHƯA cài app —
  /// nó đi vào `referrer` của Play và sống qua lượt cài — vừa dùng cho event
  /// khi ĐÃ cài); còn `c=` là dạng ngắn của những link phát ra trước đó và phải
  /// tiếp tục chạy.
  String get campaign {
    final short = params[campaignQueryKey]?.trim() ?? '';
    if (short.isNotEmpty) return short;
    return params[utmCampaignQueryKey]?.trim() ?? '';
  }

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
