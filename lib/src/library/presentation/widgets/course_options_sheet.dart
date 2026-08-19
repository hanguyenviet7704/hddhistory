part of '../../library.dart';

/// The theme glyph, inlined from the design's own markup for this sheet — the
/// same picture the floating Change-background button draws, at this sheet's
/// 1.7 stroke.
const String _kCourseThemeSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="4" width="13" height="6" rx="1.6" stroke="#554FF0" stroke-width="1.7"/><path d="M16 7h3.2a1.5 1.5 0 0 1 1.5 1.5v2A1.5 1.5 0 0 1 19.2 12H12a1.5 1.5 0 0 0-1.5 1.5V15" stroke="#554FF0" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><rect x="8.4" y="15" width="4.2" height="5" rx="1.3" stroke="#554FF0" stroke-width="1.7"/></svg>''';

/// The roadmap's `(...)` menu (design `3 · Learning` → Course detail, and
/// `_MeUp App` → COURSE OPTIONS SHEET): save the course, share it, or change
/// the study background.
///
/// Change theme moved in here from the header's own circular button: the design
/// gives the course header one trailing control, and two affordances for the
/// background — one of them a floating disc over the artwork — was the older
/// layout, not this one.
class CourseOptionsSheet extends StatelessWidget {
  const CourseOptionsSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.onSaveToggled,
  });

  final String courseId;
  final String courseTitle;

  /// Fired with the state the bookmark landed in, so the roadmap can raise its
  /// toast where the design puts it — over the course, not over the sheet the
  /// tap just dismissed.
  final void Function(bool isSaved) onSaveToggled;

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    required String courseTitle,
    required void Function(bool isSaved) onSaveToggled,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: AppDI.injector.get<SavedCubit>(),
        child: CourseOptionsSheet(
          courseId: courseId,
          courseTitle: courseTitle,
          onSaveToggled: onSaveToggled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isSaved = context.select<SavedCubit, bool>(
      (cubit) => cubit.state.isCourseSaved(courseId),
    );

    return Container(
      key: const ValueKey('course-options-sheet'),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 20.h + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE3E5EC),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          _CourseOptionRow(
            key: const Key('course-options-save'),
            label: isSaved ? l10n.unsaveCourseLabel : l10n.saveCourseLabel,
            svg: _savedSvg(
              _kSavedBookmarkSvg,
              stroke: AppCustomColor.brandPrimary,
              fill: isSaved ? AppCustomColor.brandPrimary : null,
            ),
            onTap: () async {
              final saved = await context.read<SavedCubit>().toggleCourse(courseId);
              onSaveToggled(saved);
              if (context.mounted) Navigator.of(context).maybePop();
            },
          ),
          _CourseOptionRow(
            key: const Key('course-options-share'),
            label: l10n.shareCourseLabel,
            svg: _savedSvg(_kSavedShareSvg, stroke: AppCustomColor.brandPrimary),
            onTap: () async {
              // Close first: our own share sheet replaces this one rather
              // than stacking, and the platform sheet it eventually opens
              // would sit behind ours on iOS.
              Navigator.of(context).maybePop();
              final course = AppDI.injector.get<HomeCubit>().state.currentCourse;
              if (!context.mounted) return;
              // Only the roadmap's own course can be pictured — anywhere else
              // the id would not match what HomeCubit is holding, so fall back
              // to the text share rather than picture the wrong course.
              if (course.id != courseId) {
                await shareSavedCourse(context, title: courseTitle);
                return;
              }
              await CourseShareSheet.show(
                context,
                courseId: courseId,
                courseTitle: courseTitle,
                courseDescription: _shareDescription(course),
                coverUrl: course.image,
              );
            },
          ),
          _CourseOptionRow(
            key: const Key('course-options-theme'),
            label: context.l10n.studyTheme.changeBackground,
            svg: _kCourseThemeSvg,
            onTap: () {
              Navigator.of(context).maybePop();
              StudyThemeTracking.track(
                TrackingKey.themeChangeClick,
                parameters: {'source': 'roadmap'},
              );
              ChangeBackgroundSheet.show(context, source: 'roadmap');
            },
          ),
        ],
      ),
    );
  }

  /// The blurb printed on the story card.
  ///
  /// Read from the ROADMAP, not from the course: `/skillsets` deliberately
  /// omits `description` (5 languages, ~30% of that payload, and no list
  /// surface renders it), so `HomeCubit.currentCourse.description` is always
  /// empty and the card shipped with a title and nothing under it. The roadmap
  /// carries the blurb for exactly this reason and is already loaded — the
  /// header two taps up prints the same string.
  ///
  /// The course value stays as the fallback in case a build starts sending it
  /// again, and the id check keeps a stale roadmap from lending its blurb to a
  /// different course.
  String _shareDescription(CourseEntity course) {
    final roadmap = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap;
    if (roadmap.courseId == courseId) {
      final blurb = roadmap.courseDescription.text.trim();
      if (blurb.isNotEmpty) return blurb;
    }
    return course.description.text.trim();
  }
}

/// One row: a tinted 40 icon tile and a 16/700 label (design).
class _CourseOptionRow extends StatelessWidget {
  const _CourseOptionRow({
    super.key,
    required this.label,
    required this.svg,
    required this.onTap,
  });

  final String label;
  final String svg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _kSavedTileGrey,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(svg, width: 21.w, height: 21.w),
              ),
              14.horizontalSpace,
              Expanded(
                child: AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textPrimary,
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
