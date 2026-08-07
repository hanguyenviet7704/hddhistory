part of '../../../monetization.dart';

/// Step two of the gift campaign: the sheet that finally shows the numbers —
/// "33% OFF", the countdown to [PaywallGiftCampaignEntity.endAtUtc], the
/// struck-through price against the offer price, and the Claim Offer CTA.
///
/// The countdown reads the campaign's `endAtUtc` directly, so the timer and the
/// offer share one deadline by construction. When it reaches zero the sheet
/// stays open showing 00:00:00 rather than snapping shut mid-read — the
/// campaign resolver decides eligibility, this widget only displays it.
///
/// [show] resolves to `true` when the reader tapped Claim Offer. The PURCHASE
/// itself is the caller's job (it owns the IapCubit and the product), keeping
/// this sheet as presentational as the popup before it.
class PaywallGiftSheet extends StatefulWidget {
  final PaywallGiftCampaignEntity campaign;

  /// Localized price line, already formatted by the caller from the store
  /// product (`299.000đ` style). Null hides the strike-through row rather than
  /// showing a dash — a missing "was" price is not information.
  final String? originalPriceLabel;
  final String? offerPriceLabel;

  const PaywallGiftSheet({
    super.key,
    required this.campaign,
    this.originalPriceLabel,
    this.offerPriceLabel,
  });

  static Future<bool> show(
    BuildContext context, {
    required PaywallGiftCampaignEntity campaign,
    String? originalPriceLabel,
    String? offerPriceLabel,
  }) async {
    final claimed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.bottomSheetScrim,
      builder: (_) => PaywallGiftSheet(
        campaign: campaign,
        originalPriceLabel: originalPriceLabel,
        offerPriceLabel: offerPriceLabel,
      ),
    );
    return claimed ?? false;
  }

  @override
  State<PaywallGiftSheet> createState() => _PaywallGiftSheetState();
}

class _PaywallGiftSheetState extends State<PaywallGiftSheet> {
  Timer? _timer;

  DateTime? get _endAtUtc => DateTime.tryParse(widget.campaign.endAtUtc ?? '');

  @override
  void initState() {
    super.initState();
    // Tick only when there is a deadline to count to; a campaign without one
    // simply shows no timer row instead of a frozen 00:00:00.
    if (_endAtUtc != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endAtUtc = _endAtUtc;
    final discount = widget.campaign.discountPercent;

    return Container(
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
              child: _CloseButton(onTap: () => Navigator.of(context).maybePop(false)),
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
            14.verticalSpace,
            if (discount > 0)
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
            // The urgency line under the headline ("You will never see this
            // again if you exit" in the design) — admin copy, per locale, via
            // sheetContent. No copy published → no line, not a blank row.
            if (widget.campaign.sheetContent.subheading.text.isNotEmpty) ...[
              8.verticalSpace,
              AppText(
                widget.campaign.sheetContent.subheading.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppStyle.text12.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8F8AB9),
                  height: 1.4,
                ),
              ),
            ],
            if (endAtUtc != null) ...[
              14.verticalSpace,
              _CountdownRow(endAtUtc: endAtUtc),
            ],
            // Stand-in for the design's pw-gift-open.png (280px, rotated -16°),
            // which is a binary the design bridge cannot deliver. Same artwork
            // family, so the layout holds; swap to Image.asset when the PNG
            // lands in assets/images/app/pw_gift_open.png.
            Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 8.h),
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -16 * math.pi / 180,
                  child: SvgPicture.asset(
                    AppAsset.svg.app.pwGift,
                    width: 210.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (widget.offerPriceLabel != null) ...[
              14.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (widget.originalPriceLabel != null) ...[
                    AppText(
                      widget.originalPriceLabel!,
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
                    widget.offerPriceLabel!,
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
            SizedBox(
              width: double.infinity,
              height: 60.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF5A52F0),
                  borderRadius: BorderRadius.circular(1000.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A52F0).withValues(alpha: 0.36),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(1000.r),
                    onTap: () {
                      AppHaptic.success();
                      Navigator.of(context).pop(true);
                    },
                    child: Center(
                      child: AppText(
                        l10n.monetization.giftSheetCta,
                        style: AppStyle.text16.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            14.verticalSpace,
            const PaywallLegalLinks(),
          ],
        ),
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final DateTime endAtUtc;

  const _CountdownRow({required this.endAtUtc});

  @override
  Widget build(BuildContext context) {
    final parts = resolvePaywallCountdownParts(endAtUtc, DateTime.now().toUtc());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          l10n.monetization.giftSheetEndsIn,
          style: AppStyle.text12.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8F8AB9),
          ),
        ),
        8.horizontalSpace,
        _chip(parts.hours),
        _colon(),
        _chip(parts.minutes),
        _colon(),
        _chip(parts.seconds),
      ],
    );
  }

  Widget _chip(String value) => Container(
    constraints: BoxConstraints(minWidth: 38.w),
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEDEAFD),
      borderRadius: BorderRadius.circular(9.r),
    ),
    child: AppText(
      value,
      textAlign: TextAlign.center,
      style: AppStyle.text16.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF3A3355),
      ),
    ),
  );

  Widget _colon() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 5.w),
    child: AppText(
      ':',
      style: AppStyle.text16.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFFA8A2D6),
      ),
    ),
  );
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F1FA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 34.w,
          child: Icon(
            Icons.close_rounded,
            size: 18.w,
            color: const Color(0xFF6B659B),
          ),
        ),
      ),
    );
  }
}
