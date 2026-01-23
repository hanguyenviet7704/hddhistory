part of '../../../../lesson.dart';

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

  void _onTap(int currentChars) {
    if (currentChars <= 0) return;
    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType == LearningItemType.roleplay) {
      final trackingData = RoleplayTrackingData.fromContext();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayQuizRecordTyping(
          trackingData,
          typingInteraction: 'send',
        );
      }
    } else {
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointExerciseRecordTyping(
          trackingData,
          typingInteraction: 'send',
        );
      }
    }
    context.read<SpeakingCubit>().submitAnswer();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 80.h, maxHeight: 150.h),
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
            child: TextFormField(
              controller: _controller,
              maxLines: null,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF364152),
              ),
              maxLength: context.read<SpeakingCubit>().state.question.maxCharacter,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: context.text.lesson.typeYourAnswerHint,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
                counter: null,
              ),
              onChanged: (text) {
                context.read<SpeakingCubit>().updateTextInput(text);
              },
            ),
          ),
          4.verticalSpace,
          // Bottom row: character counter + send button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Character counter
              BlocBuilder<SpeakingCubit, SpeakingState>(
                buildWhen: (previous, current) => previous.currentChars != current.currentChars || previous.maxChars != current.maxChars,
                builder: (context, state) {
                  return AppText(
                    context.text.lesson.charCounter(
                      currentChars: state.currentChars.toString(),
                      maxChars: state.maxChars.toString(),
                    ),
                    style: AppStyle.text12.copyWith(
                      color: const Color(0xFFAAB8CD),
                    ),
                  );
                },
              ),
              // Send button
              BlocSelector<SpeakingCubit, SpeakingState, int>(
                selector: (state) => state.currentChars,
                builder: (context, currentChars) {
                  return GestureDetector(
                    onTap: () => _onTap(currentChars),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: currentChars > 0 ? const Color(0xFF554FF0) : const Color(0xFF554FF0).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 16.w,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
