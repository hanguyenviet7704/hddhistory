part of '../../lesson.dart';

@freezed
abstract class ScoringCriteriaEntity with _$ScoringCriteriaEntity {
  const factory ScoringCriteriaEntity({
    @Default(0) int maxScore,
    @Default(BaseMultiLanguage()) BaseMultiLanguage criteria,
  }) = _ScoringCriteriaEntity;

  factory ScoringCriteriaEntity.fromJson(Map<String, dynamic> json) => _$ScoringCriteriaEntityFromJson(json);
}

