part of '../../library.dart';

// ---------------------------------------------------------------------------
// Design tokens for the Library screens (design `5b · Library`). Declared once
// here and visible to every `part of library.dart` file — same treatment as the
// Profile redesign's scoped tokens (see profile_page.dart), used for the design
// colours that have no app-wide token of their own.
// ---------------------------------------------------------------------------

/// Card hairline (design #EDF0F5) — a touch lighter than [AppCustomColor.borderDefault].
const Color _kLibraryCardBorder = Color(0xFFEDF0F5);

/// Placeholder behind a course thumbnail while it loads (design #E7EAF1).
const Color _kLibraryThumbPlaceholder = Color(0xFFE7EAF1);

/// Progress-bar track (design #E7E9F1).
const Color _kLibraryProgressTrack = Color(0xFFE7E9F1);

/// Author line (design #3A4250) — darker than the muted meta around it.
const Color _kLibraryAuthorText = Color(0xFF3A4250);

/// Secondary/muted copy on the Library screens (design #8891A3).
const Color _kLibraryMutedText = Color(0xFF8891A3);

/// "Completed" green (design #2F8159).
const Color _kLibraryDoneGreen = Color(0xFF2F8159);

/// Fixed height of a course row/tile in the Library (design: 98).
const double _kLibraryCardHeight = 98;

/// One course in the Library: thumbnail · title · author · progress.
///
/// Two variants of the same 98-tall card, both from the design:
/// * the tab's "In progress" carousel — fixed width, and a purple chevron disc
///   as the "continue" affordance;
/// * My history's full-width rows — no disc, and a green "Completed" line
///   instead of the bar once the course is done.
class LibraryCourseCard extends StatelessWidget {
  const LibraryCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.width,
    this.showContinueAffordance = false,
  });

  final CourseEntity course;
  final VoidCallback onTap;

  /// Fixed width for the carousel; null stretches to the parent (history list).
  final double? width;

  /// The purple chevron disc beside the progress bar (carousel only).
  final bool showContinueAffordance;

  bool get _isDone => course.numberOfLesson > 0 && course.numberOfLessonPassed >= course.numberOfLesson;

  double get _fraction => (course.completionPercentage / 100).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final title = course.title.text;
    final percent = (_fraction * 100).round();

    return Semantics(
      button: true,
      label: _isDone ? '$title, ${context.l10n.allcourse.progressCompleted}' : '$title, $percent%',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          width: width,
          height: _kLibraryCardHeight.h,
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            border: Border.all(color: _kLibraryCardBorder, width: 1.5),
            borderRadius: BorderRadius.circular(20.r),
          ),
          // clipBehavior on the Container: the thumbnail runs flush to the card's
          // left edge and has to take the card's rounded corners with it.
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _LibraryCardThumb(imageUrl: course.image),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          // Plain dark ink, NOT studyThemeOnBg: this title is
                          // inside a (glass) card, and cards keep their own dark
                          // ink whatever the study background is. Lifting it to
                          // light ink painted white-on-white — see the helper's
                          // own doc in themed_background.dart.
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                      if (course.author?.trim().isNotEmpty ?? false) ...[
                        4.verticalSpace,
                        _LibraryCardAuthor(author: course.author!.trim()),
                      ],
                      8.verticalSpace,
                      if (_isDone) const _LibraryCardDoneLine() else _LibraryCardProgress(fraction: _fraction, showAffordance: showContinueAffordance),
                    ],
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

/// Square thumbnail, flush to the card's left edge (design: 98×98).
class _LibraryCardThumb extends StatelessWidget {
  const _LibraryCardThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kLibraryCardHeight.h,
      height: _kLibraryCardHeight.h,
      color: _kLibraryThumbPlaceholder,
      child: imageUrl.trim().isEmpty
          ? Icon(Icons.menu_book_rounded, size: 28.w, color: AppCustomColor.textQuaternary)
          : CacheNetworkGraphic(
              url: imageUrl,
              width: _kLibraryCardHeight.h,
              height: _kLibraryCardHeight.h,
              fit: BoxFit.cover,
            ),
    );
  }
}

/// Author credit with the design's pencil glyph.
class _LibraryCardAuthor extends StatelessWidget {
  const _LibraryCardAuthor({required this.author});

  final String author;

  @override
  Widget build(BuildContext context) {
    final color = studyThemeCardMuted(context, _kLibraryAuthorText);
    return Row(
      children: [
        Icon(Icons.edit_outlined, size: 13.w, color: color),
        5.horizontalSpace,
        Expanded(
          child: AppText(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Progress bar, optionally with the purple "continue" disc beside it.
class _LibraryCardProgress extends StatelessWidget {
  const _LibraryCardProgress({required this.fraction, required this.showAffordance});

  final double fraction;
  final bool showAffordance;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        height: 6.h,
        color: _kLibraryProgressTrack,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: Container(height: 6.h, color: AppCustomColor.brandPrimary),
        ),
      ),
    );

    if (!showAffordance) return bar;

    return Row(
      children: [
        Expanded(child: bar),
        10.horizontalSpace,
        Container(
          width: 20.w,
          height: 20.w,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppCustomColor.brandPrimary),
          alignment: Alignment.center,
          child: Icon(Icons.chevron_right_rounded, size: 14.w, color: AppCustomColor.backgroundWhite),
        ),
      ],
    );
  }
}

/// "Completed" — replaces the bar once every item is done.
class _LibraryCardDoneLine extends StatelessWidget {
  const _LibraryCardDoneLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 15.w, color: _kLibraryDoneGreen),
        6.horizontalSpace,
        AppText(
          context.l10n.allcourse.progressCompleted,
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: _kLibraryDoneGreen,
          ),
        ),
      ],
    );
  }
}
