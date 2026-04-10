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

  testWidgets('transitions from editor save back to list without throwing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestShell(
        child: const _NotesSheetSaveTransitionHarness(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save note'), findsOneWidget);

    await tester.tap(find.text('Save note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

class _NotesSheetSaveTransitionHarness extends StatefulWidget {
  const _NotesSheetSaveTransitionHarness();

  @override
  State<_NotesSheetSaveTransitionHarness> createState() => _NotesSheetSaveTransitionHarnessState();
}

class _NotesSheetSaveTransitionHarnessState extends State<_NotesSheetSaveTransitionHarness> {
  VideoLessonState _state = VideoLessonState.initial().copyWith(
    notesMode: VideoLessonNotesMode.editor,
    noteDraft: 'Hello note',
    editingNote: const UserVideoLessonNoteEntity(
      id: 'note-1',
      content: 'Hello note',
      atSecond: 14,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return VideoLessonNotesSheet(
      state: _state,
      onClose: () {},
      onBack: () {
        setState(() {
          _state = _state.copyWith(notesMode: VideoLessonNotesMode.list);
        });
      },
      onAddNote: () {},
      onSave: () {
        setState(() {
          _state = _state.copyWith(
            notesMode: VideoLessonNotesMode.list,
            noteDraft: '',
            editingNote: null,
            noteSaveStatus: VideoLessonCrudStatus.success,
            notes: const [
              UserVideoLessonNoteEntity(
                id: 'note-1',
                content: 'Hello note',
                atSecond: 14,
              ),
            ],
          );
        });
      },
      onRetry: () {},
      onLoadMore: () {},
      onDraftChanged: (value) {
        setState(() {
          _state = _state.copyWith(noteDraft: value);
        });
      },
      onEditNote: (_) {},
      onDeleteNote: (_) {},
    );
  }
}
