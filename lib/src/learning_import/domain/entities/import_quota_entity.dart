part of '../../learning_import.dart';

/// How many imports — "tickets" on screen — the user has left this week.
///
/// Read before anything is spent so the screen can say "còn 3 lượt tuần này"
/// instead of letting someone paste a link, press Generate and be refused.
/// [isPremium] rides along because it decides which allowance applies: the
/// endpoint no longer refuses a free reader outright, it gives them a smaller
/// weekly number.
@freezed
abstract class ImportQuotaEntity with _$ImportQuotaEntity {
  const factory ImportQuotaEntity({
    /// THIS reader's weekly allowance — the free one or the premium one.
    @Default(0) int limit,
    @Default(0) int used,
    @Default(0) int remaining,

    /// Next Monday 00:00 (server time) — when [used] goes back to zero.
    DateTime? resetsAt,
    @Default(false) bool isPremium,

    /// What the allowance would be with a subscription — the number the upsell
    /// line quotes. Server-sent rather than hardcoded so the copy cannot drift
    /// away from `LEARNING_IMPORT_CONFIG.quotaPerWeek`.
    @Default(0) int premiumLimit,

    /// The admin's switch. False means the server refuses to START an import —
    /// lessons already made are unaffected, which is why nothing else in the
    /// feature reads this.
    ///
    /// Defaults to true so a server that predates the switch, or a quota read
    /// that never landed, leaves the feature exactly as it was.
    @Default(true) bool enabled,

    /// Optional sentence the admin typed. Empty falls back to the app's own
    /// localized line — a note in Vietnamese reaches a reader in Korea as noise.
    @Default('') String disabledNote,
  }) = _ImportQuotaEntity;
}

extension ImportQuotaEntityX on ImportQuotaEntity {
  /// A ticket left, whoever they are.
  ///
  /// Deliberately NOT `isPremium && remaining > 0` any more: the server stopped
  /// refusing readers without a subscription and started giving them a smaller
  /// weekly allowance, so that older rule would have the app blocking an import
  /// the API was ready to run.
  bool get canImport => enabled && remaining > 0;

  /// Off by the admin's decision rather than by anything the reader did.
  /// Checked separately from [canImport] because the two need different
  /// sentences: "come back Monday" is a lie when the feature is closed.
  bool get isFeatureOff => isKnown && !enabled;

  /// Whether the server has actually told us the allowance yet.
  ///
  /// [LearningImportCubit.loadQuota] fails SILENTLY by design, which leaves the
  /// default entity in state — and its zeroes read exactly like "you have no
  /// tickets and no Premium". Everything that would show a number or block the
  /// generate button checks this first, so a dropped request never turns into a
  /// wrong claim or a refusal the server never asked for.
  ///
  /// Keyed off [limit] rather than a flag: the allowance is a positive constant
  /// server-side, so a zero limit can only mean "not read".
  bool get isKnown => limit > 0;
}
