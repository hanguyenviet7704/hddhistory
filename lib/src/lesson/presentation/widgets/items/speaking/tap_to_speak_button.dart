part of '../../../../lesson.dart';

/// Tap to Speak Button
/// Displays a prominent button that triggers voice recording when tapped
class TapToSpeakButton extends StatelessWidget {
  const TapToSpeakButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(context.read<SpeakingCubit>().startRecordingSession());
      },
      child: Container(
        width: 80.w,
        height: 80.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF554FF0),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          AppAsset.svg.app.icMic,
          height: 28.w,
        ),
      ),
    );
  }
}
