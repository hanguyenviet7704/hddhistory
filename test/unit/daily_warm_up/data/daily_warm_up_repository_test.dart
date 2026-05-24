import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

class _FakeDailyWarmUpApi implements DailyWarmUpApi {
  _FakeDailyWarmUpApi({required this.handler});

  Future<BaseResponse<DailyWarmUpModel>> Function() handler;

  @override
  Future<BaseResponse<DailyWarmUpModel>> getDailyWarmUp() => handler();
}

class _FakeDailyWarmUpLocalDataSource implements DailyWarmUpLocalDataSource {
  DailyWarmUpModel? cachedModel;
  final Map<String, String> shownDates = {};

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {
    cachedModel = model;
  }

  @override
  Future<void> clearCache() async {
    cachedModel = null;
  }

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async => cachedModel;

  @override
  Future<String> getShownDate(String userId) async => shownDates[userId] ?? '';

  @override
  Future<void> markShownDate(String userId, String date) async {
    shownDates[userId] = date;
  }
}

void main() {
  group('DailyWarmUpRepository', () {
    test('Given API failure and cached warm-up, When loading, Then stale cache is not returned', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource()..cachedModel = const DailyWarmUpModel(suggestedCourseId: 'stale-course');
      final repository = DailyWarmUpRepository(
        _FakeDailyWarmUpApi(handler: () => throw StateError('offline')),
        localDataSource,
      );

      final result = await repository.getDailyWarmUp().run();

      expect(result.isLeft(), isTrue);
    });

    test('Given keypointId in response JSON, When parsed, Then entity keeps keypointId', () {
      final model = DailyWarmUpModel.fromJson(const {
        'courseId': 'course-1',
        'suggestedCourseId': 'course-2',
        'lessonId': 'lesson-1',
        'keypointId': 'keypoint-1',
        'isKeypointCompleted': true,
        'questions': [],
      });

      expect(model.keypointId, 'keypoint-1');
      expect(model.toEntity().keypointId, 'keypoint-1');
    });
  });
}
