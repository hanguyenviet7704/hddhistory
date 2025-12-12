part of '../../../data_collect.dart';

class DailyLearningGoalBody extends StatelessWidget {
  const DailyLearningGoalBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.text.onboarding.onboardingTimeSpentTitle,
              subtitle: context.text.onboarding.onboardingDailyGoalSubtitle,
            ),

            Spacer(),

            // Topic Options
            const DailyLearningGoalOptions(),
          ],
        );
      },
    );
  }
}

class DailyLearningGoalOptions extends StatelessWidget {
  const DailyLearningGoalOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedDailyLearningGoal != current.selectedDailyLearningGoal,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.dailyLearningGoal.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final option = state.onboardData.dailyLearningGoal[index];
            final isSelected = option == state.selectedDailyLearningGoal;
            return DataCollectOptionTile(
              option: option,
              isSelected: isSelected,
              onTap: () => cubit.selectDailyLearningGoal(option),
              type: DataCollectOptionType.radio,
            );
          },
        );
      },
    );
  }
}
