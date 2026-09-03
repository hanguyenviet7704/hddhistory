part of '../utils.dart';

class ErrorLayout extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onTryAgain;
  final String? illustration;

  const ErrorLayout({
    super.key,
    this.title = 'Something happened!',
    this.description = 'Taking a pause is also part of the creative process...',
    this.buttonText = 'Try again',
    this.onTryAgain,
    this.illustration,
  });

  /// Every caller that passes one passes a PNG, which is why this stays
  /// [Image.asset]. The default used to be `assets/images/error.svg` — a path
  /// that exists nowhere (the real file is `assets/svg/common/error.svg`) AND an
  /// SVG, which `Image.asset` cannot decode either way. So any error screen that
  /// did not name its own illustration drew nothing and logged an image-codec
  /// exception on top of whatever had already gone wrong.
  static String get _defaultIllustration => AppAsset.images.common.folderResearchError.path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorLight.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(illustration ?? _defaultIllustration, width: 204.w),
            48.verticalSpace,
            AppText(title, style: AppStyle.text40),
            20.verticalSpace,
            AppText(description, style: AppStyle.text16),
            40.verticalSpace,
            DButton(
              onPressed: onTryAgain ?? () => HomeRoute().go(context),
              customChild: AppText(buttonText, style: AppStyle.text20),
              size: Size(186.w, 60.h),
              backgroundColor: AppCustomColor.brandPrimary50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}
