part of '../../../course.dart';

/// The `(...)` disc at the top-right of the course header (design
/// `3 · Learning` → Course detail), opening [CourseOptionsSheet].
///
/// It replaced the change-theme disc that used to sit here: the design gives
/// the header one trailing control, and theme is now a row inside the sheet.
class CourseRoadmapOptionsButton extends StatelessWidget {
  const CourseRoadmapOptionsButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.library.courseOptionsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Container(
          width: size.r,
          height: size.r,
          decoration: BoxDecoration(
            // Same light chrome as the disc it replaced, so it stays readable
            // over any custom study background.
            color: const Color(0xFFF7F7FA),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0x2E252525), blurRadius: 16.r, offset: Offset(0, 6.h)),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_horiz_rounded,
            size: (size * 0.5).r,
            color: AppCustomColor.textPrimary,
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    AppHaptic.select();

    // The roadmap's course comes from HomeCubit — the same source the header
    // title and the CTA read, so the sheet can never act on a different course
    // than the one on screen.
    final course = AppDI.injector.get<HomeCubit>().state.currentCourse;
    if (course.id.isEmpty) return;

    final l10n = context.l10n.library;
    CourseOptionsSheet.show(
      context,
      courseId: course.id,
      courseTitle: course.title.text,
      onSaveToggled: (isSaved) {
        if (!context.mounted) return;
        showSavedToastOverlay(
          context,
          isSaved ? l10n.courseSavedToast : l10n.courseRemovedToast,
        );
      },
    );
  }
}
