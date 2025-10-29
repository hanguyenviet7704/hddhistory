part of '../../../../exercise.dart';

// Active Recording Mode: Cancel + Recording controls + Send
class ActiveRecordingMode extends StatelessWidget {
  const ActiveRecordingMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        ModeToggleButton(
          icon: Icons.close,
          backgroundColor: const Color(0xFFEEF2F6),
          iconColor: const Color(0xFF7F8EA4),
          size: 40.w,
          onTap: () => context.read<SpeakingCubit>().cancelRecording(),
        ),
        SizedBox(width: 16.w),
        // Recording controls area
        const Expanded(
          child: RecordingControlsArea(),
        ),
      ],
    );
  }
}
