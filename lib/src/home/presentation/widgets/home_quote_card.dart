part of '../../home.dart';

/// Motivation card background — a soft lavender sitting between
/// brandPrimary50 (#EBEAFD, too pale) and brandPrimary100 (#D6CAFD, a touch
/// strong), tuned to the design's quote card.
const Color _kQuoteBackground = Color(0xFFDED7FD);

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

        // Over a custom study background the solid lavender reads too dense next
        // to the translucent glass cards — soften it to the same ~0.82 see-through
        // level so the personalized background shows softly through. Keep the
        // solid design lavender on the stock background.
        final Color quoteBackground = studyThemeHasCustomBg(context) ? _kQuoteBackground.withValues(alpha: 0.82) : _kQuoteBackground;

        return Semantics(
          label: context.l10n.home.homeQuoteLabel,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 20.h),
              decoration: BoxDecoration(
                color: quoteBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.string(_kQuoteIconSvg, width: 30.w, height: 30.w),
                  10.verticalSpace,
                  AppText(
                    quote.content.text,
                    style: _poppins(17, FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
