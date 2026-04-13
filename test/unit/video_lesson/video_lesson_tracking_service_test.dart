import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('AppTrackingService video lesson performance metrics', () {
    late MockTrackingService trackingBase;
    late AppTrackingService trackingService;

    setUp(() {
      trackingBase = MockTrackingService();
      trackingService = AppTrackingService(trackingBase);
    });

    test('tracks player init metrics with warmup state and first-frame time', () async {
      await trackingService.trackVideoLessonPlayerInit(
        _trackingData(),
        nodeId: 'node-1',
        initStatus: 'success',
        warmupState: 'hit_ready',
        timeToFirstFrameMs: 42,
      );

      final event = trackingBase.getEvents(TrackingKey.videoLessonPlayerInit).single;
      expect(event.parameters?['node_id'], 'node-1');
      expect(event.parameters?['init_status'], 'success');
      expect(event.parameters?['warmup_state'], 'hit_ready');
      expect(event.parameters?['time_to_first_frame_ms'], 42);
    });

    test('tracks seek latency on the existing seek event', () async {
      await trackingService.trackVideoLessonSeek(
        _trackingData(),
        nodeId: 'node-1',
        seekFromSecond: 8,
        seekToSecond: 19,
        seekLatencyMs: 135,
      );

      final event = trackingBase.getEvents(TrackingKey.videoLessonSeek).single;
      expect(event.parameters?['seek_from_second'], 8);
      expect(event.parameters?['seek_to_second'], 19);
      expect(event.parameters?['seek_latency_ms'], 135);
    });
  });
}

CourseLessonTrackingData _trackingData() => CourseLessonTrackingData(
  skillset: const SkillsetEntity(
    id: 'skill-1',
    title: BaseMultiLanguage(en: 'Listening'),
  ),
  course: const CourseEntity(
    id: 'course-1',
    title: BaseMultiLanguage(en: 'English'),
    skillsetId: 'skill-1',
  ),
  lesson: const LessonEntity(
    id: 'lesson-1',
    courseId: 'course-1',
    type: LessonType.video,
    title: BaseMultiLanguage(en: 'Intro video'),
  ),
);
