import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('OnboardV2Tracking sheet params', () {
    test('keeps existing age params and adds sheet age alias', () {
      const option = OnboardOptionEntity(
        id: 18,
        label: BaseMultiLanguage(en: '18-24'),
        trackingLabel: '18-24',
      );

      final params = OnboardV2Tracking.ageSheetParams(option);

      expect(params['selected_age_id'], 18);
      expect(params['selected_age_label'], '18-24');
      expect(params['age'], '18-24');
    });

    test('keeps selected path params and adds sheet path alias', () {
      final params = OnboardV2Tracking.selectedPathSheetParams([
        OnboardingPath.feelBetter,
        OnboardingPath.workBetter,
      ]);

      expect(params['selected_path_ids'], ['FEEL_BETTER', 'WORK_BETTER']);
      expect(params['selected_path_count'], 2);
      expect(params['path_selected'], 'feel_better,work_better');
    });

    test('keeps selected symptom params and adds sheet symptom alias', () {
      final params = OnboardV2Tracking.selectedSymptomSheetParams([
        OnboardingSymptom.motivationDisappears,
        OnboardingSymptom.timeSlipsAway,
      ]);

      expect(params['selected_symptom_ids'], ['MOTIVATION_DISAPPEARS', 'TIME_SLIPS_AWAY']);
      expect(params['selected_symptom_count'], 2);
      expect(params['symptom_selected'], 'motivation_disappear,time_slips_away');
    });

    test('keeps selected path params on path relate event and adds sheet symptom alias', () {
      final params = OnboardV2Tracking.pathRelateSheetParams(
        selectedPaths: [
          OnboardingPath.feelBetter,
          OnboardingPath.workBetter,
        ],
        selectedSymptoms: [
          OnboardingSymptom.motivationDisappears,
          OnboardingSymptom.timeSlipsAway,
        ],
      );

      expect(params['selected_path_ids'], ['FEEL_BETTER', 'WORK_BETTER']);
      expect(params['selected_symptom_ids'], ['MOTIVATION_DISAPPEARS', 'TIME_SLIPS_AWAY']);
      expect(params['symptom_selected'], 'motivation_disappear,time_slips_away');
    });

    test('keeps selected course params and adds sheet course aliases', () {
      const course = CourseEntity(
        id: 'course-1',
        title: BaseMultiLanguage(en: 'Focus Basics'),
      );

      final params = OnboardV2Tracking.courseSelectParams(
        course: course,
        currentCourseIndex: 0,
      );

      expect(params['current_course_index'], 0);
      expect(params['selected_course_id'], 'course-1');
      expect(params['selected_course_name'], 'Focus Basics');
      expect(params['course_id'], 'course-1');
      expect(params['course_name'], 'Focus Basics');
      expect(params['is_best_matched'], 'yes');
    });
  });
}
