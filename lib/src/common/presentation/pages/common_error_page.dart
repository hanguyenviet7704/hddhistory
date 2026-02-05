part of '../../common.dart';

class CommonErrorPage extends StatelessWidget {
  const CommonErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorLayout(
      title: context.text.common.errorSomethingHappened,
      description: context.text.common.errorTakingAPauseIsAlsoPart,
      buttonText: context.text.common.canvasTryAgain,
      illustration: AppAsset.images.common.folderResearchError.path,
      onTryAgain: () => HomeRoute().go(context),
    );
  }
}
