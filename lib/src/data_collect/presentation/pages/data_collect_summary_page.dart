part of '../../data_collect.dart';

class DataCollectSummaryPage extends StatelessWidget {
  const DataCollectSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<DataCollectCubit>(),
      child: const _DataCollectSummaryPageBody(),
    );
  }
}

class _DataCollectSummaryPageBody extends StatefulWidget {
  const _DataCollectSummaryPageBody();

  @override
  State<_DataCollectSummaryPageBody> createState() => _DataCollectSummaryPageBodyState();
}

class _DataCollectSummaryPageBodyState extends State<_DataCollectSummaryPageBody> {
  @override
  void initState() {
    super.initState();
    // Start analysis when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DataCollectCubit>().startAnalysis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        // Show loading/analysis state
        if (!state.analysisComplete) {
          return _buildAnalysisState(context);
        }

        // Show user data state
        return _buildUserDataState(context, state);
      },
    );
  }

  Widget _buildAnalysisState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC7C5FA), // Border/Brand
      body: SafeArea(
        child: Column(
          children: [
            // Status bar space
            SizedBox(height: 59.h),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Analysis illustration
                    SizedBox(
                      height: 220.88.h,
                      width: 127.92.w,
                      child: Image.asset(
                        'assets/images/app/analysis_illustration.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Analysis text
                    AppText(
                      "We're creating a personalized\nlearning path for you....",
                      textAlign: TextAlign.center,
                      style: AppStyle.textBold20.copyWith(
                        color: const Color(0xFF362F82), // Brand/Brand/Primary/700
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom space for home indicator
            SizedBox(height: 34.h),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataState(BuildContext context, DataCollectState state) {
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
                    SizedBox(
                      height: 180.h,
                      width: 102.58.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/app/success_illustration.png',
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30.w,
                              height: 30.h,
                              decoration: const BoxDecoration(
                                color: Color(0xFF23AE86), // Success color
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 36.h),

                    // Progress bars
                    Column(
                      children: [
                        _buildProgressBar(
                          title: "Personal Background",
                          progress: state.personalBackgroundProgress,
                          progressColor: const Color(0xFF0BA5EC), // Blue
                        ),
                        SizedBox(height: 24.h),
                        _buildProgressBar(
                          title: "Difficulties",
                          progress: state.difficultiesProgress,
                          progressColor: const Color(0xFF23AE86), // Green
                        ),
                        SizedBox(height: 24.h),
                        _buildProgressBar(
                          title: "Learning Goal",
                          progress: state.learningGoalProgress,
                          progressColor: const Color(0xFFF99E0B), // Orange
                        ),
                        SizedBox(height: 24.h),
                        _buildProgressBar(
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
            Container(
              padding: EdgeInsets.all(20.w),
              child: AppButton.primary(
                onPressed: () {
                  // Navigate to home or next screen
                  // This would be implemented based on app navigation
                  HomeRoute().go(context);
                },
                fullWidthBtn: true,
                height: 54.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF554FF0), // Brand/Primary
                  borderRadius: BorderRadius.circular(1000.r),
                ),
                child: AppText(
                  'Starts your journey!',
                  style: AppStyle.textBold16.copyWith(
                    color: Colors.white, // Text/White
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Bottom space for home indicator
            SizedBox(height: 22.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String title,
    required double progress,
    required Color progressColor,
  }) {
    return Column(
      children: [
        // Title and percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              title,
              style: AppStyle.textBold16.copyWith(
                color: const Color(0xFF0D121C), // Text/Primary
                fontWeight: FontWeight.w500,
              ),
            ),
            AppText(
              '${(progress * 100).toInt()}%',
              style: AppStyle.textBold14.copyWith(
                color: const Color(0xFFAAB8CD), // Text/Quaternary
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // Progress bar
        Container(
          height: 11.h,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8EF), // Border/Default
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 11.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8EF), // Border/Default
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 11.h,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
