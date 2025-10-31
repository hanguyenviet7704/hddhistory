part of '../../../../lesson.dart';

// Active Recording Mode: Cancel + Recording controls + Send
class ActiveRecordingMode extends StatelessWidget {
  const ActiveRecordingMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        ModeToggleButton(
          svgIcon: AppAsset.svg.app.icClose,
          backgroundColor: const Color(0xFFEEF2F6),
          iconColor: const Color(0xFF7F8EA4),
          iconSize: 24,
          padding: 8,
          onTap: () => context.read<SpeakingCubit>().cancelRecording(),
        ),
        16.horizontalSpace,
        // Recording controls area
        const Expanded(
          child: RecordingControlsArea(),
        ),
      ],
    );
  }
}
