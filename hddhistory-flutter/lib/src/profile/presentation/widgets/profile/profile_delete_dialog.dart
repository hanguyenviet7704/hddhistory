part of '../../../profile.dart';

class ProfileDeleteDialog {
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) {
    AppService.instance.appTrackingService.trackProfileDeleteScrView();
    return showGeneralDialog<String>(
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
    ).then((value) {
      final result = value ?? 'exit';
      AppService.instance.appTrackingService.trackProfileDeleteOptionClick(result);
    });
  }
}

class _DialogBody extends StatefulWidget {
  const _DialogBody({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DialogBody> createState() => _DialogBodyState();
}

class _DialogBodyState extends State<_DialogBody> {
  bool _isSubmitting = false;

  // Await the caller's confirm work (dispatch + wait for the real
  // success/failure outcome) before dismissing — previously this popped the
  // dialog (and the page behind it) immediately on tap, so a failed deletion
  // showed nothing and looked like it had silently succeeded.
  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop('yes');
      }
    }
  }

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
                context.l10n.setting.settingProfileDestructiveWarnTitle,
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
                context.l10n.setting.settingProfileDestructiveWarnMessage,
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
                text: context.l10n.setting.settingProfileDestructiveYesButton,
                textColor: AppCustomColor.errorRed,
                borderColor: AppCustomColor.borderDefault,
                backgroundColor: AppCustomColor.backgroundWhite,
                isLoading: _isSubmitting,
                onTap: _handleConfirm,
              ),
              16.verticalSpace,
              _DialogButton(
                text: context.l10n.setting.settingProfileDestructiveNoButton,
                textColor: AppCustomColor.textWhite,
                backgroundColor: AppCustomColor.brandPrimary,
                onTap: _isSubmitting ? null : () => Navigator.of(context).pop('no'),
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
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(1000.r),
      onTap: isLoading || onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
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
        child: isLoading
            ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : AppText(
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
