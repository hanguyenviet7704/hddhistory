part of '../../../profile.dart';

class ProfileDeleteDialog {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profileDelete',
      barrierColor: Colors.black.op(0.6),
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: RouteNamed.profileDeleteDialog),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: _DialogBody(onConfirm: onConfirm),
          ),
        );
      },
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 327.w,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.text.setting.settingProfileDestructiveWarnTitle,
                textAlign: TextAlign.center,
                enableFitScaleDown: true,
                style: AppStyle.text20.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.verticalSpace,
              AppText(
                context.text.setting.settingProfileDestructiveWarnMessage,
                maxLines: 3,
                textAlign: TextAlign.center,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textSecondary,
                  height: 1.75,
                  fontWeight: FontWeight.w400,
                ),
              ),
              24.verticalSpace,
              _DialogButton(
                text: context.text.setting.settingProfileDestructiveYesButton,
                textColor: AppCustomColor.errorRed,
                borderColor: AppCustomColor.borderDefault,
                backgroundColor: AppCustomColor.backgroundWhite,
                onTap: () {
                  context.back();
                  onConfirm();
                },
              ),
              16.verticalSpace,
              _DialogButton(
                text: context.text.setting.settingProfileDestructiveNoButton,
                textColor: AppCustomColor.textWhite,
                backgroundColor: AppCustomColor.brandPrimary,
                onTap: () => context.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
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
    return InkWell(
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
        child: AppText(
          text,
          style: AppStyle.text16.copyWith(
            color: textColor,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
