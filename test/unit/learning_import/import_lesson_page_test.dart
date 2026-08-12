import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../support/test_di.dart';

/// Layout checks for the two import screens.
///
/// They exist because both screens were built from a design comp rather than
/// from a running app, and the failure that kind of work actually produces is
/// not a wrong colour — it is a `RenderFlex overflowed` stripe on a device with
/// a narrower screen or a longer translation, which `flutter analyze` cannot
/// see. `pumpWidget` throws on overflow, so simply rendering them at a few
/// widths is the check.
/// Never called by these tests — uploading is not part of rendering. A [Fake]
/// so any accidental call throws loudly instead of returning a silent null.
class _FakeUploadRepository extends Fake implements IUploadRepository {}

class _FakeImportRepository implements ILearningImportRepository {
  const _FakeImportRepository();

  @override
  TaskEither<AppException, ImportQuotaEntity> getQuota() =>
      TaskEither.right(const ImportQuotaEntity(limit: 10, used: 3, remaining: 7));

  @override
  TaskEither<AppException, LearningImportJobEntity> createImport(
    CreateLearningImportParams params,
  ) =>
      TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, LearningImportJobEntity> getJob(String jobId) =>
      TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, BasePageBreak<UserLessonEntity>> getUserLessons({
    int page = 1,
    int take = 20,
  }) =>
      TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, UserLessonEntity> getUserLesson(String id) =>
      TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, Unit> updateProgress(UpdateLessonProgressParams params) =>
      TaskEither.right(unit);

  @override
  TaskEither<AppException, Unit> deleteUserLesson(String id) =>
      TaskEither.right(unit);
}

void main() {
  late LearningImportCubit cubit;

  setUpAll(() async => setupLocaleCubitForTests(locale: AppLocale.vi));

  setUp(() {
    const repository = _FakeImportRepository();
    cubit = LearningImportCubit(
      CreateLearningImportUseCase(repository),
      GetLearningImportJobUseCase(repository),
      GetImportQuotaUseCase(repository),
      UploadCubit(UploadFileUseCase(_FakeUploadRepository())),
    );
  });

  tearDown(() => cubit.close());

  // TranslationProvider is what `context.l10n` reads — without it every string
  // lookup in the page throws before a single pixel is laid out.
  Widget host(Widget child) => TranslationProvider(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: BlocProvider.value(value: cubit, child: child),
          ),
        ),
      );

  /// Narrow enough to be the real floor (iPhone SE) and tall-text enough to
  /// expose a row that only fits at design width.
  const sizes = [Size(320, 568), Size(390, 844), Size(430, 932)];

  group('ImportLessonPage', () {
    for (final size in sizes) {
      testWidgets('renders without overflow at ${size.width.toInt()}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(const ImportLessonPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the source choices and the CTA', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Captured from INSIDE the tree rather than built here: non-base locales
      // are lazily deferred, so `AppLocale.vi.build()` is a Future — and asking
      // the tree is what the page itself does anyway.
      // Captured as plain strings from INSIDE the tree: the generated l10n
      // classes are per-locale types with no shared supertype, and non-base
      // locales are lazily deferred so building one here would be a Future.
      late String youtube;
      late String pdf;
      late String cta;
      late String linkHint;
      await tester.pumpWidget(
        host(Builder(builder: (context) {
          final l10n = context.l10n.learningImport;
          youtube = l10n.sourceYoutube;
          pdf = l10n.sourcePdf;
          cta = l10n.generateCta;
          linkHint = l10n.pasteLinkHint;
          return const ImportLessonPage();
        })),
      );
      await tester.pump();

      expect(find.text(youtube), findsOneWidget);
      expect(find.text(pdf), findsOneWidget);
      expect(find.text(cta), findsOneWidget);
      // YouTube is the default source, so its input is the one on screen.
      expect(find.text(linkHint), findsOneWidget);
    });
  });

  group('ImportGeneratingPage', () {
    for (final size in sizes) {
      testWidgets('renders without overflow at ${size.width.toInt()}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(const ImportGeneratingPage()));
        // One pump only: the illustration animates forever, so pumpAndSettle
        // would never return.
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
