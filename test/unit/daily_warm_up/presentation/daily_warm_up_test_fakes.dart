import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

class FakeDailyWarmUpRepository implements IDailyWarmUpRepository {
  FakeDailyWarmUpRepository(this.result);

  final TaskEither<AppException, DailyWarmUpEntity> result;

  @override
  TaskEither<AppException, DailyWarmUpEntity> getDailyWarmUp() => result;
}

class FakeDailyWarmUpLocalDataSource implements DailyWarmUpLocalDataSource {
  final Map<String, String> shownDates = {};
  final Map<String, String> onboardingCompletedDates = {};

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async => null;

  @override
  Future<String> getShownDate(String userId) async => shownDates[userId] ?? '';

  @override
  Future<String> getOnboardingCompletedDate(String userId) async => onboardingCompletedDates[userId] ?? '';

  @override
  Future<void> markOnboardingCompletedDateIfAbsent(String userId, String date) async {
    onboardingCompletedDates.putIfAbsent(userId, () => date);
  }

  @override
  Future<void> markShownDate(String userId, String date) async {
    shownDates[userId] = date;
  }
}

class FakeCourseRepository implements ICourseRepository {
  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    return TaskEither.right(CourseEntity(id: id, title: dailyWarmUpTestText('Course $id')));
  }

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) {
    throw UnimplementedError();
  }
}

DailyWarmUpEntity dailyWarmUpTestEntity() {
  return DailyWarmUpEntity(
    courseId: 'course-1',
    suggestedCourseId: 'course-2',
    lessonId: 'lesson-1',
    keypointId: 'keypoint-1',
    questions: [
      QuestionEntity(
        id: 1,
        document: [ContentDocumentEntity(data: DocumentDataEntity(content: dailyWarmUpTestText('Pick one')))],
        typedPayload: QuestionPayloadEntity.singleChoice(
          options: [
            QuestionChoiceOptionEntity(value: dailyWarmUpTestText('A'), isCorrect: true),
            QuestionChoiceOptionEntity(value: dailyWarmUpTestText('B')),
          ],
        ),
      ),
    ],
  );
}

BaseMultiLanguage dailyWarmUpTestText(String value) => BaseMultiLanguage(en: value, vi: value, zh: value);
