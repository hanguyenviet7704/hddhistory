part of '../../../../exercise.dart';

class EmptySlot extends StatelessWidget {
  final bool isHighlighted;
  const EmptySlot({super.key, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: isHighlighted ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
        strokeWidth: 2.w,
        dashPattern: [6.w, 4.w],
        radius: Radius.circular(8.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF554FF0).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: AppText(
          ' ',
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
