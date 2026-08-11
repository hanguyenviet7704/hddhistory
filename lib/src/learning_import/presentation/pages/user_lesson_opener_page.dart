part of '../../learning_import.dart';

/// The doorway between a generated lesson and the reader.
///
/// It exists because the reader takes no ids: [LessonRoute] renders whatever
/// [CourseLessonCubit] holds, so SOMETHING has to fetch the lesson and put it
/// there first. On the catalogue side the roadmap does that job; a generated
/// lesson has no roadmap, so this page is the whole of it.
///
/// Deliberately not a reader of any kind. It shows a spinner, hands off, and is
/// replaced — this feature used to own a 429-line deck screen that reimplemented
/// the catalogue's, and deleting that in favour of the real one is the point of
/// this page existing at all.
class UserLessonOpenerPage extends StatefulWidget {
  const UserLessonOpenerPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<UserLessonOpenerPage> createState() => _UserLessonOpenerPageState();
}

class _UserLessonOpenerPageState extends State<UserLessonOpenerPage> {
  /// One hand-off per mount. `openLesson` emits more than once (loading, then
  /// success) and a re-entrant listener would push the reader twice.
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<UserLessonCubit>().openLesson(widget.lessonId));
    });
  }

  /// Resume where the reader stopped — the same promise the roadmap makes.
  void _open(UserLessonEntity lesson) {
    if (_handedOff || !mounted) return;
    _handedOff = true;

    startImportedKeypointLesson(
      lessonCubit: AppDI.injector.get<LessonCubit>(),
      courseLessonCubit: AppDI.injector.get<CourseLessonCubit>(),
      navContext: context,
      userLesson: lesson,
      keypointIndex: lesson.stopAtKeypointIndex.clamp(
        0,
        lesson.keypoints.length - 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(
        context,
        AppCustomColor.backgroundWhite,
      ),
      body: ThemedBackground(
        child: SafeBody(
          child: BlocConsumer<UserLessonCubit, UserLessonState>(
            listenWhen: (previous, current) =>
                previous.selected?.id != current.selected?.id,
            listener: (context, state) {
              final lesson = state.selected;
              // A lesson whose body came back empty has nothing to enter. Rare
              // (generation enforces at least one keypoint), but a reader opened
              // on it would show an empty deck and fire completion on arrival.
              if (lesson == null || lesson.keypoints.isEmpty) return;
              _open(lesson);
            },
            builder: (context, state) {
              final failed = state.status == UserLessonStatus.failure ||
                  (state.status == UserLessonStatus.success &&
                      (state.selected?.keypoints.isEmpty ?? true));

              if (!failed) {
                return const Center(child: CircularProgressIndicator());
              }

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: AppText(
                    context.l10n.learningImport.errorGeneric,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
