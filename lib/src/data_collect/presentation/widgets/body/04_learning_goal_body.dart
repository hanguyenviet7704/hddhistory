part of '../../../data_collect.dart';

class LearningGoalBody extends StatelessWidget {
  const LearningGoalBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.text.onboarding.onboardingLearningGoalQuestion,
            ),

            const Spacer(),

            // Learning Goal Options
            const LearningGoalOptions(),
          ],
        );
      },
    );
  }
}

class LearningGoalOptions extends StatelessWidget {
  const LearningGoalOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedLearningGoal != current.selectedLearningGoal,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.learningGoal.length,
          separatorBuilder: (_, _) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final goalOption = state.onboardData.learningGoal[index];
            final selected = goalOption == state.selectedLearningGoal;
            return DataCollectOptionTile(
              option: goalOption,
              isSelected: selected,
              onTap: () => cubit.selectLearningGoal(goalOption),
              type: DataCollectOptionType.radio,
              enableLeading: false,
            );
          },
        );
      },
    );
  }
}
