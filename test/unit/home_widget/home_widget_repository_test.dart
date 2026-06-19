import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import 'home_widget_test_fakes.dart';

void main() {
  final now = DateTime.utc(2026, 6, 9, 12);

  group('HomeWidgetRepository', () {
    test('reuses same-day suggest payload without refetching random backend output', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'cached-course',
          title: const BaseMultiLanguage(en: 'Cached course'),
          description: const BaseMultiLanguage(en: 'Cached description'),
          image: 'https://cdn.example.com/cached.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi();
      final local = FakeHomeWidgetLocalDataSource(
        suggestionDate: '2026-06-09',
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncSuggestCourse(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(api.suggestCalls, 0);
      expect(bridge.savedPayloads, isEmpty);
      expect(bridge.updatedTypes, [HomeWidgetType.suggestCourse]);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('refetches same-day suggest payload when locale changes', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'cached-course',
          title: const BaseMultiLanguage(en: 'Cached course', vi: 'Khoa hoc da luu'),
          description: const BaseMultiLanguage(en: 'Cached description', vi: 'Mo ta da luu'),
          image: 'https://cdn.example.com/cached.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi(
        suggest: const HomeWidgetCourseModel(
          courseId: 'cached-course',
          title: BaseMultiLanguage(en: 'Cached course', vi: 'Khoa hoc da luu'),
          description: BaseMultiLanguage(en: 'Cached description', vi: 'Mo ta da luu'),
          image: 'https://cdn.example.com/cached.jpg',
        ),
      );
      final local = FakeHomeWidgetLocalDataSource(
        suggestionDate: '2026-06-09',
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncSuggestCourse(HomeWidgetSyncParams(localeCode: 'vi', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(api.suggestCalls, 1);
      expect(bridge.savedPayloads.single.data['localeCode'], 'vi');
      expect(bridge.savedPayloads.single.data['title'], 'Khoa hoc da luu');
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.updated);
    });

    test('refetches same-day suggest payload when changed course matches cached suggestion', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'course-active',
          title: const BaseMultiLanguage(en: 'Current suggestion'),
          description: const BaseMultiLanguage(en: 'Current description'),
          image: 'https://cdn.example.com/current.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi(
        suggest: const HomeWidgetCourseModel(
          courseId: 'course-next',
          title: BaseMultiLanguage(en: 'Next suggestion'),
          description: BaseMultiLanguage(en: 'Next description'),
          image: 'https://cdn.example.com/next.jpg',
        ),
      );
      final local = FakeHomeWidgetLocalDataSource(
        suggestionDate: '2026-06-09',
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository
          .syncSuggestCourse(
            HomeWidgetSyncParams(
              localeCode: 'en',
              now: now,
              changedCourseId: 'course-active',
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      expect(api.suggestCalls, 1);
      expect(bridge.savedPayloads.single.data['courseId'], 'course-next');
      expect(local.cachedPayloads[HomeWidgetStorageKeys.suggestCoursePayload]?.data['courseId'], 'course-next');
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.updated);
    });

    test('keeps same-day suggest payload when changed course differs from cached suggestion', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'course-cached',
          title: const BaseMultiLanguage(en: 'Cached suggestion'),
          description: const BaseMultiLanguage(en: 'Cached description'),
          image: 'https://cdn.example.com/cached.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi(
        suggest: const HomeWidgetCourseModel(
          courseId: 'course-next',
          title: BaseMultiLanguage(en: 'Next suggestion'),
          description: BaseMultiLanguage(en: 'Next description'),
        ),
      );
      final local = FakeHomeWidgetLocalDataSource(
        suggestionDate: '2026-06-09',
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository
          .syncSuggestCourse(
            HomeWidgetSyncParams(
              localeCode: 'en',
              now: now,
              changedCourseId: 'course-other',
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      expect(api.suggestCalls, 0);
      expect(bridge.savedPayloads, isEmpty);
      expect(bridge.updatedTypes, [HomeWidgetType.suggestCourse]);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('preserves previous in-progress payload when API fails', () async {
      final cached = HomeWidgetPayloadBuilder.buildInProgress(
        HomeWidgetCourseEntity(
          courseId: 'course-old',
          title: const BaseMultiLanguage(en: 'Old course'),
          image: 'https://cdn.example.com/old.jpg',
          completedLesson: 1,
          totalLesson: 4,
        ),
        localeCode: 'en',
        updatedAt: now,
      );
      final api = FakeHomeWidgetApi(inProgressError: StateError('network'));
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.inProgressPayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncInProgress(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads, isEmpty);
      expect(bridge.updatedTypes, [HomeWidgetType.inProgressCourse]);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('preserves previous ready payload when image save fails', () async {
      final cached = HomeWidgetPayloadBuilder.buildInProgress(
        HomeWidgetCourseEntity(
          courseId: 'course-old',
          title: const BaseMultiLanguage(en: 'Old course'),
          image: 'https://cdn.example.com/old.jpg',
          completedLesson: 1,
          totalLesson: 4,
        ),
        localeCode: 'en',
        updatedAt: now,
      );
      final api = FakeHomeWidgetApi(
        inProgress: HomeWidgetCourseModel(
          courseId: 'course-new',
          title: const BaseMultiLanguage(en: 'New course'),
          image: 'https://cdn.example.com/new.jpg',
          completedLesson: 2,
          totalLesson: 4,
        ),
      );
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.inProgressPayload: cached},
      );
      final bridge = FakeHomeWidgetBridge(failImageKeys: {HomeWidgetStorageKeys.inProgressImage});
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncInProgress(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads.single.data['courseId'], 'course-new');
      expect(local.cachedPayloads[HomeWidgetStorageKeys.inProgressPayload]?.data['courseId'], 'course-new');
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.updated);
    });

    test('clears all known widget data best-effort even if one clear call fails', () async {
      final api = FakeHomeWidgetApi();
      final local = FakeHomeWidgetLocalDataSource();
      final bridge = FakeHomeWidgetBridge(failClearKeys: {HomeWidgetStorageKeys.inProgressPayload});
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.clearStoredWidgets().run();

      expect(result.isRight(), isTrue);
      expect(bridge.clearedKeys, containsAll(HomeWidgetStorageKeys.allKeys));
      expect(local.clearCalled, isTrue);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.cleared);
    });

    test('preserves previous streak payload when API fails', () async {
      final cached = HomeWidgetPayloadBuilder.buildStreak(
        HomeWidgetStreakEntity(
          weekStartDate: DateTime.utc(2026, 6, 2),
          weekStudy: const [true, true, false],
          currentStreak: 2,
        ),
        updatedAt: now,
      );
      final api = FakeHomeWidgetApi(streakError: StateError('network'));
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.streakPayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncStreak(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads, isEmpty);
      expect(bridge.updatedTypes, [HomeWidgetType.weeklyStreak]);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('preserves previous suggest payload when API fails', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'course-old',
          title: const BaseMultiLanguage(en: 'Old suggestion'),
          description: const BaseMultiLanguage(en: 'Old description'),
          image: 'https://cdn.example.com/old.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi(suggestError: StateError('network'));
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncSuggestCourse(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads, isEmpty);
      expect(bridge.updatedTypes, [HomeWidgetType.suggestCourse]);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('preserves previous suggest payload when image save fails', () async {
      final cached = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'course-old',
          title: const BaseMultiLanguage(en: 'Old suggestion'),
          description: const BaseMultiLanguage(en: 'Old description'),
          image: 'https://cdn.example.com/old.jpg',
        ),
        localeCode: 'en',
        updatedAt: now,
        suggestionDate: now,
      );
      final api = FakeHomeWidgetApi(
        suggest: const HomeWidgetCourseModel(
          courseId: 'course-new',
          title: BaseMultiLanguage(en: 'New suggestion'),
          description: BaseMultiLanguage(en: 'New description'),
          image: 'https://cdn.example.com/new.jpg',
        ),
      );
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.suggestCoursePayload: cached},
      );
      final bridge = FakeHomeWidgetBridge(failImageKeys: {HomeWidgetStorageKeys.suggestCourseImage});
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncSuggestCourse(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads.single.data['courseId'], 'course-new');
      expect(local.cachedPayloads[HomeWidgetStorageKeys.suggestCoursePayload]?.data['courseId'], 'course-new');
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.updated);
    });

    test('uses local calendar day for suggest cache date', () {
      final params = HomeWidgetSyncParams(
        localeCode: 'en',
        now: DateTime(2026, 6, 9, 0, 30),
      );

      expect(params.localDateKey, '2026-06-09');
    });

    test('serializes concurrent suggest syncs so random backend is fetched once', () async {
      final api = FakeHomeWidgetApi(
        suggestDelay: const Duration(milliseconds: 10),
        suggest: const HomeWidgetCourseModel(
          courseId: 'course-new',
          title: BaseMultiLanguage(en: 'New suggestion'),
          description: BaseMultiLanguage(en: 'New description'),
          image: 'https://cdn.example.com/new.jpg',
        ),
      );
      final local = FakeHomeWidgetLocalDataSource();
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);
      final params = HomeWidgetSyncParams(localeCode: 'en', now: now);

      final results = await Future.wait([
        repository.syncSuggestCourse(params).run(),
        repository.syncSuggestCourse(params).run(),
      ]);

      expect(results.every((result) => result.isRight()), isTrue);
      expect(api.suggestCalls, 1);
      expect(bridge.savedPayloads.length, 1);
      expect(local.suggestionDate, '2026-06-09');
    });

    test('serializes concurrent suggest failures into failed results for all callers', () async {
      final api = FakeHomeWidgetApi(
        suggestDelay: const Duration(milliseconds: 10),
        suggestError: StateError('network'),
      );
      final local = FakeHomeWidgetLocalDataSource();
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);
      final params = HomeWidgetSyncParams(localeCode: 'en', now: now);

      final results = await Future.wait([
        repository.syncSuggestCourse(params).run(),
        repository.syncSuggestCourse(params).run(),
      ]);

      expect(results.every((result) => result.isRight()), isTrue);
      expect(results.map((result) => result.getRight().toNullable()?.status), everyElement(HomeWidgetSyncStatus.failed));
      expect(api.suggestCalls, 1);
      expect(bridge.savedPayloads, isEmpty);
    });

    test('preserves previous streak payload when response data is null', () async {
      final cached = HomeWidgetPayloadBuilder.buildStreak(
        HomeWidgetStreakEntity(
          weekStartDate: DateTime.utc(2026, 6, 2),
          weekStudy: const [true, true, false],
          currentStreak: 2,
        ),
        updatedAt: now,
      );
      final api = FakeHomeWidgetApi(streakReturnsNull: true);
      final local = FakeHomeWidgetLocalDataSource(
        cachedPayloads: {HomeWidgetStorageKeys.streakPayload: cached},
      );
      final bridge = FakeHomeWidgetBridge();
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncStreak(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads, isEmpty);
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.preserved);
    });

    test('writes first-run ready payload when image save fails', () async {
      final api = FakeHomeWidgetApi(
        inProgress: HomeWidgetCourseModel(
          courseId: 'course-new',
          title: const BaseMultiLanguage(en: 'New course'),
          image: 'https://cdn.example.com/new.jpg',
          completedLesson: 2,
          totalLesson: 4,
        ),
      );
      final local = FakeHomeWidgetLocalDataSource();
      final bridge = FakeHomeWidgetBridge(failImageKeys: {HomeWidgetStorageKeys.inProgressImage});
      final repository = HomeWidgetRepository(api, local, bridge);

      final result = await repository.syncInProgress(HomeWidgetSyncParams(localeCode: 'en', now: now)).run();

      expect(result.isRight(), isTrue);
      expect(bridge.savedPayloads.single.data['courseId'], 'course-new');
      expect(local.cachedPayloads[HomeWidgetStorageKeys.inProgressPayload]?.data['courseId'], 'course-new');
      expect(result.getRight().toNullable()?.status, HomeWidgetSyncStatus.updated);
      expect(result.getRight().toNullable()?.message, contains(HomeWidgetStorageKeys.inProgressImage));
    });
  });
}
