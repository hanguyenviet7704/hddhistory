part of '../../../profile.dart';

class UserAchievementBottomSheet extends StatefulWidget {
  const UserAchievementBottomSheet({
    super.key,
    required this.courseId,
    required this.skillsetId,
    required this.skillsetName,
    this.initialLevel,
  });

  final String courseId;
  final String skillsetId;
  final String skillsetName;
  final CourseLevel? initialLevel;

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    required String skillsetId,
    required String skillsetName,
    CourseLevel? initialLevel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.op(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      routeSettings: const RouteSettings(name: RouteNamed.userAchievementBottomSheet),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: AppDI.injector.get<AchievenmentProgressCubit>()),
          BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
          BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
        ],
        child: UserAchievementBottomSheet(
          courseId: courseId,
          initialLevel: initialLevel,
          skillsetId: skillsetId,
          skillsetName: skillsetName,
        ),
      ),
    );
  }

  @override
  State<UserAchievementBottomSheet> createState() => _UserAchievementBottomSheetState();
}

class _UserAchievementBottomSheetState extends State<UserAchievementBottomSheet> {
  final PageController _pageController = PageController();
  bool _didJumpToInitial = false;
  bool _hasTrackedView = false;
  bool _skipNextSlideEvent = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<CourseLevelProgressEntity> _filterCourses(AchievenmentProgressState state) {
    final List<CourseLevelProgressEntity> filtered = state.courseLevelProgresses.where((course) => course.courseId == widget.courseId).toList();
    filtered.sort((a, b) => a.level.index.compareTo(b.level.index));
    return filtered;
  }

  String _resolveCourseName(List<CourseLevelProgressEntity> courses) {
    if (courses.isEmpty) return '';
    final String name = courses.first.courseTitle.en.trim();
    if (name.isNotEmpty) return name;
    return courses.first.title;
  }

  CourseTrackingData _buildTrackingData(String courseName) {
    return CourseTrackingData.fromTrackingValues(
      skillsetId: widget.skillsetId,
      skillsetName: widget.skillsetName,
      courseId: widget.courseId,
      courseName: courseName,
    );
  }

  void _syncInitialPage(List<CourseLevelProgressEntity> courses) {
    if (_didJumpToInitial || courses.isEmpty || widget.initialLevel == null) return;

    final int index = courses.indexWhere((course) => course.level == widget.initialLevel);
    if (index < 0) return;

    _didJumpToInitial = true;
    _skipNextSlideEvent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.jumpToPage(index);
    });
  }

  void _trackDetailView(String courseName) {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackSettingBadgeDetailView(_buildTrackingData(courseName));
    _hasTrackedView = true;
  }

  void _handlePageChanged(int index, String courseName) {
    if (_skipNextSlideEvent) {
      _skipNextSlideEvent = false;
      return;
    }
    AppService.instance.appTrackingService.trackSettingBadgeDetailSlide(_buildTrackingData(courseName));
  }

  void _onGoToCourse(BuildContext context, String courseName) {
    AppService.instance.appTrackingService.trackSettingBadgeGoCourse(_buildTrackingData(courseName));
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('setting_badge');
    AppDI.injector.get<HomeCubit>().selectCourseFromCourseId(widget.courseId);
    // This sheet is a `showModalBottomSheet` (a Material Navigator route), so it
    // must be popped on the Navigator — `context.back()`/go_router `pop()` acts
    // on the router stack and leaves the modal up (the "popup không tắt" bug).
    Navigator.of(context).pop();
    // Navigate on the ROOT context, not the just-popped sheet context: the
    // latter is now defunct, so .go on it silently no-ops — the event fired but
    // the app never moved (the reported bug). The root navigator context always
    // resolves the router.
    final rootCtx = AppConfig.instance.context;
    if (rootCtx == null) return;
    CourseRoadmapRoute().go(rootCtx);
    // Not just setCurrentIndex(1) — see course_card.dart's identical fix.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
      builder: (context, state) {
        final List<CourseLevelProgressEntity> courses = _filterCourses(state);
        final String courseName = _resolveCourseName(courses);
        _syncInitialPage(courses);
        WidgetsBinding.instance.addPostFrameCallback((_) => _trackDetailView(courseName));
        final bool isLoading = state.status == AchievenmentProgressStatus.loading && courses.isEmpty;
        if (isLoading) return const Center(child: CircularProgressIndicator());
        if (courses.isEmpty) return _UserAchievementEmptyState();

        final Widget content = _UserAchievementSheetContent(
          courses: courses,
          controller: _pageController,
          onPageChanged: (index) => _handlePageChanged(index, courseName),
          onGoToCourse: () => _onGoToCourse(context, courseName),
        );

        return Container(
          height: 735.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              _UserAchievementSheetHeader(
                onClose: () {
                  AppService.instance.appTrackingService.trackProfileBadgeCloseClick();
                  context.back();
                },
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, bottomInset + 20.h),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserAchievementSheetHeader extends StatelessWidget {
  const _UserAchievementSheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            AppHaptic.select();
            onClose();
          },
          child: SvgPicture.asset(
            AppAsset.svg.app.icClose,
            width: 24.w,
            height: 24.w,
            colorFilter: ColorFilter.mode(AppCustomColor.textTertiary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _UserAchievementSheetContent extends StatelessWidget {
  final List<CourseLevelProgressEntity> courses;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onGoToCourse;

  const _UserAchievementSheetContent({
    required this.courses,
    required this.controller,
    required this.onPageChanged,
    required this.onGoToCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: courses.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) => UserAchievementDetailCard(course: courses[index]),
                ),
              ),
              if (courses.length > 1) ...[
                24.verticalSpace,
                SmoothPageIndicator(
                  controller: controller,
                  count: courses.length,
                  effect: ScrollingDotsEffect(
                    activeDotColor: AppCustomColor.brandPrimary,
                    dotColor: AppCustomColor.borderSecondary,
                    dotHeight: 8.r,
                    dotWidth: 8.r,
                    spacing: 12.w,
                  ),
                ),
              ] else
                24.verticalSpace,
            ],
          ),
        ),
        36.verticalSpace,
        _UserAchievementGoToCourseButton(onTap: onGoToCourse),
      ],
    );
  }
}

class _UserAchievementGoToCourseButton extends StatelessWidget {
  const _UserAchievementGoToCourseButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
      child: Container(
        width: double.infinity,
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: AppText(
          context.l10n.setting.achievementsGoToCourse,
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textWhite,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _UserAchievementEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText(
        context.l10n.common.emptyList,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textTertiary,
          height: 1.5,
        ),
      ),
    );
  }
}
