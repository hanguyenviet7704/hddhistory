part of '../../../data_collect.dart';

class SummaryProgressBar extends StatelessWidget {
  final String title;
  final double progress;
  final Color progressColor;

  const SummaryProgressBar({
    super.key,
    required this.title,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title and percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              title,
              style: AppStyle.textBold16.copyWith(
                color: const Color(0xFF0D121C), // Text/Primary
                fontWeight: FontWeight.w500,
              ),
            ),
            AppText(
              '${(progress * 100).toInt()}%',
              style: AppStyle.textBold14.copyWith(
                color: const Color(0xFFAAB8CD), // Text/Quaternary
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // Progress bar
        Container(
          height: 11.h,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8EF), // Border/Default
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 11.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8EF), // Border/Default
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 11.h,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
