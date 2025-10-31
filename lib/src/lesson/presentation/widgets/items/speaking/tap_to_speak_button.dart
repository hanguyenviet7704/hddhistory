part of '../../../../lesson.dart';

/// Tap to Speak Button
/// Displays a prominent button that triggers voice recording when tapped
class TapToSpeakButton extends StatelessWidget {
  const TapToSpeakButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<SpeakingCubit>().startRecording();
      },
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEAFD),
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAsset.svg.app.icMic,
              height: 18.w,
            ),
            10.horizontalSpace,
            AppText(
              context.text.exerciseTapToSpeakButton,
              style: AppStyle.textBold16.copyWith(
                color: const Color(0xFF554FF0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
