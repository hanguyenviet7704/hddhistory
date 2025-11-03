part of '../../../../lesson.dart';

// Idle Recording Mode: Keyboard button + "Tap to speak" button
class IdleRecordingMode extends StatelessWidget {
  const IdleRecordingMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Keyboard toggle button
        ModeToggleButton(
          svgIcon: AppAsset.svg.app.icKeyboard,
          backgroundColor: const Color(0xFFEEF2F6),
          iconColor: const Color(0xFF7F8EA4),
          onTap: () => context.read<SpeakingCubit>().toggleInputMode(),
        ),
        // Tap to speak button
        TapToSpeakButton(),
        ModeToggleButton(
          svgIcon: AppAsset.svg.app.icKeyboard,
          backgroundColor: Colors.transparent,
          iconColor: Colors.transparent,
          onTap: () {},
        ),
      ],
    );
  }
}
