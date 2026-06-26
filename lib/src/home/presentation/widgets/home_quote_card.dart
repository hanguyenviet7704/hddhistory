part of '../../home.dart';

class HomeQuoteCard extends StatelessWidget {
  const HomeQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, QuoteEntity?>(
      selector: (state) => state.quote,
      builder: (context, quote) {
        if (quote == null || quote.content.text.isEmpty) return const SizedBox.shrink();

        return Semantics(
          label: context.l10n.home.homeQuoteLabel,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: quote.resolvedBackgroundColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText(
                      quote.content.text,
                      style: AppStyle.text14.copyWith(
                        color: quote.resolvedTextColor,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  8.horizontalSpace,
                  Icon(
                    Icons.format_quote_rounded,
                    color: quote.resolvedTextColor.withValues(alpha: 0.4),
                    size: 24.w,
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
