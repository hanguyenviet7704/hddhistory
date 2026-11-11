import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('CategoryFilterRequest', () {
    test('serializes onboarding introduce values for the categories API', () {
      final request = PageBreakRequest<CategoryFilterRequest>(
        filter: CategoryFilterRequest.forOnboarding(
          values: [
            CategoryOnboardingIntroduce.myFeelingsFeelLoud,
            CategoryOnboardingIntroduce.myThoughtsCircle,
          ],
        ),
      );

      final json = request.toJson();
      final encodedQuery = Transformer.urlEncodeMap(json, ListFormat.multiCompatible);

      expect(
        json,
        containsPair(
          'onboardingIntroduces',
          const ListParam<String>(
            ['MY_FEELINGS_FEEL_LOUD', 'MY_THOUGHTS_CIRCLE'],
            ListFormat.multi,
          ),
        ),
      );
      expect(
        encodedQuery,
        contains(
          'onboardingIntroduces=MY_FEELINGS_FEEL_LOUD&onboardingIntroduces=MY_THOUGHTS_CIRCLE',
        ),
      );
      expect(encodedQuery, isNot(contains('onboardingIntroduces%5B%5D')));
      expect(encodedQuery, isNot(contains('MY_FEELINGS_FEEL_LOUD%2CMY_THOUGHTS_CIRCLE')));
      expect(json, containsPair('isAll', true));
      expect(json, containsPair('page', 1));
      expect(json, containsPair('take', 10));
      expect(json, containsPair('orderBy', 'createdAt'));
      expect(json, containsPair('order', 'desc'));
    });
  });
}
