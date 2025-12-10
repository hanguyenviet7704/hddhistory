part of '../../../data_collect.dart';

class AgeCollectBody extends StatelessWidget {
  const AgeCollectBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboarding.onboardingUserAgeQuestion,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
            ),

            // Age Range Options
            AgeOptions(),
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
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12.h,
            children: state.onboardData.age
                .map(
                  (option) => AgeOption(
                    value: option,
                    groupValue: state.selectedAgeRange ?? OnboardOptionEntity(),
                    onChanged: (value) => cubit.selectAgeRange(value ?? OnboardOptionEntity()),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
