part of '../../exercise.dart';

@freezed
abstract class OptionModel with _$OptionModel {
  const factory OptionModel({
    @Default(0) int id,
    @Default('') String label,
    @Default('') String value,
  }) = _OptionModel;

  factory OptionModel.fromJson(Map<String, dynamic> json) => _$OptionModelFromJson(json);
}

extension OptionModelExtension on OptionModel {
  OptionEntity toEntity() => OptionEntity(
    id: id,
    label: label,
    value: value,
  );
}