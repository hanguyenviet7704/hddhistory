import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('OnboardV2SymptomSelectionMapper', () {
    test('merges selected path symptoms while preserving path order', () {
      final symptoms = OnboardV2SymptomSelectionMapper.availableSymptoms([
        OnboardingPath.workBetter,
        OnboardingPath.feelBetter,
      ]);

      expect(
        symptoms,
        [
          OnboardingSymptom.difficultyBuildingHabits,
          OnboardingSymptom.timeSlipsAway,
          OnboardingSymptom.strugglingToBreakBadHabits,
          OnboardingSymptom.motivationDisappears,
          OnboardingSymptom.lifeFeelsOverwhelming,
          OnboardingSymptom.endlessScrollingFeelsEmpty,
        ],
      );
    });

    test('dedupes symptoms and removes unknown values', () {
      final symptoms = OnboardV2SymptomSelectionMapper.dedupeSymptoms([
        OnboardingSymptom.unknown,
        OnboardingSymptom.timeSlipsAway,
        OnboardingSymptom.timeSlipsAway,
        OnboardingSymptom.motivationDisappears,
      ]);

      expect(
        symptoms,
        [
          OnboardingSymptom.timeSlipsAway,
          OnboardingSymptom.motivationDisappears,
        ],
      );
    });

    test('retains only selected symptoms that are still available after path changes', () {
      final retained = OnboardV2SymptomSelectionMapper.retainAvailableSymptoms(
        selectedSymptoms: const [
          OnboardingSymptom.timeSlipsAway,
          OnboardingSymptom.motivationDisappears,
        ],
        availableSymptoms: const [
          OnboardingSymptom.motivationDisappears,
          OnboardingSymptom.lifeFeelsOverwhelming,
        ],
      );

      expect(retained, [OnboardingSymptom.motivationDisappears]);
    });
  });
}
