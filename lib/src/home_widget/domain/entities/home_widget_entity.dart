part of '../../home_widget.dart';

class HomeWidgetCourseEntity {
  const HomeWidgetCourseEntity({
    this.courseId = '',
    this.title = const {},
    this.description = const {},
    this.image = '',
    this.completedLesson = 0,
    this.totalLesson = 0,
  });

  final String courseId;
  final Map<String, String> title;
  final Map<String, String> description;
  final String image;
  final int completedLesson;
  final int totalLesson;
}

class HomeWidgetStreakEntity {
  const HomeWidgetStreakEntity({
    this.weekStartDate,
    this.weekStudy = const [],
    this.studyTime = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  final DateTime? weekStartDate;
  final List<bool> weekStudy;
  final int studyTime;
  final int currentStreak;
  final int bestStreak;
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

  String get storageKey {
    return switch (widgetType) {
      HomeWidgetType.inProgressCourse => HomeWidgetStorageKeys.inProgressPayload,
      HomeWidgetType.weeklyStreak => HomeWidgetStorageKeys.streakPayload,
      HomeWidgetType.suggestCourse => HomeWidgetStorageKeys.suggestCoursePayload,
    };
  }

  String? get imageKey {
    return switch (widgetType) {
      HomeWidgetType.inProgressCourse => HomeWidgetStorageKeys.inProgressImage,
      HomeWidgetType.suggestCourse => HomeWidgetStorageKeys.suggestCourseImage,
      HomeWidgetType.weeklyStreak => null,
    };
  }

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

  String toJsonString() => jsonEncode(toJson());
}

class HomeWidgetSyncParams {
  HomeWidgetSyncParams({
    required this.localeCode,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  final String localeCode;
  final DateTime now;

  DateTime get currentTime => now.toUtc();

  String get localDateKey {
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
