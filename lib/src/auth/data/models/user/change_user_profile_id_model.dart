part of '../models.dart';

@freezed
abstract class ChangeUserProfileIdModel with _$ChangeUserProfileIdModel {
  const factory ChangeUserProfileIdModel({
    @Default('') String reason,
    @Default('') String targetEmail,
    @Default(0) int targetProgress,
    @Default(0) int currentProgress,
    @Default('') String targetProfileId,
    @Default(false) bool profileTransferred,
  }) = _ChangeUserProfileIdModel;

  factory ChangeUserProfileIdModel.fromJson(Map<String, dynamic> json) => _$ChangeUserProfileIdModelFromJson(json);
}
