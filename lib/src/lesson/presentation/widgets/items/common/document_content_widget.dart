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
    return switch (type) {
      ContentDocumentType.title => AppText(content, maxLines: 5, style: AppStyle.textBold14.copyWith(color: const Color(0xFF0D121C))),
      ContentDocumentType.text => Column(
        children: [
          4.horizontalSpace,
          AppText(content, maxLines: 50, style: AppStyle.text14.copyWith(color: const Color(0xFF364152))),
        ],
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
    return Column(
      children: [
        16.verticalSpace,
        Container(
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
        ),
      ],
    );
  }
}
