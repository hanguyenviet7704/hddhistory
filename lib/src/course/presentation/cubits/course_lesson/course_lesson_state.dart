part of '../../../course.dart';

enum CourseLessonStatus { initial, loading, success, failure }

@freezed
abstract class CourseLessonState with _$CourseLessonState {
  const factory CourseLessonState({
    @Default(CourseLessonStatus.initial) CourseLessonStatus status,
    @Default(LessonEntity()) LessonEntity selectedLesson,
    @Default('') String currentKeypointId,
    String? errorMessage,
  }) = _CourseLessonState;

  factory CourseLessonState.initial() => CourseLessonState();

  factory CourseLessonState.fromJson(Map<String, dynamic> json) => _$CourseLessonStateFromJson(json);
}

extension CourseLessonStateExtension on CourseLessonState {
  bool get isCompleted => selectedLesson.progess == ProcessEnum.done;

  bool get isAllOtherKeypointsCompleted {
    List<KeypointEntity> otherKeypoints = selectedLesson.keypoints.where((keypoint) {
      return keypoint.id != currentKeypointId;
    }).toList();
    if (otherKeypoints.isEmpty) return true;
    return otherKeypoints.every((keypoint) => keypoint.progess == ProcessEnum.done);
  }
}
