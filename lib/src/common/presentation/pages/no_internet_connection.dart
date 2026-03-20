part of '../../common.dart';

class NoInternetConnectionPage extends StatelessWidget {
  const NoInternetConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.l10n.common.errorNoInternetConnection,
      description: context.l10n.common.errorOopsItLooksLikeYouAreOffline,
      buttonText: context.l10n.common.canvasTryAgain,
      illustration: AppAsset.images.common.connectionError.path,
      onTryAgain: () {
        context.back();
      },
    );
  }
}
