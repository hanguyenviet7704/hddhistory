// ignore_for_file: unused_element

part of '../../../../exercise.dart';


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
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              // Checkbox for multiple choice
              Expanded(
                child: AppText(
                  option.value,
                  maxLines: 10,
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xFF364152),
                    fontWeight: fontWeight,
                    height: 1.75,
                  ),
                ),
              ),

              // if (isMultiChoice) ...[
              //   12.horizontalSpace,
              //   _buildCheckbox(),
              // ],

              // Answer text
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    Color checkColor;
    Color borderColor;
    Color backgroundColor;

    switch (state) {
      case AnswerState.selected:
        checkColor = Colors.white;
        borderColor = const Color(0xFF554FF0);
        backgroundColor = const Color(0xFF554FF0);
        break;
      case AnswerState.correct:
        checkColor = Colors.white;
        borderColor = const Color(0xFF1DA75E);
        backgroundColor = const Color(0xFF1DA75E);
        break;
      case AnswerState.incorrect:
        checkColor = Colors.white;
        borderColor = const Color(0xFFE34646);
        backgroundColor = const Color(0xFFE34646);
        break;
      case AnswerState.disabled:
        checkColor = Colors.transparent;
        borderColor = const Color(0xFFE3E8EF);
        backgroundColor = Colors.white;
        break;
      default:
        checkColor = Colors.transparent;
        borderColor = const Color(0xFFE3E8EF);
        backgroundColor = Colors.white;
    }

    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2.w),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: state == AnswerState.selected || state == AnswerState.correct
          ? Icon(
              Icons.check,
              color: checkColor,
              size: 14.w,
            )
          : state == AnswerState.incorrect
          ? Icon(
              Icons.close,
              color: checkColor,
              size: 14.w,
            )
          : null,
    );
  }

  Widget _buildRadioButton() {
    Color borderColor;
    Color innerColor;

    switch (state) {
      case AnswerState.selected:
        borderColor = const Color(0xFF554FF0);
        innerColor = const Color(0xFF554FF0);
        break;
      case AnswerState.correct:
        borderColor = const Color(0xFF1DA75E);
        innerColor = const Color(0xFF1DA75E);
        break;
      case AnswerState.incorrect:
        borderColor = const Color(0xFFE34646);
        innerColor = const Color(0xFFE34646);
        break;
      case AnswerState.disabled:
        borderColor = const Color(0xFFE3E8EF);
        innerColor = Colors.transparent;
        break;
      default:
        borderColor = const Color(0xFFE3E8EF);
        innerColor = Colors.transparent;
    }

    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.w),
      ),
      child: Center(
        child: Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: innerColor,
          ),
        ),
      ),
    );
  }
}
