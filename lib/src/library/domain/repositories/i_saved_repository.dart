part of '../../library.dart';

/// What to snapshot when a recap card is saved.
///
/// [recapText] is the text the reader was looking at. It travels with the save
/// because the server cannot re-derive it — see [SavedCardEntity].
class SaveCardParams {
  final String keypointId;
  final String lessonId;
  final String courseId;
  final String recapText;

  const SaveCardParams({
    required this.keypointId,
    this.lessonId = '',
    this.courseId = '',
    this.recapText = '',
  });
}

abstract class ISavedRepository {
  TaskEither<AppException, BasePageBreak<CourseEntity>> getSavedCourses({
    required int page,
    required int take,
    required SavedCourseFilter filter,
  });

  /// Every saved course id. Cheap enough to re-read whenever the set could
  /// have gone stale, which is what keeps the bookmark honest across screens.
  TaskEither<AppException, List<String>> getSavedCourseIds();

  TaskEither<AppException, Unit> saveCourse(String courseId);

  TaskEither<AppException, Unit> unsaveCourse(String courseId);

  TaskEither<AppException, BasePageBreak<SavedCardEntity>> getSavedCards({
    required int page,
    required int take,
  });

  TaskEither<AppException, List<String>> getSavedCardIds();

  TaskEither<AppException, Unit> saveCard(SaveCardParams params);

  TaskEither<AppException, Unit> unsaveCard(String keypointId);
}
