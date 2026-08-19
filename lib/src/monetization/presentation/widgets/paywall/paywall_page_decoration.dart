part of '../../../monetization.dart';

/// Chiều cao thanh CTA ghim đáy, dùng để chừa chỗ cuối scroll.
const double _kBottomBarReserve = 130;

class PaywallPageDecoration extends StatefulWidget {
  final IapState state;
  final double bottomPadding;
  final Future<void> Function() onClose;
  final bool showCloseButton;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const PaywallPageDecoration({
    super.key,
    required this.state,
    required this.bottomPadding,
    required this.onClose,
    required this.showCloseButton,
    required this.onPurchase,
    required this.onRetry,
  });

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedInfoSwipe = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _hasTrackedScroll) return;
    if (_scrollController.position.pixels <= 0) return;
    // premium_scroll tracking removed (not in the paywall spec).
    _hasTrackedScroll = true;
  }

  void _handleInfoSwipe() {
    if (_hasTrackedInfoSwipe) return;
    // premium_infor_swipe tracking removed (not in the paywall spec).
    _hasTrackedInfoSwipe = true;
  }

  void _handleRestore() {
    AppHaptic.select();
    AppService.instance.appTrackingService.trackPremiumRestoreClick();
    context.read<IapCubit>().restorePurchases();
  }

  bool get _isRestoring => widget.state.status == MonetizationStatus.restoring;

  void _handlePlanTap(IapProductEntity product) {
    if (product.id == widget.state.selectedProductId) return;
    AppService.instance.appTrackingService.trackPremiumAllpackPick(product.productId);
    context.read<IapCubit>().setSelectedProductId(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.state.paywallContent;
    final heading = _fallbackText(content.heading.text, l10n.monetization.paywallHeroTitle);
    final subheading = _fallbackText(content.subheading.text, l10n.monetization.paywallHeroSubtitle);
    final benefits = content.benefits.where((benefit) => benefit.title.text.isNotEmpty).toList();
    // Bảng chỉ thay danh sách khi config chọn `comparison` VÀ locale này thực sự
    // có dòng. Thiếu điều kiện thứ hai thì bật layout trước lúc nhập dữ liệu sẽ
    // cho ra một paywall không có khối nào ở giữa — trông y như lỗi.
    final comparisonRows = content.comparison.where((row) => row.label.text.trim().isNotEmpty || row.free.text.trim().isNotEmpty || row.premium.text.trim().isNotEmpty).toList();
    final showComparison = context.read<IapCubit>().resolvedPaywallConfig.bodyVariant == PaywallBodyVariant.comparison && comparisonRows.isNotEmpty;

    // Design `6b · Premium`: the close button does NOT sit in a header row with
    // the wordmark — it floats over the scroll, top-right, so the `MeUp PREMIUM`
    // lockup is centred on the screen rather than on the space left beside it.
    return Stack(
      children: [
        _buildScroll(heading, subheading, benefits, showComparison ? comparisonRows : const []),
        // Thanh CTA GHIM ĐÁY, không nằm trong scroll (design `6b · Premium`:
        // `<!-- fixed bottom CTA bar -->`). Nút mua phải luôn trong tầm ngón tay
        // — bảng so sánh đẩy nó xuống quá xa nếu để nó cuộn theo, và người đọc
        // vừa bị thuyết phục bởi bảng thì không nên phải cuộn đi tìm nút.
        Positioned(left: 0, right: 0, bottom: 0, child: _bottomCtaBar()),
        if (widget.showCloseButton)
          Positioned(
            top: 4.h,
            right: 20.w,
            child: _PaywallCloseButton(onTap: () => unawaited(widget.onClose())),
          ),
      ],
    );
  }

  Widget _buildScroll(
    String heading,
    String subheading,
    List<PaywallBenefitEntity> benefits,
    List<PaywallComparisonRowEntity> comparisonRows,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      // `+ _kBottomBarReserve`: thanh CTA ghim đáy che mất phần cuối scroll nếu
      // không chừa chỗ. Con số lấy từ chính design — toast của nó đặt ở
      // `bottom:172px`, tức chiều cao thanh cộng một khoảng thở. Đo bằng
      // GlobalKey sẽ chính xác hơn nhưng thanh này có nội dung cố định nên
      // không đáng phức tạp thêm.
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, widget.bottomPadding + _kBottomBarReserve.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PremiumPill(),
          6.verticalSpace,
          // Floating hero illustration. Decorative only — excluded from semantics
          // so the reader lands straight on the heading.
          ExcludeSemantics(
            child: SvgPicture.asset(
              AppAsset.svg.app.pwHeaderGraphic,
              width: 290.w,
              fit: BoxFit.contain,
            ),
          ),
          14.verticalSpace,
          // Heading first, then the subheading beneath it. This used to be the
          // other way round, which put the smallest, faintest text at the top of
          // the screen and buried the promise under it.
          AppText(
            heading,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: AppStyle.textBold24.copyWith(
              fontSize: 21.sp,
              color: AppCustomColor.textBrand,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
          2.verticalSpace,
          AppText(
            subheading,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8F8AB9),
              height: 1.4,
            ),
          ),
          22.verticalSpace,
          // Benefits sit ABOVE the plans: the reader has to know what they get
          // before a price means anything. Indented 12 from the card edges, per
          // the design — the check marks hang inside the text block rather than
          // lining up with the plan cards below.
          // Danh sách lợi ích biến mất khi bảng so sánh thay chỗ nó — hai khối
          // nói cùng một chuyện, hiện cả hai là lặp lại chính mình.
          if (comparisonRows.isEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Column(
                children: [
                  if (benefits.isEmpty)
                    ..._defaultBenefits()
                  else
                    for (var index = 0; index < benefits.length; index++)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 4.h),
                        child: _PaywallBenefitRow(text: benefits[index].title.text),
                      ),
                ],
              ),
            ),
            22.verticalSpace,
          ] else
            22.verticalSpace,
          // Full-width countdown, directly above the plans it discounts. The
          // compact copy inside the purchase bar stays — that one follows the
          // button, this one gives the offer its own line. Renders nothing when
          // no sale is running.
          _CountdownStrip(strategy: widget.state.resolvedPaywallStrategy),
          // The LogicSale campaign's own countdown — a separate, per-user
          // signal from `_CountdownStrip`'s CMS sale event (see
          // IapState.logicSaleCountdownEndAt). Renders nothing on its own
          // when no LogicSale is driving this load.
          _LogicSaleCountdownStrip(endAt: widget.state.logicSaleCountdownEndAt),
          _PaywallInlinePlans(
            state: widget.state,
            onPlanTap: _handlePlanTap,
          ),
          PaywallPromoCode(state: widget.state),
          // Bảng nằm DƯỚI các thẻ gói, đúng thứ tự trong design: nó lập luận
          // khác với danh sách lợi ích — người đọc đã thấy giá và giờ được cho
          // thấy bản miễn phí thiếu những gì.
          if (comparisonRows.isNotEmpty) PaywallComparisonTable(rows: comparisonRows),
          // Nút mua KHÔNG còn ở đây — nó đã lên thanh ghim đáy. Comment cũ ở chỗ
          // này nói "per the design, not in a sticky bottom bar"; design đã đổi.
          32.verticalSpace,
          // Config-gated: a claim about MIT and Harvard may not hold in every
          // market. Absent from the config parses to true (the behaviour of the
          // build that introduced the strip).
          if (context.read<IapCubit>().resolvedPaywallConfig.showCredibilityBlock) ...[
            const _PaywallCredibilityBlock(),
            6.verticalSpace,
          ],
          // "What people say about MeUp" — the carousel below is unlabelled
          // otherwise, and the design gives the section its own heading.
          32.verticalSpace,
          AppText(
            l10n.monetization.paywallReviewsHeading,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.text16.copyWith(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppCustomColor.textBrand,
              height: 1.3,
            ),
          ),
          16.verticalSpace,
          PaywallFeedbackList(onFirstScroll: _handleInfoSwipe),
          // Legal + Khôi phục đã chuyển vào thanh ghim đáy, đúng như design gom
          // cả ba vào một hàng dưới nút.
          50.verticalSpace,
        ],
      ),
    );
  }

  /// Icon khiên của design, nguyên bản — nền tím nhạt, tick tím đậm.
  static const String _shieldSvg =
      '''<svg width="15" height="15" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2.6l2.7 1.9 3.3-.2 1 3.1 2.4 2.3-1.3 3 .5 3.3-3 1.4-1.8 2.8-3.2-.6-3 1.3-2.3-2.4-3.2-.9.2-3.3-1.9-2.7 1.9-2.7-.2-3.3 3.2-.9 2.3-2.4 3 1.3z" fill="#DDD8FA"/><path d="M8.5 12.3l2.4 2.4 4.8-5.1" stroke="#5A52F0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  Widget _bottomCtaBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, MediaQuery.paddingOf(context).bottom + 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFECE9F6))),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14110751),
            offset: Offset(0, -10.h),
            blurRadius: 30.r,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InlinePurchaseSection(
            state: widget.state,
            onPurchase: widget.onPurchase,
            onRetry: widget.onRetry,
          ),
          // 18, up from 12 ("hạ thấp phần ở dưới nâng cấp premium",
          // 2026-08-19): the trust line and legal links sat glued to the CTA.
          18.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(_shieldSvg, width: 15.w, height: 15.w),
              6.horizontalSpace,
              AppText(
                l10n.monetization.paywallCtaTrustLine,
                maxLines: 1,
                style: AppStyle.text12.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9A96AE),
                  height: 1.3,
                ),
              ),
            ],
          ),
          12.verticalSpace,
          // `compact: true` là hàng một dòng có kèm Khôi phục — đúng ba mục
          // design gom dưới nút. Truyền handler vô điều kiện rồi tự chặn tái
          // nhập: nếu truyền null lúc đang restore thì cái link biến mất giữa
          // thao tác, còn tệ hơn là nó đứng im.
          PaywallLegalLinks(
            compact: true,
            onRestore: () {
              if (_isRestoring) return;
              _handleRestore();
            },
          ),
        ],
      ),
    );
  }

  String _fallbackText(String value, String fallback) => value.isEmpty ? fallback : value;

  List<Widget> _defaultBenefits() {
    final fallback = [
      '${l10n.monetization.benefit1Title} ${l10n.monetization.benefit1Desc}',
      '${l10n.monetization.benefit2Title} ${l10n.monetization.benefit2Desc}',
      '${l10n.monetization.benefit3Title} ${l10n.monetization.benefit3Desc}',
    ];
    return [
      for (var index = 0; index < fallback.length; index++)
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 8.h),
          child: _PaywallBenefitRow(text: fallback[index]),
        ),
    ];
  }
}

/// The trust strip between the plans and the reviews: a laurel-framed claim
/// about where the method comes from, and the store rating.
///
/// Only ONE laurel asset ships. The right-hand branch is the same drawing
/// mirrored on X — the artwork is symmetric, so a second file would have been a
/// second copy of the same paths to download and cache.
class _PaywallCredibilityBlock extends StatelessWidget {
  const _PaywallCredibilityBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _laurel(),
            10.horizontalSpace,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 220.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    l10n.monetization.paywallScienceTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textBrand,
                      height: 1.35,
                    ),
                  ),
                  AppText(
                    l10n.monetization.paywallScienceSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E67D8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            // Mirrored, not a separate asset.
            Transform.flip(flipX: true, child: _laurel()),
          ],
        ),
        16.verticalSpace,
        // The stars are decoration for a rating the text already states, so
        // they are hidden from screen readers rather than read out five times.
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Icon(Icons.star_rounded, size: 24.w, color: const Color(0xFFF9C51A)),
            ],
          ),
        ),
        6.verticalSpace,
        AppText(
          l10n.monetization.paywallStoreRating,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppStyle.text14.copyWith(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            color: AppCustomColor.textBrand,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _laurel() => SvgPicture.asset(
    AppAsset.svg.app.pwLaurelLeft,
    width: 24.w,
    height: 44.w,
    fit: BoxFit.contain,
  );
}

/// The purchase CTA inside the scroll flow — the sticky bottom bar's job,
/// relocated per the design. Flips to Retry when the catalogue failed to load.
///
/// Carries NO price of its own, unlike the bar it replaced. The total and the
/// per-month renewal line are still on screen — on the plan cards immediately
/// above, which is where the reader chooses between them — so this drops a
/// repetition, not the disclosure.
class _InlinePurchaseSection extends StatelessWidget {
  final IapState state;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const _InlinePurchaseSection({
    required this.state,
    required this.onPurchase,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasProducts = state.iapProducts.isNotEmpty;
    final isBusy = state.status == MonetizationStatus.loading || state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring;
    final isFailure = state.status == MonetizationStatus.failure && !hasProducts;

    // Design `6b · Premium` carries a bare "Upgrade to Premium" — the total and
    // the per-month renewal line both sit on the plan cards directly above,
    // where the reader picks. Repeating them on the button and again in a
    // caption underneath said the same number three times in one glance.
    final label = isFailure ? l10n.monetization.retry : l10n.monetization.paywallCtaUpgrade;

    return _PurchaseButton(
      label: label,
      busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
      enabled: !isBusy && (hasProducts || isFailure),
      onTap: isFailure ? onRetry : onPurchase,
    );
  }
}
