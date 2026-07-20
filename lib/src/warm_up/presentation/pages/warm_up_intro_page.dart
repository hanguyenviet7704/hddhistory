part of '../../warm_up.dart';

/// Figma 11242-49537 — "Pick up where you left off". Entry point for the
/// return-refresher: reuses the daily_warm_up entry step's visual language
/// (soft violet background, floating illustration) so the two "warm up"
/// moments in the app read as one family.
class WarmUpIntroPage extends StatefulWidget {
  const WarmUpIntroPage({super.key});

  @override
  State<WarmUpIntroPage> createState() => _WarmUpIntroPageState();
}

class _WarmUpIntroPageState extends State<WarmUpIntroPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    // Non-primary route name → hides the shell's floating bottom nav during the
    // warm-up flow (branch nav doesn't fire the root observer; mirrors
    // keypoint_complete_page). Runs after nav so it wins.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.warmUpIntro);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _float = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startWarmUp(BuildContext context) {
    context.read<WarmUpCubit>().startWarmUp();
    WarmUpQuestionRoute().go(context);
  }

  void _skipToLesson(BuildContext context) {
    // Same mechanism as the completion CTA: return to the roadmap first and let
    // its WarmUpCubit listener open the lesson — launching from this
    // (root-navigator) page would leave a dead-end warm-up screen underneath
    // the paywall/lesson.
    context.read<WarmUpCubit>().closeFlowAndRouteToLesson();
    CourseRoadmapRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || MediaQuery.accessibleNavigationOf(context);

    return BlocSelector<WarmUpCubit, WarmUpState, bool>(
      selector: (state) => state.hasWarmUpAvailable,
      builder: (context, hasWarmUpAvailable) {
        return Scaffold(
          key: const Key('warm-up-intro-page'),
          backgroundColor: const Color(0xFFC7C5FA),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 58.h, 20.w, 24.h),
              children: [
                AppText(
                  context.l10n.warmUp.introTitle,
                  textAlign: TextAlign.center,
                  style: AppStyle.text32.copyWith(color: const Color(0xFF362F82), fontWeight: FontWeight.w700),
                ),
                12.verticalSpace,
                AppText(
                  context.l10n.warmUp.introSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.text16.copyWith(color: const Color(0xFF362F82), fontWeight: FontWeight.w500),
                ),
                40.verticalSpace,
                SizedBox(
                  height: 290.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(AppAsset.images.app.dailyWarmUpDecor.path, width: 275.w, fit: BoxFit.contain),
                      Positioned(
                        top: 85.h,
                        left: 110.w,
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, reduceMotion ? 0 : _float.value),
                              child: child,
                            );
                          },
                          child: Image.asset(AppAsset.images.app.dailyWarmUpDecorOption.path, width: 145.w, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // SafeArea: Scaffold does NOT inset bottomNavigationBar, and Android
          // 15 is edge-to-edge — without this the Skip button sits under the
          // 3-button system nav bar.
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DailyWarmUpBottomCta(
                label: context.l10n.warmUp.startWarmUpButton,
                enabled: hasWarmUpAvailable,
                width: 250.w,
                onPressed: () => _startWarmUp(context),
              ),
              Semantics(
                button: true,
                label: context.l10n.warmUp.skipToLesson,
                child: TextButton(
                  key: const Key('warm-up-skip-to-lesson-button'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    AppHaptic.select();
                    _skipToLesson(context);
                  },
                  child: AppText(
                    context.l10n.warmUp.skipToLesson,
                    style: AppStyle.text16.copyWith(color: const Color(0xFF362F82), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              12.verticalSpace,
            ],
            ),
          ),
        );
      },
    );
  }
}
