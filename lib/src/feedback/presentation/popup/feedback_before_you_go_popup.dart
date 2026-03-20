part of '../../feedback.dart';

class FeedbackBeforeYouGoPopup extends StatelessWidget {
  const FeedbackBeforeYouGoPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'feedbackBeforeYouGoPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: RouteNamed.feedbackBeforeYouGoPopup),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: const FeedbackBeforeYouGoPopup(),
          ),
        );
      },
    ).then((value) {
      String pageRouteName = AppDI.injector.get<FeedbackCubit>().state.pageRouteName;
      AppDI.injector.get<PageCubit>().setCurrentRouteName(pageRouteName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeedbackPopupShell(
      onTapOutside: () => context.back(),
      child: GestureDetector(
        onTap: () => context.back(),
        child: FeedbackThankYouBody(
          titleLine1: context.l10n.feedback.thankYouTitleLine1,
          titleLine2: context.l10n.feedback.thankYouTitleLine2,
          subtitle: context.l10n.feedback.thankYouSubtitle,
        ),
      ),
    );
  }
}
