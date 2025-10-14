part of '../widgets.dart';

class ServerErrorPage extends StatelessWidget {
  const ServerErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.errorServerError,
      description: context.text.errorOopsSomethingWentWrongWhileLoading,
      buttonText: context.text.canvasTryAgain,
      illustration: AppAsset.images.common.databaseError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}