part of '../../onboard.dart';

class ForceUpdateContent extends StatelessWidget {
  static const String _title = "We're getting better!";
  static const String _message = 'For more features and a better user experience,\nupgrade your app please.';
  static const String _actionText = 'Go to Update';

  final VoidCallback? onUpdatePressed;

  const ForceUpdateContent({
    super.key,
    this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 45.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      _title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: AppStyle.textBold20.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    8.verticalSpace,
                    AppText(
                      _message,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.textSecondary,
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  child: DButton(
                    onPressed: onUpdatePressed,
                    backgroundColor: AppCustomColor.brandPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
                    size: Size.fromHeight(48.h),
                    customChild: AppText(
                      _actionText,
                      textAlign: TextAlign.center,
                      style: AppStyle.textBold16.copyWith(
                        color: AppCustomColor.textWhite,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppAsset.images.app.forceUpdateDecor.image(
          width: 216.84.w,
          height: 90.h,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ],
    );
  }
}
