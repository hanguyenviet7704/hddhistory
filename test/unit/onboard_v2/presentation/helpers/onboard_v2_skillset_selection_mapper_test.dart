import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('OnboardV2SkillsetSelectionMapper', () {
    test('dedupes selected skillsets by id while preserving first selection order', () {
      final mapped = OnboardV2SkillsetSelectionMapper.mapSelected([
        const SkillsetEntity(id: 'think', onboardingIntroduce: SkillsetOnboardingIntroduce.myThoughtsCircle),
        const SkillsetEntity(id: 'feel', onboardingIntroduce: SkillsetOnboardingIntroduce.myFeelingsFeelLoud),
        const SkillsetEntity(id: 'think', onboardingIntroduce: SkillsetOnboardingIntroduce.imBusyAllDay),
      ]);

      expect(mapped.skillsets.map((skillset) => skillset.id), ['think', 'feel']);
      expect(mapped.skillsetIds, ['think', 'feel']);
    });

    test('dedupes mapped P5 concepts while preserving selected order', () {
      final mapped = OnboardV2SkillsetSelectionMapper.mapSelected([
        const SkillsetEntity(id: 'a', onboardingIntroduce: SkillsetOnboardingIntroduce.myThoughtsCircle),
        const SkillsetEntity(id: 'b', onboardingIntroduce: SkillsetOnboardingIntroduce.myThoughtsCircle),
        const SkillsetEntity(id: 'c', onboardingIntroduce: SkillsetOnboardingIntroduce.whatILearnFades),
      ]);

      expect(
        mapped.introduces,
        [
          SkillsetOnboardingIntroduce.myThoughtsCircle,
          SkillsetOnboardingIntroduce.whatILearnFades,
        ],
      );
    });

    test('keeps null-concept skillsets for P7 but activates no P5 node', () {
      final mapped = OnboardV2SkillsetSelectionMapper.mapSelected([
        const SkillsetEntity(id: 'raw_a'),
        const SkillsetEntity(id: 'raw_b'),
      ]);

      expect(mapped.skillsetIds, ['raw_a', 'raw_b']);
      expect(mapped.introduces, isEmpty);
    });

    test('removes empty ids from recommendation id output', () {
      final mapped = OnboardV2SkillsetSelectionMapper.mapSelected([
        const SkillsetEntity(id: ''),
        const SkillsetEntity(id: 'course_skillset'),
      ]);

      expect(mapped.skillsetIds, ['course_skillset']);
    });
  });
}
