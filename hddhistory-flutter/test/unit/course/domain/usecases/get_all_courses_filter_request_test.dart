import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('CourseFilterRequest', () {
    test('removes empty ids and dedupes category ids while preserving order', () {
      final request = CourseFilterRequest.byCategories(['', 'a', 'b', 'a', ' ', 'c']);

      expect(request.categoryIds, ['a', 'b', 'c']);
    });

    test('serializes category ids and isAll for the courses API', () {
      final request = PageBreakRequest<CourseFilterRequest>(
        filter: CourseFilterRequest.byCategories(['category_1', 'category_2']),
      );

      final json = request.toJson();
      final encodedQuery = Transformer.urlEncodeMap(json, ListFormat.multiCompatible);

      expect(
        json,
        containsPair(
          'categoryIds',
          const ListParam<String>(['category_1', 'category_2'], ListFormat.multi),
        ),
      );
      expect(encodedQuery, contains('categoryIds=category_1&categoryIds=category_2'));
      expect(encodedQuery, isNot(contains('categoryIds%5B%5D')));
      expect(encodedQuery, isNot(contains('category_1%2Ccategory_2')));
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
