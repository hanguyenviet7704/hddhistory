part of '../../habit.dart';

@freezed
abstract class HabitPracticeModel with _$HabitPracticeModel {
  const factory HabitPracticeModel({
    @JsonKey(name: '_id') String? id,
    String? habitId,
    String? learningItemId,
    @Default(0) int order,
    // Raw wire string: a method a newer API adds must not fail the whole list.
    String? method,
    // The hydrated learning_item. Reuses the lesson feature's ExerciseEntity,
    // which already parses this exact document (including the `options` ->
    // typedPayload inference in QuestionEntity.fromJson).
    ExerciseEntity? learningItem,
  }) = _HabitPracticeModel;

  factory HabitPracticeModel.fromJson(Map<String, dynamic> json) => _$HabitPracticeModelFromJson(json);
}

extension HabitPracticeModelX on HabitPracticeModel {
  HabitPracticeEntity toEntity() => HabitPracticeEntity(
    id: id ?? '',
    habitId: habitId ?? '',
    learningItemId: learningItemId ?? '',
    // `this.` is required: a bare `order` resolves to a top-level `order` of
    // type `Order` pulled in by the project barrel, not to this field.
    order: this.order,
    method: HabitCheckinMethodEntity.fromApi(method),
    learningItem: learningItem,
  );
}
