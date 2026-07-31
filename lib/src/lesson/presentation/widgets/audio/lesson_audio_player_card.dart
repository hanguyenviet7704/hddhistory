part of '../../../lesson.dart';

class LessonAudioPlayerCard extends StatelessWidget {
  const LessonAudioPlayerCard({
    super.key,
    required this.state,
    required this.controls,
    required this.onRetry,
  });

  final LessonAudioState state;
  final Widget controls;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LessonContentCard(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LessonAudioThumbnail(imageUrl: state.imageUrl),
              SizedBox(height: 32.h),
              AppText(
                state.title,
                style: AppStyle.textBold20.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
          if (state.hasFailure)
            Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: LessonAudioFailureCard(onRetry: onRetry),
            )
          else ...[
            Padding(
              padding: EdgeInsets.only(top: 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LessonAudioProgressBar(
                    progress: state.progressFraction,
                    // Tap/drag to scrub. Only interactive once a duration is
                    // known; the cubit seeks to fraction × total.
                    onSeek: state.durationSeconds > 0
                        ? (fraction) => context.read<LessonAudioCubit>().seekTo(
                              Duration(seconds: (fraction * state.durationSeconds).round()),
                            )
                        : null,
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    state.playbackLabel,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.75,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 56.h),
            Center(child: controls),
          ],
        ],
      ),
    );
  }
}
