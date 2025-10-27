part of '../../../../exercise.dart';

class FilledSlot extends StatelessWidget {
  final String word;
  final bool isDragging;
  final SlotState state;

  const FilledSlot({
    super.key,
    required this.word,
    this.isDragging = false,
    this.state = SlotState.normal,
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: _getBorderColor(),
        strokeWidth: 2,
        dashPattern: const [6, 4],
        radius: Radius.circular(8.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: AppText(
          word,
          style: AppStyle.text16.copyWith(
            fontWeight: FontWeight.w500,
            color: _getTextColor(),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    return switch (state) {
      SlotState.correct => const Color(0xFF1DA75E),
      SlotState.incorrect => const Color(0xFFE34646),
      SlotState.normal => const Color(0xFF554FF0),
    };
  }

  Color _getBackgroundColor() {
    return switch (state) {
      SlotState.correct => const Color(0xFFEAFFEF),
      SlotState.incorrect => const Color(0xFFFDEAE7),
      SlotState.normal => const Color(0xFF554FF0).withValues(alpha: 0.12),
    };
  }

  Color _getTextColor() {
    return switch (state) {
      SlotState.correct => const Color(0xFF1DA75E),
      SlotState.incorrect => const Color(0xFFEC2028),
      SlotState.normal => const Color(0xFF554FF0),
    };
  }
}
