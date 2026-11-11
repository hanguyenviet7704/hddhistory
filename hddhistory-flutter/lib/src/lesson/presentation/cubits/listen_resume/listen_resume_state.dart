part of '../../../lesson.dart';

@freezed
abstract class ListenResumeState with _$ListenResumeState {
  const factory ListenResumeState({
    @Default('') String keypointId,
    @Default(0) int positionMs,
    @Default(0) int updatedAtMillis,
  }) = _ListenResumeState;

  factory ListenResumeState.initial() => const ListenResumeState();

  factory ListenResumeState.fromJson(Map<String, dynamic> json) => _$ListenResumeStateFromJson(json);
}
