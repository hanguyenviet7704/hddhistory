part of '../../../data_collect.dart';

class GenderCollectBody extends StatelessWidget {
  const GenderCollectBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.text.onboarding.onboardingUserGenderQuestion,
            ),

            Spacer(),

            // Gender Options
            const GenderOptions(),
          ],
        );
      },
    );
  }
}

class GenderOptions extends StatelessWidget {
  const GenderOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedGender != current.selectedGender,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();
        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.gender.length,
          separatorBuilder: (_, _) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final option = state.onboardData.gender[index];
            final selected = option == state.selectedGender;
            return DataCollectOptionTile(
              option: option,
              isSelected: selected,
              onTap: () => cubit.selectGender(option),
              type: DataCollectOptionType.radio,
              enableLeading: true,
            );
          },
        );
      },
    );
  }
}
