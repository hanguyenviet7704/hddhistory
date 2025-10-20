part of '../../../data_collect.dart';

class UserDataState extends StatelessWidget {
  const UserDataState({super.key});

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
                    SuccessIllustration(),

                    36.verticalSpace,

                    // Progress bars
                    BlocBuilder<DataCollectCubit, DataCollectState>(
                      buildWhen: (previous, current) => previous.personalBackgroundProgress != current.personalBackgroundProgress || previous.difficultiesProgress != current.difficultiesProgress || previous.learningGoalProgress != current.learningGoalProgress || previous.studyHabitsProgress != current.studyHabitsProgress,
                      builder: (context, state) {
                        return Column(
                          spacing: 24.h,
                          children: [
                            SummaryProgressBar(
                              title: context.text.onboardingEvaluateBackground,
                              progress: state.personalBackgroundProgress,
                              progressColor: const Color(0xFF0BA5EC), // Blue
                            ),

                            SummaryProgressBar(
                              title: context.text.onboardingEvaluateDificulty,
                              progress: state.difficultiesProgress,
                              progressColor: const Color(0xFF23AE86), // Green
                            ),

                            SummaryProgressBar(
                              title: context.text.onboardingEvaluateLearningGoal,
                              progress: state.learningGoalProgress,
                              progressColor: const Color(0xFFF99E0B), // Orange
                            ),

                            SummaryProgressBar(
                              title: context.text.onboardingEvaluateStudyHabits,
                              progress: state.studyHabitsProgress,
                              progressColor: const Color(0xFFF04438), // Red
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            StartJourneyButton(),
          ],
        ),
      ),
    );
  }
}
