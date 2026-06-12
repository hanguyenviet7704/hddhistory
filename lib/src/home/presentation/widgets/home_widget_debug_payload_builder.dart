part of '../../home.dart';

Future<List<HomeWidgetPayload>> _buildDebugNoStartedHomeWidgetPayloads() async {
  final now = DateTime.now();
  final localeCode = _debugLocaleCode();
  final textDefaults = await HomeWidgetTextDefaults.load(localeCode);
  return [
    HomeWidgetPayloadBuilder.buildInProgress(
      null,
      localeCode: localeCode,
      updatedAt: now,
      textDefaults: textDefaults,
    ),
    HomeWidgetPayloadBuilder.buildStreak(
      const HomeWidgetStreakEntity(),
      localeCode: localeCode,
      updatedAt: now,
      textDefaults: textDefaults,
    ),
    HomeWidgetPayloadBuilder.buildSuggestCourse(
      const HomeWidgetCourseEntity(
        courseId: 'debug-suggest-course',
        title: BaseMultiLanguage(
          en: 'Try a course today',
          vi: 'Thử một khóa học hôm nay',
          zh: '今天试试一门课程',
          ja: '今日のコースを始めよう',
          ko: '오늘 코스를 시작해보세요',
        ),
        description: BaseMultiLanguage(
          en: 'Pick a lesson and start building your streak.',
          vi: 'Chọn một bài học và bắt đầu chuỗi học.',
          zh: '选择一节课，开始建立你的连续学习记录。',
          ja: 'レッスンを選んで連続記録を作り始めましょう。',
          ko: '레슨을 골라 연속 학습을 시작하세요.',
        ),
      ),
      localeCode: localeCode,
      updatedAt: now,
      suggestionDate: now,
      textDefaults: textDefaults,
    ),
  ];
}

Future<List<HomeWidgetPayload>> _buildDebugDoneAllHomeWidgetPayloads() async {
  final now = DateTime.now();
  final localeCode = _debugLocaleCode();
  final textDefaults = await HomeWidgetTextDefaults.load(localeCode);
  return [
    HomeWidgetPayloadBuilder.buildInProgress(
      null,
      localeCode: localeCode,
      updatedAt: now,
      textDefaults: textDefaults,
    ),
    HomeWidgetPayloadBuilder.buildStreak(
      const HomeWidgetStreakEntity(
        weekStudy: [true, true, true, true, true, false, false],
        currentStreak: 5,
        bestStreak: 12,
      ),
      localeCode: localeCode,
      updatedAt: now,
      textDefaults: textDefaults,
    ),
    HomeWidgetPayloadBuilder.buildSuggestCourse(
      null,
      localeCode: localeCode,
      updatedAt: now,
      suggestionDate: now,
      textDefaults: textDefaults,
    ),
  ];
}

String _debugLocaleCode() {
  if (AppDI.injector.isRegistered<LocaleCubit>()) {
    return AppDI.injector.get<LocaleCubit>().state.languageCode;
  }
  return AppLocale.en.languageCode;
}
