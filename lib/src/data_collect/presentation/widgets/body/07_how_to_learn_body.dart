part of '../../../data_collect.dart';

class HowToLearnBody extends StatelessWidget {
  const HowToLearnBody({super.key});

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
            const SkillsetsWantToMasterBodyOptions(),
          ],
        );
      },
    );
  }
}
