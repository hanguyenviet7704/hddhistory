part of '../../onboard_v2.dart';

/// Resolves screen copy from [OnboardEntity.copy] — mapped out of
/// `GET /onboarding-config` by [OnboardV2ConfigMapper] and already available on
/// `onboard_v2_cubit` as `onboardData` — falling back to the bundled l10n
/// string when the config has no (or a blank) entry for [key]: first run, no
/// cache, empty/failed response, or a section the admin has not filled in yet.
/// Mọi màn onboarding đọc chữ qua đây, nên một config chưa seed vẫn hiện đúng
/// bản l10n 5 thứ tiếng.
String onbCopy(OnboardEntity onboardData, String key, {required String fallback}) {
  for (final entry in onboardData.copy) {
    if (entry.key != key) continue;
    final resolved = entry.value.text.trim();
    return resolved.isNotEmpty ? resolved : fallback;
  }
  return fallback;
}
