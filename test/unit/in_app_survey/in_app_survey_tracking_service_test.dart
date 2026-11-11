import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

class _ThrowingTrackingService extends BaseTrackingService {
  _ThrowingTrackingService() : super(trackingServiceName: 'ThrowingTrackingService');

  @override
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    throw StateError('tracking unavailable');
  }
}

void main() {
  group('In-app survey tracking', () {
    test('send click tracks feedback emptiness but never raw feedback text', () async {
      final mockTracking = MockTrackingService();
      final service = AppTrackingService(mockTracking);

      await service.trackInAppSurveySendClick(
        source: 'home',
        branchId: 'branch-1',
        branchIndex: 1,
        selectedOptionIds: ['option-1', 'option-2'],
        feedbackEmpty: false,
      );

      final event = mockTracking.getEvents(TrackingKey.inAppSurveySendClick).single;
      expect(event.parameters, containsPair('source', 'home'));
      expect(event.parameters, containsPair('branch_id', 'branch-1'));
      expect(event.parameters?['selected_option_ids'], ['option-1', 'option-2']);
      expect(event.parameters, containsPair('selected_option_count', 2));
      expect(event.parameters, containsPair('feedback_empty', false));
      expect(event.parameters.toString(), isNot(contains('raw feedback')));
      expect(event.parameters, isNot(containsPair('feedback', anything)));
    });

    test('send failure tracks error type without raw backend body', () async {
      final mockTracking = MockTrackingService();
      final service = AppTrackingService(mockTracking);

      await service.trackInAppSurveySendFailure(
        source: 'home',
        branchId: 'branch-1',
        branchIndex: 1,
        selectedOptionIds: const [],
        feedbackEmpty: true,
        errorType: 'ServerException',
      );

      final event = mockTracking.getEvents(TrackingKey.inAppSurveySendFailure).single;
      expect(event.parameters?['selected_option_ids'], const <String>[]);
      expect(event.parameters, containsPair('error_type', 'ServerException'));
      expect(event.parameters.toString(), isNot(contains('response body')));
    });

    test('tracking failures are swallowed', () async {
      final service = AppTrackingService(_ThrowingTrackingService());

      await service.trackInAppSurveyEntryView(source: 'home');
    });
  });
}
