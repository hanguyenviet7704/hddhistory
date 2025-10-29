part of '../../../../exercise.dart';

class SpeakingBottomAction extends StatelessWidget {
  const SpeakingBottomAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeakingCubit, SpeakingState>(
      builder: (context, state) {
        // Show error message if permission is denied or restricted
        final permission = state.microphonePermission;
        if (permission != null &&
            (permission.isDenied ||
             permission.isPermanentlyDenied ||
             permission.isRestricted)) {
          return _buildErrorContainer(context, state);
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildErrorContainer(BuildContext context, SpeakingState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off,
            size: 48.w,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(height: 12.h),
          Text(
            state.errorMessage ?? 'Microphone permission is required',
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          if (state.microphonePermission?.isPermanentlyDenied == true) ...[
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => openAppSettings(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF554FF0),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Open Settings',
                  style: AppStyle.textBold14.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SpeakingState state) {
    // Text input mode
    if (state.inputMode == SpeakingInputMode.text) {
      return _TextInputMode();
    }

    // Recording mode - idle state
    if (state.recordingState == SpeakingRecordingState.idle) {
      return _IdleRecordingMode();
    }

    // Recording mode - active/stopped/playing state
    return _ActiveRecordingMode();
  }
}

// Idle Recording Mode: Keyboard button + "Tap to speak" button
class _IdleRecordingMode extends StatelessWidget {
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

// Active Recording Mode: Cancel + Recording controls + Send
class _ActiveRecordingMode extends StatelessWidget {
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

// Text Input Mode: Microphone button + Text input area
class _TextInputMode extends StatelessWidget {
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
