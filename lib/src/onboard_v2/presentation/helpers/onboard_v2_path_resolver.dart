part of '../../onboard_v2.dart';

/// Resolves the effective onboarding paths (and their nested symptoms) to
/// render on the path-selection / path-map / symptom-selection screens.
///
/// Prefers [OnboardEntity.paths] — fetched from `GET /onboardings` and
/// already available on `onboard_v2_cubit` as `onboardData` — and falls back
/// to the legacy [OnboardingPath] / [OnboardingSymptom] enums (+ their l10n
/// labels and bundled icons) when the API has no data yet (first run, no
/// cache, empty/failed response). This keeps onboarding content identical to
/// today even before the backend is seeded.
///
/// See meup-api/plans/260717-onboarding-v2-api-driven/design.md.
abstract final class OnboardV2PathResolver {
  static List<OnboardPathEntity> resolvePaths(OnboardEntity onboardData) {
    if (onboardData.paths.isNotEmpty) return onboardData.paths;
    return _fallbackPaths;
  }

  static List<OnboardSymptomEntity> resolveSymptoms(OnboardEntity onboardData) {
    return [for (final path in resolvePaths(onboardData)) ...path.symptoms];
  }

  /// Maps a resolved path `key` back to the legacy enum so selection state
  /// and course-recommendation matching keep the same key/trackingLabel
  /// contract, whether content came from the API or the offline fallback.
  static OnboardingPath? matchPath(String key) {
    for (final path in OnboardingPath.values) {
      if (path.trackingId == key) return path;
    }
    return null;
  }

  /// Maps a resolved symptom `key` back to the legacy enum — see [matchPath].
  static OnboardingSymptom? matchSymptom(String key) {
    for (final symptom in OnboardingSymptom.values) {
      if (symptom.trackingId == key) return symptom;
    }
    return null;
  }

  static List<OnboardPathEntity> get _fallbackPaths {
    final paths = OnboardingPath.values;
    return [for (var i = 0; i < paths.length; i++) _fallbackPathEntity(paths[i], order: i)];
  }

  static OnboardPathEntity _fallbackPathEntity(OnboardingPath path, {required int order}) {
    final symptoms = path.symptoms;
    return OnboardPathEntity(
      key: path.trackingId,
      title: _fallbackTitle(path.title),
      shortTitle: path.shortTitle,
      iconKey: OnboardV2IconResolver.iconKeyForLegacyPath(path),
      trackingLabel: path.trackingId,
      order: order,
      symptoms: [for (var i = 0; i < symptoms.length; i++) _fallbackSymptomEntity(symptoms[i], order: i)],
    );
  }

  static OnboardSymptomEntity _fallbackSymptomEntity(OnboardingSymptom symptom, {required int order}) => OnboardSymptomEntity(
    key: symptom.trackingId,
    title: _fallbackTitle(symptom.title),
    trackingLabel: symptom.trackingId,
    order: order,
  );

  /// [OnboardingPath.title] / [OnboardingSymptom.title] already resolve
  /// through the app's active locale (`l10n`). Mirroring that single
  /// resolved string into every [BaseMultiLanguage] slot keeps `.text` (and
  /// any direct locale-field read) correct regardless of the user's
  /// language, without needing a second, locale-specific translation lookup.
  static BaseMultiLanguage _fallbackTitle(String resolvedText) => BaseMultiLanguage(
    en: resolvedText,
    vi: resolvedText,
    zh: resolvedText,
    ja: resolvedText,
    ko: resolvedText,
  );
}
