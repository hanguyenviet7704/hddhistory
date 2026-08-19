part of '../../../monetization.dart';

/// One benefit line on the paywall.
///
/// Every row carries the SAME check mark rather than its own illustration. The
/// icons this used to render (`pw_lessons`, `pw_practice`, …) were 28px colour
/// drawings, one per row — at three rows they read as three unrelated pictures
/// and pulled the eye away from the words, which are the part that sells. A
/// repeated check turns the list back into a list: the reader scans the claims,
/// not the artwork.
///
/// The consequence to know about: `benefit.icon` from the paywall config is no
/// longer rendered here. Setting an icon in the admin panel changes nothing on
/// this screen.
class _PaywallBenefitRow extends StatelessWidget {
  final String text;

  const _PaywallBenefitRow({required this.text});

  /// The design's own check, verbatim (`6b · Premium` → benefits list).
  ///
  /// `Icons.check_rounded` was close enough to pass a glance and wrong in all
  /// three ways that matter at this size: a thinner stroke, a Material glyph whose
  /// arms sit at different angles, and the wrong ink (it was drawn in the heading
  /// navy `#110751` where the design uses brand purple). A 4-wide stroke is the
  /// whole character of this mark — it is the only bold thing in the column.
  static const String _checkSvg =
      '''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 13l4.5 4.5L19 7" stroke="#4B44CA" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22.w,
          height: 22.w,
          child: Center(
            child: SvgPicture.string(_checkSvg, width: 20.w, height: 20.w),
          ),
        ),
        // The design's row gap is 9, not the 14 this shipped with — at 14 the
        // checks read as a separate column instead of anchoring their line.
        9.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textBrand,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
