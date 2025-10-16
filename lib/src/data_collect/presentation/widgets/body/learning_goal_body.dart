part of '../../../data_collect.dart';

class LearningGoalBody extends StatelessWidget {
  const LearningGoalBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              "Your daily learning goal",
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            SizedBox(height: 20.h),

            // Learning Goal Options
            LearningGoalOptions(),
          ],
        );
      },
    );
  }
}

class LearningGoalOptions extends StatelessWidget {
  const LearningGoalOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, String?>(
      selector: (state) => state.selectedDailyLearningGoal,
      builder: (context, selectedGoal) {
        final cubit = context.read<DataCollectCubit>();

        final goalOptions = [
          {"title": "5 min", "emoji": "📚"},
          {"title": "10 min", "emoji": "📖"},
          {"title": "15 min", "emoji": "📘"},
          {"title": "20 min", "emoji": "📗"},
        ];

        return Column(
          children: goalOptions.map((goalOption) {
            final title = goalOption["title"] as String;
            final emoji = goalOption["emoji"] as String;
            final isSelected = selectedGoal == title;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: LearningGoalOption(
                title: title,
                emoji: emoji,
                isSelected: isSelected,
                onChanged: (value) {
                  if (value) {
                    cubit.selectDailyLearningGoal(title);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class LearningGoalOption extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isSelected;
  final Function(bool) onChanged;

  const LearningGoalOption({
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
              decoration: BoxDecoration(
                color: const Color(0xFFC7C5FA), // Border/Brand
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: AppText(
                emoji,
                style: TextStyle(fontSize: 16.sp),
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
