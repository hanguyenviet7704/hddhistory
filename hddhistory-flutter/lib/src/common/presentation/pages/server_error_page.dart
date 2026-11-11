part of '../../common.dart';

class ServerErrorPage extends StatelessWidget {
  const ServerErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.l10n.common.errorServerError,
      description: context.l10n.common.errorOopsSomethingWentWrongWhileLoading,
      buttonText: context.l10n.common.canvasTryAgain,
      illustration: AppAsset.images.common.databaseError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}
