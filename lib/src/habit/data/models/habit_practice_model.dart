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
    // The hydrated learning_item, parsed with the COURSE feature's model — the
    // same one the lesson flow uses. Not `ExerciseEntity` straight from JSON:
    // `QuestionEntity`'s decoder throws on `type: 'drag_drop'` (the wire form of
    // the whole drag-drop family), which took the entire practices response down
    // with it. `QuestionModel` carries `unknownEnumValue` and maps
    // `(type, form)` onto the entity's dragAndDrop / arrangeTheSequence values.
    LearningItemModel? learningItem,
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
    learningItem: learningItem?.toEntity(),
  );
}
