part of '../../habit.dart';

@freezed
abstract class ReanchorReasonModel with _$ReanchorReasonModel {
  const factory ReanchorReasonModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage reason,
    @JsonKey(name: 'order') @Default(0) int sortOrder,
  }) = _ReanchorReasonModel;

  factory ReanchorReasonModel.fromJson(Map<String, dynamic> json) => _$ReanchorReasonModelFromJson(json);
}

extension ReanchorReasonModelX on ReanchorReasonModel {
  ReanchorReasonEntity toEntity() => ReanchorReasonEntity(
    id: id,
    courseId: courseId,
    reason: reason,
    sortOrder: sortOrder,
  );
}
