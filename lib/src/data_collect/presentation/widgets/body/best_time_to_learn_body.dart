part of '../../../data_collect.dart';

class BestTimeToLearnBody extends StatelessWidget {
  const BestTimeToLearnBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboardingTimeStudyQuestion,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            4.verticalSpace,

            // Subtitle
            AppText(
              context.text.onboardingTimeStudySubtitle,
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            Spacer(),

            // Time Options
            TimeOptions(),
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
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedBestTimeToLearn != current.selectedBestTimeToLearn,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          itemCount: state.onboardData.comfortableLearningTime.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final timeOption = state.onboardData.comfortableLearningTime[index];
            return TimeOption(
              value: timeOption,
              groupValue: state.selectedBestTimeToLearn ?? OnboardOptionEntity(),
              onChanged: (value) => cubit.selectBestTimeToLearn(value ?? OnboardOptionEntity()),
            );
          },
        );
      },
    );
  }
}

class TimeOption extends StatelessWidget {
  final OnboardOptionEntity value;
  final OnboardOptionEntity groupValue;
  final Function(OnboardOptionEntity?) onChanged;

  const TimeOption({
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
          color: value == groupValue ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
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

            // Title
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
