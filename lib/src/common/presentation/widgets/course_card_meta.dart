part of '../../common.dart';

/// Course-card meta ink, from the design: the author credit reads slightly
/// darker than the muted reach figure.
const Color kCourseMetaAuthorColor = Color(0xFF3A4250);
const Color kCourseMetaViewsColor = Color(0xFF7C8AA4);

/// Dark translucent pill overlaid on a course thumbnail (bottom-right in the
/// design) showing the curated reader count — eye icon + "6.3k".
///
/// Callers should only render it when the count is set and positive; both the
/// admin-blank (null) and zero cases mean "claim no reach".
class CourseViewsChip extends StatelessWidget {
  final int count;

  const CourseViewsChip({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C14).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 12.r, color: Colors.white),
          4.horizontalSpace,
          AppText(
            count.compactViews,
            style: AppStyle.text10.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pencil + author-name line under a course-card title. Callers should only
/// render it when the author is a non-empty string.
class CourseAuthorLine extends StatelessWidget {
  final String author;

  /// Ink override for themed backgrounds (e.g. `studyThemeOnBg(...)` on Home).
  final Color? color;

  const CourseAuthorLine({super.key, required this.author, this.color});

  @override
  Widget build(BuildContext context) {
    final ink = color ?? kCourseMetaAuthorColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.edit_outlined, size: 12.r, color: ink),
        4.horizontalSpace,
        Flexible(
          child: AppText(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text12.copyWith(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline author + reach meta row for horizontal course rows (search results,
/// recently-viewed). Drops each half when unset; collapses to nothing when
/// both are, so callers can add it unconditionally.
class CourseMetaInline extends StatelessWidget {
  final String? author;
  final int? viewCount;

  const CourseMetaInline({super.key, this.author, this.viewCount});

  @override
  Widget build(BuildContext context) {
    final name = author?.trim() ?? '';
    final views = viewCount ?? 0;
    if (name.isEmpty && views <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name.isNotEmpty)
          Flexible(child: CourseAuthorLine(author: name)),
        if (name.isNotEmpty && views > 0) 12.horizontalSpace,
        if (views > 0) ...[
          Icon(Icons.visibility_outlined, size: 13.r, color: kCourseMetaViewsColor),
          4.horizontalSpace,
          AppText(
            views.compactViews,
            style: AppStyle.text12.copyWith(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: kCourseMetaViewsColor,
            ),
          ),
        ],
      ],
    );
  }
}
