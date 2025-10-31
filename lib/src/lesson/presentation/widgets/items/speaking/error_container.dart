part of '../../../../lesson.dart';

class ErrorContainer extends StatelessWidget {
  const ErrorContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select((SpeakingCubit cubit) => cubit.state);
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
          12.verticalSpace,
          Text(
            state.errorMessage ?? 'Microphone permission is required',
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          if (state.microphonePermission?.isPermanentlyDenied == true) ...[
            12.verticalSpace,
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
}