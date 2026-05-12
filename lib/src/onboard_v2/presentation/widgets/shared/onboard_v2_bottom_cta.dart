part of '../../../onboard_v2.dart';

class OnboardV2BottomCta extends StatelessWidget {
  const OnboardV2BottomCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            key: const Key('onboard_v2_primary_cta'),
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppCustomColor.brandPrimary,
              disabledBackgroundColor: AppCustomColor.buttonDisable,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : AppText(
                    label,
                    style: AppStyle.text16.copyWith(
                      color: onPressed == null ? AppCustomColor.textTertiary : AppCustomColor.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        if (secondaryLabel != null) ...[
          10.verticalSpace,
          TextButton(
            key: const Key('onboard_v2_secondary_cta'),
            onPressed: isLoading ? null : onSecondaryPressed,
            child: AppText(
              secondaryLabel!,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
