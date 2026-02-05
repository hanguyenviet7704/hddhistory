part of '../../../../lesson.dart';

class SpeakingBottomAction extends StatelessWidget {
  const SpeakingBottomAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeakingCubit, SpeakingState>(
      builder: (context, state) {
        // Show error message if permission is denied or restricted
        final permission = state.microphonePermission;
        if (permission != null && (permission.isDenied || permission.isPermanentlyDenied || permission.isRestricted)) {
          return ErrorContainer();
        }

        return BlocSelector<LessonCubit, LessonState, bool>(
          selector: (state) => state.isShowResultOverlay,
          builder: (context, isShowResultOverlay) {
            if (isShowResultOverlay) {
              return const SizedBox.shrink();
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
              child: BottomInputContent(),
            );
          },
        );
      },
    );
  }
}
