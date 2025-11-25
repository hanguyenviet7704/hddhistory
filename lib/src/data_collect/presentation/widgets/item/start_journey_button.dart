part of '../../../data_collect.dart';

class StartJourneyButton extends StatelessWidget {
  const StartJourneyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: const Color(0xFF554FF0),
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppDI.injector.get<HomeCubit>().initializeData();
            AppDI.injector.get<UserCubit>().setIsFirstTime(false);
            RegisterRoute().go(context);
          },
          borderRadius: BorderRadius.circular(1000.r),
          child: Center(
            child: AppText(
              context.text.onboarding.onboardingStartJourneyButton,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
