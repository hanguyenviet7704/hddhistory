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
  }

  Future<void> _startImport() async {
    final cubit = context.read<LearningImportCubit>();
    final isPremium =
        AppDI.injector.get<ProfileCubit>().state.user.isPremium;

    if (!isPremium) {
      AppDI.injector
          .get<IapCubit>()
          .setPaywallEntryPoint(PaywallEntryPoint.learningImport);
      const PaywallRoute().push(context);
      return;
    }

    cubit.reset();
    await showImportSourceSheet(context);
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
                        itemCount: state.pageData.items.length,
                        separatorBuilder: (_, _) => 12.verticalSpace,
                        itemBuilder: (context, index) {
                          final lesson = state.pageData.items[index];

                          return _LessonCard(
                            lesson: lesson,
                            onTap: () =>
                                LessonReaderRoute(lesson.id).push(context),
                            onDelete: () => _confirmDelete(context, lesson),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              _CreateLessonBar(label: l10n.createButton, onPressed: _startImport),
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
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    lesson.sourceType == ImportSourceTypeEntity.youtube
                        ? Icons.smart_display_outlined
                        : Icons.picture_as_pdf_outlined,
                    size: 22.w,
                    color: AppCustomColor.brandPrimary,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppText(
                      lesson.title,
                      maxLines: 2,
                      style: AppStyle.textBold16,
                    ),
                  ),
                  GestureDetector(
                    key: Key('my-lesson-delete-${lesson.id}'),
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20.w,
                        color: AppCustomColor.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (lesson.sourceLabel.isNotEmpty) ...[
                6.verticalSpace,
                AppText(
                  lesson.sourceLabel,
                  maxLines: 1,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textSecondary,
                  ),
                ),
              ],
              12.verticalSpace,
              Row(
                children: [
                  AppText(
                    l10n.minutesRead(minutes: lesson.estimatedMinutes),
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textSecondary,
                    ),
                  ),
                  if (percent > 0) ...[
                    12.horizontalSpace,
                    AppText(
                      l10n.readingProgress(percent: percent),
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.brandPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
