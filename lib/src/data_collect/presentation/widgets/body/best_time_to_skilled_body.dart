part of '../../../data_collect.dart';

class BestTimeToSkilledBody extends StatelessWidget {
  const BestTimeToSkilledBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              "How much time do you want\nto become skilled?",
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            SizedBox(height: 20.h),

            // Time Options
            SkilledTimeOptions(),
          ],
        );
      },
    );
  }
}

class SkilledTimeOptions extends StatelessWidget {
  const SkilledTimeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, String?>(
      selector: (state) => state.selectedTimeToBecomeSkilled,
      builder: (context, selectedTime) {
        final cubit = context.read<DataCollectCubit>();

        final timeOptions = [
          "1 month",
          "2 months",
          "3 months",
        ];

        return Flexible(
          child: ListView.builder(
            itemCount: timeOptions.length,
            itemBuilder: (context, index) {
              final timeOption = timeOptions[index];
              final isSelected = selectedTime == timeOption;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: SkilledTimeOption(
                  title: timeOption,
                  isSelected: isSelected,
                  onChanged: (value) {
                    if (value) {
                      cubit.selectTimeToBecomeSkilled(timeOption);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SkilledTimeOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function(bool) onChanged;

  const SkilledTimeOption({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(true),
      child: Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
          border: Border.all(
            color: isSelected
                ? const Color(0xFF554FF0) // Brand/Primary
                : const Color(0xFFE3E8EF), // Border/Default
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            // Title
            Expanded(
              child: AppText(
                title,
                style: AppStyle.text16.copyWith(
                  color: isSelected
                      ? const Color(0xFF0D121C) // content/primary
                      : const Color(0xFF7F8EA4), // Text/Tertiary
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),

            // Radio button using CustomRadio
            CustomRadio(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}
