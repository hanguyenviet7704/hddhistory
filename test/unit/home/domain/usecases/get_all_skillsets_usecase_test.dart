import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('SkillsetFilterRequest', () {
    test('serializes onboarding introduce values for the skillsets API', () {
      final request = PageBreakRequest<SkillsetFilterRequest>(
        filter: SkillsetFilterRequest.forOnboarding(
          values: [
            SkillsetOnboardingIntroduce.myFeelingsFeelLoud,
            SkillsetOnboardingIntroduce.myThoughtsCircle,
          ],
        ),
      );

      expect(
        request.toJson(),
        containsPair('onboardingIntroduces', 'MY_FEELINGS_FEEL_LOUD,MY_THOUGHTS_CIRCLE'),
      );
      expect(request.toJson(), containsPair('isAll', true));
      expect(request.toJson(), containsPair('page', 1));
      expect(request.toJson(), containsPair('take', 10));
      expect(request.toJson(), containsPair('orderBy', 'createdAt'));
      expect(request.toJson(), containsPair('order', 'desc'));
    });
  });
}
