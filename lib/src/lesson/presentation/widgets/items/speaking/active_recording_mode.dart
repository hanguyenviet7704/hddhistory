part of '../../../../lesson.dart';

// Active Recording Mode: Cancel + Recording controls + Send
class ActiveRecordingMode extends StatelessWidget {
  const ActiveRecordingMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocSelector<SpeakingCubit, SpeakingState, ({bool isRecording, Duration duration})>(
          selector: (state) => (isRecording: state.recordingState == SpeakingRecordingState.recording, duration: state.recordingDuration),
          builder: (context, data) {
            return AppText(
              data.duration.formatDuration,
              style: AppStyle.textBold16.copyWith(color: data.isRecording ? const Color(0xFF554FF0) : const Color(0xFFAAB7CC)),
            );
          },
        ),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cancel button
            ModeToggleButton(
              svgIcon: AppAsset.svg.app.icClose,
              backgroundColor: const Color(0xFFEEF2F6),
              iconColor: const Color(0xFF7F8EA4),
              iconSize: 24,
              padding: 12,
              onTap: () => context.read<SpeakingCubit>().cancelRecording(),
            ),
            // Recording controls area
            RecordingControlsArea(),
            GestureDetector(
              onTap: () {
                // if (state.isRecording) {
                //   context.read<SpeakingCubit>().stopRecording();
                //   return;
                // }

                final state = context.read<SpeakingCubit>().state;
                final canSubmit = state.audioFilePath != null;
                if (!canSubmit) return;
                context.read<SpeakingCubit>().submitAnswer();
              },
              child: Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF554FF0),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppAsset.svg.app.icSend,
                  width: 24.w,
                  height: 24.w,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
