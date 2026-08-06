part of '../../home.dart';

/// The design's quote tint — brandPrimary at 13%. Readable on the stock white
/// page, where the design lives.
final Color _kQuoteTint = AppCustomColor.brandPrimary.withValues(alpha: 0.13);

/// Same card over a custom study background. The design's 13% tint is almost
/// transparent, and this card's ink is near-black italic text — on a dark photo
/// it stops being readable. So a custom background gets a denser lavender panel
/// instead of the tint: the design's look on the surface the design was drawn
/// for, a legible one everywhere else.
const Color _kQuoteBackgroundOnCustomBg = Color(0xFFDED7FD);

/// Small caps eyebrow above the quote.
const Color _kQuoteEyebrowColor = Color(0xFF7C74B0);

/// Quote ink — deeper than the app's textPrimary, per the design.
const Color _kQuoteInkColor = Color(0xFF211B40);

/// Design asset `quote-icon.svg` (double-quote glyph, brand lavender), inlined
/// so it needs no asset-bundle rebuild.
const String _kQuoteIconSvg =
    '''<svg width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg"><g opacity="0.9"><path opacity="0.9" d="M15.2815 13.9231V7H22.1533V8.79487C22.1533 11.5983 21.9482 13.6838 21.5379 15.0513C21.0935 16.453 19.9482 18.4359 18.102 21L15.179 19.359C16.7174 16.7265 17.6063 14.9145 17.8456 13.9231H15.2815ZM5.94819 13.9231V7H12.82V8.79487C12.82 11.5983 12.6149 13.6838 12.2046 15.0513C11.7602 16.453 10.6149 18.4359 8.7687 21L5.84563 19.359C7.38409 16.7265 8.27298 14.9145 8.51229 13.9231H5.94819Z" fill="#8E86F5"></path></g></svg>''';

/// "Motivation" card on Home — a quote-mark glyph over the quote text on a
/// single soft-lavender background (design node "Motivation").
class HomeQuoteCard extends StatelessWidget {
  const HomeQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, QuoteEntity?>(
      selector: (state) => state.quote,
      builder: (context, quote) {
        if (quote == null || quote.content.text.isEmpty) return const SizedBox.shrink();

        final bool onCustomBg = studyThemeHasCustomBg(context);
        final Color quoteBackground =
            onCustomBg ? _kQuoteBackgroundOnCustomBg.withValues(alpha: 0.9) : _kQuoteTint;

        return Semantics(
          label: context.l10n.home.homeQuoteLabel,
          child: Padding(
            // Top space is for the quote medallion, which sits half outside the
            // card — without it the medallion would collide with the greeting.
            padding: EdgeInsets.fromLTRB(20.w, 17.h, 20.w, 0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
                  decoration: BoxDecoration(
                    color: quoteBackground,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      AppText(
                        context.l10n.home.homeQuoteEyebrow.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.12 * 9.5.sp,
                          color: _kQuoteEyebrowColor,
                        ),
                      ),
                      5.verticalSpace,
                      AppText(
                        quote.content.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          height: 1.45,
                          color: _kQuoteInkColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Medallion straddling the card's top edge (design: top:-13px).
                Positioned(
                  top: -17.h,
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: const BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.string(_kQuoteIconSvg, width: 17.w, height: 17.w),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
