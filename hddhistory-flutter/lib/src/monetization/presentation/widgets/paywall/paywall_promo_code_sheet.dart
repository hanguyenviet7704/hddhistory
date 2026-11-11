part of '../../../monetization.dart';

/// Promo-code entry as a modal sheet, opened from [PaywallPromoCode].
///
/// It closes itself only once the cubit confirms the discounted plans actually
/// resolved. `applyVoucher` stores the code first and rolls it back if the
/// discounted SKUs are missing from the store, so popping on "code accepted"
/// alone would flash success and then silently drop the discount behind the
/// user's back. Rejections keep the sheet open with the keyboard up, so a
/// mistyped code is one edit away rather than a re-open.
class PaywallPromoCodeSheet extends StatefulWidget {
  const PaywallPromoCodeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        // The sheet builds off the navigator's context, outside the paywall's
        // provider scope — resolve the singleton cubit from DI instead.
        value: AppDI.injector.get<IapCubit>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: const PaywallPromoCodeSheet(),
        ),
      ),
    );
  }

  @override
  State<PaywallPromoCodeSheet> createState() => _PaywallPromoCodeSheetState();
}

class _PaywallPromoCodeSheetState extends State<PaywallPromoCodeSheet> {
  final TextEditingController _controller = TextEditingController();

  /// Until the user submits once, a plain `loading` status belongs to the
  /// paywall's own product fetch, not to this sheet.
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  /// The validate call and the plan reload it triggers are one wait to the
  /// user, even though the cubit reports them as two phases.
  bool _isBusy(IapState state) => state.isValidatingVoucher || (_hasSubmitted && state.status == MonetizationStatus.loading);

  void _apply(IapState state) {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty || _isBusy(state)) return;
    AppHaptic.select();
    setState(() => _hasSubmitted = true);
    unawaited(context.read<IapCubit>().applyVoucher(code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IapCubit, IapState>(
      listenWhen: (previous, current) =>
          previous.appliedVoucherCode != current.appliedVoucherCode || previous.status != current.status || previous.isValidatingVoucher != current.isValidatingVoucher,
      listener: (context, state) {
        if (!_hasSubmitted || _isBusy(state)) return;
        if (!state.hasAppliedVoucher) return;
        if (state.status != MonetizationStatus.success) return;
        AppHaptic.success();
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        final isBusy = _isBusy(state);
        final canApply = _controller.text.trim().isNotEmpty && !isBusy;
        final error = _hasSubmitted && !isBusy && state.hasVoucherFeedback && !state.hasAppliedVoucher ? _promoRejectMessage(state.voucherRejectReason) : null;

        // The keyboard offset already lifts the sheet, so only add the bottom
        // safe area when the keyboard is down — otherwise it reads as a gap.
        final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
        final bottomSafeArea = keyboardHeight > 0 ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomSafeArea),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.borderSecondary,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
              16.verticalSpace,
              _SheetHeader(onClose: () => Navigator.of(context).pop()),
              14.verticalSpace,
              _CodeField(
                controller: _controller,
                isBusy: isBusy,
                hasError: error != null,
                onSubmitted: () => _apply(state),
              ),
              if (error != null) ...[
                8.verticalSpace,
                _ErrorLine(message: error),
              ],
              20.verticalSpace,
              _ApplyButton(
                isBusy: isBusy,
                onPressed: canApply ? () => _apply(state) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            l10n.monetization.promoSheetTitle,
            style: AppStyle.textBold18.copyWith(color: AppCustomColor.textBrand),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.common.close,
          child: GestureDetector(
            onTap: () {
              AppHaptic.select();
              onClose();
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44.w,
              height: 44.h,
              child: Center(
                child: Icon(
                  Icons.close_rounded,
                  size: 20.w,
                  color: AppCustomColor.paywallPromoMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.isBusy,
    required this.hasError,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isBusy;
  final bool hasError;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppCustomColor.errorRed : AppCustomColor.borderSecondary;
    return TextField(
      controller: controller,
      autofocus: true,
      // readOnly, not `enabled: false`: disabling a focused field drops focus
      // and takes the keyboard with it, so a rejected code would cost an
      // extra tap to correct. readOnly blocks edits and keeps both.
      readOnly: isBusy,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      maxLength: 32,
      onSubmitted: (_) => onSubmitted(),
      style: AppStyle.text18.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppCustomColor.textBrand,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppCustomColor.backgroundWhite,
        // The box's height comes from THIS padding, deliberately — and neither
        // from a wrapping `SizedBox` nor with `isDense`. A SizedBox only bounds
        // the field and centres the stock ~48pt layout inside it, so the box
        // never actually grew; `isDense` then shrinks that layout further.
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
        border: _border(borderColor),
        enabledBorder: _border(borderColor),
        disabledBorder: _border(borderColor),
        focusedBorder: _border(hasError ? AppCustomColor.errorRed : AppCustomColor.brandPrimary),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14.r),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16.w,
            color: AppCustomColor.errorRed,
          ),
          6.horizontalSpace,
          Expanded(
            child: AppText(
              message,
              maxLines: 3,
              style: AppStyle.text14.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppCustomColor.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppCustomColor.brandPrimary,
          disabledBackgroundColor: AppCustomColor.buttonDisable,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
        ),
        child: isBusy
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : AppText(
                l10n.monetization.promoSheetApply,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onPressed == null ? AppCustomColor.paywallPromoMuted : AppCustomColor.textWhite,
                ),
              ),
      ),
    );
  }
}

/// Server reject reason → the line shown under the field.
String _promoRejectMessage(VoucherRejectReason reason) => switch (reason) {
  VoucherRejectReason.notFound => l10n.monetization.promoCodeErrorInvalid,
  VoucherRejectReason.expired => l10n.monetization.promoCodeErrorExpired,
  VoucherRejectReason.exhausted => l10n.monetization.promoCodeErrorExhausted,
  VoucherRejectReason.notApplicable => l10n.monetization.promoCodeErrorNotApplicable,
  // Not a failure from the user's point of view — they already have the better
  // deal — so the copy reassures rather than blames.
  VoucherRejectReason.notBetter => l10n.monetization.promoCodeErrorNotBetter,
  VoucherRejectReason.unavailable => l10n.monetization.promoCodeErrorUnavailable,
  VoucherRejectReason.unknown => l10n.monetization.promoCodeErrorGeneric,
};
