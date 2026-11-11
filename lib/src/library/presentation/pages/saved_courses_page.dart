part of '../../library.dart';

/// "Saved" (design `5b · Library` → screen 4): the courses the reader
/// bookmarked, split by how far into each of them they are.
///
/// Unlike My history — which filters one already-loaded list client-side — each
/// chip here is its own request: the bucket is computed server-side from
/// progress, and the app has no progress for a course it has never opened.
class SavedCoursesPage extends StatefulWidget {
  const SavedCoursesPage({super.key});

  @override
  State<SavedCoursesPage> createState() => _SavedCoursesPageState();
}

class _SavedCoursesPageState extends State<SavedCoursesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SavedCubit>().ensureCoursesLoaded());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240.h) return;
    unawaited(context.read<SavedCubit>().loadCourses(isInit: false));
  }

  void _setFilter(SavedCourseFilter filter) {
    AppHaptic.select();
    context.read<SavedCubit>().setCoursesFilter(filter);
  }

  /// Same jump the Library carousel and My history make — including the
  /// re-anchor of the route name, which a `.go()` into an already-built branch
  /// does not fire on its own.
  void _openCourse(CourseEntity course) {
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    final resolved = course.withCategory;
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceLibrary);
    AppDI.injector.get<HomeCubit>()
      ..selectCategory(resolved.category)
      ..selectCourse(resolved);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  String _emptyMessage(BuildContext context, SavedCourseFilter filter) {
    final l10n = context.l10n.library;
    return switch (filter) {
      SavedCourseFilter.upNext => l10n.emptySavedUpNext,
      SavedCourseFilter.inProgress => l10n.emptySavedInProgress,
      SavedCourseFilter.finished => l10n.emptySavedFinished,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: BlocBuilder<SavedCubit, SavedState>(
        builder: (context, state) {
          return Column(
            children: [
              _SavedCoursesHeader(
                filter: state.coursesFilter,
                onFilterTap: _setFilter,
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SavedState state) {
    if (state.isCoursesInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary));
    }

    if (state.isCoursesFailure && state.coursesPageData.items.isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 12.h),
        child: LibraryInlineError(
          message: state.errorMessage,
          onRetry: () => context.read<SavedCubit>().loadCourses(isInit: true),
        ),
      );
    }

    final courses = state.coursesPageData.items;
    final showPagingLoader = state.coursesStatus == SavedStatus.loading && courses.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<SavedCubit>().loadCourses(isInit: true),
          context.read<SavedCubit>().loadIds(),
        ]);
      },
      child: courses.isEmpty
          ? _LibraryHistoryEmpty(message: _emptyMessage(context, state.coursesFilter))
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, floatingNavBarHeight(context) + 20.h + resumeChipClearance(context)),
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
  }
}

/// Back · centred "Saved" · three filter pills. The history header with one
/// more chip, and the chips scroll: three pills in German or Japanese overflow
/// a 390 frame that two never did.
class _SavedCoursesHeader extends StatelessWidget {
  const _SavedCoursesHeader({required this.filter, required this.onFilterTap});

  final SavedCourseFilter filter;
  final void Function(SavedCourseFilter filter) onFilterTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    final ink = studyThemeOnBg(context, AppCustomColor.textPrimary);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 14.h, 0, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              height: 44.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AppText(
                    l10n.savedTitle,
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
                        key: const Key('saved-courses-back-button'),
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
          ),
          14.verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                _LibraryHistoryFilterPill(
                  label: l10n.filterUpNext,
                  isSelected: filter == SavedCourseFilter.upNext,
                  onTap: () => onFilterTap(SavedCourseFilter.upNext),
                ),
                8.horizontalSpace,
                _LibraryHistoryFilterPill(
                  label: l10n.filterInProgress,
                  isSelected: filter == SavedCourseFilter.inProgress,
                  onTap: () => onFilterTap(SavedCourseFilter.inProgress),
                ),
                8.horizontalSpace,
                _LibraryHistoryFilterPill(
                  label: l10n.filterFinished,
                  isSelected: filter == SavedCourseFilter.finished,
                  onTap: () => onFilterTap(SavedCourseFilter.finished),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
