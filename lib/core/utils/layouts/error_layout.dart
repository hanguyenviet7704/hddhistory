part of '../utils.dart';

class ErrorLayout extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onTryAgain;
  final String illustration;

  const ErrorLayout({
    super.key,
    this.title = 'Something happened!',
    this.description = 'Taking a pause is also part of the creative process...',
    this.buttonText = 'Try again',
    this.onTryAgain,
    this.illustration = 'assets/images/error.svg',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorLight.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(illustration, width: 204.w),
            48.verticalSpace,
            AppText(title, style: AppStyle.text40),
            20.verticalSpace,
            AppText(description, style: AppStyle.text16),
            40.verticalSpace,
            DButton(
              onPressed: onTryAgain ?? () => HomeRoute().go(context),
              customChild: AppText(buttonText, style: AppStyle.text20),
              size: Size(186.w, 60.h),
              backgroundColor: AppCustomColor.greyEE,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}
