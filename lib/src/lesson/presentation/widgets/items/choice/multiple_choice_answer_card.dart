part of '../../../../lesson.dart';

class MultipleChoiceAnswerCard extends StatelessWidget {
  final OptionEntity option;
  final AnswerState state;
  final VoidCallback? onTap;

  const MultipleChoiceAnswerCard({
    super.key,
    required this.option,
    this.state = AnswerState.normal,
    this.onTap,
  });

  Color get backgroundColor {
    return switch (state) {
      AnswerState.selected => Colors.white,
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      AnswerState.correctNotSelected => const Color(0xFFF5F7FB),
      AnswerState.disabled => Colors.white,
      _ => Colors.white,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFF554FF0),
      AnswerState.correct => const Color(0xFF41AE8C),
      AnswerState.incorrect => const Color(0xFFE34646),
      AnswerState.correctNotSelected => const Color(0xFF364152),
      AnswerState.disabled => const Color(0xFFE3E8EF),
      _ => const Color(0xFFE3E8EF),
    };
  }

  double get opacity {
    return switch (state) {
      AnswerState.disabled => 0.7,
      _ => 1.0,
    };
  }

  FontWeight get fontWeight {
    return switch (state) {
      AnswerState.selected => FontWeight.w500,
      AnswerState.correct => FontWeight.w500,
      AnswerState.incorrect => FontWeight.w500,
      AnswerState.correctNotSelected => FontWeight.w500,
      AnswerState.disabled => FontWeight.w400,
      _ => FontWeight.w400,
    };
  }

  Widget? get checkboxIcon {
    return switch (state) {
      AnswerState.correct => Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          color: const Color(0xFF41AE8C),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 14.sp,
          color: Colors.white,
        ),
      ),
      AnswerState.incorrect => Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE34646),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 14.sp,
          color: Colors.white,
        ),
      ),
      AnswerState.correctNotSelected => Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          color: const Color(0xFFAAB8CD),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 14.sp,
          color: Colors.white,
        ),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 16.w,
            right: checkboxIcon != null ? 12.w : 16.w,
            top: 12.h,
            bottom: 12.h,
          ),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  option.value.text,
                  maxLines: 10,
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xFF364152),
                    fontWeight: fontWeight,
                    height: 1.75,
                  ),
                ),
              ),
              if (checkboxIcon != null) ...[
                10.horizontalSpace,
                checkboxIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
