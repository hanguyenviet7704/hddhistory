part of '../../exercise.dart';

@freezed
abstract class OptionEntity with _$OptionEntity {
  const factory OptionEntity({
    @Default(0) int id,
    @Default('') String text,
    @Default('') String value,
    @Default(false) bool isCorrect,
  }) = _OptionEntity;

  factory OptionEntity.fromJson(Map<String, dynamic> json) => _$OptionEntityFromJson(json);
}
