part of '../../in_app_survey.dart';

enum InAppSurveyStatus { initial, loading, success, failure }

@freezed
abstract class InAppSurveyState with _$InAppSurveyState {
  const factory InAppSurveyState({
    @Default(InAppSurveyStatus.initial) InAppSurveyStatus status,
    InAppSurveyConfigEntity? config,
    String? errorMessage,
  }) = _InAppSurveyState;

  factory InAppSurveyState.initial() => const InAppSurveyState();

  factory InAppSurveyState.fromJson(Map<String, dynamic> json) => _$InAppSurveyStateFromJson(json);
}

