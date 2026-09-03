part of '../../learning_import.dart';

/// Everything the user has generated from their own material.
///
/// Reached from a row in Profile. Deliberately a plain list rather than a
/// roadmap: these lessons have no ordering, no prerequisites and no progression
/// — they are a shelf, not a course.
///
/// Read-only, by product call (2026-08-12): no delete, and no create bar over
/// the list. The EMPTY state is the one exception (2026-08-25): a reader who
/// lands here with nothing on the shelf was told what the feature does and then
/// left with nowhere to do it — the import form lives on Explore, a tab away.
/// A shelf that already has lessons still has no create affordance; there the
/// Explore header's button (`course_header.dart` → `ImportLessonRoute`) is the
/// way in.
class MyLessonsPage extends StatefulWidget {
  const MyLessonsPage({super.key});

  @override
  State<MyLessonsPage> createState() => _MyLessonsPageState();
}

class _MyLessonsPageState extends State<MyLessonsPage> {
  @override
  void initState() {
    super.initState();
    // Refetched on every entry rather than cached: a lesson may have finished
    // generating while the user was elsewhere in the app.
    context.read<UserLessonCubit>().loadLessons();
    // The allowance is read again, for one reason only: the empty state's create
    // button is hidden while the admin has importing switched off, and
    // `isFeatureOff` can only be true once the server has said so (see
    // `isKnown`). Without this the gate would be decorative on a reader who
    // never opened Explore this session.
    unawaited(context.read<LearningImportCubit>().loadQuota());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Scaffold(
      backgroundColor:
          studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      body: ThemedBackground(
        child: BlocListener<LearningImportCubit, LearningImportState>(
          // The run just ended. Its lesson exists on the server now but not in
          // the page this screen fetched on entry, so the card vanishes and
          // nothing takes its place — the shelf would be missing the very lesson
          // the reader watched being made. Ask the list again.
          listenWhen: (previous, current) =>
              (previous.job?.isRunning ?? false) &&
              !(current.job?.isRunning ?? false),
          listener: (context, _) =>
              unawaited(context.read<UserLessonCubit>().loadLessons()),
          child: SafeBody(
            child: Column(
              children: [
                _MyLessonsHeader(title: l10n.myLessonsTitle),
                Expanded(
                  // The run in flight is read FIRST, outside the lesson list.
                  //
                  // A running job has no lesson row yet — the list endpoint only
                  // knows about finished ones — so the shelf is built from two
                  // sources and the empty/loading branches below may only speak for
                  // one of them. They used to be checked first, which meant a
                  // reader's FIRST import spent its several minutes looking at
                  // "Chưa có bài nào": nothing on the screen they had just been
                  // sent to said a lesson was being made.
                  child: BlocBuilder<LearningImportCubit, LearningImportState>(
                    buildWhen: (previous, current) =>
                        previous.job?.id != current.job?.id ||
                        previous.job?.percent != current.job?.percent ||
                        (previous.job?.isRunning ?? false) !=
                            (current.job?.isRunning ?? false),
                    builder: (context, importState) {
                      final job = importState.job;
                      final isRunning = job?.isRunning ?? false;
                      final extra = isRunning ? 1 : 0;

                      return BlocBuilder<UserLessonCubit, UserLessonState>(
                        builder: (context, state) {
                          // Nothing generating: the shelf is only as good as the
                          // list, so a spinner and an empty state are honest.
                          if (!isRunning) {
                            if (state.isLoading && state.pageData.items.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state.isEmpty) {
                              return const _MyLessonsEmpty();
                            }
                          }

                          return RefreshIndicator(
                            onRefresh: () =>
                                context.read<UserLessonCubit>().loadLessons(),
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                8.h,
                                20.w,
                                floatingNavBarHeight(context) + 20.h,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: state.pageData.items.length + extra,
                              separatorBuilder: (_, _) => 12.verticalSpace,
                              itemBuilder: (context, index) {
                                if (isRunning && index == 0) {
                                  return _GeneratingCard(
                                    title: job!.sourceLabel.isNotEmpty
                                        ? job.sourceLabel
                                        : context
                                              .l10n
                                              .learningImport
                                              .generatingTitle,
                                  );
                                }

                                final lesson =
                                    state.pageData.items[index - extra];

                                return _LessonCard(
                                  lesson: lesson,
                                  onTap: () =>
                                      LessonReaderRoute(lesson.id).push(context),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _MyLessonsHeader extends StatelessWidget {
  const _MyLessonsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 8.h),
      child: Row(
        children: [
          IconButton(
            // A plain pop: `didPop` names the page underneath (the Library tab,
            // which pushed this one) by itself, so there is nothing to assert
            // here — the nav bar going
            // missing on Profile after reading a generated lesson was the
            // lesson reader reclaiming its own name from a backgrounded branch,
            // not a blank name from this pop. See `canAssertOwnRouteName` and
            // `user_lesson_roadmap_nav_test.dart`.
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.w,
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
          Expanded(
            child: AppText(
              title,
              style: AppStyle.textBold16.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLessonsEmpty extends StatelessWidget {
  const _MyLessonsEmpty();

  /// Over to the import form.
  ///
  /// `go`, not `push`: [ImportLessonRoute] is mounted under the EXPLORE branch
  /// (see `routes_shell.dart`) while this screen sits in the Library branch, and
  /// an imperative push would build the form in a navigator that is off screen —
  /// the tap would look like it did nothing. The name is claimed the way the
  /// deeplink handler claims one: the form takes the whole screen, so the
  /// floating pill must not stay over it, and a branch that ALREADY has the form
  /// on top pushes nothing for the route observer to notice.
  void _openImport(BuildContext context) {
    AppHaptic.select();
    const ImportLessonRoute().go(context);
    AppDI.injector.get<PageCubit>().setCurrentRouteName(
      RouteNamed.importLesson,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    // Over a custom study background this block gets a card of its own (below),
    // so its ink is the ordinary dark card ink either way — never light-on-photo.
    // Light ink was the previous answer and it fails on a BRIGHT patch of a photo
    // exactly as dark ink fails on a dark one: three lines of centred text on a
    // forest, with nothing behind them, has no contrast to rely on.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_stories_outlined,
          size: 56.w,
          color: studyThemeCardMuted(context, AppCustomColor.textSecondary),
        ),
        20.verticalSpace,
        AppText(
          l10n.emptyTitle,
          textAlign: TextAlign.center,
          style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
        ),
        8.verticalSpace,
        // An empty state that explains the feature, not a blank panel: this
        // is the first thing a user sees here and it has to answer "what is
        // this for?" on its own.
        AppText(
          l10n.emptyBody,
          textAlign: TextAlign.center,
          maxLines: 4,
          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
        ),
        // …and then a way to actually do it. Gone entirely while the feature is
        // switched off, for the same reason the Explore header drops its pill: a
        // button that opens a screen whose only message is "not right now"
        // reads as broken rather than as paused. Unknown allowance still shows
        // the button — the server stays the judge (see `isFeatureOff`).
        BlocBuilder<LearningImportCubit, LearningImportState>(
          buildWhen: (previous, current) =>
              previous.quota.isFeatureOff != current.quota.isFeatureOff,
          builder: (context, importState) => importState.quota.isFeatureOff
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: _MakeLessonButton(onTap: () => _openImport(context)),
                ),
        ),
      ],
    );

    // No card on the stock theme: there the page background IS a flat light
    // surface, and a white panel on light gray would be a box drawn around
    // nothing.
    if (!studyThemeHasCustomBg(context)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: content,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ThemedGlassCard(
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h),
          child: content,
        ),
      ),
    );
  }
}

/// The empty shelf's only action: "make one".
///
/// Shaped like the import screen's own Generate button (brand pill, 99r) rather
/// than like a card, so the two ends of the same errand look related.
class _MakeLessonButton extends StatelessWidget {
  const _MakeLessonButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.learningImport.createButton;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const Key('my-lessons-empty-create'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          // Sized by its padding, with no `alignment`: a Container given an
          // alignment and no width fills the column's whole cross axis, and a
          // full-bleed pill inside a centred card reads as a banner.
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 20.w, color: Colors.white),
              8.horizontalSpace,
              AppText(
                label,
                style: AppStyle.textBold16.copyWith(
                  fontSize: 15.5.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One made lesson: cover, title, and where the reader is in it.
///
/// Cover on the left rather than a source glyph, because that is what makes a
/// shelf scannable — a column of identical PDF icons is a list you read word by
/// word. The picture is a stand-in (see [mockUserLessonCover]); the progress
/// line under the title is real.
class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  final UserLessonEntity lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    final percent = lesson.readPercent;
    final done = lesson.isCompleted;
    final started = percent > 0;

    return Semantics(
      button: true,
      label: lesson.title,
      child: GestureDetector(
        key: Key('my-lesson-card-${lesson.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFEEF1F6), width: 1.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                // The admin-pool cover when the server dealt one; the bundled
                // mock otherwise. DCachedImage renders either kind of path.
                child: DCachedImage(
                  url: userLessonCoverArt(lesson),
                  width: 78.w,
                  height: 78.w,
                  fit: BoxFit.cover,
                ),
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      lesson.title,
                      maxLines: 2,
                      style: AppStyle.text16.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    8.verticalSpace,
                    // A lesson the server is still writing announces itself as
                    // such — a spinner where the progress icon goes. It is
                    // already readable (the roadmap gates per keypoint), so the
                    // card stays tappable; this line just explains why it may
                    // look short.
                    lesson.isContentPartial
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  color: AppCustomColor.brandPrimary,
                                ),
                              ),
                              9.horizontalSpace,
                              AppText(
                                l10n.statusCreating,
                                style: AppStyle.textBold12.copyWith(
                                  fontSize: 13.sp,
                                  color: AppCustomColor.brandPrimary,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle_rounded
                                    : (started
                                          ? Icons.incomplete_circle_rounded
                                          : Icons.circle_outlined),
                                size: 16.w,
                                color: started
                                    ? AppCustomColor.brandPrimary
                                    : AppCustomColor.textTertiary,
                              ),
                              7.horizontalSpace,
                              AppText(
                                started
                                    ? l10n.readingProgress(percent: percent)
                                    : l10n.statusNotStarted,
                                style: AppStyle.textBold12.copyWith(
                                  fontSize: 13.sp,
                                  color: started
                                      ? AppCustomColor.brandPrimary
                                      : AppCustomColor.textTertiary,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lesson being generated right now, at the top of the shelf.
///
/// Same row shape as a finished one so the list does not jump when it lands,
/// but with the document mark instead of a cover — there is no lesson yet to
/// have a picture of — and a bar where the progress line goes.
class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEEF1F6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 78.w,
            height: 78.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFB),
              borderRadius: BorderRadius.circular(15.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.description_outlined,
              size: 30.w,
              color: AppCustomColor.brandPrimary,
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  maxLines: 2,
                  style: AppStyle.text16.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    Expanded(child: ImportProgressBar(minHeight: 6.h)),
                    9.horizontalSpace,
                    AppText(
                      context.l10n.learningImport.statusCreating,
                      style: AppStyle.textBold12.copyWith(
                        color: AppCustomColor.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
