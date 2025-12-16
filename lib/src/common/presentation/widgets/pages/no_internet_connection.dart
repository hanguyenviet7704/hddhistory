part of '../widgets.dart';

class NoInternetConnectionPage extends StatelessWidget {
  const NoInternetConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.common.errorNoInternetConnection,
      description: context.text.common.errorOopsItLooksLikeYouAreOffline,
      buttonText: context.text.common.canvasTryAgain,
      illustration: AppAsset.images.common.connectionError.path,
      onTryAgain: () {
        context.back();
      },
    );
  }
}
