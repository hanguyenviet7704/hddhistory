part of '../../roleplay.dart';

class RoleplayFeedbackPage extends StatelessWidget {
  const RoleplayFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundGray,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RoleplayFeedbackChart(),
                      RoleplayFeedbackBreakdownSection(),
                      24.verticalSpace,
                      if (kDebugMode) RoleplayFeedbackSummarySection(),
                    ],
                  ),
                ),
              ),
              RoleplayFeedbackBottomCTA(
                onPressed: () {
                  context.read<CourseRoadmapCubit>().setRoadmapSource('nav_course');
                  CourseRoadmapRoute().go(context);
                  context.read<PageCubit>().setCurrentIndex(1);
                },
                label: context.text.roleplay.rolePlayResultStartLearningButton,
                helperText: context.text.roleplay.rolePlayHelperTextStartLearnButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
