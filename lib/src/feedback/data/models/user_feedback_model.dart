part of '../../feedback.dart';

@freezed
abstract class UserFeedbackModel with _$UserFeedbackModel {
  const factory UserFeedbackModel({
    @Default('') String userId,
    @Default(UserFeedbackCompleteModel()) UserFeedbackCompleteModel roleplayComplete,
    @Default(UserFeedbackIncompleteModel()) UserFeedbackIncompleteModel roleplayIncomplete,
    @Default(UserFeedbackCompleteModel()) UserFeedbackCompleteModel keypointComplete,
    @Default(UserFeedbackIncompleteModel()) UserFeedbackIncompleteModel keypointIncomplete,
  }) = _UserFeedbackModel;

  factory UserFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$UserFeedbackModelFromJson(json);
}

enum FeedbackType {
  @JsonValue('complete')
  complete,
  @JsonValue('incomplete')
  incomplete,
}

enum FeedbackEntry {
  @JsonValue('roleplay')
  roleplay,
  @JsonValue('keypoint')
  keypoint,
}

extension UserFeedbackModelExtension on UserFeedbackModel {
  UserFeedbackEntity toEntity() => UserFeedbackEntity(
        userId: userId,
        roleplayComplete: roleplayComplete.toEntity(),
        roleplayIncomplete: roleplayIncomplete.toEntity(),
        keypointComplete: keypointComplete.toEntity(),
        keypointIncomplete: keypointIncomplete.toEntity(),
      );
}