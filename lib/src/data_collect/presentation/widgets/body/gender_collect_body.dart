part of '../../../data_collect.dart';

class GenderCollectBody extends StatelessWidget {
  const GenderCollectBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboardingUserGenderQuestion,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
            ),

            // Gender Options
            GenderOptions(),
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
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: state.onboardData.gender
                .map(
                  (option) => GenderOption(
                    value: option,
                    groupValue: state.selectedGender ?? OnboardOptionEntity(),
                    onChanged: (value) => cubit.selectGender(value ?? OnboardOptionEntity()),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
