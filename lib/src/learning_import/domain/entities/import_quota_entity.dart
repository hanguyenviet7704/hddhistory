part of '../../learning_import.dart';

/// How many imports the user has left this calendar month.
///
/// Read before the confirm step so the sheet can say "còn 7/10 lượt" instead of
/// letting someone commit to an import that will be rejected. [isPremium] rides
/// along because the same call answers both gates the create endpoint applies.
@freezed
abstract class ImportQuotaEntity with _$ImportQuotaEntity {
  const factory ImportQuotaEntity({
    @Default(0) int limit,
    @Default(0) int used,
    @Default(0) int remaining,

    /// Start of next calendar month — when [used] goes back to zero.
    DateTime? resetsAt,
    @Default(false) bool isPremium,
  }) = _ImportQuotaEntity;
}

extension ImportQuotaEntityX on ImportQuotaEntity {
  bool get canImport => isPremium && remaining > 0;
}
