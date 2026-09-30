part of '../../../../lesson.dart';

// Text Input Mode: Microphone button + Text input area
class TextInputMode extends StatelessWidget {
  const TextInputMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Microphone toggle button
        ModeToggleButton(
          svgIcon: AppAsset.svg.app.icMic,
          backgroundColor: const Color(0xFFFDF8EA),
          iconColor: const Color(0xFFB5860F),
          iconSize: 18,
          onTap: () => context.read<SpeakingCubit>().toggleInputMode(),
        ),
        12.horizontalSpace,
        // Text input area
        const Expanded(
          child: TextInputArea(),
        ),
      ],
    );
  }
}
