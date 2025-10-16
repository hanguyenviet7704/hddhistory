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
              "What's your age?",
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
    return BlocSelector<DataCollectCubit, DataCollectState, String?>(
      selector: (state) => state.selectedAgeRange,
      builder: (context, selectedAgeRange) {
        final cubit = context.read<DataCollectCubit>();
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AgeOption(
                title: '17 or younger',
                value: '17_or_younger',
                groupValue: selectedAgeRange ?? '25-34', // Default selected value
                onChanged: (value) {
                  cubit.selectAgeRange(value!);
                },
              ),
              SizedBox(height: 12.h),
              AgeOption(
                title: '18-24',
                value: '18-24',
                groupValue: selectedAgeRange ?? '25-34', // Default selected value
                onChanged: (value) {
                  cubit.selectAgeRange(value!);
                },
              ),
              SizedBox(height: 12.h),
              AgeOption(
                title: '25-34',
                value: '25-34',
                groupValue: selectedAgeRange ?? '25-34', // Default selected value
                onChanged: (value) {
                  cubit.selectAgeRange(value!);
                },
              ),
              SizedBox(height: 12.h),
              AgeOption(
                title: '35-44',
                value: '35-44',
                groupValue: selectedAgeRange ?? '25-34', // Default selected value
                onChanged: (value) {
                  cubit.selectAgeRange(value!);
                },
              ),
              SizedBox(height: 12.h),
              AgeOption(
                title: '45 or older',
                value: '45_or_older',
                groupValue: selectedAgeRange ?? '25-34', // Default selected value
                onChanged: (value) {
                  cubit.selectAgeRange(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
