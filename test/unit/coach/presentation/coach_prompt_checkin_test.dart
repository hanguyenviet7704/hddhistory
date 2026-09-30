import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

/// Luồng 5 — the check-in question names the habit it asks about, and the
/// Vietnamese address rewriter must not reach into that name.
///
/// The rewriter turns every standalone "bạn" in a FIXED line into the reader's
/// address. Habit titles are CONTENT and are written to the reader too ("Ôn lại
/// một điều bạn đã học hôm qua"), so an unguarded rewrite put the reader's name
/// inside their own habit's name.
void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  Future<String?> resolve(
    WidgetTester tester,
    AppLocale locale,
    String key,
    Map<String, String> args,
  ) async {
    // `setLocaleSync` throws for every locale but the base one: non-base
    // locales are lazily DEFERRED (slang.yaml), so they have to be awaited in.
    await LocaleSettings.setLocale(locale);
    String? line;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                line = coachPrompt(context, key, args);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    return line;
  }

  group('coach.prompt.checkinAsk', () {
    testWidgets('names the habit and drops its leading capital', (tester) async {
      final line = await resolve(tester, AppLocale.vi, 'coach.prompt.checkinAsk', {
        'habit': 'Nghỉ đúng lúc trước khi cạn sức',
        'address': 'Hà',
      });

      expect(line, 'Hôm nay Hà có dịp nào nghỉ đúng lúc trước khi cạn sức chưa?');
    });

    testWidgets('leaves a "bạn" that belongs to the habit title alone', (tester) async {
      final line = await resolve(tester, AppLocale.vi, 'coach.prompt.checkinAsk', {
        'habit': 'Ôn lại một điều bạn đã học hôm qua',
        'address': 'Hà',
      });

      // The frame's own "bạn" follows the address; the title's does not.
      expect(line, 'Hôm nay Hà có dịp nào ôn lại một điều bạn đã học hôm qua chưa?');
    });

    testWidgets('falls back to the title-less wording when the habit is unknown', (tester) async {
      final line = await resolve(tester, AppLocale.vi, 'coach.prompt.checkinAsk', {
        'habit': '',
        'address': 'Hà',
      });

      expect(line, 'Hôm nay Hà có dịp nào dùng tới thói quen này chưa?');
    });

    testWidgets('quotes the habit rather than inlining it outside vi/en', (tester) async {
      final line = await resolve(tester, AppLocale.vi, 'coach.prompt.checkinAsk', {
        'habit': '体からのサインに気づく',
      });

      expect(line, contains('「体からのサインに気づく」'));
    });
  });

  group('coach.prompt.lessonIntro', () {
    testWidgets('does not rewrite a "bạn" inside the quoted habit title', (tester) async {
      final line = await resolve(tester, AppLocale.vi, 'coach.prompt.lessonIntro', {
        'habit': 'Ôn lại một điều bạn đã học hôm qua',
        'address': 'Hà',
      });

      expect(line, contains('Ôn lại một điều bạn đã học hôm qua'));
      expect(line, isNot(contains('một điều Hà đã học')));
    });
  });
}
