part of '../../lesson.dart';

@freezed
abstract class ScoringCriteriaModel with _$ScoringCriteriaModel {
  const factory ScoringCriteriaModel({
    @Default(0) int maxScore,
    @Default('') String criteria,
  }) = _ScoringCriteriaModel;

  factory ScoringCriteriaModel.fromJson(Map<String, dynamic> json) => _$ScoringCriteriaModelFromJson(json);
}

extension ScoringCriteriaModelExtension on ScoringCriteriaModel {
  ScoringCriteriaEntity toEntity() => ScoringCriteriaEntity(
    maxScore: maxScore,
    criteria: criteria,
  );
}