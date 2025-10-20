part of '../../../data_collect.dart';

class StartJourneyButton extends StatelessWidget {
  const StartJourneyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: AppButton.primary(
        onPressed: () {
          // Navigate to home or next screen
          // This would be implemented based on app navigation
          HomeRoute().go(context);
        },
        fullWidthBtn: true,
        height: 54.h,
        decoration: BoxDecoration(
          color: const Color(0xFF554FF0), // Brand/Primary
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: AppText(
          'Starts your journey!',
          style: AppStyle.textBold16.copyWith(
            color: Colors.white, // Text/White
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
