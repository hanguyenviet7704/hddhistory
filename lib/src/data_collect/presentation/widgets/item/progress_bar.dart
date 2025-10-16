part of '../../../data_collect.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, double>(
      selector: (state) => state.currentStep.progress,
      builder: (context, progress) {
        return Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: LinearPercentIndicator(
            width: 1.sw - 40.w,
            animation: true,
            animationDuration: 500,
            animateFromLastPercent: true,
            lineHeight: 10.h,
            percent: progress,
            backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
            progressColor: const Color(0xFF917FF6), // Brand/Brand/Primary/300
            barRadius: Radius.circular(30.r),
            padding: EdgeInsets.zero,
          ),
        );
      },
    );
  }
}
