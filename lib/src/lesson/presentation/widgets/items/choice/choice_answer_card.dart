part of '../../../../lesson.dart';

class ChoiceAnswerCard extends StatelessWidget {
  final OptionEntity option;
  final bool isMultiChoice;
  final AnswerState state;
  final VoidCallback? onTap;

  const ChoiceAnswerCard({
    super.key,
    required this.option,
    this.isMultiChoice = false,
    this.state = AnswerState.normal,
    this.onTap,
  });

  Color get backgroundColor {
    return switch (state) {
      AnswerState.selected => Colors.white,
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      AnswerState.disabled => Colors.white,
      _ => Colors.white,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFF554FF0),
      AnswerState.correct => const Color(0xFF1DA75E),
      AnswerState.incorrect => const Color(0xFFE34646),
      AnswerState.disabled => const Color(0xFFE3E8EF),
      _ => const Color(0xFFE3E8EF),
    };
  }

  double get opacity {
    return switch (state) {
      AnswerState.selected => 1.0,
      AnswerState.correct => 1.0,
      AnswerState.incorrect => 1.0,
      AnswerState.disabled => 0.7,
      _ => 1.0,
    };
  }

  FontWeight get fontWeight {
    return switch (state) {
      AnswerState.selected => FontWeight.w500,
      AnswerState.correct => FontWeight.w500,
      AnswerState.incorrect => FontWeight.w500,
      AnswerState.disabled => FontWeight.w400,
      _ => FontWeight.w400,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          alignment: Alignment.centerLeft,
          constraints: BoxConstraints(minHeight: 60.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
