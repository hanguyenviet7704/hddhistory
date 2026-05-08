import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('CourseFilterRequest', () {
    test('removes empty ids and dedupes skillset ids while preserving order', () {
      final request = CourseFilterRequest.bySkillsets(['', 'a', 'b', 'a', ' ', 'c']);

      expect(request.skillsetIds, ['a', 'b', 'c']);
    });

    test('serializes skillset ids and isAll for the courses API', () {
      final request = PageBreakRequest<CourseFilterRequest>(
        filter: CourseFilterRequest.bySkillsets(['skillset_1', 'skillset_2']),
      );

      final json = request.toJson();
      final encodedQuery = Transformer.urlEncodeMap(json, ListFormat.multiCompatible);

      expect(
        json,
        containsPair(
          'skillsetIds',
          const ListParam<String>(['skillset_1', 'skillset_2'], ListFormat.multi),
        ),
      );
      expect(encodedQuery, contains('skillsetIds=skillset_1&skillsetIds=skillset_2'));
      expect(encodedQuery, isNot(contains('skillsetIds%5B%5D')));
      expect(encodedQuery, isNot(contains('skillset_1%2Cskillset_2')));
      expect(json, containsPair('isAll', true));
      expect(json, containsPair('page', 1));
      expect(json, containsPair('take', 10));
    });

    test('removes unknown symptoms and dedupes onboarding symptoms while preserving order', () {
      final request = CourseFilterRequest.byOnboardingSymptoms([
        OnboardingSymptom.unknown,
        OnboardingSymptom.motivationDisappears,
        OnboardingSymptom.lifeFeelsOverwhelming,
        OnboardingSymptom.motivationDisappears,
      ]);

      expect(
        request.onboardingSymptoms,
        [
          OnboardingSymptom.motivationDisappears,
          OnboardingSymptom.lifeFeelsOverwhelming,
        ],
      );
    });

    test('serializes onboarding symptoms as repeated query params without comma joining', () {
      final request = PageBreakRequest<CourseFilterRequest>(
        filter: CourseFilterRequest.byOnboardingSymptoms([
          OnboardingSymptom.motivationDisappears,
          OnboardingSymptom.endlessScrollingFeelsEmpty,
        ]),
      );

      final json = request.toJson();
      final encodedQuery = Transformer.urlEncodeMap(json, ListFormat.multiCompatible);

      expect(
        json,
        containsPair(
          'onboardingSymptoms',
          const ListParam<String>(
            ['MOTIVATION_DISAPPEARS', 'ENDLESS_SCROLLING_FEELS_EMPTY'],
            ListFormat.multi,
          ),
        ),
      );
      expect(
        encodedQuery,
        contains('onboardingSymptoms=MOTIVATION_DISAPPEARS&onboardingSymptoms=ENDLESS_SCROLLING_FEELS_EMPTY'),
      );
      expect(encodedQuery, isNot(contains('onboardingSymptoms%5B%5D')));
      expect(encodedQuery, isNot(contains('MOTIVATION_DISAPPEARS%2CENDLESS_SCROLLING_FEELS_EMPTY')));
      expect(json, containsPair('isAll', true));
    });
  });
}
