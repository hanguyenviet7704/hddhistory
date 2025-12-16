part of '../../lesson.dart';

@freezed
abstract class LessonEntity with _$LessonEntity {
  const factory LessonEntity({
    @Default('') String id,
    @Default('') String courseId,
    @Default('') String learningItemId,
    @Default(LessonType.lesson) LessonType type,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<KeypointEntity> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default(TagEntity()) TagEntity icon,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,
    @Default(0) int index,
  }) = _LessonEntity;

  factory LessonEntity.fromJson(Map<String, dynamic> json) => _$LessonEntityFromJson(json);
}

extension LessonEntityListExtension on List<LessonEntity> {
  LessonEntity lessonRolePlay(String lessonId) {
    int index = indexWhere((lesson) => lesson.id == lessonId);
    if (index == -1) return LessonEntity();
    for (int i = index; i >= 0; i--) {
      if (elementAt(i).type == LessonType.roleplay) return elementAt(i);
    }
    return LessonEntity();
  }

  // Premium Lesson starts from the second roleplay lesson in the list
  // Returns the index of the second roleplay (first premium lesson), or -1 if none
  int get premiumLessonIndex {
    int roleplayCount = 0;
    for (int i = 0; i < length; i++) {
      if (elementAt(i).type == LessonType.roleplay) {
        roleplayCount++;
        if (roleplayCount == 2) {
          return i;
        }
      }
    }
    return -1;
  }

  // Check if a lesson at the given index is a premium lesson
  bool isPremiumLessonAt(int lessonIndex) {
    // int premiumIndex = premiumLessonIndex;
    // if (premiumIndex == -1) return false;
    int premiumIndex = 2;
    return lessonIndex >= premiumIndex;
  }
}

extension LessonEntityExtension on LessonEntity {
  List<KeypointEntity> get sortedKeypoints {
    List<KeypointEntity> sortedKeypoints = List<KeypointEntity>.from(keypoints);
    sortedKeypoints.sort((a, b) => a.strengthLevel.index.compareTo(b.strengthLevel.index));
    return sortedKeypoints;
  }
}
