part of '../../../profile.dart';

class UserAchievementBottomSheet extends StatefulWidget {
  const UserAchievementBottomSheet({
    super.key,
    required this.courseId,
    this.initialLevel,
    this.onGoToCourse,
  });

  final String courseId;
  final CourseLevel? initialLevel;
  final VoidCallback? onGoToCourse;

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    CourseLevel? initialLevel,
    VoidCallback? onGoToCourse,
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
        ],
        child: UserAchievementBottomSheet(
          courseId: courseId,
          initialLevel: initialLevel,
          onGoToCourse: onGoToCourse,
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

  void _syncInitialPage(List<CourseLevelProgressEntity> courses) {
    if (_didJumpToInitial || courses.isEmpty || widget.initialLevel == null) return;

    final int index = courses.indexWhere((course) => course.level == widget.initialLevel);
    if (index < 0) return;

    _didJumpToInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
      builder: (context, state) {
        final List<CourseLevelProgressEntity> courses = _filterCourses(state);
        _syncInitialPage(courses);
        final bool isLoading = state.status == AchievenmentProgressStatus.loading && courses.isEmpty;
        if (isLoading) return const Center(child: CircularProgressIndicator());
        if (courses.isEmpty) return _UserAchievementEmptyState();

        final Widget content = _UserAchievementSheetContent(
          courses: courses,
          controller: _pageController,
          onGoToCourse: widget.onGoToCourse,
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
              _UserAchievementSheetHeader(onClose: () => context.back()),
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
          onTap: onClose,
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
  const _UserAchievementSheetContent({
    required this.courses,
    required this.controller,
    required this.onGoToCourse,
  });

  final List<CourseLevelProgressEntity> courses;
  final PageController controller;
  final VoidCallback? onGoToCourse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 507.h,
              child: PageView.builder(
                controller: controller,
                itemCount: courses.length,
                physics: const BouncingScrollPhysics(),
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
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: AppText(
          context.text.setting.achievementsGoToCourse,
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
        context.text.common.emptyList,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textTertiary,
          height: 1.5,
        ),
      ),
    );
  }
}
