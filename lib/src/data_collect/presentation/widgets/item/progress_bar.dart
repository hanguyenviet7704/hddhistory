part of '../../../data_collect.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: LinearPercentIndicator(
        width: double.infinity,
        animation: true,
        animationDuration: 500,
        lineHeight: 10.h,
        percent: progress,
        backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
        progressColor: const Color(0xFF917FF6), // Brand/Brand/Primary/300
        barRadius: Radius.circular(30.r),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
