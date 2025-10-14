part of '../widgets.dart';

class CommonErrorPage extends StatelessWidget {
  const CommonErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.errorSomethingHappened,
      description: context.text.errorTakingAPauseIsAlsoPart,
      buttonText: context.text.canvasTryAgain,
      illustration: AppAsset.images.common.folderResearchError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}
