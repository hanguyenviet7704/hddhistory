part of '../../spaced_review.dart';

/// End of a "Ôn tập hôm nay" session: the score, and what happens next to the
/// keypoints the reader got right and wrong.
class SpacedReviewCompletionPage extends StatefulWidget {
  const SpacedReviewCompletionPage({super.key});

  @override
  State<SpacedReviewCompletionPage> createState() => _SpacedReviewCompletionPageState();
}

class _SpacedReviewCompletionPageState extends State<SpacedReviewCompletionPage> {
  @override
  void initState() {
    super.initState();
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.spacedReviewCompletion);
  }

  void _backHome(BuildContext context) {
    unawaited(context.read<SpacedReviewCubit>().finish());
    if (context.canPop()) {
      context.pop();
    } else {
      HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.spacedReview;
    final state = context.watch<SpacedReviewCubit>().state;
    final total = state.results.length;
    final correct = state.correctCount;

    return PopScope(
      // System back behaves like the CTA so the finished session is cleared.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backHome(context);
      },
      child: Scaffold(
        key: const Key('spaced-review-completion-page'),
        backgroundColor: const Color(0xFFFEFAF1),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  l10n.completionTitle,
                  textAlign: TextAlign.center,
                  style: AppStyle.text32.copyWith(color: const Color(0xFF94762A), fontWeight: FontWeight.w700, height: 1.25),
                ),
                12.verticalSpace,
                AppText(
                  l10n.completionScore(correct: correct, total: total),
                  textAlign: TextAlign.center,
                  style: AppStyle.text18.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
                ),
                8.verticalSpace,
                AppText(
                  l10n.completionHint,
                  textAlign: TextAlign.center,
                  maxLines: 100,
                  style: AppStyle.text14.copyWith(color: const Color(0xFF5F6F86), height: 1.75),
                ),
              ],
            ),
          ),
        ),
        // SafeArea: Scaffold does NOT inset bottomNavigationBar (see
        // WarmUpCompletionPage).
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DailyWarmUpBottomCta(
                key: const Key('spaced-review-back-home-button'),
                label: l10n.backHomeButton,
                enabled: true,
                onPressed: () => _backHome(context),
              ),
              12.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
