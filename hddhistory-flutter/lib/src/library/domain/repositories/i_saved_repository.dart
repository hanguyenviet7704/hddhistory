part of '../../library.dart';

/// What to snapshot when a recap card is saved.
///
/// [recapText] is the text the reader was looking at. It travels with the save
/// because the server cannot re-derive it — see [SavedCardEntity].
class SaveCardParams {
  final String keypointId;
  final String lessonId;
  final String courseId;

  /// Recap ở CẢ NĂM ngôn ngữ. Thẻ đã lưu chốt recap thành ảnh chụp tại thời
  /// điểm lưu (nó được suy ra ở client, không phải field có sẵn trên keypoint
  /// — xem [SavedCardEntity]); chốt một ngôn ngữ là thẻ ngừng đi theo người
  /// đọc: lưu lúc tiếng Việt, đổi app sang tiếng Anh, Thư viện hiện tiêu đề
  /// tiếng Anh trên thân bài tiếng Việt (báo lỗi on-device 2026-09-10).
  final BaseMultiLanguage recap;

  /// Ngôn ngữ đang bật, gửi kèm cho bản API chưa biết tới [recap]. Bỏ được
  /// sau khi API mới đã lên hết mọi môi trường.
  final String recapText;

  const SaveCardParams({
    required this.keypointId,
    this.lessonId = '',
    this.courseId = '',
    this.recap = const BaseMultiLanguage(),
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
