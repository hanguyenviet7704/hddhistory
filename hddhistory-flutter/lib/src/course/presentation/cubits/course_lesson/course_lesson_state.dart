part of '../../../course.dart';

enum CourseLessonStatus { initial, loading, success, failure }

@freezed
abstract class CourseLessonState with _$CourseLessonState {
  const factory CourseLessonState({
    @Default(CourseLessonStatus.initial) CourseLessonStatus status,
    @Default(LessonEntity()) LessonEntity selectedLesson,
    @Default('') String currentKeypointId,
    @Default(false) bool wasLessonCompletedBefore,
    String? errorMessage,
  }) = _CourseLessonState;

  factory CourseLessonState.initial() => CourseLessonState();

  factory CourseLessonState.fromJson(Map<String, dynamic> json) => _$CourseLessonStateFromJson(json);
}

extension CourseLessonStateExtension on CourseLessonState {
  bool get isCompleted => selectedLesson.progess == ProcessEnum.done;

  KeypointEntity get resolvedCurrentKeypoint {
    if (currentKeypointId.isNotEmpty) {
      return selectedLesson.keypoints.firstWhere(
        (keypoint) => keypoint.id == currentKeypointId,
        orElse: () => selectedLesson.firstKeypoint,
      );
    }
    return selectedLesson.firstKeypoint;
  }

  String get currentTitle {
    final keypoint = resolvedCurrentKeypoint;
    if (keypoint.title.text.isNotEmpty) return keypoint.title.text;
    return selectedLesson.title.text;
  }

  LessonEntity get currentLessonForNext {
    final keypoint = resolvedCurrentKeypoint;
    if (keypoint.id.isNotEmpty) {
      return selectedLesson.copyWith(keypoints: [keypoint]);
    }
    return selectedLesson;
  }

  KeypointEntity get currentKeypoint {
    return selectedLesson.keypoints.firstWhere((keypoint) => keypoint.id == currentKeypointId);
  }

  bool get isAllOtherKeypointsCompleted {
    List<KeypointEntity> otherKeypoints = selectedLesson.keypoints.where((keypoint) {
      return keypoint.id != currentKeypointId;
    }).toList();
    if (otherKeypoints.isEmpty) return true;
    return otherKeypoints.every((keypoint) => keypoint.progess == ProcessEnum.done);
  }

  LessonEntity updateLessonWithResults(LessonResultEntity currentLessonResult) {
    final updatedKeypoints = selectedLesson.keypoints.map((keypoint) {
      final matchingResult = currentLessonResult.keypointsResult.firstWhere(
        (result) => result.keypointId == keypoint.id,
        orElse: () => KeypointResultEntity(),
      );

      if (matchingResult.keypointId.isNotEmpty) {
        return keypoint.copyWith(point: matchingResult.averageScore.toInt(), isUseProgressData: true);
      }
      return keypoint.copyWith(isUseProgressData: true);
    }).toList();

    return selectedLesson.copyWith(keypoints: updatedKeypoints);
  }
}
