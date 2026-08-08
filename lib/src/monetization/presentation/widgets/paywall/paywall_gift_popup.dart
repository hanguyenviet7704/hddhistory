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
  const PaywallGiftPopup({super.key});

  static Future<bool> show(BuildContext context) async {
    final opened = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppCustomColor.bottomSheetScrim,
      builder: (_) => const PaywallGiftPopup(),
    );
    return opened ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // The one configurable line of this popup. Empty config falls back to the
    // bundled copy; the CTA below stays hardcoded per the spec.
    // Via DI, NOT context.read: this dialog mounts on the root navigator,
    // above any BlocProvider — context.read threw 38 times on the sim.
    final remoteTitle = AppDI.injector.get<IapCubit>().resolvedPaywallConfig.giftCampaign?.title.text ?? '';
    final title = remoteTitle.isEmpty ? l10n.monetization.giftPopupTitle : remoteTitle;

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
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Same overhang pattern as PaywallSuccessPurchasePopup: the design
            // pulls the artwork up 96 of its ~166px, so most of the box floats
            // ABOVE the card. Transform.translate only repaints (layout keeps
            // the hole), and a negative-height SizedBox is not a thing — a
            // Stack with clip none is the way Flutter says margin-top:-96.
            Positioned(
              top: -96.h,
              child: ExcludeSemantics(
                child: SvgPicture.asset(
                  AppAsset.svg.app.pwGift,
                  width: 170.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Room for the artwork's in-card half (~70) + the design's 18 gap.
                SizedBox(height: 88.h),
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
          ],
        ),
      ),
    );
  }
}
