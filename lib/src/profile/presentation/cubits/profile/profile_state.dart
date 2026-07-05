part of '../../../profile.dart';

enum ProfileStatus { initial, loading, success, failure }

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(ProfileStatus.initial) ProfileStatus status,
    @Default(UserEntity()) UserEntity user,
    String? errorMessage,
  }) = _ProfileState;

  factory ProfileState.initial() => ProfileState();

  factory ProfileState.fromJson(Map<String, dynamic> json) => _$ProfileStateFromJson(json);
}

/// True when the profile page should trigger a (re)fetch: the last load
/// failed, or the user identity is blank. The blank-identity case is only
/// recoverable when [UserCubit] knows the user — loadUser() is
/// id-parameterized, so [ProfileCubit.ensureProfileLoaded] seeds the id from
/// there before fetching. Never true while a load is in flight, so it's safe
/// to call on every page mount and tab return. Kept as a pure function so the
/// self-heal trigger is unit-testable (mirrors [shouldSelfHealHomeData]).
bool shouldEnsureProfileReload(ProfileState state) {
  if (state.status == ProfileStatus.loading) return false;
  return state.user.id.isEmpty || state.status == ProfileStatus.failure;
}

/// Hydration restores the last PERSISTED state — including a `loading`
/// status captured if the process died mid-fetch. Nothing completes that
/// phantom load after a cold start, and [shouldEnsureProfileReload] treats
/// `loading` as "fetch in flight", so a hydrated `loading` would silently
/// disable the self-heal for the whole session even with a blank identity.
/// Normalize it back to `initial` on restore.
ProfileState normalizeHydratedProfileState(ProfileState state) =>
    state.status == ProfileStatus.loading ? state.copyWith(status: ProfileStatus.initial) : state;
