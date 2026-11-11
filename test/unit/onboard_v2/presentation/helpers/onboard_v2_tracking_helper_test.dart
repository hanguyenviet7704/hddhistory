import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('OnboardV2Tracking sheet params', () {
    test('screen-view + action event names match the tracking sheet exactly', () {
      // Screen views
      expect(TrackingKey.onboardV2P1View, 'obd_welcome_scr_view');
      expect(TrackingKey.onboardV2P2View, 'obd_name_scr_view');
      expect(TrackingKey.onboardV2P3View, 'obd_age_scr_view');
      expect(TrackingKey.onboardV2P4View, 'obd_notif_scr_view');
      expect(TrackingKey.onboardV2P5View, 'obd_paths_scr_view');
      expect(TrackingKey.onboardV2P6View, 'obd_infor_scr_view');
      expect(TrackingKey.onboardV2P7View, 'obd_symptom_scr_view');
      expect(TrackingKey.onboardV2P8View, 'obd_course_view');
      expect(TrackingKey.onboardV2P10View, 'obd_result_scr_view');
      expect(TrackingKey.onboardV2P11View, 'obd_theme_scr_view');
      // Primary actions
      expect(TrackingKey.onboardV2P1GetStartedClick, 'obd_welcome_get_started');
      expect(TrackingKey.onboardV2P2ContinueClick, 'obd_name_continue');
      expect(TrackingKey.onboardV2P3ContinueClick, 'obd_age_select');
      expect(TrackingKey.onboardV2P5ContinueClick, 'obd_paths_select');
      expect(TrackingKey.onboardV2P6ContinueClick, 'obd_infor_continue');
      expect(TrackingKey.onboardV2P7ContinueClick, 'obd_symptom_select');
      expect(TrackingKey.onboardV2CourseSelectClick, 'obd_course_select');
      expect(TrackingKey.onboardV2P9StartExploreClick, 'obd_theme_select');
      // Notification allow vs later are now distinct
      expect(TrackingKey.onboardV2NotificationNotifyClick, 'obd_notif_allow');
      expect(TrackingKey.onboardV2NotificationMaybeLaterClick, 'obd_notif_later');
      expect(
        TrackingKey.onboardV2NotificationNotifyClick,
        isNot(TrackingKey.onboardV2NotificationMaybeLaterClick),
      );
      // Back events
      expect(TrackingKey.onboardV2AgeBack, 'obd_age_back');
      expect(TrackingKey.onboardV2PathsBack, 'obd_paths_back');
      expect(TrackingKey.onboardV2InforBack, 'obd_infor_back');
      expect(TrackingKey.onboardV2SymptomBack, 'obd_symptom_back');
    });

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
