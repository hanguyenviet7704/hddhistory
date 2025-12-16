part of '../../data_collect.dart';

class DataCollectSummaryPage extends StatefulWidget {
  const DataCollectSummaryPage({super.key});

  @override
  State<DataCollectSummaryPage> createState() => _DataCollectSummaryPageState();
}

class _DataCollectSummaryPageState extends State<DataCollectSummaryPage> {
  late final ValueNotifier<bool> _showStartButtonNotifier;
  int _completedAnimations = 0;
  static const int _totalAnimations = 4; // Total number of progress bars

  @override
  void initState() {
    super.initState();
    _requestTrackingPermission();
    _showStartButtonNotifier = ValueNotifier<bool>(false);
  }

  void _requestTrackingPermission() {
    AppService.instance.appEventService.requestTrackingPermission();
  }

  @override
  void dispose() {
    _showStartButtonNotifier.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    _completedAnimations++;
    if (_completedAnimations >= _totalAnimations) {
      _showStartButtonNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background/White
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 36.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success illustration
                    CacheNetworkGraphic(
                      width: 300.w,
                      url: context.select((OnboardCubit bloc) => bloc.state.onboardData.loading.image),
                      fit: BoxFit.contain,
                    ),
                    36.verticalSpace,

                    // Progress bars
                    BlocBuilder<DataCollectCubit, DataCollectState>(
                      buildWhen: (previous, current) =>
                          previous.personalBackgroundProgress != current.personalBackgroundProgress ||
                          previous.difficultiesProgress != current.difficultiesProgress ||
                          previous.learningGoalProgress != current.learningGoalProgress ||
                          previous.studyHabitsProgress != current.studyHabitsProgress,
                      builder: (context, state) {
                        return Column(
                          spacing: 24.h,
                          children: [
                            // First progress bar - starts immediately
                            AnimatedSummaryProgressBar(
                              title: context.text.onboarding.onboardingEvaluateBackground,
                              progress: state.personalBackgroundProgress,
                              progressColor: const Color(0xFF0BA5EC), // Blue
                              delay: Duration.zero,
                              onAnimationComplete: _onAnimationComplete,
                            ),

                            // Second progress bar - starts after first one completes
                            AnimatedSummaryProgressBar(
                              title: context.text.onboarding.onboardingEvaluateDificulty,
                              progress: state.difficultiesProgress,
                              progressColor: const Color(0xFF23AE86), // Green
                              delay: const Duration(milliseconds: 1500),
                              onAnimationComplete: _onAnimationComplete,
                            ),

                            // Third progress bar - starts after second one completes
                            AnimatedSummaryProgressBar(
                              title: context.text.onboarding.onboardingEvaluateLearningGoal,
                              progress: state.learningGoalProgress,
                              progressColor: const Color(0xFFF99E0B), // Orange
                              delay: const Duration(milliseconds: 3000),
                              onAnimationComplete: _onAnimationComplete,
                            ),

                            // Fourth progress bar - starts after third one completes
                            AnimatedSummaryProgressBar(
                              title: context.text.onboarding.onboardingEvaluateStudyHabits,
                              progress: state.studyHabitsProgress,
                              progressColor: const Color(0xFFF04438), // Red
                              delay: const Duration(milliseconds: 4500),
                              onAnimationComplete: _onAnimationComplete,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA - only show after all animations complete
            ValueListenableBuilder<bool>(
              valueListenable: _showStartButtonNotifier,
              builder: (context, showButton, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1.0), // Start from bottom
                            end: Offset.zero, // End at final position
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: showButton
                      ? Container(
                          key: const ValueKey('start_button'),
                          child: StartJourneyButton(),
                        )
                      : SizedBox(
                          key: const ValueKey('empty_space'),
                          height: 94.h,
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
