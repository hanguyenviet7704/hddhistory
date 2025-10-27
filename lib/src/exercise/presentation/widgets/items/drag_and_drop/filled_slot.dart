part of '../../../../exercise.dart';

class FilledSlot extends StatelessWidget {
  final String word;
  final bool isDragging;
  const FilledSlot({super.key, required this.word, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: const Color(0xFF554FF0),
        strokeWidth: 2,
        dashPattern: const [6, 4],
        radius: Radius.circular(8.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF554FF0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF554FF0),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
