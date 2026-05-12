import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('SkillsetModel', () {
    test('maps backend onboardingIntroduce wire value to entity enum', () {
      final model = SkillsetModel.fromJson({
        '_id': 'skillset_1',
        'onboardingIntroduce': 'MY_FEELINGS_FEEL_LOUD',
      });

      expect(model.toEntity().onboardingIntroduce, SkillsetOnboardingIntroduce.myFeelingsFeelLoud);
    });

    test('keeps unknown onboardingIntroduce values null', () {
      final model = SkillsetModel.fromJson({
        '_id': 'skillset_1',
        'onboardingIntroduce': 'UNKNOWN_VALUE',
      });

      expect(model.toEntity().onboardingIntroduce, isNull);
    });
  });
}
