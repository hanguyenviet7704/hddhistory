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
      expect(event.parameters?['video_position'], 19);
      expect(event.parameters?['keypoint_id'], 'keypoint-1');
    });

    test('tracks video pause with existing params and sheet position alias', () async {
      await trackingService.trackVideoLessonPauseClick(
        _trackingData(),
        nodeId: 'node-1',
        videoPosition: 17,
      );

      final event = trackingBase.getEvents(TrackingKey.videoLessonPauseClick).single;
      expect(event.parameters?['node_id'], 'node-1');
      expect(event.parameters?['lesson_id'], 'lesson-1');
      expect(event.parameters?['keypoint_id'], 'keypoint-1');
      expect(event.parameters?['video_position'], 17);
    });
  });

  group('AppTrackingService audio lesson sheet params', () {
    late MockTrackingService trackingBase;
    late AppTrackingService trackingService;

    setUp(() {
      trackingBase = MockTrackingService();
      trackingService = AppTrackingService(trackingBase);
    });

    test('tracks audio pause with audio position alias', () async {
      await trackingService.trackKeypointAudioPauseClick(
        _keypointTrackingData(),
        audioPosition: 21,
      );

      final event = trackingBase.getEvents(TrackingKey.keypointAudioPauseClick).single;
      expect(event.parameters?['keypoint_id'], 'keypoint-1');
      expect(event.parameters?['audio_position'], 21);
      expect(event.parameters?['mode'], LessonEntryMode.audio.routeValue);
    });

    test('tracks audio-to-text mode switch with audio position alias', () async {
      await trackingService.trackKeypointAudioModeSwitch(
        _keypointTrackingData(),
        mode: LessonEntryMode.read.routeValue,
        entryPoint: 'in_route_switch',
        audioPosition: 12,
      );

      final event = trackingBase.getEvents(TrackingKey.keypointAudioToTextSwitchClick).single;
      expect(event.parameters?['entry_point'], 'in_route_switch');
      expect(event.parameters?['mode'], LessonEntryMode.read.routeValue);
      expect(event.parameters?['audio_position'], 12);
    });

    test('keeps speed and adds sheet speed value alias', () async {
      await trackingService.trackKeypointAudioSpeedSelect(
        _keypointTrackingData(),
        speed: 1.25,
      );

      final event = trackingBase.getEvents(TrackingKey.keypointAudioSpeedSelect).single;
      expect(event.parameters?['speed'], 1.25);
      expect(event.parameters?['speed_value'], 1.25);
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
    keypoints: [
      KeypointEntity(
        id: 'keypoint-1',
        title: BaseMultiLanguage(en: 'Warm up'),
      ),
    ],
  ),
);

KeypointTrackingData _keypointTrackingData() => KeypointTrackingData(
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
    type: LessonType.lesson,
    title: BaseMultiLanguage(en: 'Intro audio'),
  ),
  keypoint: const KeypointEntity(
    id: 'keypoint-1',
    title: BaseMultiLanguage(en: 'Warm up'),
  ),
);
