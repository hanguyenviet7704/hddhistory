part of '../../home_widget.dart';

@freezed
abstract class HomeWidgetCourseEntity with _$HomeWidgetCourseEntity {
  const factory HomeWidgetCourseEntity({
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int completedLesson,
    @Default(0) int totalLesson,
  }) = _HomeWidgetCourseEntity;
}

@freezed
abstract class HomeWidgetStreakEntity with _$HomeWidgetStreakEntity {
  const factory HomeWidgetStreakEntity({
    DateTime? weekStartDate,
    @Default([]) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _HomeWidgetStreakEntity;
}

@freezed
abstract class HomeWidgetTextDefaults with _$HomeWidgetTextDefaults {
  const HomeWidgetTextDefaults._();

  const factory HomeWidgetTextDefaults({
    @Default('Pick a course and stay in the loop') String inProgressEmptyTitle,
    @Default('Keep going!') String streakActiveSubtitle,
    @Default('Start your streak today') String streakEmptySubtitle,
    @Default("Today's suggestion") String suggestLabel,
    @Default('You crushed every course!') String suggestExhaustedTitle,
    @Default('More coming soon!') String suggestExhaustedSubtitle,
    @Default('{completed}/{total} lesson') String progressTextTemplate,
    @Default('{count} day') String streakCountSingularTemplate,
    @Default('{count} days') String streakCountPluralTemplate,
    @Default(['M', 'T', 'W', 'T', 'F', 'S', 'S']) List<String> weekLabels,
  }) = _HomeWidgetTextDefaults;

  static Future<HomeWidgetTextDefaults> load(String localeCode) => Future.value(HomeWidgetTextDefaults.forLocaleCode(localeCode));

  /// App chỉ còn tiếng Việt, nên tham số localeCode không còn dùng để chọn
  /// bộ chữ nữa; giữ chữ ký hàm vì phía widget iOS/Android vẫn gọi kèm mã.
  factory HomeWidgetTextDefaults.forLocaleCode(String localeCode) {
    return const HomeWidgetTextDefaults(
      inProgressEmptyTitle: 'Chọn khóa học để bắt đầu',
      streakActiveSubtitle: 'Tiếp tục nhé!',
      streakEmptySubtitle: 'Bắt đầu chuỗi hôm nay',
    );
  }

  String progressText({required int completed, required int total}) {
    return progressTextTemplate.replaceAll('{completed}', completed.toString()).replaceAll('{total}', total.toString());
  }

  String streakCountText(int count) {
    final template = count == 1 ? streakCountSingularTemplate : streakCountPluralTemplate;
    return template.replaceAll('{count}', count.toString());
  }
}

class HomeWidgetPayload {
  const HomeWidgetPayload({
    required this.widgetType,
    required this.state,
    required this.updatedAt,
    required this.deeplink,
    required this.data,
    this.imageUrl,
    this.staticAssetKey,
  });

  final HomeWidgetType widgetType;
  final HomeWidgetPayloadState state;
  final DateTime updatedAt;
  final String deeplink;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? staticAssetKey;

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'widgetType': widgetType.value,
      'state': state.value,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deeplink': deeplink,
      'data': data,
    };
  }

  static HomeWidgetPayload fromJson(Map<String, dynamic> json) {
    final widgetType = HomeWidgetType.fromValue(json['widgetType']?.toString() ?? '');
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final staticAssetKey = data['staticAssetKey']?.toString();

    return HomeWidgetPayload(
      widgetType: widgetType,
      state: HomeWidgetPayloadState.fromValue(json['state']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deeplink: json['deeplink']?.toString() ?? '',
      data: data,
      staticAssetKey: staticAssetKey == null || staticAssetKey.isEmpty ? null : staticAssetKey,
    );
  }
}

extension HomeWidgetPayloadX on HomeWidgetPayload {
  String get storageKey => widgetType.storageKey;

  String? get imageKey {
    return switch (widgetType) {
      HomeWidgetType.inProgressCourse => HomeWidgetStorageKeys.inProgressImage,
      HomeWidgetType.suggestCourse => HomeWidgetStorageKeys.suggestCourseImage,
      HomeWidgetType.weeklyStreak => null,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class HomeWidgetSyncParams {
  HomeWidgetSyncParams({
    required this.localeCode,
    DateTime? now,
    this.textDefaults,
    this.changedCourseId = '',
  }) : now = now ?? DateTime.now();

  final String localeCode;
  final DateTime now;
  final HomeWidgetTextDefaults? textDefaults;
  final String changedCourseId;

  DateTime get currentTime => now.toUtc();

  String get localDateKey {
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<HomeWidgetTextDefaults> resolveTextDefaults() => textDefaults == null ? HomeWidgetTextDefaults.load(localeCode) : Future.value(textDefaults);

  HomeWidgetSyncParams withTextDefaults(HomeWidgetTextDefaults value) {
    return HomeWidgetSyncParams(
      localeCode: localeCode,
      now: now,
      textDefaults: value,
      changedCourseId: changedCourseId,
    );
  }
}

class HomeWidgetSyncResult {
  const HomeWidgetSyncResult({
    required this.widgetType,
    required this.status,
    this.payload,
    this.message = '',
  });

  final HomeWidgetType? widgetType;
  final HomeWidgetSyncStatus status;
  final HomeWidgetPayload? payload;
  final String message;
}
