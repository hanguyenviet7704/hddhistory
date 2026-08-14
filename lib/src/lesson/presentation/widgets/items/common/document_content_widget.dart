part of '../../../../lesson.dart';

/// Which typographic role a run of CMS copy is playing.
///
/// Sizes come straight from the design's quiz cards (`_Keypoint Swipe Lab`):
/// intro copy 14.5/w500/1.65, stem 15.5/w800/1.4 — both a step SMALLER than
/// theory prose, so a question reads as a compact task, not as more reading.
/// (First unified TO theory sizes on 2026-08-13, which fixed the shouting
/// 17-19px stems but overshot: next to the design the cards still read too
/// large — "trông vẫn khác design lắm".) What differs beyond size is the
/// reading machinery: the Text-display sheet's font family and scale apply
/// ONLY to theory — a question's copy stays fixed so its options and slots
/// keep their measured layout.
enum DocumentProse { theory, question }

class DocumentContentWidget extends StatelessWidget {
  final String content;
  final ContentDocumentType type;
  final DocumentProse prose;

  const DocumentContentWidget({
    super.key,
    required this.content,
    required this.type,
    this.prose = DocumentProse.theory,
  });

  @override
  Widget build(BuildContext context) {
    // Reading font scale/family (Keypoint "Text display" sheet) applies ONLY
    // to the theory title/body copy — never to a question stem, captions/chips
    // or any chrome.
    final display = context.watch<KeypointDisplayCubit>().state;
    final isQuestion = prose == DocumentProse.question;

    return switch (type) {
      ContentDocumentType.title => _buildProse(
        maxLines: 5,
        display: display,
        scalable: !isQuestion,
        style: AppStyle.textBold18.copyWith(
          fontSize: isQuestion ? 15.5.sp : null,
          fontWeight: isQuestion ? FontWeight.w800 : null,
          height: isQuestion ? 1.4 : null,
          color: AppCustomColor.textPrimary,
          fontFamily: isQuestion ? null : display.fontFamilyName,
          fontFamilyFallback: isQuestion ? null : display.fontFamilyFallback,
        ),
      ),
      ContentDocumentType.text => _buildProse(
        maxLines: 50,
        display: display,
        scalable: !isQuestion,
        style: isQuestion
            // Design quiz intro copy: `c.text` 14.5/w500/1.65.
            ? AppStyle.text14.copyWith(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w500,
                height: 1.65,
                color: AppCustomColor.kpBodyText,
              )
            // Design body copy: 16px at rest, medium weight, generous leading —
            // the reader scales it from here with the Text sheet.
            : AppStyle.text16.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.75,
                color: AppCustomColor.kpBodyText,
                fontFamily: display.fontFamilyName,
                fontFamilyFallback: display.fontFamilyFallback,
              ),
      ),
      ContentDocumentType.caption => _ChoiceDocumentTypeTag(label: content),
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
    required bool scalable,
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
      textScaler: scalable ? TextScaler.linear(display.fontScale) : TextScaler.noScaling,
    );
  }
}

class _ChoiceDocumentTypeTag extends StatelessWidget {
  final String label;

  const _ChoiceDocumentTypeTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          color: AppCustomColor.brandPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
