part of '../../../monetization.dart';

/// Step one of the gift campaign: the interruption that offers to be opened.
///
/// It deliberately carries no price, no discount and no terms — everything that
/// would let a reader decide before opening. The whole point of the step is the
/// gesture; the numbers live in the sheet it opens, and duplicating them here
/// would make the popup an ordinary offer with an extra tap in front of it.
///
/// [show] resolves to `true` when the reader chose to open the gift, and `false`
/// for every other exit (barrier tap, back gesture). The caller drives the sheet
/// off that answer rather than this widget pushing it, so the two steps stay
/// independently testable.
class PaywallGiftPopup extends StatelessWidget {
  final PaywallGiftCampaignEntity campaign;

  const PaywallGiftPopup({super.key, required this.campaign});

  static Future<bool> show(
    BuildContext context, {
    required PaywallGiftCampaignEntity campaign,
  }) async {
    final opened = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppCustomColor.bottomSheetScrim,
      builder: (_) => PaywallGiftPopup(campaign: campaign),
    );
    return opened ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Remote copy wins when the campaign supplies it; the bundled string is the
    // floor so a campaign published with an empty heading still reads as a gift
    // rather than as a blank card with a button.
    final heading = campaign.popupContent.heading.text;
    final title = heading.isEmpty ? l10n.monetization.giftPopupTitle : heading;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D073C).withValues(alpha: 0.3),
              blurRadius: 60,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overhangs the card by design — a negative top margin rather than a
            // Stack, so the column below keeps laying out from the artwork's
            // real bottom edge and the title never collides with it.
            Transform.translate(
              offset: Offset(0, -48.h),
              child: ExcludeSemantics(
                child: SvgPicture.asset(
                  AppAsset.svg.app.pwGift,
                  width: 170.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Claws back the space the overhang borrowed, so the gap under the
            // artwork is the design's 18 rather than 18 minus the offset.
            (18 - 48).h.verticalSpace,
            AppText(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.text20.copyWith(
                fontSize: 21.sp,
                fontWeight: FontWeight.w600,
                color: AppCustomColor.textBrand,
                height: 1.3,
              ),
            ),
            22.verticalSpace,
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF5A52F0),
                  borderRadius: BorderRadius.circular(1000.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A52F0).withValues(alpha: 0.34),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
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
                        l10n.monetization.giftPopupCta,
                        style: AppStyle.text16.copyWith(
                          fontSize: 17.sp,
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
          ],
        ),
      ),
    );
  }
}
