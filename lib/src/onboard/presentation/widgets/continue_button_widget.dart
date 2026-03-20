part of '../../onboard.dart';

class ContinueButtonWidget extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ContinueButtonWidget({
    super.key,
    this.text,
    this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFF554FF0) : Colors.grey[400],
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(1000.r),
          child: Center(
            child: AppText(
              text ?? context.l10n.onboarding.onboardingSkipGreetingButton,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
