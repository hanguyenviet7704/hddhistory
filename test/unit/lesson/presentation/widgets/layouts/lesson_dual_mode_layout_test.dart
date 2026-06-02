import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../../support/test_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('renders close-only shell without the read/listen toggle', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      _buildShellTestApp(
        LessonShellLayout(
          selectedMode: LessonEntryMode.read,
          onModeSelected: (_) {},
          onClose: () => closed = true,
          showModeToggle: false,
          readBody: const Center(child: Text('Read only body')),
          audioBody: const SizedBox.shrink(),
          bottom: const ExerciseContinueButton(onPressed: null),
          isLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppCustomColor.brandPrimary50);
    expect(find.text('Read only body'), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    expect(find.text('Listen'), findsNothing);
    expect(find.byType(LessonProgressBar), findsNothing);
    expect(find.byType(LessonBadge), findsNothing);

    await tester.tap(find.byKey(const ValueKey('lesson-shell-close-button')));
    expect(closed, isTrue);
  });

  testWidgets('keeps sticky bottom action visible when old visibility flag is false', (tester) async {
    final lessonCubit = LessonCubit(
      _FakeGetAllLearningItemsUseCase(),
      _FakeGetLearningItemUseCase(),
      _FakeProgressCubit(),
      _FakeExerciseCubit(),
      _FakeTheoryCubit(),
    );
    addTearDown(lessonCubit.close);

    lessonCubit.setBottomButtonVisible(false);

    await tester.pumpWidget(
      _buildShellTestApp(
        BlocProvider<LessonCubit>.value(
          value: lessonCubit,
          child: LessonShellLayout(
            selectedMode: LessonEntryMode.read,
            onModeSelected: (_) {},
            onClose: () {},
            showModeToggle: true,
            readBody: const Center(child: Text('Read body')),
            audioBody: const Center(child: Text('Audio body')),
            bottom: const ExerciseContinueButton(
              onPressed: null,
              text: 'Sticky action',
            ),
            isLoading: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sticky action'), findsOneWidget);
    expect(find.byType(LessonStickyBottomAction), findsOneWidget);
  });

  testWidgets('preserves read scroll offset when switching read to audio and back', (tester) async {
    final lessonCubit = LessonCubit(
      _FakeGetAllLearningItemsUseCase(),
      _FakeGetLearningItemUseCase(),
      _FakeProgressCubit(),
      _FakeExerciseCubit(),
      _FakeTheoryCubit(),
    );
    final readScrollController = ScrollController();
    var selectedMode = LessonEntryMode.read;

    addTearDown(lessonCubit.close);
    addTearDown(readScrollController.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: BlocProvider<LessonCubit>.value(
              value: lessonCubit,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return LessonDualModeLayout(
                    selectedMode: selectedMode,
                    onModeSelected: (mode) => setState(() => selectedMode = mode),
                    onClose: () {},
                    readBody: ListView.builder(
                      key: const ValueKey('lesson-read-list'),
                      controller: readScrollController,
                      itemExtent: 96,
                      itemCount: 30,
                      itemBuilder: (context, index) => Text('Read item $index'),
                    ),
                    audioBody: const Center(
                      child: Text('Audio body'),
                    ),
                    isLoading: false,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('lesson-read-list')), const Offset(0, -620));
    await tester.pumpAndSettle();
    final offsetBeforeModeSwitch = readScrollController.offset;

    expect(offsetBeforeModeSwitch, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('lesson-mode-audio-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-mode-read-tab')));
    await tester.pumpAndSettle();

    expect(readScrollController.offset, closeTo(offsetBeforeModeSwitch, 1));
  });
}

Widget _buildShellTestApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(home: child),
    ),
  );
}

class _FakeGetAllLearningItemsUseCase implements GetAllLearningItemsUseCase {
  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest params) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetLearningItemUseCase implements GetLearningItemUseCase {
  @override
  TaskEither<AppException, LearningItemEntity> call(String params) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgressCubit implements ProgressCubit {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExerciseCubit implements ExerciseCubit {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTheoryCubit implements TheoryCubit {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
