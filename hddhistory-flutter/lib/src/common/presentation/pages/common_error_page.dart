part of '../../common.dart';

class CommonErrorPage extends StatelessWidget {
  const CommonErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.l10n.common.errorSomethingHappened,
      description: context.l10n.common.errorTakingAPauseIsAlsoPart,
      buttonText: context.l10n.common.canvasTryAgain,
      illustration: AppAsset.images.common.folderResearchError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}
