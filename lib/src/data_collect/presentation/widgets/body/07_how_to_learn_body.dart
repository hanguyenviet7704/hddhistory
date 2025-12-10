part of '../../../data_collect.dart';

class HowToLearnBody extends StatelessWidget {
  const HowToLearnBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboarding.onboardingChooseSkillsetTitle,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            4.verticalSpace,
            // Subtitle
            AppText(
              context.text.onboarding.onboardingChooseSkillsetSubtitle,
              maxLines: 10,
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            20.verticalSpace,

            // Topic Options
            TopicOptions(),
          ],
        );
      },
    );
  }
}

class HowToLearnOptions extends StatelessWidget {
  const HowToLearnOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedTopics != current.selectedTopics,
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
                isSelected: state.isTopicSelected(topic),
                onChanged: (value) => cubit.selectTopic(value ?? OnboardOptionEntity()),
              );
            },
          ),
        );
      },
    );
  }
}
