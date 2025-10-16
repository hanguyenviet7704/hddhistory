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
              "What's your gender?",
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
    return BlocSelector<DataCollectCubit, DataCollectState, String?>(
      selector: (state) => state.selectedGender,
      builder: (context, selectedGender) {
        final cubit = context.read<DataCollectCubit>();
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GenderOption(
                title: 'Male',
                value: 'male',
                emoji: '👨',
                groupValue: selectedGender ?? 'others', // Default selected value
                onChanged: (value) {
                  cubit.selectGender(value!);
                },
              ),
              SizedBox(height: 12.h),
              GenderOption(
                title: 'Female',
                value: 'female',
                emoji: '👩',
                groupValue: selectedGender ?? 'others', // Default selected value
                onChanged: (value) {
                  cubit.selectGender(value!);
                },
              ),
              SizedBox(height: 12.h),
              GenderOption(
                title: 'Others',
                value: 'others',
                emoji: '🧑',
                groupValue: selectedGender ?? 'others', // Default selected value
                onChanged: (value) {
                  cubit.selectGender(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
