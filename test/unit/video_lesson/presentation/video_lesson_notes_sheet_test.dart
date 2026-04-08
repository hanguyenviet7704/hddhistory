import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('opens note editor callback when tapping a note card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var openedNoteId = '';
    final note = const UserVideoLessonNoteEntity(
      id: 'note-1',
      content: 'Tap this note',
      atSecond: 12,
    );

    await tester.pumpWidget(
      _buildTestShell(
        child: VideoLessonNotesSheet(
          state: VideoLessonState.initial().copyWith(
            notes: [note],
          ),
          onClose: () {},
          onBack: () {},
          onAddNote: () {},
          onSave: () {},
          onRetry: () {},
          onLoadMore: () {},
          onDraftChanged: (_) {},
          onEditNote: (selected) => openedNoteId = selected.id,
          onDeleteNote: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('video-lesson-note-card-${note.id}')));
    await tester.pumpAndSettle();

    expect(openedNoteId, note.id);
  });

  testWidgets('dismisses notes sheet when dragging the header down', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var didClose = false;

    await tester.pumpWidget(
      _buildTestShell(
        child: VideoLessonNotesSheet(
          state: VideoLessonState.initial().copyWith(
            notes: const [
              UserVideoLessonNoteEntity(
                id: 'note-1',
                content: 'drag me',
              ),
            ],
          ),
          onClose: () => didClose = true,
          onBack: () {},
          onAddNote: () {},
          onSave: () {},
          onRetry: () {},
          onLoadMore: () {},
          onDraftChanged: (_) {},
          onEditNote: (_) {},
          onDeleteNote: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const ValueKey('video-lesson-notes-sheet-header-drag-region')), const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(didClose, isTrue);
  });
}

Widget _buildTestShell({required Widget child}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, widget) => TranslationProvider(
      child: MaterialApp(
        localizationsDelegates: quill.FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: AppLocaleUtils.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
    child: child,
  );
}
