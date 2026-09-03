part of '../../community.dart';

/// The course a writer attached to a post (design `S-01`/`S-04`).
///
/// Shows the COURSE — its cover, its title, its description — not a generic
/// "a course is attached" placard. The whole point of attaching one is that the
/// post says what helped and the card is how a reader gets to it, and a reader
/// cannot decide to go there without being told where "there" is.
///
/// Fetches the course itself: a post carries only `attachedCourseId`, and the
/// feed endpoint does not expand it.
class CommunityAttachedCourseCard extends StatefulWidget {
  const CommunityAttachedCourseCard({super.key, required this.courseId, this.onRemove});

  final String courseId;

  /// Set while COMPOSING: the same card gains a remove button and drops the
  /// "Xem khoá học" link, because the writer is holding the course rather than
  /// being invited to go to it (design `S-06`).
  final VoidCallback? onRemove;

  @override
  State<CommunityAttachedCourseCard> createState() => _CommunityAttachedCourseCardState();
}

class _CommunityAttachedCourseCardState extends State<CommunityAttachedCourseCard> {
  CourseEntity? _course;
  bool _failed = false;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AppDI.injector.get<GetCourseUseCase>()(widget.courseId).run();
    if (!mounted) return;

    result.fold(
      (_) => setState(() => _failed = true),
      (course) => setState(() => _course = course),
    );
  }

  /// The roadmap screen reads its course from [HomeCubit], not from a route
  /// parameter — so the course has to be selected before navigating, exactly as
  /// the Home and Explore cards do it.
  ///
  /// `.go()` rather than `.push()`: the roadmap lives in its own shell branch,
  /// and a cross-branch push renders in the community branch's navigator, which
  /// is not the one on screen. The explicit route name is needed because a
  /// cross-branch `.go()` to a branch root does not re-fire the route observer.
  Future<void> _open() async {
    final course = _course;
    if (course == null || _isOpening || widget.onRemove != null) return;
    setState(() => _isOpening = true);

    // Read through the injector rather than context.read: this card renders
    // inside community screens, which do not provide these cubits.
    //
    // Select BY ID, not via `course.skillset`: the course-detail endpoint's
    // entity carries a default-empty skillset, so `selectSkillset` no-oped
    // silently and the roadmap could open on whatever course was selected
    // before. `selectCourseFromCourseId` locates the skillset itself and
    // falls back to loading the roadmap outside the catalog.
    LogDev.data('[Community] open attached course: ${course.id}');
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceCommunityPost);
    AppDI.injector.get<HomeCubit>().selectCourseFromCourseId(course.id);
    if (!mounted) return;
    CourseRoadmapRoute().go(context);
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    setState(() => _isOpening = false);
  }

  @override
  Widget build(BuildContext context) {
    // A course that cannot be fetched renders nothing at all: an error card
    // inside someone else's post is noise the reader can do nothing about, and
    // the post still reads fine without it.
    if (_failed) return const SizedBox.shrink();

    final course = _course;
    final l10n = context.l10n.community;

    final onRemove = widget.onRemove;

    final card = Container(
      height: 96.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppCustomColor.communityAttachSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.communityAttachBorder),
      ),
      child: course == null
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full-bleed cover down the left edge, as in the design. The
                  // tint behind it is what shows while it loads and for a course
                  // with no cover at all.
                  Container(
                    width: 92.w,
                    color: AppCustomColor.communityRoomTints.first,
                    child: course.image.isEmpty
                        ? null
                        : DCachedImage(url: course.image, fit: BoxFit.cover),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            course.title.text,
                            style: AppStyle.textBold14.copyWith(
                              fontSize: 13.5.sp,
                              color: AppCustomColor.textPrimary,
                              height: 1.25,
                            ),
                            maxLines: 1,
                          ),
                          if (course.description.text.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            // Flexible, because the card's height is fixed
                            // while the text scales by .sp: on some screens
                            // two full lines plus the CTA run a few pixels
                            // past the box, and the stripe of the resulting
                            // overflow renders inside the reader's feed.
                            Flexible(
                              child: AppText(
                                course.description.text,
                                style: AppStyle.text12.copyWith(
                                  fontSize: 11.5.sp,
                                  color: AppCustomColor.streakTextMuted,
                                  height: 1.45,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                          if (onRemove == null) ...[
                            const Spacer(),
                            Row(
                              children: [
                                AppText(
                                  l10n.attachedCourseCta,
                                  style: AppStyle.textBold12.copyWith(
                                    color: AppCustomColor.brandPrimary,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                if (_isOpening)
                                  SizedBox(
                                    width: 13.w,
                                    height: 13.w,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  CommunityGlyph(
                                    AppAsset.svg.app.icCommunityChevron,
                                    size: 13,
                                    color: AppCustomColor.brandPrimary,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );

    if (onRemove == null) return GestureDetector(onTap: _open, child: card);

    // Over the cover rather than beside the text: the design puts it on the
    // corner of the thing being removed, and the body column is already full.
    return Stack(
      children: [
        card,
        Positioned(
          top: 8.h,
          right: 8.w,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24.w,
              height: 24.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppCustomColor.textPrimary.withValues(alpha: 0.55),
              ),
              child: CommunityGlyph(
                AppAsset.svg.app.icCommunityClose,
                size: 12,
                color: AppCustomColor.textWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
