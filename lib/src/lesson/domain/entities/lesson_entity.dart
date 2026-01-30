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
    @Default(TagEntity()) TagEntity lightIcon,
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

  List<LessonEntity> applySequentialUnlock({bool enableAutoUnlock = true}) {
    if (!enableAutoUnlock) return toList();
    bool hasInProgress = false;
    bool previousAllDone = true;
    return map((lesson) {
      final progress = lesson.roadmapProgress;
      if (progress == ProcessEnum.done) return lesson;
      if (progress == ProcessEnum.inProgress) {
        hasInProgress = true;
        previousAllDone = false;
        return lesson;
      }
      if (!hasInProgress && previousAllDone) {
        hasInProgress = true;
        previousAllDone = false;
        return lesson.markInProgressForRoadmap();
      }
      previousAllDone = false;
      return lesson;
    }).toList();
  }
}

extension LessonEntityExtension on LessonEntity {
  LessonEntity get asKeypointLesson {
    if (type != LessonType.lesson) return this;
    final keypoint = firstKeypoint;
    if (keypoint.id.isEmpty) return this;
    return copyWith(
      title: keypoint.title,
      description: keypoint.description,
      estimateCompleTime: keypoint.estimateCompleTime,
    );
  }

  bool isSameLesson(LessonEntity other) {
    if (id.isEmpty || other.id.isEmpty) return false;
    final keypointId = firstKeypoint.id;
    final otherKeypointId = other.firstKeypoint.id;
    if (keypointId.isNotEmpty && otherKeypointId.isNotEmpty) {
      return keypointId == otherKeypointId;
    }
    return id == other.id;
  }

  List<KeypointEntity> get sortedKeypoints {
    List<KeypointEntity> sortedKeypoints = List<KeypointEntity>.from(keypoints);
    sortedKeypoints.sort((a, b) => a.strengthLevel.index.compareTo(b.strengthLevel.index));
    return sortedKeypoints;
  }

  String get trackingName => title.en;

  String get trackingNameOrText => title.en.isNotEmpty ? title.en : title.text;

  List<LessonEntity> get lessonsPerKeypoint {
    return List.generate(
      keypoints.length,
      (index) => copyWith(keypoints: [keypoints[index]]),
    );
  }

  KeypointEntity get firstKeypoint => keypoints.isNotEmpty ? keypoints.first : KeypointEntity();

  ProcessEnum get roadmapProgress {
    if (firstKeypoint.id.isEmpty) return progess;
    final keypointProgress = firstKeypoint.progressFromAverageScore;
    return _higherProgress(progess, keypointProgress);
  }

  LessonEntity markInProgressForRoadmap() {
    if (keypoints.isEmpty) {
      return copyWith(progess: ProcessEnum.inProgress);
    }

    final keypoint = keypoints.first;
    if (keypoint.progressFromAverageScore != ProcessEnum.notStarted) return this;
    return copyWith(
      keypoints: [
        keypoint.copyWith(progess: ProcessEnum.inProgress),
      ],
    );
  }

  ProcessEnum _higherProgress(ProcessEnum a, ProcessEnum b) {
    return a.rank >= b.rank ? a : b;
  }

  String get roadmapIconUrl {
    if (roadmapProgress == ProcessEnum.notStarted) return icon.url;
    if (lightIcon.url.isNotEmpty) return lightIcon.url;
    return icon.url;
  }
}
