part of '../widgets.dart';

class ServerErrorPage extends StatelessWidget {
  const ServerErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.common.errorServerError,
      description: context.text.common.errorOopsSomethingWentWrongWhileLoading,
      buttonText: context.text.common.canvasTryAgain,
      illustration: AppAsset.images.common.databaseError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}
