import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

class _FakeDeepLinkService implements IDeepLinkService {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  Uri? initialUri;
  Object? initialLinkError;

  @override
  Stream<Uri> get uriStream => _controller.stream;

  @override
  Future<Uri?> getInitialLink() async {
    if (initialLinkError != null) {
      throw initialLinkError!;
    }

    return initialUri;
  }

  @override
  Future<Uri?> getLatestLink() async => null;

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeDeeplinkPath', () {
    test('normalizes empty and home aliases to the home route', () {
      expect(normalizeDeeplinkPath(''), RoutePath.home);
      expect(normalizeDeeplinkPath('/'), RoutePath.home);
      expect(normalizeDeeplinkPath('/home'), RoutePath.home);
    });

    test('keeps supported route-like paths in slash format', () {
      expect(normalizeDeeplinkPath('/profile'), '/profile');
      expect(normalizeDeeplinkPath('course-roadmap'), '/course-roadmap');
    });
  });

  group('resolveDeeplinkRoutePath', () {
    test('maps host-only home deeplinks to the home route', () {
      expect(resolveDeeplinkRoutePath(Uri.parse('meup://home')), RoutePath.home);
    });

    test('keeps explicit app-link paths intact', () {
      expect(resolveDeeplinkRoutePath(Uri.parse('https://meup.training/notification-request')), RoutePath.notificationRequest);
    });

    test('maps widget host-style course roadmap links to the route path', () {
      expect(
        resolveDeeplinkRoutePath(
          Uri.parse('meup://course-roadmap?courseId=course-1&source=home_widget&widgetType=in_progress_course'),
        ),
        RoutePath.courseRoadmap,
      );
    });
  });

  group('HomeWidgetDeeplinkTarget', () {
    test('parses ready course widget links as course roadmap targets', () {
      final target = HomeWidgetDeeplinkTarget.tryParse(
        Uri.parse('meup://course-roadmap?courseId=course-1&source=home_widget&widgetType=suggest_course'),
      );

      expect(target?.routePath, RoutePath.courseRoadmap);
      expect(target?.widgetType, HomeWidgetType.suggestCourse);
      expect(target?.courseId, 'course-1');
      expect(target?.trackingParams, containsPair('widget_type', 'suggest_course'));
    });

    test('parses weekly streak widget links without course id as course roadmap targets', () {
      final target = HomeWidgetDeeplinkTarget.tryParse(
        Uri.parse('https://meup.training/course-roadmap?source=home_widget&widgetType=weekly_streak'),
      );

      expect(target?.routePath, RoutePath.courseRoadmap);
      expect(target?.widgetType, HomeWidgetType.weeklyStreak);
      expect(target?.courseId, isNull);
    });

    test('parses empty and exhausted widget links as home targets', () {
      final emptyTarget = HomeWidgetDeeplinkTarget.tryParse(
        Uri.parse('meup://home?source=home_widget&widgetType=in_progress_course&state=empty'),
      );
      final exhaustedTarget = HomeWidgetDeeplinkTarget.tryParse(
        Uri.parse('meup://home?source=home_widget&widgetType=suggest_course&state=exhausted'),
      );

      expect(emptyTarget?.routePath, RoutePath.home);
      expect(emptyTarget?.state, HomeWidgetPayloadState.empty);
      expect(exhaustedTarget?.routePath, RoutePath.home);
      expect(exhaustedTarget?.state, HomeWidgetPayloadState.exhausted);
    });

    test('rejects non-widget and unsupported widget links', () {
      expect(HomeWidgetDeeplinkTarget.tryParse(Uri.parse('meup://course-roadmap?widgetType=suggest_course')), isNull);
      expect(
        HomeWidgetDeeplinkTarget.tryParse(Uri.parse('meup://course-roadmap?source=home_widget&widgetType=unknown')),
        isNull,
      );
    });
  });

  group('DeeplinkTarget.tryParse', () {
    test('parses the canonical /open/<key> web link', () {
      final target = DeeplinkTarget.tryParse(
        Uri.parse('https://meup.training/open/paywall?variant=full&c=tet-2027'),
      );

      expect(target?.destination, DeeplinkDestination.paywall);
      expect(target?.params['variant'], 'full');
      expect(target?.campaign, 'tet-2027');
    });

    test('parses the in-app meup://open/<key> form', () {
      final target = DeeplinkTarget.tryParse(Uri.parse('meup://open/course-roadmap?courseId=c1'));

      expect(target?.destination, DeeplinkDestination.courseRoadmap);
      expect(target?.params['courseId'], 'c1');
    });

    test('keeps the legacy prefix-less forms working', () {
      expect(DeeplinkTarget.tryParse(Uri.parse('meup://paywall'))?.destination, DeeplinkDestination.paywall);
      expect(DeeplinkTarget.tryParse(Uri.parse('meup://'))?.destination, DeeplinkDestination.home);
      expect(DeeplinkTarget.tryParse(Uri.parse('https://meup.training/'))?.destination, DeeplinkDestination.home);
      expect(DeeplinkTarget.tryParse(Uri.parse('meup://open'))?.destination, DeeplinkDestination.home);
    });

    test('reports an unknown key instead of dropping it', () {
      final target = DeeplinkTarget.tryParse(Uri.parse('meup://open/does-not-exist'));

      expect(target?.destination, isNull);
      expect(target?.rawKey, 'does-not-exist');
    });

    test('leaves home-widget and live-activity links to their own handlers', () {
      expect(
        DeeplinkTarget.tryParse(Uri.parse('meup://course-roadmap?source=home_widget&widgetType=suggest_course')),
        isNull,
      );
      expect(
        DeeplinkTarget.tryParse(Uri.parse('meup://course-roadmap?courseId=c1&source=live_activity')),
        isNull,
      );
    });

    test('exposes every destination key exactly once', () {
      final values = DeeplinkDestination.values.map((destination) => destination.value).toList();

      expect(values.toSet().length, values.length);
      expect(values.length, 17);
    });
  });

  group('DeeplinkCubit.initialLink', () {
    late _FakeDeepLinkService service;
    late DeeplinkCubit cubit;

    setUp(() {
      service = _FakeDeepLinkService();
      cubit = DeeplinkCubit(service);
    });

    tearDown(() async {
      await cubit.close();
      service.dispose();
    });

    test('returns false for unknown destinations so splash can continue', () async {
      service.initialUri = Uri.parse('https://meup.training/open/no-such-screen');
      cubit.setIsPassSplashScreen(true);

      final isHandled = await cubit.initialLink();

      expect(isHandled, isFalse);
    });

    test('returns false when initial link lookup throws', () async {
      service.initialLinkError = StateError('boom');
      cubit.setIsPassSplashScreen(true);

      final isHandled = await cubit.initialLink();

      expect(isHandled, isFalse);
    });
  });
}
