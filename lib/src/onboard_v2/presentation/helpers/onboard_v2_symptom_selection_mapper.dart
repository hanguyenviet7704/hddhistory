part of '../../onboard_v2.dart';

abstract final class OnboardV2SymptomSelectionMapper {
  static List<OnboardingPath> dedupePaths(Iterable<OnboardingPath> paths) {
    final seenPaths = <OnboardingPath>{};
    final dedupedPaths = <OnboardingPath>[];

    for (final path in paths) {
      if (!seenPaths.add(path)) continue;
      dedupedPaths.add(path);
    }

    return dedupedPaths;
  }

  /// Resolves the symptoms available for [selectedPaths] via
  /// [OnboardV2PathResolver] — API-driven when [onboardData] carries `paths`,
  /// otherwise the legacy enum fallback (identical to the previous
  /// `path.symptoms` behaviour when [onboardData] is omitted/empty).
  static List<OnboardingSymptom> availableSymptoms(
    Iterable<OnboardingPath> selectedPaths, {
    OnboardEntity? onboardData,
  }) {
    final dedupedPaths = dedupePaths(selectedPaths);
    final resolvedPaths = OnboardV2PathResolver.resolvePaths(onboardData ?? const OnboardEntity());
    final resolvedPathsByKey = {for (final resolvedPath in resolvedPaths) resolvedPath.key: resolvedPath};

    final matchedSymptoms = <OnboardingSymptom>[];
    for (final path in dedupedPaths) {
      final resolvedPath = resolvedPathsByKey[path.trackingId];
      if (resolvedPath == null) {
        // No resolved match for this key (shouldn't happen once content is
        // seeded) — keep behaviour identical by using the enum directly.
        matchedSymptoms.addAll(path.symptoms);
        continue;
      }
      for (final resolvedSymptom in resolvedPath.symptoms) {
        final symptom = OnboardV2PathResolver.matchSymptom(resolvedSymptom.key);
        if (symptom != null) matchedSymptoms.add(symptom);
      }
    }

    return dedupeSymptoms(matchedSymptoms);
  }

  static List<OnboardingSymptom> dedupeSymptoms(Iterable<OnboardingSymptom> symptoms) {
    final seenSymptoms = <OnboardingSymptom>{};
    final dedupedSymptoms = <OnboardingSymptom>[];

    for (final symptom in symptoms) {
      if (symptom == OnboardingSymptom.unknown || !seenSymptoms.add(symptom)) continue;
      dedupedSymptoms.add(symptom);
    }

    return dedupedSymptoms;
  }

  static List<OnboardingSymptom> retainAvailableSymptoms({
    required Iterable<OnboardingSymptom> selectedSymptoms,
    required Iterable<OnboardingSymptom> availableSymptoms,
  }) {
    final availableSet = availableSymptoms.toSet();
    return dedupeSymptoms(selectedSymptoms.where(availableSet.contains));
  }
}
