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

  static List<OnboardingSymptom> availableSymptoms(Iterable<OnboardingPath> selectedPaths) {
    return dedupeSymptoms(
      dedupePaths(selectedPaths).expand((path) => path.symptoms),
    );
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
