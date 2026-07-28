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
      ContentDocumentType.title => _buildProse(
        maxLines: 5,
        display: display,
        style: AppStyle.textBold18.copyWith(
          color: const Color(0xFF0D121C),
          fontFamily: display.fontFamilyName,
          fontFamilyFallback: display.fontFamilyFallback,
        ),
      ),
      ContentDocumentType.text => _buildProse(
        maxLines: 50,
        display: display,
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

  /// Renders the copy with its authored emphasis. The CMS ships `<b>`, `<i>`,
  /// `<br>` and HTML entities; a plain `Text` leaked those tags verbatim.
  ///
  /// No reading highlight: narration follows the CARD (swiping to a page reads
  /// that page), and tinting the sentence being spoken on top of that was noise
  /// rather than help.
  Widget _buildProse({
    required int maxLines,
    required KeypointDisplayState display,
    required TextStyle style,
  }) {
    final runs = KeypointRichText.runs(content);

    return Text.rich(
      TextSpan(
        children: [
          for (final run in runs)
            TextSpan(
              text: run.text,
              style: style.copyWith(
                fontWeight: run.bold ? FontWeight.w700 : null,
                fontStyle: run.italic ? FontStyle.italic : null,
              ),
            ),
        ],
      ),
      maxLines: maxLines,
      textScaler: TextScaler.linear(display.fontScale),
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
