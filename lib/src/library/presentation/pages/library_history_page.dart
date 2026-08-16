part of '../../library.dart';

/// Which slice of the reader's enrolled courses My history is showing.
enum LibraryHistoryFilter { inProgress, finished }

/// "My history" (design `5b · Library` — screens 2 and 3): every enrolled
/// course, filtered In progress / Finished.
///
/// The list is the same one the Library tab's carousel reads
/// ([ProgressState.libraryPageData]) — one fetch, two views — and this screen
/// owns the paging beyond page one.
class LibraryHistoryPage extends StatefulWidget {
  const LibraryHistoryPage({super.key});

  @override
  State<LibraryHistoryPage> createState() => _LibraryHistoryPageState();
}

class _LibraryHistoryPageState extends State<LibraryHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  LibraryHistoryFilter _filter = LibraryHistoryFilter.inProgress;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ProgressCubit>().ensureLibraryCoursesLoaded());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  /// Pages in the rest of the list as the reader nears the bottom.
  ///
  /// Both filters are views over ONE paginated list, so the trigger is the
  /// scroll position, not the visible count: a page that happens to hold only
  /// finished courses would otherwise never load the next one while the "In
  /// progress" filter is selected.
  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240.h) return;
    unawaited(context.read<ProgressCubit>().loadLibraryCourses());
  }

  void _setFilter(LibraryHistoryFilter filter) {
    if (_filter == filter) return;
    AppHaptic.select();
    setState(() => _filter = filter);
  }

  void _openCourse(CourseEntity course) {
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    final resolved = course.withSkillset;
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceLibraryHistory);
    AppDI.injector.get<HomeCubit>()
      ..selectSkillset(resolved.skillset)
      ..selectCourse(resolved);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  List<CourseEntity> _visibleCourses(ProgressState state) => switch (_filter) {
    LibraryHistoryFilter.inProgress => state.libraryInProgressCourses,
    LibraryHistoryFilter.finished => state.libraryFinishedCourses,
  };

  String _emptyMessage(BuildContext context) => switch (_filter) {
    LibraryHistoryFilter.inProgress => context.l10n.library.emptyHistoryInProgress,
    LibraryHistoryFilter.finished => context.l10n.library.emptyHistoryFinished,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: Column(
        children: [
          _LibraryHistoryHeader(
            filter: _filter,
            onFilterTap: _setFilter,
          ),
          Expanded(
            child: BlocBuilder<ProgressCubit, ProgressState>(
              buildWhen: (previous, current) =>
                  previous.libraryPageData != current.libraryPageData || previous.libraryStatus != current.libraryStatus,
              builder: (context, state) {
                if (state.isLibraryInitialLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary));
                }

                if (state.isLibraryFailure) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(top: 12.h),
                    child: LibraryInlineError(
                      message: state.libraryErrorMessage,
                      onRetry: () => context.read<ProgressCubit>().loadLibraryCourses(isInit: true),
                    ),
                  );
                }

                final courses = _visibleCourses(state);
                // The trailing row is the pager's own spinner — keep it out of
                // the empty branch, or an empty filter reads as "still loading".
                final showPagingLoader = state.isLibraryLoading && courses.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: () => context.read<ProgressCubit>().loadLibraryCourses(isInit: true),
                  child: courses.isEmpty
                      ? _LibraryHistoryEmpty(message: _emptyMessage(context))
                      : ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, floatingNavBarHeight(context) + 20.h),
                          itemCount: courses.length + (showPagingLoader ? 1 : 0),
                          separatorBuilder: (_, _) => SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            if (index >= courses.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary)),
                              );
                            }
                            final course = courses[index];
                            return LibraryCourseCard(
                              course: course,
                              onTap: () => _openCourse(course),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Back · centred "My history" · the two filter pills (design: 18/700 title,
/// pills 13/700 at 7×14).
class _LibraryHistoryHeader extends StatelessWidget {
  const _LibraryHistoryHeader({required this.filter, required this.onFilterTap});

  final LibraryHistoryFilter filter;
  final void Function(LibraryHistoryFilter filter) onFilterTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    final ink = studyThemeOnBg(context, AppCustomColor.textPrimary);

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, MediaQuery.paddingOf(context).top + 14.h, 24.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 44 tall, not the design's bare 26: the back button needs a 44 tap
          // target and a 26-tall row would overflow around it. Same shape as
          // Profile's title bar (`_ProfileHeaderBar`).
          SizedBox(
            height: 44.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppText(
                  l10n.myHistoryTitle,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    color: ink,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: context.l10n.common.back,
                    child: GestureDetector(
                      key: const Key('library-history-back-button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptic.select();
                        context.back();
                      },
                      child: SizedBox(
                        width: 44.w,
                        height: 44.h,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.w, color: ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          14.verticalSpace,
          Row(
            children: [
              _LibraryHistoryFilterPill(
                label: l10n.filterInProgress,
                isSelected: filter == LibraryHistoryFilter.inProgress,
                onTap: () => onFilterTap(LibraryHistoryFilter.inProgress),
              ),
              10.horizontalSpace,
              _LibraryHistoryFilterPill(
                label: l10n.filterFinished,
                isSelected: filter == LibraryHistoryFilter.finished,
                onTap: () => onFilterTap(LibraryHistoryFilter.finished),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryHistoryFilterPill extends StatelessWidget {
  const _LibraryHistoryFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.brandPrimary50,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: AppText(
            label,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppCustomColor.backgroundWhite : AppCustomColor.brandPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty for THIS filter — scrollable so pull-to-refresh still works.
class _LibraryHistoryEmpty extends StatelessWidget {
  const _LibraryHistoryEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(32.w, 60.h, 32.w, floatingNavBarHeight(context) + 20.h),
      children: [
        AppText(
          message,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            color: studyThemeOnBg(context, AppCustomColor.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// Shared failure card for the Library screens: the message the request came
/// back with, plus a retry — mirrors Profile's `_InlineSectionError`.
class LibraryInlineError extends StatelessWidget {
  const LibraryInlineError({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          border: Border.all(color: _kLibraryCardBorder, width: 1.5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 36.w, color: AppCustomColor.textTertiary),
            10.verticalSpace,
            AppText(
              (message?.trim().isNotEmpty ?? false) ? message!.trim() : context.l10n.library.loadFailed,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: studyThemeCardMuted(context, AppCustomColor.textSecondary)),
            ),
            10.verticalSpace,
            OutlinedButton(
              onPressed: () {
                AppHaptic.select();
                onRetry();
              },
              child: AppText(
                context.l10n.monetization.retry,
                style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
