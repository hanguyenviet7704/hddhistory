part of '../../../data_collect.dart';

class UserDataState extends StatelessWidget {
  final DataCollectState state;

  const UserDataState({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background/White
      body: SafeArea(
        child: Column(
          children: [
            // Status bar space
            SizedBox(height: 59.h),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 36.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success illustration
                    SuccessIllustration(),

                    SizedBox(height: 36.h),

                    // Progress bars
                    Column(
                      children: [
                        SummaryProgressBar(
                          title: "Personal Background",
                          progress: state.personalBackgroundProgress,
                          progressColor: const Color(0xFF0BA5EC), // Blue
                        ),
                        SizedBox(height: 24.h),
                        SummaryProgressBar(
                          title: "Difficulties",
                          progress: state.difficultiesProgress,
                          progressColor: const Color(0xFF23AE86), // Green
                        ),
                        SizedBox(height: 24.h),
                        SummaryProgressBar(
                          title: "Learning Goal",
                          progress: state.learningGoalProgress,
                          progressColor: const Color(0xFFF99E0B), // Orange
                        ),
                        SizedBox(height: 24.h),
                        SummaryProgressBar(
                          title: "Study Habits",
                          progress: state.studyHabitsProgress,
                          progressColor: const Color(0xFFF04438), // Red
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            StartJourneyButton(),

            // Bottom space for home indicator
            SizedBox(height: 22.h),
          ],
        ),
      ),
    );
  }
}
