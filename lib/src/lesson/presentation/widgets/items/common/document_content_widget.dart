part of '../../../../lesson.dart';

class DocumentContentWidget extends StatelessWidget {
  final String content;
  final ContentDocumentType type;
  const DocumentContentWidget({
    super.key,
    required this.content,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Reading font scale/family (Keypoint "Text display" sheet) applies ONLY
    // to the theory title/body copy — never to captions/chips or any chrome.
    final display = context.watch<KeypointDisplayCubit>().state;

    return switch (type) {
      ContentDocumentType.title => AppText(
          content,
          maxLines: 5,
          textScaleFactor: display.fontScale,
          style: AppStyle.textBold18.copyWith(
            color: const Color(0xFF0D121C),
            fontFamily: display.fontFamilyName,
            fontFamilyFallback: display.fontFamilyFallback,
          ),
        ),
      ContentDocumentType.text => AppText(
          content,
          maxLines: 50,
          textScaleFactor: display.fontScale,
          style: AppStyle.text18.copyWith(
            color: const Color(0xFF364152),
            fontFamily: display.fontFamilyName,
            fontFamilyFallback: display.fontFamilyFallback,
          ),
        ),
      ContentDocumentType.caption => _ChoiceDocumentTypeTag(label: content, accentColor: const Color(0xFFEBEAFD)),
      _ => const SizedBox.shrink(),
    };
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
