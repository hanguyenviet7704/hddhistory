part of '../../../../exercise.dart';

// Idle Recording Mode: Keyboard button + "Tap to speak" button
class IdleRecordingMode extends StatelessWidget {
  const IdleRecordingMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Keyboard toggle button
        ModeToggleButton(
          icon: Icons.keyboard,
          backgroundColor: const Color(0xFFEEF2F6),
          iconColor: const Color(0xFF7F8EA4),
          onTap: () => context.read<SpeakingCubit>().toggleInputMode(),
        ),
        SizedBox(width: 16.w),
        // Tap to speak button
        const Expanded(
          child: TapToSpeakButton(),
        ),
      ],
    );
  }
}
