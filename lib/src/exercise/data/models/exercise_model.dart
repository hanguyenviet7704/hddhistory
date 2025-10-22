part of '../../exercise.dart';

@freezed
abstract class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseModel;


  factory ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);
}

extension ExerciseModelExtension on ExerciseModel {
  ExerciseEntity toEntity() => ExerciseEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}