part of '../../../../exercise.dart';

class ChoiceDocumentItem extends StatelessWidget {
  final ExerciseDocumentEntity document;

  const ChoiceDocumentItem({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: ShapeDecoration(
        color: AppColorLight.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2.w,
            color: const Color(0xFFE3E8EF),
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.isNotEmpty) ...[
            AppText(
              data.title,
              maxLines: 5,
              style: AppStyle.textBold14.copyWith(
                color: const Color(0xFF0D121C),
              ),
            ),
            4.horizontalSpace,
          ],
          if (data.content.isNotEmpty) ...[
            AppText(
              data.content,
              maxLines: 50,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF364152),
              ),
            ),
          ],
          _ChoiceDocumentTypeTag(
            label: 'Client',
            accentColor: const Color(0xFFEBEAFD),
          ),
          if (data.thumbnail.isNotEmpty) ...[
            DCachedImage(
              url: data.thumbnail,
              width: double.infinity,
              borderRadius: BorderRadius.circular(16.r),
              fit: BoxFit.cover,
            ),
            16.verticalSpace,
          ],
          // AudioPlayerWidget(audioUrl: data.url),
          AudioPlayerWidget(audioUrl: 'https://file-examples.com/storage/fe47641ea668fe3d898fdf3/2017/11/file_example_MP3_1MG.mp3'),
        ],
      ),
    );
  }
}

class _ChoiceDocumentPreview extends StatelessWidget {
  final ExerciseDocumentEntity document;

  const _ChoiceDocumentPreview({required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data;
    switch (document.type) {
      case ExerciseDocumentType.image:
        return _MediaPreviewFrame(
          child: DCachedImage(
            url: _resolveImageUrl(data),
            fit: BoxFit.cover,
          ),
        );
      case ExerciseDocumentType.video:
        return _MediaPreviewFrame(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DCachedImage(
                url: _resolveImageUrl(data),
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _withOpacity(Colors.black, 0.15),
                        _withOpacity(Colors.black, 0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: _withOpacity(Colors.white, 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _withOpacity(Colors.black, 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28.w,
                    color: const Color(0xFF0D121C),
                  ),
                ),
              ),
            ],
          ),
        );
      case ExerciseDocumentType.audio:
        return _AudioPreviewCard(
          accentColor: document.type.accentColor,
          audioUrl: data.url,
          title: data.title,
          description: data.content,
        );
      case ExerciseDocumentType.text:
        return _TextPreviewCard(
          title: data.title,
          content: data.content,
          accentColor: document.type.accentColor,
        );
    }
  }

  String _resolveImageUrl(DocumentDataEntity data) {
    return data.thumbnail.isNotEmpty ? data.thumbnail : data.url;
  }
}

class _ChoiceDocumentCaption extends StatelessWidget {
  final String caption;

  const _ChoiceDocumentCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    return AppText(
      caption,
      maxLines: 3,
      style: AppStyle.text13.copyWith(
        color: const Color(0xFF4C5968),
        height: 1.5,
      ),
    );
  }
}

class _MediaPreviewFrame extends StatelessWidget {
  final Widget child;

  const _MediaPreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: child,
      ),
    );
  }
}

class _AudioPreviewCard extends StatelessWidget {
  final Color accentColor;
  final String audioUrl;
  final String title;
  final String description;

  const _AudioPreviewCard({
    required this.accentColor,
    required this.audioUrl,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _withOpacity(accentColor, 0.2), width: 1.5.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.h,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _withOpacity(accentColor, 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: accentColor,
                  size: 22.w,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4.h,
                  children: [
                    if (title.trim().isNotEmpty)
                      AppText(
                        title,
                        maxLines: 1,
                        style: AppStyle.text14.copyWith(
                          color: const Color(0xFF1F2933),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (description.trim().isNotEmpty)
                      AppText(
                        description,
                        maxLines: 2,
                        style: AppStyle.text12.copyWith(
                          color: const Color(0xFF7F8EA4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AudioPlayerWidget(audioUrl: audioUrl),
        ],
      ),
    );
  }
}

class _TextPreviewCard extends StatelessWidget {
  final String title;
  final String content;
  final Color accentColor;

  const _TextPreviewCard({
    required this.title,
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;
    final hasContent = content.trim().isNotEmpty;

    if (!hasTitle && !hasContent) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _withOpacity(accentColor, 0.16), width: 1.5.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.h,
        children: [
          if (hasTitle)
            AppText(
              title,
              maxLines: 2,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2933),
                height: 1.4,
              ),
            ),
          if (hasContent)
            AppText(
              content,
              maxLines: 6,
              style: AppStyle.text13.copyWith(
                color: const Color(0xFF4C5968),
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceDocumentTypeTag extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _ChoiceDocumentTypeTag({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      margin: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Color(0xFFEBEAFD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          color: Color(0xFF554FF0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _withOpacity(Color color, double opacity) {
  final num clamped = opacity.clamp(0.0, 1.0);
  return color.withAlpha((clamped * 255).round());
}

extension _ExerciseDocumentTypeX on ExerciseDocumentType {
  String get displayName {
    switch (this) {
      case ExerciseDocumentType.image:
        return 'Image';
      case ExerciseDocumentType.video:
        return 'Video';
      case ExerciseDocumentType.audio:
        return 'Audio';
      case ExerciseDocumentType.text:
        return 'Text';
    }
  }

  String get defaultTitle {
    switch (this) {
      case ExerciseDocumentType.image:
        return 'Illustration';
      case ExerciseDocumentType.video:
        return 'Video Reference';
      case ExerciseDocumentType.audio:
        return 'Audio Reference';
      case ExerciseDocumentType.text:
        return 'Supporting Text';
    }
  }

  IconData get iconData {
    switch (this) {
      case ExerciseDocumentType.image:
        return Icons.image_rounded;
      case ExerciseDocumentType.video:
        return Icons.videocam_rounded;
      case ExerciseDocumentType.audio:
        return Icons.library_music_rounded;
      case ExerciseDocumentType.text:
        return Icons.description_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case ExerciseDocumentType.image:
        return const Color(0xFF3F83F8);
      case ExerciseDocumentType.video:
        return const Color(0xFFF59E0B);
      case ExerciseDocumentType.audio:
        return const Color(0xFF10B981);
      case ExerciseDocumentType.text:
        return const Color(0xFF6366F1);
    }
  }
}
