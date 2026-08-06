part of '../../onboard.dart';

/// Blocking "you must update" card shown over the splash.
///
/// [PopScope] with `canPop: false` lives here rather than in `showDDialog`:
/// that helper is shared by every dialog in the app, so swallowing the back
/// gesture there would make all of them undismissable. Paired with
/// `showGeneralDialog`'s default `barrierDismissible: false`, this leaves exactly
/// two ways out — update, or kill the app. That is the whole point of a forced
/// update; a dialog the back button dismisses is only a suggestion.
class ForceUpdateContent extends StatelessWidget {
  final VoidCallback? onUpdatePressed;

  const ForceUpdateContent({
    super.key,
    this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Stack(
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
                        context.l10n.common.forceUpdateTitle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        style: AppStyle.textBold20.copyWith(
                          color: AppCustomColor.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      8.verticalSpace,
                      AppText(
                        context.l10n.common.forceUpdateMessage,
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
                        context.l10n.common.forceUpdateAction,
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
      ),
    );
  }
}
