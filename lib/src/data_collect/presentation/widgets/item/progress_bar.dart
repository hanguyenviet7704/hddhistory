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
        Widget child = Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: LinearPercentIndicator(
            width: 1.sw - (progress == 0 ? 40.w : 100.w),
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

        if (progress == 0) return child;
        return Row(
          spacing: 10.w,
          children: [
            10.horizontalSpace,
            InkWell(
              onTap: () {
                final step = context.read<DataCollectCubit>().state.currentStep;
                final trackingService = AppService.instance.appTrackingService;
                switch (step) {
                  case DataCollectStep.collectAge:
                    trackingService.trackObdAgeBack();
                    break;
                  case DataCollectStep.collectGender:
                    trackingService.trackObdGenderBack();
                    break;
                  case DataCollectStep.collectLearningGoal:
                    trackingService.trackObdLearningGoalBack();
                    break;
                  case DataCollectStep.collectSkillsetsWantToMaster:
                    trackingService.trackObdSkillsetBack();
                    break;
                  case DataCollectStep.collectLearningStrugger:
                    trackingService.trackObdStrugglesBack();
                    break;
                  case DataCollectStep.motivateHowToLearn:
                    trackingService.trackObdHowToLearnBack();
                    break;
                  case DataCollectStep.collectDailyLearningGoal:
                    trackingService.trackObdDailyTimeBack();
                    break;
                  case DataCollectStep.collectComfortableLearningTime:
                    trackingService.trackObdLearningTimeBack();
                    break;
                  case DataCollectStep.collectName:
                    break;
                }

                context.read<DataCollectCubit>().goToPreviousStep();
              },
              child: Icon(
                Icons.arrow_back_rounded,
                color: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                size: 20.sp,
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
