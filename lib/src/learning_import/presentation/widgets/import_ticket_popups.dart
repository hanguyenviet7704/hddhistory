part of '../../learning_import.dart';

/// The two things a ticket count can mean, each as its own popup (design
/// `4 · Explore` → `import#ticketinfo` / `import#ticketinfofree`).
///
/// Both hang off the same affordance — the ticket pill on the import screen —
/// and which one opens is decided by what the reader could do with a ticket:
///
/// - **Premium**: [showImportTicketInfoPopup] answers "what is a ticket, how
///   many do I have, when do they come back". Nothing to sell, so nothing is
///   sold.
/// - **Not Premium**: [showImportTicketUpsellPopup] — the same count headline
///   (the design titles this popup with the number too, "1 ticket left", and
///   at zero it reads "0 tickets left"), but the one useful thing under it is
///   what Premium would change.
///
/// A premium reader at zero gets the INFO popup rather than an upsell: they
/// already bought the thing being advertised, and the only fact they need is
/// when the tickets come back.

/// Scrim shade from the design (#0B0B10 at 55%).
const Color _kTicketScrim = Color(0x8C0B0B10);

/// Whole days until [resetsAt], never less than one.
///
/// Rounded UP: the design line is "reset in 3 days", and a reset 26 hours away
/// is "in 2 days" to a person — "in 1 day" would promise tomorrow-morning what
/// arrives tomorrow-night. Zero never shows: a reset already past still says
/// "in 1 day" for the moments before the refreshed quota arrives.
int importTicketResetInDays(DateTime resetsAt) {
  final days = (resetsAt.difference(DateTime.now()).inHours / 24).ceil();
  return days < 1 ? 1 : days;
}

/// What the reader has, and when it refills.
Future<void> showImportTicketInfoPopup(
  BuildContext context, {
  required ImportQuotaEntity quota,
}) {
  final l10n = context.l10n.learningImport;

  return showDialog<void>(
    context: context,
    barrierColor: _kTicketScrim,
    builder: (dialogContext) => _TicketPopupCard(
      title: l10n.ticketInfoTitle(count: quota.remaining),
      body: l10n.ticketInfoBody,
      // Only when the server actually told us — a made-up reset date is worse
      // than none, because this line is the whole reason a reader at zero opens
      // this popup.
      resetNote: quota.resetsAt == null
          ? null
          : l10n.ticketInfoReset(
              count: quota.limit,
              days: importTicketResetInDays(quota.resetsAt!),
            ),
      primaryLabel: l10n.ticketInfoCta,
      onPrimary: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// The same count, and Premium as the way to raise it.
Future<void> showImportTicketUpsellPopup(
  BuildContext context, {
  required ImportQuotaEntity quota,
}) {
  final l10n = context.l10n.learningImport;

  return showDialog<void>(
    context: context,
    barrierColor: _kTicketScrim,
    builder: (dialogContext) => _TicketPopupCard(
      title: l10n.ticketInfoTitle(count: quota.remaining),
      body: l10n.noTicketBody(premiumLimit: quota.premiumLimit),
      primaryLabel: l10n.noTicketCta,
      onPrimary: () {
        Navigator.of(dialogContext).pop();
        AppDI.injector.get<IapCubit>().setPaywallEntryPoint(
          PaywallEntryPoint.learningImport,
        );
        const PaywallRoute().push(context);
      },
      dismissLabel: l10n.noTicketDismiss,
      onDismiss: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// The shared shell: ticket mark, a sentence, one filled action.
class _TicketPopupCard extends StatelessWidget {
  const _TicketPopupCard({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.resetNote,
    this.dismissLabel,
    this.onDismiss,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// The "reset in N days" strip. Absent on the upsell, where the reader has no
  /// allowance to come back to.
  final String? resetNote;

  final String? dismissLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppCustomColor.backgroundWhite,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFB),
                borderRadius: BorderRadius.circular(20.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 32.w,
                color: AppCustomColor.brandPrimary,
              ),
            ),
            16.verticalSpace,
            AppText(
              title,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
            ),
            8.verticalSpace,
            AppText(
              body,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                height: 1.5,
                color: AppCustomColor.textTertiary,
              ),
              maxLines: 4,
            ),
            if (resetNote != null) ...[
              18.verticalSpace,
              _ResetStrip(text: resetNote!),
            ],
            22.verticalSpace,
            _PrimaryButton(label: primaryLabel, onTap: onPrimary),
            if (dismissLabel != null && onDismiss != null) ...[
              10.verticalSpace,
              _DismissRow(label: dismissLabel!, onTap: onDismiss!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResetStrip extends StatelessWidget {
  const _ResetStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 18.w,
            color: AppCustomColor.brandPrimary,
          ),
          10.horizontalSpace,
          Expanded(
            child: AppText(
              text,
              style: AppStyle.textBold12.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: AppCustomColor.textSecondary,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(99.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            style: AppStyle.textBold16.copyWith(
              fontSize: 15.5.sp,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissRow extends StatelessWidget {
  const _DismissRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: 44.h,
          child: Center(
            child: AppText(
              label,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w600,
                color: AppCustomColor.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
