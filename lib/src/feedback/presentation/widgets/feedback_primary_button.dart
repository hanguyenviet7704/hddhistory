part of '../../feedback.dart';

class FeedbackPrimaryButton extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback? onTap;

  const FeedbackPrimaryButton({
    super.key,
    required this.title,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = enabled ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault;
    final textColor = enabled ? AppCustomColor.textWhite : AppCustomColor.textTertiary;

    return Container(
      height: 54.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(1000.r),
          child: Center(
            child: AppText(
              title,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
