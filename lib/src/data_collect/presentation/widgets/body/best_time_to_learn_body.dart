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
              "What time of day is most comfortable for you to learn something new?",
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
              "Let's set up a learning routine!",
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            SizedBox(height: 20.h),

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
    return BlocSelector<DataCollectCubit, DataCollectState, String?>(
      selector: (state) => state.selectedBestTimeToLearn,
      builder: (context, selectedTime) {
        final cubit = context.read<DataCollectCubit>();

        final timeOptions = [
          {"title": "In the morning", "emoji": "🌅"},
          {"title": "Quick break", "emoji": "☕"},
          {"title": "Before bed", "emoji": "🌙"},
          {"title": "Any spare time", "emoji": "⏰"},
        ];

        return Flexible(
          child: ListView.builder(
            itemCount: timeOptions.length,
            itemBuilder: (context, index) {
              final timeOption = timeOptions[index];
              final title = timeOption["title"] as String;
              final emoji = timeOption["emoji"] as String;
              final isSelected = selectedTime == title;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: TimeOption(
                  title: title,
                  emoji: emoji,
                  isSelected: isSelected,
                  onChanged: (value) {
                    if (value) {
                      cubit.selectBestTimeToLearn(title);
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

class TimeOption extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isSelected;
  final Function(bool) onChanged;

  const TimeOption({
    super.key,
    required this.title,
    required this.emoji,
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
            // Emoji
            Container(
              width: 24.w,
              height: 24.h,
              alignment: Alignment.center,
              child: AppText(
                emoji,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),

            16.horizontalSpace,

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
