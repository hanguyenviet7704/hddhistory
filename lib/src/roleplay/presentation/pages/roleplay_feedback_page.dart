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
                child: BlocBuilder<RoleplayPointCubit, RoleplayPointState>(
                  builder: (context, state) {
                    final points = state.points;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoleplayFeedbackChart(),
                          RoleplayFeedbackBreakdownSection(points: points),
                          24.verticalSpace,
                          RoleplayFeedbackSummarySection(points: points),
                          32.verticalSpace,
                        ],
                      ),
                    );
                  },
                ),
              ),
              RoleplayFeedbackBottomCTA(
                onPressed: () => _handleStartLearning(context),
                label: context.text.rolePlayResultStartLearningButton,
                helperText: context.text.rolePlayHelperTextStartLearnButton,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStartLearning(BuildContext context) {
    context.pop();
  }
}
