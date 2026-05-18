part of '../../../lesson.dart';

class LessonAudioSurface extends StatelessWidget {
  const LessonAudioSurface({
    super.key,
    required this.onOpenSpeedSheet,
  });

  final Future<void> Function() onOpenSpeedSheet;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonAudioCubit, LessonAudioState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LessonAudioThumbnail(imageUrl: state.imageUrl),
                    SizedBox(height: 24.h),
                    AppText(
                      state.title,
                      style: AppStyle.textBold20.copyWith(
                        color: const Color(0xFF0D121C),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    if (!state.hasFailure)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LessonAudioProgressBar(progress: state.progressFraction),
                          SizedBox(height: 8.h),
                          AppText(
                            state.playbackLabel,
                            style: AppStyle.text12.copyWith(
                              color: const Color(0xFF364152),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Center(
                            child: LessonAudioSpeedButton(
                              label: '${state.speedValueLabel} ${context.l10n.lesson.audioSpeedSuffix}',
                              enabled: !state.isLoading,
                              onTap: () async {
                                final trackingData = KeypointTrackingData.fromContext();
                                if (trackingData != null) {
                                  AppService.instance.appTrackingService.trackKeypointAudioSpeedOpen(trackingData);
                                }
                                await onOpenSpeedSheet();
                              },
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Center(
                            child: LessonAudioControls(
                              isPlaying: state.isPlaying,
                              isLoading: state.isLoading,
                              canSeekBackward: state.canSeekBackward,
                              canSeekForward: state.canSeekForward,
                              onSeekBackward: () => _handleSeek(context, const Duration(seconds: -10)),
                              onPlayPause: () => _handlePlayPause(context, state),
                              onSeekForward: () => _handleSeek(context, const Duration(seconds: 10)),
                            ),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: _LessonAudioFailureCard(
                          onRetry: () => context.read<LessonAudioCubit>().retry(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePlayPause(BuildContext context, LessonAudioState state) async {
    final trackingData = KeypointTrackingData.fromContext();
    final audioCubit = context.read<LessonAudioCubit>();

    if (state.isPlaying) {
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointAudioPauseClick(
          trackingData,
          audioPosition: state.positionSeconds,
        );
      }
      await audioCubit.pause();
      return;
    }

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPlayClick(trackingData);
    }
    await audioCubit.enterAudioMode();
  }

  Future<void> _handleSeek(BuildContext context, Duration delta) async {
    final state = context.read<LessonAudioCubit>().state;
    final trackingData = KeypointTrackingData.fromContext();
    final seekFrom = state.positionSeconds;
    final seekTo = (state.position + delta).inSeconds.clamp(0, state.durationSeconds);

    if (trackingData != null) {
      if (delta.isNegative) {
        AppService.instance.appTrackingService.trackKeypointAudioSeekBackClick(
          trackingData,
          seekFromSecond: seekFrom,
          seekToSecond: seekTo,
        );
      } else {
        AppService.instance.appTrackingService.trackKeypointAudioSeekForwardClick(
          trackingData,
          seekFromSecond: seekFrom,
          seekToSecond: seekTo,
        );
      }
    }

    await context.read<LessonAudioCubit>().seekBy(delta);
  }
}

class _LessonAudioThumbnail extends StatelessWidget {
  const _LessonAudioThumbnail({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: double.infinity,
        height: 281.h,
        child: imageUrl.trim().isEmpty ? const _LessonAudioThumbnailPlaceholder() : _LessonAudioImage(imageUrl: imageUrl),
      ),
    );
  }
}

class _LessonAudioImage extends StatelessWidget {
  const _LessonAudioImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _LessonAudioThumbnailPlaceholder(),
      );
    }

    if (imageUrl.startsWith('/')) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _LessonAudioThumbnailPlaceholder(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _LessonAudioThumbnailPlaceholder(),
    );
  }
}

class _LessonAudioThumbnailPlaceholder extends StatelessWidget {
  const _LessonAudioThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF2F6),
      alignment: Alignment.center,
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AppAsset.svg.app.icMusicNote,
          width: 28.w,
          height: 28.w,
          colorFilter: const ColorFilter.mode(
            Color(0xFF554FF0),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _LessonAudioFailureCard extends StatelessWidget {
  const _LessonAudioFailureCard({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE3E8EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.lesson.audioErrorTitle,
            style: AppStyle.textBold16.copyWith(
              color: const Color(0xFF0D121C),
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            context.l10n.lesson.audioErrorDescription,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
            ),
          ),
          SizedBox(height: 16.h),
          AppButton.secondary(
            onPressed: onRetry,
            fullWidthBtn: true,
            height: 48.h,
            borderRadius: BorderRadius.circular(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppText(
              context.l10n.lesson.audioRetry,
              style: AppStyle.textBold14.copyWith(
                color: const Color(0xFF0D121C),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
