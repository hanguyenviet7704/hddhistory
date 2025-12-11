part of '../../../data_collect.dart';

class SkillsetsWantToMasterBody extends StatelessWidget {
  const SkillsetsWantToMasterBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.text.onboarding.onboardingChooseSkillsetTitle,
              subtitle: context.text.onboarding.onboardingChooseSkillsetSubtitle,
            ),

            24.verticalSpace,

            // Topic Options
            const TopicOptions(),
          ],
        );
      },
    );
  }
}

class TopicOptions extends StatelessWidget {
  const TopicOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return Expanded(
          child: ListView.separated(
            itemCount: state.onboardData.skillsetWantToMaster.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final topic = state.onboardData.skillsetWantToMaster[index];
              return TopicOption(
                value: topic,
                isSelected: state.selectedSkillsetsWantToMaster.contains(topic),
                onChanged: (value) => cubit.selectSkillsetWantToMaster(value ?? OnboardOptionEntity()),
              );
            },
          ),
        );
      },
    );
  }
}
