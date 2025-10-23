part of '../../../../exercise.dart';

class ExerciseContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ExerciseContinueButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: AppButton.primary(
        onPressed: onPressed,
        fullWidthBtn: true,
        height: 54.h,
        child: AppText(
          context.text.onboardingSkipGreetingButton,
          style: AppStyle.textBold16.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
