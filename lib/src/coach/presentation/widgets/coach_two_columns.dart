part of '../../coach.dart';

/// ⑦ — the two-column draft.
///
/// Every line on the left came out of the reader's own telling; the server
/// throws away anything the model invented before this ever renders. Tapping
/// moves a line across, and the sentence they then write is the only thing that
/// gets stored — which is the whole reason the lines have to be theirs.
///
/// The right column is tinted and its heading takes the accent colour: it is
/// the destination, and the design makes that legible before anyone reads a
/// word of the labels.
class CoachTwoColumns extends StatelessWidget {
  final List<String> left;
  final List<String> right;
  final void Function(String text, bool toRight) onMove;

  const CoachTwoColumns({
    super.key,
    required this.left,
    required this.right,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Column(
                  title: context.l10n.coach.twoColsLeftTitle,
                  titleColor: CoachStyle.textMuted,
                  lines: left,
                  onTap: (text) => onMove(text, true),
                  highlighted: false,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _Column(
                  title: context.l10n.coach.twoColsRightTitle,
                  titleColor: CoachStyle.skin,
                  lines: right,
                  onTap: (text) => onMove(text, false),
                  highlighted: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 11.h),
        Text(
          context.l10n.coach.twoColsHint,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: CoachStyle.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<String> lines;
  final ValueChanged<String> onTap;
  final bool highlighted;

  const _Column({
    required this.title,
    required this.titleColor,
    required this.lines,
    required this.onTap,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: CoachStyle.sectionLabel(color: titleColor, size: 10.5),
        ),
        SizedBox(height: 6.h),
        if (lines.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              context.l10n.coach.twoColsEmpty,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: CoachStyle.textMuted,
              ),
            ),
          )
        else
          ...lines.map(
            (line) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: GestureDetector(
                onTap: () => onTap(line),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: highlighted ? CoachStyle.selectedBackground : CoachStyle.chipBackground,
                    border: Border.all(
                      color: highlighted ? CoachStyle.selectedBorderSoft : CoachStyle.border,
                    ),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                      height: 1.4,
                      color: highlighted ? CoachStyle.selectedText : CoachStyle.textBody,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
