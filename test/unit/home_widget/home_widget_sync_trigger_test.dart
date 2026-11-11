import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import 'home_widget_test_fakes.dart';

void main() {
  group('HomeWidgetSyncTrigger', () {
    late String previousAccessToken;

    setUp(() async {
      previousAccessToken = AppGlobalValue.accessToken;
      AppGlobalValue.accessToken = 'token';
      await AppDI.injector.reset();
    });

    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await AppDI.injector.reset();
      AppGlobalValue.accessToken = previousAccessToken;
    });

    test('keeps changed course id when a later generic debounce replaces the timer', () async {
      final repository = FakeHomeWidgetRepository();
      AppDI.injector.registerSingleton<SyncHomeWidgetsUseCase>(SyncHomeWidgetsUseCase(repository));

      HomeWidgetSyncTrigger.requestDebouncedSync(changedCourseId: 'course-active');
      HomeWidgetSyncTrigger.requestDebouncedSync();

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(repository.syncAllParams, hasLength(1));
      expect(repository.syncAllParams.single.changedCourseId, 'course-active');
    });
  });
}
