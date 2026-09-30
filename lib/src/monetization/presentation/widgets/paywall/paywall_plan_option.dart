part of '../../../monetization.dart';

/// Reusable inline plan option tile for the paywall.
class PaywallPlanOption extends StatelessWidget {
  final IapProductEntity product;
  final bool selected;
  final VoidCallback? onTap;

  const PaywallPlanOption({
    super.key,
    required this.product,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap == null
              ? null
              : () {
                  AppHaptic.select();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            // Design `6b · Premium`: 15/18 padding — the card carries real air
            // around its two rows ("design trông card nó to hơn", 2026-08-19).
            // The page scrolls, so the extra height costs nothing below.
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: selected ? AppCustomColor.backgroundWhite : const Color(0xFFFEFAF1),
              borderRadius: BorderRadius.circular(18.r),
              // Unselected keeps a VISIBLE lavender border (design): the old
              // borderDefault (#EBF0F7) vanished against the card's #F2F1FE
              // fill and the card read as borderless.
              border: Border.all(
                color: selected ? const Color(0xFF94762A) : const Color(0xFFF6EDD5),
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            // Hai hàng, không phải một (design `6b · Premium`): hàng trên là
            // tên gói + mức tiết kiệm và cái radio, hàng dưới là giá + giá gạch
            // và giá/ngày. Layout một hàng cũ dồn tên, pill, giá và giá gạch vào
            // cùng một dòng — trên máy hẹp thì hoặc tên bị cắt hoặc giá bị co.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // `Expanded`, không phải `Flexible`: nhóm tên+pill phải CHIẾM
                    // hết chỗ trống để đẩy radio ra mép phải như design. Với
                    // Flexible thì cả ba co lại về bên trái và radio dính vào
                    // pill — đúng cái đang sai trên bản 132.
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            // Scale down instead of ellipsizing: on narrow
                            // screens the pill and the price are fixed-width, so
                            // "HẰNG THÁNG" was truncated to "HẰNG THÁ…".
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AppText(
                                _planTitle.toUpperCase(),
                                maxLines: 1,
                                // Design: 14/w800, .02em. It shipped at 15 and
                                // read heavier than the price under it.
                                style: AppStyle.text14.copyWith(
                                  color: AppCustomColor.textBrand,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.28,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                          if (_showDiscountPill) ...[
                            9.horizontalSpace,
                            _DiscountPill(
                              label: context.l10n.monetization.planSavePercent(
                                percent: product.salePercent.toInt(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    8.horizontalSpace,
                    // Radio sang PHẢI theo design. Bên trái là nơi mắt bắt đầu
                    // đọc, và ở đó nó cạnh tranh với tên gói — thứ thật sự phân
                    // biệt hai thẻ.
                    _RadioIndicator(selected: selected),
                  ],
                ),
                // 8 between the rows, per the design's margin-top on the
                // price line — 2 made the card read as one squashed line pair.
                8.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Cụm giá chiếm chỗ trống để đẩy giá/ngày ra mép phải.
                    //
                    // KHÔNG ellipsis giá. Bản 136 cắt giá gạch thành "1.199.0…"
                    // — một cái giá bị cắt còn tệ hơn không hiện: người đọc
                    // không thể tự bù chữ số. Thay vào đó cả cụm nằm trong
                    // FittedBox(scaleDown): khi chật, TOÀN BỘ cụm co lại vài
                    // phần trăm và mọi chữ số vẫn còn — cùng cách hàng tiêu đề
                    // xử "HẰNG THÁNG". FittedBox cũng tự chặn vẽ tràn, nên
                    // không cần ClipRect: nội dung luôn được ép vào đúng khung.
                    //
                    // Bên trong FittedBox KHÔNG được có Flexible/Expanded —
                    // FittedBox đo con ở bề rộng không giới hạn, và một flex
                    // child trong Row không giới hạn là lỗi layout ngay khi
                    // build.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AppText(
                              _displayPrice,
                              maxLines: 1,
                              // One price colour for both states, per the design:
                              // the radio and the border say which plan is picked,
                              // and greying the other one's price made it read as
                              // unavailable rather than unselected.
                              // w700, not w800 — the design keeps the price one
                              // step lighter than the plan name so the two rows
                              // don't shout at the same volume.
                              style: AppStyle.text20.copyWith(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: AppCustomColor.textBrand,
                                height: 1.25,
                              ),
                            ),
                            AppText(
                              '/${_planPeriodLabel(product)}',
                              maxLines: 1,
                              style: AppStyle.text12.copyWith(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFA39369),
                                height: 1.6,
                              ),
                            ),
                            if (_showOriginalPrice) ...[
                              8.horizontalSpace,
                              Semantics(
                                label: l10n.monetization.paywallOriginalPriceLabel(price: product.compareAtPrice),
                                excludeSemantics: true,
                                child: AppText(
                                  product.compareAtPrice,
                                  maxLines: 1,
                                  style: AppStyle.text12.copyWith(
                                    fontSize: 12.5.sp,
                                    color: const Color(0xFFA39369),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: const Color(0xFFA39369),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Giá/ngày giữ cỡ tự nhiên bên phải — nó ngắn và cố định
                    // dạng, còn cụm giá bên trái mới là bên co giãn.
                    if (product.perDayPriceString.isNotEmpty) ...[
                      8.horizontalSpace,
                      AppText(
                        l10n.monetization.paywallPricePerDay(price: product.perDayPriceString),
                        maxLines: 1,
                        style: AppStyle.text12.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA39369),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (product.bestDeal)
          Positioned(
            right: 18.w,
            top: -9.h,
            child: _BestDealBadge(label: l10n.monetization.mostPopularBadge.toUpperCase()),
          ),
      ],
    );
  }

  String get _displayTitle => product.title.isEmpty ? product.productId : product.title;

  String get _planTitle {
    final idLower = product.productId.toLowerCase();
    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return l10n.monetization.paywallPlanAnnual;
    if (idLower.contains('quarter') || idLower.contains('3m')) return l10n.monetization.paywallPlanQuarterly;
    if (idLower.contains('month') || idLower.contains('1m')) return l10n.monetization.paywallPlanMonthly;
    if (idLower.contains('week') || idLower.contains('1w')) return l10n.monetization.paywallPlanWeekly;
    if (idLower.contains('lifetime')) return l10n.monetization.paywallPlanLifetime;
    return _displayTitle;
  }

  String get _displayPrice => product.price.isEmpty ? product.pricePerPeriodString : product.price;

  bool get _showDiscountPill => product.hasDiscount;

  /// The struck-through price is the live store price of the SKU configured in
  /// admin ("Giá gốc so sánh"). It now sits INLINE after the price on the
  /// design's second row, beside the per-day figure, rather than replacing a
  /// per-period line — that fallback line is gone with the one-row layout.
  /// Hidden whenever the compare-at price cannot be trusted — see
  /// [IapProductEntityX.hasCompareAtPrice].
  bool get _showOriginalPrice => product.hasCompareAtPrice;

  /// Đơn vị chu kỳ của gói cho hậu tố "/năm", "/tháng" (design `6b · Premium`).
  ///
  /// Thay cho `product.periodLabel` — nhãn đó là "mỗi tháng" kể cả với gói năm,
  /// nên ghép với tổng giá năm sẽ in "959.000đ/mỗi tháng": sai sự thật, không chỉ
  /// sai design.
  String _planPeriodLabel(IapProductEntity product) => product.planPeriodLabel;
}
