part of '../../../../lesson.dart';

class MarkStressWordCard extends StatelessWidget {
  final OptionEntity option;
  final AnswerState state;
  final VoidCallback? onTap;

  const MarkStressWordCard({
    super.key,
    required this.option,
    this.state = AnswerState.normal,
    this.onTap,
  });

  Color get backgroundColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFFEFF0FE),
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      AnswerState.correctNotSelected => Colors.white,
      AnswerState.disabled => Colors.white,
      _ => Colors.white,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => const Color(0xFF554FF0),
      AnswerState.correct => const Color(0xFF1DA75E),
      AnswerState.incorrect => const Color(0xFFE34646),
      AnswerState.correctNotSelected => const Color(0xFF364152),
      AnswerState.disabled => const Color(0xFFE3E8EF),
      _ => const Color(0xFFE3E8EF),
    };
  }

  double get opacity {
    return switch (state) {
      AnswerState.selected => 1.0,
      AnswerState.correct => 1.0,
      AnswerState.incorrect => 1.0,
      AnswerState.correctNotSelected => 1.0,
      AnswerState.disabled => 0.6,
      _ => 1.0,
    };
  }

  FontWeight get fontWeight {
    return switch (state) {
      AnswerState.selected => FontWeight.w600,
      AnswerState.correct => FontWeight.w600,
      AnswerState.incorrect => FontWeight.w600,
      AnswerState.correctNotSelected => FontWeight.w600,
      AnswerState.disabled => FontWeight.w500,
      _ => FontWeight.w500,
    };
  }

  String get displayText {
    return switch (state) {
      AnswerState.correct || AnswerState.correctNotSelected || AnswerState.selected || AnswerState.incorrect => option.text.toUpperCase(),
      _ => option.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2.w),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: AppText(
            displayText,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(
              color: const Color(0xFF364152),
              fontWeight: fontWeight,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
