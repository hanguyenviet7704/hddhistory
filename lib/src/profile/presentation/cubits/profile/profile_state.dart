part of '../../../profile.dart';

enum ProfileStatus { initial, loading, success, failure }

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(ProfileStatus.initial) ProfileStatus status,
    @Default(UserEntity()) UserEntity user,
    String? errorMessage,
  }) = _ProfileState;

  factory ProfileState.initial() => ProfileState();

  factory ProfileState.fromJson(Map<String, dynamic> json) => _$ProfileStateFromJson(json);
}
