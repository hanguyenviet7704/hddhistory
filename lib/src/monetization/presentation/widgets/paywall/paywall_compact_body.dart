part of '../../../monetization.dart';

/// The compact-variant paywall — what an entry point configured "Rút gọn" in
/// the admin renders instead of the full page.
///
/// Badge, N% OFF, countdown, artwork, price, one CTA. The plan is the compact
/// SKU the resolver already picked; discount and deadline come from the live
/// sale event only. No sale → badge, plan and CTA; urgency is never invented
/// client-side.
///
/// Still a full route (the callers just push PaywallPage), so close pops the
/// route exactly like the full variant — only the body is sheet-shaped.
class _PaywallCompactBody extends StatelessWidget {
  final IapState state;
  final Future<void> Function() onClose;
  final VoidCallback onPurchase;

  /// Per-reader deadline from [CompactCountdownSchedule], resolved by the page
  /// because it needs an async storage read. Null while that is still in
  /// flight, or when config has switched the rolling countdown off.
  final DateTime? countdownEndAt;

  const _PaywallCompactBody({
    required this.state,
    required this.onClose,
    required this.onPurchase,
    this.countdownEndAt,
  });

  @override
  Widget build(BuildContext context) {
    // NOT `state.selectedProduct`: selectedProductId is chosen when the FULL
    // list loads, and the compact list usually doesn't contain that id — the
    // getter then answers with an empty entity, which is how this sheet first
    // shipped with no price row and a permanently disabled CTA.
    IapProductEntity? selected;
    for (final candidate in state.iapProducts) {
      if (candidate.id == state.selectedProductId) selected = candidate;
    }
    selected ??= state.iapProducts.firstOrNull;
    final product = selected;
    final hasProduct = product != null && product.price.isNotEmpty;

    // Converge the cubit's selection onto the plan this sheet actually shows.
    // The purchase path buys `selectedProductId`, and without this the Claim
    // button would charge the FULL list's selection at a different price than
    // the one on screen.
    if (product != null && product.id != state.selectedProductId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<IapCubit>().setSelectedProductId(product.id);
      });
    }

    // Discount and deadline belong to the compact config itself — sale events
    // are full-paywall-only, so nothing here reads the resolved sale state.
    final config = AppDI.injector.get<IapCubit>().resolvedPaywallConfig;
    final discount = config.compactDiscountPercent > 0 && config.compactDiscountPercent < 100 ? config.compactDiscountPercent : 0;
    // The per-reader rolling countdown wins when config asks for one: it gives
    // everybody the same window measured from when THEY were shown the offer.
    // `endAtUtc` stays as the escape hatch for a genuine campaign that ends at
    // one instant for the whole user base — set `countdownHours` to 0 to get
    // that behaviour back.
    final fixed = DateTime.tryParse(config.compactEndAtUtc ?? '');
    final DateTime? fixedEndAt = fixed != null && fixed.isAfter(DateTime.now().toUtc()) ? fixed : null;
    final DateTime? endAtUtc = countdownEndAt ?? fixedEndAt;

    return Container(
      // Flush to the ceiling ("kéo cao lên sát trần", 2026-08-09): the page's
      // SafeArea already clears the notch, so this sliver of gradient is all
      // that stays visible above the sheet's rounded corners.
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 30.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
            if (discount > 0)
              Builder(builder: (context) {
                // Config wins, bundled copy is the floor. Only rendered while a
                // sale gives the warning something true to warn about.
                final remote = AppDI.injector.get<IapCubit>().resolvedPaywallConfig.compactUrgencyLine.text;
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: AppText(
                    remote.isEmpty ? l10n.monetization.compactUrgencyLine : remote,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text12.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8F8AB9),
                      height: 1.4,
                    ),
                  ),
                );
              }),
            if (endAtUtc != null) ...[
              14.verticalSpace,
              _CountdownRow(endAtUtc: endAtUtc),
            ],
            // The artwork owns the leftover middle of the sheet (design:
            // the price row flexes, box sits large in the center) — an
            // Expanded, so the sheet always fills from 68px down instead of
            // shrink-wrapping and floating mid-screen. The open-box PNG is the
            // design's own asset (pulled from the design project), rotated
            // -16° exactly as its HTML does.
            Expanded(
              child: Center(
                child: ExcludeSemantics(
                  child: Transform.rotate(
                    angle: -16 * math.pi / 180,
                    child: Image.asset(
                      AppAsset.images.app.pwGiftOpen.path,
                      width: 280.w,
                      fit: BoxFit.contain,
                    ),
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
    );
  }
}
