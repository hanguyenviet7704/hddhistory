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
  group('Daily warm-up tracking', () {
    test('question result tracks metadata without raw answer or question text', () async {
      final mockTracking = MockTrackingService();
      final service = AppTrackingService(mockTracking);

      await service.trackDailyWarmUpQuestionResultView(
        questionId: 'question-1',
        questionIndex: 2,
        questionType: 'multiple_choice',
        questionForm: 'Text Gap Filling',
        isCorrect: false,
        resultType: 'incorrect',
      );

      final event = mockTracking.getEvents(TrackingKey.dailyWarmUpQuestionResultView).single;
      expect(event.parameters, containsPair('question_id', 'question-1'));
      expect(event.parameters, containsPair('question_index', 2));
      expect(event.parameters, containsPair('question_type', 'multiple_choice'));
      expect(event.parameters, containsPair('is_correct', false));
      expect(event.parameters.toString(), isNot(contains('raw answer')));
      expect(event.parameters, isNot(containsPair('answer', anything)));
      expect(event.parameters, isNot(containsPair('question_text', anything)));
    });

    test('tracking failures are swallowed', () async {
      final service = AppTrackingService(_ThrowingTrackingService());

      await service.trackDailyWarmUpSkip(source: 'home_open', skipReason: 'api_failure');
    });
  });
}
