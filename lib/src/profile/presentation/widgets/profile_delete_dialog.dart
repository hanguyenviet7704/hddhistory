part of '../../profile.dart';

Future<void> showProfileDeleteDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        backgroundColor: AppCustomColor.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.text.settingProfileDestructiveWarnTitle,
                textAlign: TextAlign.center,
                style: AppStyle.text20.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.text.settingProfileDestructiveWarnMessage,
                textAlign: TextAlign.center,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textSecondary,
                  height: 1.75,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 24.h),
              _ProfileDialogButton(
                text: context.text.settingProfileDestructiveYesButton,
                textColor: AppCustomColor.errorRed,
                borderColor: AppCustomColor.borderDefault,
                backgroundColor: AppCustomColor.backgroundWhite,
                onTap: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
              SizedBox(height: 16.h),
              _ProfileDialogButton(
                text: context.text.settingProfileDestructiveNoButton,
                textColor: AppCustomColor.textWhite,
                backgroundColor: AppCustomColor.brandPrimary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileDialogButton extends StatelessWidget {
  const _ProfileDialogButton({
    required this.text,
    required this.onTap,
    required this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String text;
  final VoidCallback onTap;
  final Color textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(1000.r),
        onTap: onTap,
        child: Container(
          height: 54.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(1000.r),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: borderColor == null ? 0 : 2,
            ),
          ),
          child: Text(
            text,
            style: AppStyle.text16.copyWith(
              color: textColor,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
