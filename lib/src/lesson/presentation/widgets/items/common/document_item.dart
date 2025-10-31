part of '../../../../lesson.dart';

class DocumentItem extends StatelessWidget {
  final ContentDocumentEntity document;

  const DocumentItem({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data;

    if (!document.dataAvailable) return const SizedBox.shrink();

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
          ],
          if (data.content.isNotEmpty) ...[
            4.horizontalSpace,
            AppText(
              data.content,
              maxLines: 50,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF364152),
              ),
            ),
          ],
          if (data.caption.isNotEmpty) ...[
            16.verticalSpace,
            _ChoiceDocumentTypeTag(
              label: document.data.caption,
              accentColor: const Color(0xFFEBEAFD),
            ),
          ],
          if (data.thumbnail.isNotEmpty) ...[
            16.verticalSpace,
            DCachedImage(
              url: data.thumbnail,
              width: double.infinity,
              borderRadius: BorderRadius.circular(16.r),
              fit: BoxFit.cover,
            ),
          ],
          if (document.type == ContentDocumentType.audio && data.url.isNotEmpty) ...[
            16.verticalSpace,
            AudioPlayerWidget(audioUrl: data.url),
          ],
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
