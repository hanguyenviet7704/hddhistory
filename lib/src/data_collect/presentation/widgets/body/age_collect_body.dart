part of '../../../data_collect.dart';

class AgeCollectBody extends StatelessWidget {
  const AgeCollectBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AppText(
              "What's your age?",
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20.h),

            // Age Range Options
            Expanded(
              child: _buildAgeOptions(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgeOptions(BuildContext context, DataCollectState state) {
    final cubit = context.read<DataCollectCubit>();

    return Column(
      children: [
        AgeOption(
          title: '17 or younger',
          value: '17_or_younger',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        AgeOption(
          title: '18-24',
          value: '18-24',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        AgeOption(
          title: '25-34',
          value: '25-34',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        AgeOption(
          title: '35-44',
          value: '35-44',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        AgeOption(
          title: '45 or older',
          value: '45_or_older',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
      ],
    );
  }
}
