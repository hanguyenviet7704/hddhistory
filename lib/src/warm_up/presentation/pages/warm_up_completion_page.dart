part of '../../warm_up.dart';

/// Figma 11242-49643 — "All warmed up! Here's your next step". Reuses the
/// daily_warm_up completion screen's visual language (gradient headline,
/// confetti lottie) and the roadmap's normal "start lesson" action so the
/// destination lesson behaves identically to any other roadmap entry point.
class WarmUpCompletionPage extends StatefulWidget {
  const WarmUpCompletionPage({super.key});

  @override
  State<WarmUpCompletionPage> createState() => _WarmUpCompletionPageState();
}

class _WarmUpCompletionPageState extends State<WarmUpCompletionPage> {
  @override
  void initState() {
    super.initState();
    // Non-primary route name → hides the shell's floating bottom nav on the
    // completion screen (branch nav doesn't fire the root observer).
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.warmUpCompletion);
    WarmUpTracking.track(
      TrackingKey.warmupDoneScrView,
      parameters: WarmUpTracking.courseParams(AppDI.injector.get<WarmUpCubit>().state.courseId),
    );
  }

  void _startTodaysLesson(BuildContext context) {
    WarmUpTracking.track(
      TrackingKey.warmupContinueClick,
      parameters: WarmUpTracking.courseParams(context.read<WarmUpCubit>().state.courseId),
    );
    // Leave the warm-up flow FIRST (back to the roadmap), then let the roadmap
    // page launch today's lesson via the WarmUpCubit listener. Launching the
    // lesson/paywall from this (root-navigator) page left the completion screen
    // underneath — dismissing the paywall trapped the user on it with no exit.
    context.read<WarmUpCubit>().closeFlowAndRouteToLesson();
    CourseRoadmapRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    final nextLesson = context.select<CourseRoadmapCubit, LessonEntity>((cubit) => cubit.state.currentLesson);

    return Scaffold(
      key: const Key('warm-up-completion-page'),
      backgroundColor: const Color(0xFFF2F1FE),
      body: SafeArea(
        child: Stack(
          children: [
            const _WarmUpCompletionBackground(),
            // Content is vertically centered between the status bar and CTA
            // (Figma 11242:49645 "Content" — flex-1, justify-center, gap 25).
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFF4B44CA), Color(0xFFA052FF), Color(0xFFEF81D4), Color(0xFFFF8F8F), Color(0xFFFFCE66)],
                    ).createShader(rect),
                    child: AppText(
                      context.l10n.warmUp.completionTitle,
                      textAlign: TextAlign.center,
                      style: AppStyle.text32.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.25),
                    ),
                  ),
                  4.verticalSpace,
                  AppText(
                    context.l10n.warmUp.completionSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(color: const Color(0xFF5F6F86), height: 1.75),
                  ),
                  if (nextLesson.id.isNotEmpty) ...[
                    25.verticalSpace,
                    WarmUpNextLessonCard(lesson: nextLesson),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // SafeArea: Scaffold does NOT inset bottomNavigationBar, and Android 15
      // is edge-to-edge — without this the CTA sits under the 3-button system
      // nav bar. (iOS home indicator gets safe inset + 12 ≈ the old 32 gap.)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: context.l10n.warmUp.startTodaysLessonButton,
              child: DailyWarmUpBottomCta(
                key: const Key('warm-up-start-todays-lesson-button'),
                label: context.l10n.warmUp.startTodaysLessonButton,
                enabled: true,
                onPressed: () => _startTodaysLesson(context),
              ),
            ),
            12.verticalSpace,
          ],
        ),
      ),
    );
  }
}

class _WarmUpCompletionBackground extends StatelessWidget {
  const _WarmUpCompletionBackground();

  @override
  Widget build(BuildContext context) {
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false) || MediaQuery.accessibleNavigationOf(context)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Lottie.asset(
          AppAsset.lottie.congratulations,
          fit: BoxFit.cover,
          repeat: true,
        ),
      ),
    );
  }
}
