part of '../../../../exercise.dart';


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
          icon: Icons.mic,
          backgroundColor: const Color(0xFFEBEAFD),
          iconColor: const Color(0xFF554FF0),
          size: 40.w,
          onTap: () => context.read<SpeakingCubit>().toggleInputMode(),
        ),
        SizedBox(width: 12.w),
        // Text input area
        const Expanded(
          child: TextInputArea(),
        ),
      ],
    );
  }
}
