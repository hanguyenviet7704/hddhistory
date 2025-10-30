part of '../../../../exercise.dart';

class TheoryProgressBar extends StatelessWidget {
  const TheoryProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10.w,
      children: [
        10.horizontalSpace,
        InkWell(
          onTap: () => context.read<TheoryCubit>().previousDocument(),
          child: Icon(
            Icons.close_rounded,
            color: const Color(0xFF0D121C), // Brand/Brand/Primary/300
            size: 20.sp,
          ),
        ),
        Expanded(
          child: BlocSelector<TheoryCubit, TheoryState, double>(
            selector: (state) => state.progress,
            builder: (context, progress) {
              return Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: LinearPercentIndicator(
                  width: 1.sw - 100.w,
                  animation: true,
                  animationDuration: 500,
                  animateFromLastPercent: true,
                  lineHeight: 10.h,
                  percent: progress,
                  backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                  progressColor: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                  barRadius: Radius.circular(30.r),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
