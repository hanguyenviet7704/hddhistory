part of '../../habit.dart';

/// A BTV-authored "why does this matter to you?" reason for a course, shown on
/// the Re-anchor screen before the course's first lesson (§9.1).
@freezed
abstract class ReanchorReasonEntity with _$ReanchorReasonEntity {
  const factory ReanchorReasonEntity({
    @Default('') String id,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage reason,
    @Default(0) int sortOrder,
  }) = _ReanchorReasonEntity;
}
