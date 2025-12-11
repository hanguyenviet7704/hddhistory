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
            20.verticalSpace,
            Spacer(),

            // Topic Options
            const SkillsetsWantToMasterBodyOptions(),
          ],
        );
      },
    );
  }
}

class SkillsetsWantToMasterBodyOptions extends StatelessWidget {
  const SkillsetsWantToMasterBodyOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedSkillsetsWantToMaster != current.selectedSkillsetsWantToMaster,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.skillsetWantToMaster.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final topic = state.onboardData.skillsetWantToMaster[index];
            return DataCollectOptionTile(
              option: topic,
              isSelected: state.selectedSkillsetsWantToMaster.contains(topic),
              onTap: () => cubit.selectSkillsetWantToMaster(topic),
              type: DataCollectOptionType.checkbox,
            );
          },
        );
      },
    );
  }
}
