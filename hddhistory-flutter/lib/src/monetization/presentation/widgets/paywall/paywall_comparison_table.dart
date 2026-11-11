part of '../../../monetization.dart';

/// The Free-vs-Premium table (design `6b · Premium` → Version 2).
///
/// Replaces the benefit list rather than joining it: the two say the same thing,
/// and the design gates them on mutually exclusive branches. Which one renders is
/// [PaywallConfigEntity.bodyVariant], config-driven so the choice can be changed
/// without an app release.
///
/// Position matters and is not arbitrary. The benefit list sits ABOVE the plans
/// ("know what you get before a price means anything"); this table sits BELOW
/// them, because it argues a different case — the reader has seen the price and
/// is now being shown what the free tier costs them.
///
/// The three column labels and the heading are slang keys, not config: they are
/// fixed chrome in all five locales. Only the ROWS come from the admin panel,
/// where each locale writes its own prose.
class PaywallComparisonTable extends StatelessWidget {
  final List<PaywallComparisonRowEntity> rows;

  const PaywallComparisonTable({super.key, required this.rows});

  /// Column widths, adapted from the design's `74px 1fr 1.15fr`.
  ///
  /// The benefit column is FIXED while the two value columns flex: the labels
  /// are short nouns ("Lessons", "Habits") and letting them flex would steal
  /// width from the values, which are the part that carries the argument.
  /// Premium is the widest because its cell also holds the tick.
  ///
  /// The ratios are NOT the design's verbatim, and that is deliberate. Inside
  /// this screen's 24 page padding and the card's 16, the design's own numbers
  /// leave ~97 for the Premium text after the tick — and "Không giới hạn", the
  /// design's OWN content, needs ~100 in this app's font. It fits in the mock
  /// because that was drawn in Mulish, which is narrower at the same size. So
  /// the design's numbers would break the design's own layout here: every
  /// Premium cell wraps to two lines and the rows go ragged.
  ///
  /// Trimmed from the label column and shifted toward Premium rather than
  /// shrinking the type: the values are what the reader compares, and 12.5 is
  /// already the smallest size on this screen.
  static const double _labelWidth = 68;
  static const int _freeFlex = 100;
  static const int _premiumFlex = 140;

  /// The design's tick, verbatim — white on a filled `#5A52F0` disc. Inlined as
  /// a string for the same reason `_PaywallBenefitRow` does it: the mark's weight
  /// (4.5 stroke in a 16px circle) is its whole character, and a Material glyph
  /// at this size reads as a different symbol.
  static const String _checkSvg =
      '''<svg width="9" height="9" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 13l4.5 4.5L19 7" stroke="#fff" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  @override
  Widget build(BuildContext context) {
    // A row with nothing in any cell is dropped rather than rendered as a blank
    // line: the admin adds a row before typing into it, and a half-filled draft
    // must not become an empty stripe in the table.
    final visibleRows = rows.where((row) => row.label.text.trim().isNotEmpty || row.free.text.trim().isNotEmpty || row.premium.text.trim().isNotEmpty).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        26.verticalSpace,
        AppText(
          context.l10n.monetization.paywallCompareTitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppStyle.text16.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppCustomColor.textBrand,
            height: 1.25,
          ),
        ),
        14.verticalSpace,
        Container(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 18.h, bottom: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A513C07), // rgba(17,7,81,.10)
                offset: Offset(0, 12.h),
                blurRadius: 30.r,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              // Every row keeps its divider, including the last — the design's
              // card has 8 of bottom padding after that final line rather than
              // dropping it.
              for (final row in visibleRows) _Row(row: row, checkSvg: _checkSvg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final l10n = context.l10n.monetization;

    return Container(
      padding: EdgeInsets.only(bottom: 11.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFAF6EC))),
      ),
      child: Row(
        // `end`, not `center`: the three labels have different sizes and the
        // design sits them on one baseline at the bottom of the header.
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: _labelWidth.w,
            child: AppText(
              l10n.paywallCompareBenefit,
              style: AppStyle.text14.copyWith(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: AppCustomColor.textBrand,
                height: 1.2,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: _freeFlex,
            child: AppText(
              l10n.paywallCompareFree,
              style: AppStyle.text12.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7E6F4B),
                height: 1.2,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: _premiumFlex,
            child: AppText(
              l10n.paywallComparePremium,
              style: AppStyle.text12.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94762A),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final PaywallComparisonRowEntity row;
  final String checkSvg;

  const _Row({required this.row, required this.checkSvg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFCF9F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: PaywallComparisonTable._labelWidth.w,
            child: AppText(
              row.label.text,
              maxLines: 3,
              style: AppStyle.text12.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textBrand,
                height: 1.3,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: PaywallComparisonTable._freeFlex,
            child: AppText(
              row.free.text,
              maxLines: 3,
              style: AppStyle.text12.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B8698),
                height: 1.3,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: PaywallComparisonTable._premiumFlex,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.hasCheck) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB88810),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.string(checkSvg, width: 9.w, height: 9.w),
                    ),
                  ),
                  5.horizontalSpace,
                ],
                Expanded(
                  child: AppText(
                    row.premium.text,
                    maxLines: 3,
                    style: AppStyle.text12.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF94762A),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
