part of '../widgets.dart';

class NoInternetConnectionPage extends StatelessWidget {
  const NoInternetConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.errorNoInternetConnection,
      description: context.text.errorOopsItLooksLikeYouAreOffline,
      buttonText: context.text.canvasTryAgain,
      illustration: AppAsset.images.connectionError.path,
      onTryAgain: () {context.back();},
    );
  }
}
