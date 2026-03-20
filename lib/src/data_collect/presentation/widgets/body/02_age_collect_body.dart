part of '../../../data_collect.dart';

class AgeCollectBody extends StatelessWidget {
  const AgeCollectBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.l10n.onboarding.onboardingUserAgeQuestion,
            ),

            Spacer(),

            // Age Range Options
            const AgeOptions(),
          ],
        );
      },
    );
  }
}

class AgeOptions extends StatelessWidget {
  const AgeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedAgeRange != current.selectedAgeRange,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();
        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.age.length,
          physics: AlwaysScrollableScrollPhysics(),
          separatorBuilder: (_, _) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final option = state.onboardData.age[index];
            final selected = option == state.selectedAgeRange;
            return DataCollectOptionTile(
              option: option,
              isSelected: selected,
              onTap: () {
                AppService.instance.appTrackingService.trackObdAgeClick();
                cubit.selectAgeRange(option);
              },
              enableLeading: false,
            );
          },
        );
      },
    );
  }
}
