part of '../../habit.dart';

@freezed
abstract class HabitModel with _$HabitModel {
  const factory HabitModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String skillsetId,
    @Default(HabitLibraryStatusEntity.unknown) HabitLibraryStatusEntity status,
    // Null on the wire for a habit with no picture; the default keeps every
    // consumer dealing in a plain empty string instead of a nullable.
    @JsonKey(defaultValue: '') @Default('') String image,
    String? defaultReminderTime,
    @JsonKey(name: 'order') @Default(0) int sortOrder,
  }) = _HabitModel;

  factory HabitModel.fromJson(Map<String, dynamic> json) => _$HabitModelFromJson(json);
}

extension HabitModelX on HabitModel {
  HabitEntity toEntity() => HabitEntity(
    id: id,
    title: title,
    skillsetId: skillsetId,
    status: status,
    image: image,
    defaultReminderTime: defaultReminderTime,
    sortOrder: sortOrder,
  );
}
