part of '../../../data_collect.dart';

class ComfortableLearningTimeBody extends StatelessWidget {
  const ComfortableLearningTimeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.text.onboarding.onboardingTimeStudyQuestion,
              subtitle: context.text.onboarding.onboardingTimeStudySubtitle,
            ),

            Spacer(),

            // Time Options
            const TimeOptions(),
          ],
        );
      },
    );
  }
}

class TimeOptions extends StatelessWidget {
  const TimeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedComfortableLearningTime != current.selectedComfortableLearningTime,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.comfortableLearningTime.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final timeOption = state.onboardData.comfortableLearningTime[index];
            final isSelected = timeOption == state.selectedComfortableLearningTime;
            final subtitle = timeOption.title.text.isNotEmpty ? timeOption.title.text : null;
            return DataCollectOptionTile(
              option: timeOption,
              isSelected: isSelected,
              onTap: () {
                AppService.instance.appTrackingService.trackObdLearningTimeClick();
                cubit.selectComfortableLearningTime(timeOption);
              },
              type: DataCollectOptionType.none,
              subtitle: subtitle,
              titleStyle: AppStyle.text14,
              subtitleStyle: AppStyle.text12,
            );
          },
        );
      },
    );
  }
}
