part of '../../daily_warm_up.dart';

class DailyWarmUpChoiceAnswerCard extends StatelessWidget {
  const DailyWarmUpChoiceAnswerCard({
    super.key,
    required this.option,
    this.state = AnswerState.normal,
    this.onTap,
  });

  final OptionEntity option;
  final AnswerState state;
  final VoidCallback? onTap;

  Color get backgroundColor {
    return switch (state) {
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      _ => Colors.white,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFFB5860F),
      AnswerState.correct => const Color(0xFF1DA75E),
      AnswerState.incorrect => const Color(0xFFE34646),
      _ => const Color(0xFFE3E8EF),
    };
  }

  FontWeight get fontWeight {
    return switch (state) {
      AnswerState.selected || AnswerState.correct || AnswerState.incorrect => FontWeight.w500,
      _ => FontWeight.w400,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: state == AnswerState.disabled ? 0.7 : 1,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
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
      ),
    );
  }
}

class DailyWarmUpMultipleChoiceAnswerCard extends StatelessWidget {
  const DailyWarmUpMultipleChoiceAnswerCard({
    super.key,
    required this.option,
    this.state = AnswerState.normal,
    this.onTap,
  });

  final OptionEntity option;
  final AnswerState state;
  final VoidCallback? onTap;

  Widget? get checkboxIcon {
    final color = switch (state) {
      AnswerState.correct => const Color(0xFF41AE8C),
      AnswerState.incorrect => const Color(0xFFE34646),
      AnswerState.correctNotSelected => const Color(0xFFAAB8CD),
      _ => null,
    };
    if (color == null) return null;

    return Container(
      width: 20.w,
      height: 20.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Icon(
        state == AnswerState.incorrect ? Icons.close_rounded : Icons.check_rounded,
        size: 14.sp,
        color: Colors.white,
      ),
    );
  }

  Color get backgroundColor {
    return switch (state) {
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      AnswerState.correctNotSelected => const Color(0xFFF5F7FB),
      _ => Colors.white,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFFB5860F),
      AnswerState.correct => const Color(0xFF41AE8C),
      AnswerState.incorrect => const Color(0xFFE34646),
      AnswerState.correctNotSelected => const Color(0xFF364152),
      _ => const Color(0xFFE3E8EF),
    };
  }

  FontWeight get fontWeight {
    return switch (state) {
      AnswerState.selected || AnswerState.correct || AnswerState.incorrect || AnswerState.correctNotSelected => FontWeight.w500,
      _ => FontWeight.w400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCheckboxIcon = checkboxIcon;
    return Opacity(
      opacity: state == AnswerState.disabled ? 0.7 : 1,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 16.w,
            right: resolvedCheckboxIcon != null ? 12.w : 16.w,
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
              if (resolvedCheckboxIcon != null) ...[
                10.horizontalSpace,
                resolvedCheckboxIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
