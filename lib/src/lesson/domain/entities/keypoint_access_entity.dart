part of '../../lesson.dart';

/// Why a keypoint reads the way it does. Mirrors the server's `reason`, and the
/// unknown case is what an older API (or a future reason) lands on.
enum KeypointAccessReason {
  quotaDisabled,
  premium,
  alreadyCompleted,
  todaysFreeKeypoint,

  /// Capped, but today's ticket is unspent — claiming here would succeed. What
  /// lets the app say "1 free lesson today" instead of showing a hard wall.
  ticketAvailable,

  /// Capped and the ticket is already on another keypoint today. A real wall
  /// until tomorrow.
  quotaSpent,
  unknown;

  static KeypointAccessReason fromWire(String? value) => switch (value) {
        'quota_disabled' => KeypointAccessReason.quotaDisabled,
        'premium' => KeypointAccessReason.premium,
        'already_completed' => KeypointAccessReason.alreadyCompleted,
        'todays_free_keypoint' => KeypointAccessReason.todaysFreeKeypoint,
        'ticket_available' => KeypointAccessReason.ticketAvailable,
        'quota_spent' => KeypointAccessReason.quotaSpent,
        _ => KeypointAccessReason.unknown,
      };
}

/// How much of one keypoint this reader may read, as the SERVER decided.
///
/// The free tier gets one keypoint a day read in full; every other keypoint that
/// day stops at [cardCap]. The app deliberately computes none of this: the rule
/// depends on what this reader has already read today, across every device they
/// own, which only the server knows.
@freezed
abstract class KeypointAccessEntity with _$KeypointAccessEntity {
  const factory KeypointAccessEntity({
    /// Highest card index the reader may reach, or null for no limit.
    ///
    /// Handed straight to [KeypointCardCubit.setPaywallCardCap] — the single place
    /// every deck movement is bounded (swipe, pip tap, the voice turning pages,
    /// the return-from-background jump), so nothing else needs to know.
    int? cardCap,
    @Default(KeypointAccessReason.unknown) KeypointAccessReason reason,

    /// Null when the quota does not apply to this reader (premium, off, revision).
    KeypointQuotaEntity? quota,
  }) = _KeypointAccessEntity;
}

@freezed
abstract class KeypointQuotaEntity with _$KeypointQuotaEntity {
  const factory KeypointQuotaEntity({
    @Default(0) int limit,
    @Default(0) int used,
    @Default(0) int remaining,

    /// Which keypoint holds today's ticket, when one has been spent.
    String? claimedKeypointId,
  }) = _KeypointQuotaEntity;
}

/// The answer to "let me past the lock".
@freezed
abstract class KeypointClaimEntity with _$KeypointClaimEntity {
  const factory KeypointClaimEntity({
    @Default(false) bool granted,
    int? cardCap,
    @Default(KeypointAccessReason.unknown) KeypointAccessReason reason,
    String? claimedKeypointId,
  }) = _KeypointClaimEntity;
}
