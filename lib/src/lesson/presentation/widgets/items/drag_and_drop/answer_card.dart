part of '../../../../lesson.dart';

/// A draggable word chip in the text-gap-filling word bank (Keypoint v2
/// design): white, lightly bordered and lifted by its own shadow, so the chips
/// read as loose pieces on the card rather than rows in a list.
///
/// [isInvisible] is the gap left behind while the chip is being dragged — the
/// design keeps a flat grey placeholder there so the bank does not reflow
/// mid-drag.
class AnswerCard extends StatelessWidget {
  final String word;
  final bool isDragging;
  final bool isInvisible;

  const AnswerCard({super.key, required this.word, this.isDragging = false, this.isInvisible = false});

  @override
  Widget build(BuildContext context) {
    if (isInvisible) {
      // FIXED size, not min-constraints: a childless Container treats loose
      // incoming constraints as "expand", so min-only ghosts stretched into
      // full-width gray bars the moment they stood alone in the Wrap
      // ("vẫn sai", 2026-08-13). The design ghost is a word-sized 80×34 box.
      return Container(
        width: 80.w,
        height: 34.h,
        decoration: BoxDecoration(
          color: AppCustomColor.kpChipPlaceholder,
          borderRadius: BorderRadius.circular(9.r),
        ),
      );
    }

    // No `alignment` here — it would turn this into an Align that expands to
    // the word bank's full width, so every chip became a full-width row.
    // Design word-bank chip: 34 tall, radius 9 — a word, not a button-sized
    // card (min-HEIGHT rather than a fixed height so a long word may wrap).
    return Container(
      constraints: BoxConstraints(minHeight: 34.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        border: Border.all(
          color: isDragging ? AppCustomColor.brandPrimary : AppCustomColor.kpOptionBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(9.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.neutral01.withValues(alpha: isDragging ? 0.12 : 0.05),
            blurRadius: isDragging ? 20.r : 16.r,
            offset: Offset(0, isDragging ? 8.h : 6.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            word,
            style: AppStyle.text14.copyWith(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
