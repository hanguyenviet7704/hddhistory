part of '../../../../exercise.dart';

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
            Icon(
              Icons.mic,
              size: 24.w,
              color: const Color(0xFF554FF0),
            ),
            SizedBox(width: 10.w),
            Text(
              'Tap to speak',
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
