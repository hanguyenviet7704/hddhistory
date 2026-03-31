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
      expect(resolveDeeplinkRoutePath(Uri.parse('https://meup.com/notification-request')), RoutePath.notificationRequest);
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

    test('returns false for unsupported initial links so splash can continue', () async {
      service.initialUri = Uri.parse('https://meup.com/profile');
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
