part of '../../warm_up.dart';

/// "Here's your next step" card on the completion screen — mirrors
/// [LessonKeypointCard]'s visual language (rounded card, thumbnail, title)
/// but is self-contained since the warm-up flow only needs a read-only
/// preview, not the tap-to-open roadmap interaction.
class WarmUpNextLessonCard extends StatelessWidget {
  const WarmUpNextLessonCard({super.key, required this.lesson});

  final LessonEntity lesson;

  KeypointEntity get _keypoint => lesson.firstKeypoint;

  String get _thumbnailUrl => _keypoint.image.isNotEmpty ? _keypoint.image : lesson.image;

  @override
  Widget build(BuildContext context) {
    final title = _keypoint.title.text.isNotEmpty ? _keypoint.title.text : lesson.title.text;

    // Figma 11242:49651 "AnswerCard": vertical card, w263, white, radius 12,
    // shadow 0 4 24 rgba(75,68,202,.15), padding (8,8,8,24), gap 12. Image on
    // top (h247, radius 4, cover), then the lesson title (Bold 14, #0D121C,
    // centered, line-height 1.75) — no duration row.
    return Container(
      width: 263.w,
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94762A).withValues(alpha: 0.15),
            blurRadius: 24.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: SizedBox(
              width: double.infinity,
              height: 247.w,
              child: _thumbnailUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFFEFAF1),
                      alignment: Alignment.center,
                      child: Icon(Icons.menu_book_rounded, color: const Color(0xFF94762A), size: 40.w),
                    )
                  : CachedNetworkImage(
                      imageUrl: _thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: const Color(0xFFFEFAF1)),
                    ),
            ),
          ),
          12.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppText(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.textBold14.copyWith(color: const Color(0xFF0D121C), height: 1.75),
            ),
          ),
        ],
      ),
    );
  }
}
