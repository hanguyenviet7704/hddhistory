import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  Widget buildSubject({required VoidCallback onRetry}) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => TranslationProvider(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
      child: CourseRoadmapLoadFailureState(onRetry: onRetry),
    );
  }

  group('CourseRoadmapLoadFailureState', () {
    testWidgets('shows the load-failure message and a retry button', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      await tester.pumpWidget(buildSubject(onRetry: () {}));
      await tester.pump();

      expect(find.text('Oops! Something went wrong while loading...'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping retry fires the callback', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      var retried = 0;
      await tester.pumpWidget(buildSubject(onRetry: () => retried++));
      await tester.pump();

      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });
}
