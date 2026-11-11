part of '../../../../lesson.dart';

class DocumentMediaWidget extends StatelessWidget {
  final String url;
  final ContentDocumentType type;

  /// Theory illustrations are pinned to the design's fixed 200pt band so every
  /// card in the swipe deck has the same rhythm regardless of the artwork's
  /// aspect ratio. Question/roleplay images keep their intrinsic height.
  final DocumentProse prose;

  /// Photo credit shown beneath an illustration, e.g.
  /// `Ảnh: <tác giả> / CC BY-SA — Wikimedia Commons`.
  ///
  /// Not decoration: CC BY and CC BY-SA oblige us to name the author and the
  /// licence wherever the image is shown, so this line is what makes those
  /// images legal to use at all. Empty for public-domain artwork that carries
  /// no such condition, and the row then collapses.
  final String credit;

  const DocumentMediaWidget({
    super.key,
    required this.url,
    required this.type,
    this.prose = DocumentProse.theory,
    this.credit = '',
  });

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ContentDocumentType.image => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CacheNetworkGraphic(
            url: url,
            width: double.infinity,
            height: prose == DocumentProse.theory ? 200.h : null,
            borderRadius: BorderRadius.circular(16.r),
            fit: BoxFit.cover,
          ),
          if (credit.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: AppText(
                credit,
                maxLines: 2,
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      ContentDocumentType.audio => AudioPlayerUrlWidget(audioUrl: url),
      _ => const SizedBox.shrink(),
    };
  }
}
