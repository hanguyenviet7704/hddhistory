part of '../../../monetization.dart';

/// Promo code on the paywall: a low-emphasis trigger under the plan cards,
/// swapped for a chip once a code is live. Entry itself lives in
/// [PaywallPromoCodeSheet].
///
/// The field was inline here before. It sat in the scroll area that runs under
/// the fixed purchase bar, and that bar knows nothing about the keyboard — so
/// the field being typed into could end up behind the countdown strip. A modal
/// sheet rides above the bar with its own keyboard offset, which removes the
/// conflict instead of tuning padding around it.
///
/// Renders nothing while no plan resolved: there is no price to discount, and
/// applying a code then fails with a message that blames the code.
class PaywallPromoCode extends StatelessWidget {
  const PaywallPromoCode({super.key, required this.state});

  final IapState state;

  @override
  Widget build(BuildContext context) {
    if (state.iapProducts.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: state.hasAppliedVoucher
          ? _AppliedChip(
              code: state.appliedVoucherCode,
              onRemove: () => context.read<IapCubit>().removeVoucher(),
            )
          : _PromoTrigger(onTap: () => unawaited(PaywallPromoCodeSheet.show(context))),
    );
  }
}

/// "Have a promo code?" — deliberately quieter than the plan cards (14/w600,
/// not 15/w700): it must be findable without competing with the price choice.
class _PromoTrigger extends StatelessWidget {
  const _PromoTrigger({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Center(
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: () {
              AppHaptic.select();
              onTap();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: BoxConstraints(minHeight: 44.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 16.w,
                    color: AppCustomColor.paywallPromoLink,
                  ),
                  8.horizontalSpace,
                  AppText(
                    l10n.monetization.promoCodeCta,
                    style: AppStyle.text14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppCustomColor.paywallPromoLink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Applied state. Tinted with the brand colour rather than the green pair it
/// used to carry — that green existed nowhere else in the app.
class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.code, required this.onRemove});

  final String code;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Container(
        constraints: BoxConstraints(minHeight: 52.h),
        padding: EdgeInsets.only(left: 14.w, right: 4.w),
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppCustomColor.brandPrimary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: '${l10n.monetization.promoCodeApplied}: $code',
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppAsset.svg.app.pwPromoApplied,
                      width: 20.w,
                      height: 20.w,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: AppText(
                        code,
                        maxLines: 1,
                        style: AppStyle.text14.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppCustomColor.paywallPromoLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.monetization.promoCodeRemove,
              child: GestureDetector(
                onTap: () {
                  AppHaptic.select();
                  onRemove();
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.w,
                      color: AppCustomColor.paywallPromoRemove,
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
