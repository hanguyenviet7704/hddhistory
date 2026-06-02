part of '../../../lesson.dart';

class LessonAudioThumbnail extends StatelessWidget {
  const LessonAudioThumbnail({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (imageUrl.trim().isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Opacity(
                opacity: 0.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: _LessonAudioImage(imageUrl: imageUrl),
                ),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: double.infinity,
            height: 281.h,
            child: imageUrl.trim().isEmpty ? const _LessonAudioThumbnailPlaceholder() : _LessonAudioImage(imageUrl: imageUrl),
          ),
        ),
      ],
    );
  }
}

class LessonAudioFailureCard extends StatelessWidget {
  const LessonAudioFailureCard({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.lesson.audioErrorTitle,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
          SizedBox(height: 4.h),
          AppText(
            context.l10n.lesson.audioErrorDescription,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
          ),
          SizedBox(height: 16.h),
          AppButton.secondary(
            onPressed: onRetry,
            fullWidthBtn: true,
            height: 48.h,
            borderRadius: BorderRadius.circular(12.r),
            decoration: BoxDecoration(
              color: AppCustomColor.neutral100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppText(
              context.l10n.lesson.audioRetry,
              style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      color: AppCustomColor.borderBrand,
      alignment: Alignment.center,
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AppAsset.svg.app.icMusicNote,
          width: 28.w,
          height: 28.w,
          colorFilter: const ColorFilter.mode(
            AppCustomColor.brandPrimary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
