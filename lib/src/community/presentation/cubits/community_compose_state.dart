part of '../../community.dart';

@freezed
abstract class CommunityComposeState with _$CommunityComposeState {
  const factory CommunityComposeState({
    @Default('') String body,

    /// Null means "không chọn nhóm" — posting without a topic is allowed.
    String? topicId,
    @Default(<String>[]) List<String> images,
    String? attachedCourseId,
    String? attachedCourseTitle,
    @Default(<CommunityTopicEntity>[]) List<CommunityTopicEntity> topics,
    @Default(false) bool isSubmitting,
    @Default(false) bool isUploadingImage,
    String? errorMessage,
  }) = _CommunityComposeState;

  factory CommunityComposeState.initial() => const CommunityComposeState();
}

extension CommunityComposeStateX on CommunityComposeState {
  bool get canSubmit => body.trim().isNotEmpty && !isSubmitting && !isUploadingImage;
}
