import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

/// The API buckets day-scoped data (the learning streak's week strip above all)
/// by the caller's own calendar day, and learns that calendar from this header.
/// Without it the server falls back to its own timezone — UTC — which files a
/// 00:30 check-in in Vietnam under the previous day.
void main() {
  group('AppInterceptor timezone header', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('attaches the device UTC offset in minutes to every request', () async {
      final interceptor = AppInterceptor(
        UserCubit(NoOpTrackingService()),
        AppDI.injector.get<LocaleCubit>(),
        PageCubit(),
      );
      final options = RequestOptions(path: AppEndpoint.coursesUserProgressStreakCheckIn);

      interceptor.onRequest(options, RequestInterceptorHandler());

      final header = options.headers['x-timezone-offset'];
      expect(header, isNotNull);
      // Sent as the plain minute count, which is what the server parses. In
      // Vietnam this is '420'; asserted against the running device's own offset
      // so the test holds wherever it runs.
      expect(header, DateTime.now().timeZoneOffset.inMinutes.toString());
      expect(int.tryParse(header as String), isNotNull);
    });

    test('still sends the language header alongside it', () async {
      final interceptor = AppInterceptor(
        UserCubit(NoOpTrackingService()),
        AppDI.injector.get<LocaleCubit>(),
        PageCubit(),
      );
      final options = RequestOptions(path: AppEndpoint.coursesUserProgressStreak);

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['lang'], isNotNull);
      expect(options.headers['x-timezone-offset'], isNotNull);
    });
  });
}
