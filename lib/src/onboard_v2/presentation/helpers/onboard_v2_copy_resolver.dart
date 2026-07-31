part of '../../onboard_v2.dart';

/// Resolves narrative-screen copy (P1 intro, P2 name, P6 notification + its
/// preview card) from [OnboardEntity.copy] — fetched from `GET /onboardings`
/// and already available on `onboard_v2_cubit` as `onboardData` — falling
/// back to the bundled l10n string when the API has no entry for [key] yet
/// (first run, no cache, empty/failed response, or an untranslated locale).
/// This keeps onboarding copy identical to today even before the backend is
/// seeded — see [OnboardV2PathResolver] for the same fallback shape applied
/// to paths/symptoms.
String onbCopy(OnboardEntity onboardData, String key, {required String fallback}) {
  for (final entry in onboardData.copy) {
    if (entry.key != key) continue;
    final resolved = entry.value.text.trim();
    return resolved.isNotEmpty ? resolved : fallback;
  }
  return fallback;
}
