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
    @Default(ConversationAvatarEntity()) ConversationAvatarEntity animation,
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
    final lessons = toList();
    bool previousBlockingCompleted = true;
    bool hasActiveBlockingLesson = false;

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final progress = lesson.roadmapProgress;

      if (!lesson.type.blocksRoadmap) {
        if (progress == ProcessEnum.done || progress == ProcessEnum.inProgress) continue;
        if (previousBlockingCompleted && !hasActiveBlockingLesson) {
          lessons[i] = lesson.copyWithRoadmapProgress(ProcessEnum.done);
        }
        continue;
      }

      if (progress == ProcessEnum.done) continue;
      if (progress == ProcessEnum.inProgress) {
        previousBlockingCompleted = false;
        hasActiveBlockingLesson = true;
        continue;
      }

      if (previousBlockingCompleted && !hasActiveBlockingLesson) {
        lessons[i] = lesson.copyWithRoadmapProgress(ProcessEnum.inProgress);
        hasActiveBlockingLesson = true;
      }
      previousBlockingCompleted = false;
    }

    return lessons;
  }
}

extension LessonEntityExtension on LessonEntity {
  String get roadmapKey {
    final keypointId = firstKeypoint.id;
    if (keypointId.isNotEmpty) return keypointId;
    return id;
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
    return firstKeypoint.progess;
  }

  LessonEntity copyWithRoadmapProgress(ProcessEnum progress) {
    if (keypoints.isEmpty) {
      return copyWith(progess: progress);
    }

    final updatedKeypoints = [...keypoints];
    updatedKeypoints[0] = updatedKeypoints[0].copyWith(progess: progress);
    return copyWith(keypoints: updatedKeypoints);
  }

  LessonEntity markInProgressForRoadmap() {
    if (roadmapProgress != ProcessEnum.notStarted) return this;
    return copyWithRoadmapProgress(ProcessEnum.inProgress);
  }

  String get roadmapIconUrl {
    if (roadmapProgress == ProcessEnum.notStarted) return icon.url;
    if (lightIcon.url.isNotEmpty) return lightIcon.url;
    return icon.url;
  }

  String get displayTitleForNextLesson {
    if (type == LessonType.lesson) {
      final keypointTitle = firstKeypoint.title.text;
      if (keypointTitle.isNotEmpty) return keypointTitle;
    }
    return title.text;
  }
}
