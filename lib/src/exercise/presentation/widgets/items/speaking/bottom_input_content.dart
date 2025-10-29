part of '../../../../exercise.dart';

class BottomInputContent extends StatelessWidget {
  const BottomInputContent({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select((SpeakingCubit cubit) => cubit.state);
    if (state.inputMode == SpeakingInputMode.text) {
      return TextInputMode();
    }

    // Recording mode - idle state
    if (state.recordingState == SpeakingRecordingState.idle) {
      return IdleRecordingMode();
    }

    // Recording mode - active/stopped/playing state
    return ActiveRecordingMode();
  }
}