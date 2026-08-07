part of '../../../monetization.dart';

/// The compact-variant paywall — what an entry point configured "Rút gọn" in
/// the admin renders instead of the full page.
///
/// Same design language as the gift sheet (badge, N% OFF, countdown, artwork,
/// price, one CTA) but driven by the RESOLVED STRATEGY, not a gift campaign:
/// the plan is the compact SKU the resolver already picked, the headline is
/// that product's own salePercent, and the countdown appears only while a sale
/// event is running. No sale → badge, plan and CTA only; urgency is never
/// invented client-side.
///
/// Still a full route (the callers just push PaywallPage), so close pops the
/// route exactly like the full variant — only the body is sheet-shaped.
class _PaywallCompactBody extends StatelessWidget {
  final IapState state;
  final Future<void> Function() onClose;
  final VoidCallback onPurchase;

  const _PaywallCompactBody({
    required this.state,
    required this.onClose,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final strategy = state.resolvedPaywallStrategy;
    final product = state.selectedProduct;
    final hasProduct = product.price.isNotEmpty;
    final discount = product.salePercent > 0 && product.salePercent < 100 ? product.salePercent.round() : 0;
    final endAtUtc = strategy?.hasSaleCountdown == true ? strategy?.endAtUtc : null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(top: 68.h),
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 30.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _CloseButton(onTap: () => unawaited(onClose())),
              ),
              12.verticalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFD),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText(
                  l10n.monetization.giftSheetBadge.toUpperCase(),
                  style: AppStyle.text12.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF4B44CA),
                  ),
                ),
              ),
              if (discount > 0) ...[
                14.verticalSpace,
                AppText(
                  l10n.monetization.giftSheetDiscount(percent: discount),
                  textAlign: TextAlign.center,
                  style: AppStyle.textBold24.copyWith(
                    fontSize: 56.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.6,
                    color: const Color(0xFF4B44CA),
                    height: 1.1,
                  ),
                ),
              ],
              if (endAtUtc != null) ...[
                14.verticalSpace,
                _CountdownRow(endAtUtc: endAtUtc),
              ],
              Padding(
                padding: EdgeInsets.only(top: 20.h, bottom: 8.h),
                child: ExcludeSemantics(
                  child: Transform.rotate(
                    angle: -16 * math.pi / 180,
                    child: SvgPicture.asset(
                      AppAsset.svg.app.pwGift,
                      width: 190.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (hasProduct) ...[
                14.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (product.hasCompareAtPrice) ...[
                      AppText(
                        product.compareAtPrice,
                        style: AppStyle.text16.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA8A2C6),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: const Color(0xFFA8A2C6),
                        ),
                      ),
                      10.horizontalSpace,
                    ],
                    AppText(
                      product.price,
                      style: AppStyle.textBold24.copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppCustomColor.textBrand,
                      ),
                    ),
                  ],
                ),
              ],
              26.verticalSpace,
              _PurchaseButton(
                label: l10n.monetization.giftSheetCta,
                busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
                enabled: hasProduct,
                onTap: onPurchase,
              ),
              14.verticalSpace,
              const PaywallLegalLinks(),
            ],
          ),
        ),
      ),
    );
  }
}
