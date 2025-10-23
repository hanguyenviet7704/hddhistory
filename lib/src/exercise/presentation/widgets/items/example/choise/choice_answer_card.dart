part of '../../../../../exercise.dart';

enum AnswerState { normal, selected, correct, incorrect, disabled }

class ChoiceAnswerCard extends StatelessWidget {
  final String text;
  final bool isMultiChoice;
  final AnswerState state;
  final VoidCallback? onTap;

  const ChoiceAnswerCard({super.key, required this.text, this.isMultiChoice = false, this.state = AnswerState.normal, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    double opacity;
    FontWeight fontWeight;

    switch (state) {
      case AnswerState.selected:
        backgroundColor = Colors.white;
        borderColor = const Color(0xFF554FF0);
        opacity = 1.0;
        fontWeight = FontWeight.w500;
        break;
      case AnswerState.correct:
        backgroundColor = const Color(0xFFEAFFEF);
        borderColor = const Color(0xFF1DA75E);
        opacity = 1.0;
        fontWeight = FontWeight.w500;
        break;
      case AnswerState.incorrect:
        backgroundColor = const Color(0xFFFDEAE7);
        borderColor = const Color(0xFFE34646);
        opacity = 1.0;
        fontWeight = FontWeight.w500;
        break;
      case AnswerState.disabled:
        backgroundColor = Colors.white;
        borderColor = const Color(0xFFE3E8EF);
        opacity = 0.7;
        fontWeight = FontWeight.w400;
        break;
      default:
        backgroundColor = Colors.white;
        borderColor = const Color(0xFFE3E8EF);
        opacity = 1.0;
        fontWeight = FontWeight.w400;
    }

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: state == AnswerState.disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: AppText(
            text,
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
