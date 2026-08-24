part of '../../community.dart';

/// The "Lộ trình MeUp" card a writer can attach to a post (design `S-08`).
///
/// Tapping it opens the course roadmap, which is the point of attaching one:
/// the post says what helped, the card is how a reader gets there.
class CommunityAttachedCourseCard extends StatefulWidget {
  const CommunityAttachedCourseCard({super.key, required this.courseId});

  final String courseId;

  @override
  State<CommunityAttachedCourseCard> createState() => _CommunityAttachedCourseCardState();
}

class _CommunityAttachedCourseCardState extends State<CommunityAttachedCourseCard> {
  bool _isOpening = false;

  /// The roadmap screen reads its course from [HomeCubit], not from a route
  /// parameter — so the course has to be fetched and selected before
  /// navigating, exactly as the Home and Explore cards do it.
  ///
  /// `.go()` rather than `.push()`: the roadmap lives in its own shell branch,
  /// and a cross-branch push renders in the community branch's navigator, which
  /// is not the one on screen. The explicit route name is needed because a
  /// cross-branch `.go()` to a branch root does not re-fire the route observer.
  Future<void> _open() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);

    final result = await AppDI.injector.get<GetCourseUseCase>()(widget.courseId).run();
    if (!mounted) return;

    setState(() => _isOpening = false);

    result.fold(
      (_) => DMessage.showMessage(
        message: context.l10n.community.errorBody,
        type: MessageType.error,
      ),
      (course) {
        // Read through the injector rather than context.read: this card renders
        // inside community screens, which do not provide these cubits.
        AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('community_post');
        AppDI.injector.get<HomeCubit>()
          ..selectSkillset(course.skillset)
          ..selectCourse(course);
        CourseRoadmapRoute().go(context);
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundBrandSoft,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 20.sp,
                color: AppCustomColor.streakActive,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.attachedCourseTitle,
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    l10n.attachedCourseHint,
                    style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            _isOpening
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right,
                    size: 18.sp,
                    color: AppCustomColor.communityMuted,
                  ),
          ],
        ),
      ),
    );
  }
}
