part of '../../../monetization.dart';

/// Promo-code block on the paywall, directly under the plan cards.
///
/// Four states, per the design (see
/// `plans/260727-paywall-redesign/design-spec.md`):
/// collapsed link → open panel → code entry → applied.
///
/// Purely presentational: it owns only whether the panel is expanded and the
/// text being typed. Whether a code is applied, and any message to show, are
/// driven from outside so the cubit stays the single source of truth.
class PaywallPromoCode extends StatefulWidget {
  const PaywallPromoCode({
    super.key,
    required this.onApply,
    required this.onRemove,
    this.appliedCode,
    this.isApplying = false,
    this.message,
    this.isMessageError = false,
  });

  /// Non-null once a code is successfully applied — switches to the applied state.
  final String? appliedCode;

  /// True while the validate call is in flight.
  final bool isApplying;

  /// Feedback under the field; shown for both success and failure.
  final String? message;
  final bool isMessageError;

  final ValueChanged<String> onApply;
  final VoidCallback onRemove;

  @override
  State<PaywallPromoCode> createState() => _PaywallPromoCodeState();
}

class _PaywallPromoCodeState extends State<PaywallPromoCode> {
  final TextEditingController _controller = TextEditingController();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // A code applied before this mounted (e.g. restored with the paywall
    // state) must not open onto the collapsed link.
    _expanded = widget.appliedCode != null;
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(PaywallPromoCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appliedCode != null && !_expanded) {
      _expanded = true;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canApply => _controller.text.trim().isNotEmpty && !widget.isApplying;

  void _open() {
    AppHaptic.select();
    setState(() => _expanded = true);
  }

  void _hide() {
    AppHaptic.select();
    FocusScope.of(context).unfocus();
    setState(() => _expanded = false);
  }

  void _apply() {
    if (!_canApply) return;
    AppHaptic.select();
    FocusScope.of(context).unfocus();
    widget.onApply(_controller.text.trim().toUpperCase());
  }

  void _remove() {
    AppHaptic.select();
    _controller.clear();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) return _CollapsedLink(onTap: _open);

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(onHide: _hide),
          8.verticalSpace,
          if (widget.appliedCode != null)
            _AppliedRow(code: widget.appliedCode!, onRemove: _remove)
          else
            _EntryRow(
              controller: _controller,
              isApplying: widget.isApplying,
              canApply: _canApply,
              onApply: _apply,
            ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            10.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: AppText(
                widget.message!,
                style: AppStyle.text14.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isMessageError
                      ? AppCustomColor.errorRed
                      : AppCustomColor.successGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollapsedLink extends StatelessWidget {
  const _CollapsedLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 17.w,
                  color: AppCustomColor.paywallPromoLink,
                ),
                8.horizontalSpace,
                AppText(
                  l10n.monetization.promoCodeCta,
                  style: AppStyle.text14.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.paywallPromoLink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onHide});

  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 16.w,
              color: AppCustomColor.paywallPromoLink,
            ),
            7.horizontalSpace,
            AppText(
              l10n.monetization.promoCodeLabel,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.paywallPromoLabel,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onHide,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: AppText(
              l10n.monetization.promoCodeHide,
              style: AppStyle.text14.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppCustomColor.paywallPromoMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.controller,
    required this.isApplying,
    required this.canApply,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool isApplying;
  final bool canApply;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: TextField(
              controller: controller,
              enabled: !isApplying,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onApply(),
              style: AppStyle.text14.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppCustomColor.textBrand,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppCustomColor.backgroundWhite,
                hintText: l10n.monetization.promoCodeHint,
                hintStyle: AppStyle.text14.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.paywallPromoMuted,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                border: _border(AppCustomColor.borderSecondary),
                enabledBorder: _border(AppCustomColor.borderSecondary),
                disabledBorder: _border(AppCustomColor.borderSecondary),
                focusedBorder: _border(AppCustomColor.brandPrimary),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        GestureDetector(
          onTap: canApply ? onApply : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: canApply
                  ? AppCustomColor.brandPrimary
                  : AppCustomColor.buttonDisable,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: isApplying
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppCustomColor.backgroundWhite,
                      ),
                    ),
                  )
                : AppText(
                    l10n.monetization.promoCodeApply,
                    style: AppStyle.text14.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: canApply
                          ? AppCustomColor.backgroundWhite
                          : AppCustomColor.paywallPromoMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14.r),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}

class _AppliedRow extends StatelessWidget {
  const _AppliedRow({required this.code, required this.onRemove});

  final String code;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppCustomColor.paywallPromoAppliedBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAsset.svg.app.pwPromoApplied,
                  width: 22.w,
                  height: 21.w,
                ),
                10.horizontalSpace,
                Flexible(
                  child: AppText(
                    code,
                    maxLines: 1,
                    style: AppStyle.text14.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppCustomColor.paywallPromoAppliedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: AppText(
                l10n.monetization.promoCodeRemove,
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppCustomColor.paywallPromoRemove,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
