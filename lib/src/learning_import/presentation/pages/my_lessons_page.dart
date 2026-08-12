part of '../../learning_import.dart';

/// Everything the user has generated from their own material.
///
/// Reached from a row in Profile. Deliberately a plain list rather than a
/// roadmap: these lessons have no ordering, no prerequisites and no progression
/// — they are a shelf, not a course.
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
    // Same read the Explore button relies on — it also carries the feature
    // switch, which decides whether the create bar belongs on screen.
    unawaited(context.read<LearningImportCubit>().loadQuota());
  }

  Future<void> _startImport() async {
    final cubit = context.read<LearningImportCubit>();

    // No premium gate on the way IN any more. A free reader gets one ticket a
    // week, so the paywall belongs where the ticket runs out — on the import
    // screen itself, next to the count — not in front of the door. Sending them
    // to the paywall from here would also be a promise the server no longer
    // makes: it stopped refusing non-subscribers outright.
    cubit.reset();
    await const ImportLessonRoute().push(context);
    if (mounted) context.read<UserLessonCubit>().loadLessons();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Scaffold(
      backgroundColor:
          studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      body: ThemedBackground(
        child: SafeBody(
          child: Column(
            children: [
              _MyLessonsHeader(title: l10n.myLessonsTitle),
              Expanded(
                child: BlocBuilder<UserLessonCubit, UserLessonState>(
                  builder: (context, state) {
                    if (state.isLoading && state.pageData.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.isEmpty) {
                      return _MyLessonsEmpty(onCreate: _startImport);
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<UserLessonCubit>().loadLessons(),
                      child: BlocBuilder<LearningImportCubit, LearningImportState>(
                        buildWhen: (previous, current) =>
                            previous.job?.id != current.job?.id ||
                            previous.job?.percent != current.job?.percent,
                        builder: (context, importState) {
                          // A run in flight has no lesson row yet — the list
                          // endpoint only knows about finished ones. Without
                          // this the shelf looks unchanged for the minutes a
                          // generation takes, which reads as nothing happened.
                          final job = importState.job;
                          final isRunning = job?.isRunning ?? false;
                          final extra = isRunning ? 1 : 0;

                          return ListView.separated(
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
                                      : context.l10n.learningImport.generatingTitle,
                                  percent: job.percent,
                                );
                              }

                              final lesson =
                                  state.pageData.items[index - extra];

                              return _LessonCard(
                                lesson: lesson,
                                onTap: () =>
                                    LessonReaderRoute(lesson.id).push(context),
                                onDelete: () => _confirmDelete(context, lesson),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // The shelf still lists everything; only making a new one is
              // closed, so the bar goes and the list stays.
              BlocBuilder<LearningImportCubit, LearningImportState>(
                buildWhen: (previous, current) =>
                    previous.quota.enabled != current.quota.enabled ||
                    previous.quota.isKnown != current.quota.isKnown,
                builder: (context, importState) =>
                    importState.quota.isFeatureOff
                    ? const SizedBox.shrink()
                    : _CreateLessonBar(
                        label: l10n.createButton,
                        onPressed: _startImport,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserLessonEntity lesson,
  ) async {
    final l10n = context.l10n.learningImport;
    final cubit = context.read<UserLessonCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppCustomColor.backgroundWhite,
        title: AppText(l10n.deleteConfirmTitle, style: AppStyle.textBold16),
        content: AppText(l10n.deleteConfirmBody, style: AppStyle.text14),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(l10n.cancel, style: AppStyle.text14),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(
              l10n.deleteConfirmAction,
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.backgroundError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) cubit.deleteLesson(lesson.id);
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
  const _MyLessonsEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
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
              style: AppStyle.textBold16.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
            8.verticalSpace,
            // An empty state that explains the feature, not a blank panel: this
            // is the first thing a user sees here and it has to answer "what is
            // this for?" on its own.
            AppText(
              l10n.emptyBody,
              textAlign: TextAlign.center,
              maxLines: 4,
              style: AppStyle.text14.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textSecondary),
              ),
            ),
          ],
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
    required this.onDelete,
  });

  final UserLessonEntity lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
                child: Image.asset(
                  mockUserLessonCover(lesson.id),
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
                    Row(
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
              // Not in the design, kept anyway: deleting a lesson is the only
              // destructive thing the reader owns here, and the comp simply did
              // not draw a way to do it.
              GestureDetector(
                key: Key('my-lesson-delete-${lesson.id}'),
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 20.w,
                    color: AppCustomColor.textTertiary,
                  ),
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
  const _GeneratingCard({required this.title, required this.percent});

  final String title;
  final int percent;

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
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99.r),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 6.h,
                          backgroundColor: const Color(0xFFEDF0F5),
                          valueColor: const AlwaysStoppedAnimation(
                            AppCustomColor.brandPrimary,
                          ),
                        ),
                      ),
                    ),
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

class _CreateLessonBar extends StatelessWidget {
  const _CreateLessonBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        16.h + MediaQuery.paddingOf(context).bottom,
      ),
      color: AppCustomColor.backgroundWhite,
      child: DButton(
        text: label,
        backgroundColor: AppCustomColor.brandPrimary,
        size: Size(double.infinity, 54.h),
        style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
        onPressed: onPressed,
      ),
    );
  }
}
