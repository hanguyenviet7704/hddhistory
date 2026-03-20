part of '../../../data_collect.dart';

class LearningStruggerBody extends StatelessWidget {
  const LearningStruggerBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              note: context.l10n.onboarding.onboardingStruggleNote,
              title: context.l10n.onboarding.onboardingStruggleQuestion,
              subtitle: context.l10n.onboarding.onboardingStruggleQuestionSubtitle,
            ),
            24.verticalSpace,
            // Topic Options
            const LearningStruggerOptions(),
          ],
        );
      },
    );
  }
}

class LearningStruggerOptions extends StatelessWidget {
  const LearningStruggerOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedLearningStruggles != current.selectedLearningStruggles,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return Expanded(
          child: ListView.separated(
            itemCount: state.onboardData.learningStruggles.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final struggle = state.onboardData.learningStruggles[index];
              final isSelected = state.selectedLearningStruggles.contains(struggle);
              return DataCollectOptionTile(
                option: struggle,
                isSelected: isSelected,
                onTap: () {
                  AppService.instance.appTrackingService.trackObdStrugglesClick();
                  cubit.selectLearningStruggles(struggle);
                },
                type: DataCollectOptionType.checkbox,
              );
            },
          ),
        );
      },
    );
  }
}
