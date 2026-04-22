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

    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(readScrollController.offset, closeTo(offsetBeforeModeSwitch, 1));
  });
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
