import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

class _FakeStudyThemeRepository extends Fake implements IStudyThemeRepository {
  @override
  TaskEither<AppException, List<StudyThemePreset>> getStudyThemes() => TaskEither.right(const []);
}

/// Real period names and year ranges, not placeholders: the longest Vietnamese
/// title ("Nam Bắc triều – Trịnh–Nguyễn phân tranh") is exactly what breaks a
/// row layout, so the test must carry it.
CategoryEntity _period(String id, String name, String years, {int courses = 3}) => CategoryEntity(
  id: id,
  title: BaseMultiLanguage(vi: name),
  description: BaseMultiLanguage(vi: years),
  courses: List.generate(courses, (i) => CourseEntity(id: '$id-c$i')),
);

void main() {
  setUpAll(() async => setupLocaleCubitForTests(locale: AppLocale.vi));

  setUp(() {
    if (AppDI.injector.isRegistered<StudyThemeCubit>()) {
      AppDI.injector.unregister<StudyThemeCubit>();
    }
    AppDI.injector.registerSingleton<StudyThemeCubit>(
      StudyThemeCubit(GetStudyThemesUseCase(_FakeStudyThemeRepository())),
    );
  });

  Widget wrap(Widget child) => ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, c) => TranslationProvider(
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: c))),
    ),
    child: BlocProvider.value(
      value: AppDI.injector.get<StudyThemeCubit>(),
      child: child,
    ),
  );

  final periods = [
    _period('p04_ly', 'Nhà Lý', '1009 – 1225'),
    _period('p08_trinhnguyen', 'Nam Bắc triều – Trịnh–Nguyễn phân tranh', '1527 – 1789'),
    _period('p09_tayson', 'Tây Sơn', '1771 – 1802', courses: 0),
  ];

  group('ExploreTimeline', () {
    testWidgets('hiện đủ mọi thời kỳ, đúng thứ tự nhận vào', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(ExploreTimeline(categories: periods, onTapCategory: (_) {})));
      await tester.pump();

      expect(find.text('Dòng thời gian'), findsOneWidget);

      // Order is the contract: CategoryEntity has no index to sort by, so the
      // widget must keep whatever order the API sent.
      final ly = tester.getTopLeft(find.text('Nhà Lý')).dy;
      final trinh = tester.getTopLeft(find.text('Nam Bắc triều – Trịnh–Nguyễn phân tranh')).dy;
      final tayson = tester.getTopLeft(find.text('Tây Sơn')).dy;
      expect(ly, lessThan(trinh));
      expect(trinh, lessThan(tayson));

      expect(find.text('1009 – 1225'), findsOneWidget);
      expect(find.text('1527 – 1789'), findsOneWidget);
    });

    testWidgets('thời kỳ có 0 khoá thì không hiện dòng số khoá', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(ExploreTimeline(categories: periods, onTapCategory: (_) {})));
      await tester.pump();

      // Two periods have 3 courses, Tây Sơn has none.
      expect(find.text('3 khoá'), findsNWidgets(2));
      expect(find.text('0 khoá'), findsNothing);
    });

    testWidgets('chạm một hàng gọi callback với đúng thời kỳ đó', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(ExploreTimeline(categories: periods, onTapCategory: (c) => tapped.add(c.id))),
      );
      await tester.pump();

      await tester.tap(find.text('Tây Sơn'));
      await tester.tap(find.text('Nhà Lý'));
      expect(tapped, ['p09_tayson', 'p04_ly']);
    });

    testWidgets('không có thời kỳ nào thì không vẽ gì, kể cả tiêu đề', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      await tester.pumpWidget(wrap(ExploreTimeline(categories: const [], onTapCategory: (_) {})));
      await tester.pump();

      expect(find.text('Dòng thời gian'), findsNothing);
    });

    testWidgets('mỗi hàng là một nút đọc liền tên, khoảng năm và số khoá', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(ExploreTimeline(categories: periods, onTapCategory: (_) {})));
      await tester.pump();

      expect(find.bySemanticsLabel('Nhà Lý, 1009 – 1225, 3 khoá'), findsOneWidget);
      // No course count for a period without courses — the label must not
      // announce "0 khoá" either.
      expect(find.bySemanticsLabel('Tây Sơn, 1771 – 1802'), findsOneWidget);
      handle.dispose();
    });
  });
}
