part of '../../exercise.dart';

enum ExerciseStatus { initial, loading, success, failure }

@freezed
abstract class ExerciseState with _$ExerciseState {
  const factory ExerciseState({
    @Default(ExerciseStatus.initial) ExerciseStatus status,
    @Default(BasePageBreak<ExerciseEntity>()) BasePageBreak<ExerciseEntity> pageData,
    ExerciseEntity? selectedItem,
    String? errorMessage,
  }) = _ExerciseState;

  factory ExerciseState.initial() => ExerciseState();

  factory ExerciseState.fromJson(Map<String, dynamic> json) => _$ExerciseStateFromJson(json);
}
