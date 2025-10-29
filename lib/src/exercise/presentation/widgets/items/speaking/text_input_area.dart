part of '../../../../exercise.dart';

/// Text Input Area
/// Provides a text field for typing answers with character counter and send button
class TextInputArea extends StatefulWidget {
  const TextInputArea({super.key});

  @override
  State<TextInputArea> createState() => _TextInputAreaState();
}

class _TextInputAreaState extends State<TextInputArea> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SpeakingCubit>().state;
    final maxChars = state.question.maxCharacter;
    final currentChars = state.characterCount;

    // Update controller text if state changes
    if (_controller.text != state.textInput) {
      _controller.text = state.textInput;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: 80.h, maxHeight: 120.h),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 12.w,
        top: 12.h,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE3E8EF),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input field
          Flexible(
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF364152),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your answer...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (text) {
                context.read<SpeakingCubit>().updateTextInput(text);
              },
            ),
          ),
          SizedBox(height: 8.h),
          // Bottom row: character counter + send button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Character counter
              Text(
                '$currentChars/$maxChars chars',
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFFAAB8CD),
                ),
              ),
              // Send button
              GestureDetector(
                onTap: currentChars > 0
                    ? () => context.read<SpeakingCubit>().submitAnswer()
                    : null,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: currentChars > 0
                        ? const Color(0xFF554FF0)
                        : const Color(0xFF554FF0).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: pi / 2,
                    child: Icon(
                      Icons.arrow_back,
                      size: 16.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
