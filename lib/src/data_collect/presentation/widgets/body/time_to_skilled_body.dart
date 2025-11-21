part of '../../../data_collect.dart';

class TimeToSkilledBody extends StatelessWidget {
  const TimeToSkilledBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboarding.onboardingBeSkilledExpectTimeQuestion,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            Spacer(),

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
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedTimeToBecomeSkilled != current.selectedTimeToBecomeSkilled,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return Column(
          spacing: 12.h,
          children: state.onboardData.timeToBecomeSkilled
              .map(
                (timeOption) => SkilledTimeOption(
                  value: timeOption,
                  groupValue: state.selectedTimeToBecomeSkilled ?? OnboardOptionEntity(),
                  onChanged: (value) => cubit.selectTimeToBecomeSkilled(value ?? OnboardOptionEntity()),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class SkilledTimeOption extends StatelessWidget {
  final OnboardOptionEntity value;
  final OnboardOptionEntity groupValue;
  final Function(OnboardOptionEntity?) onChanged;

  const SkilledTimeOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
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
            // Emoji
            DCachedImage(url: value.icon, width: 24.w, height: 24.h),

            16.horizontalSpace,

            Expanded(
              child: AppText(
                value.label.text,
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
