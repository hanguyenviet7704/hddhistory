part of '../../monetization.dart';

class UserSubscriptionActiveCard extends StatelessWidget {
  const UserSubscriptionActiveCard({super.key, required this.subscription});

  final IapSubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final text = t.monetization;
    final product = IapProductEntity(productId: subscription.productId);
    final planName = subscription.productId.isNotEmpty ? subscription.productId : text.manageDefaultPlan;
    final billingPeriod = product.periodLabel;
    final nextBilling = _formatDate(subscription.currentPeriodEnd, context);
    final autoRenewLabel = subscription.autoRenewing ? text.manageAutoRenewOn : text.manageAutoRenewOff;
    final statusConfig = _statusConfig(subscription.status, text);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48.w,
                width: 48.w,
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, color: AppCustomColor.brandPrimary, size: 26.w),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      planName,
                      maxLines: 1,
                      style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary, height: 1.2),
                    ),
                    6.verticalSpace,
                    AppText(
                      billingPeriod,
                      maxLines: 1,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: statusConfig.label, color: statusConfig.color, background: statusConfig.background),
            ],
          ),
          16.verticalSpace,
          const Divider(height: 1, color: AppCustomColor.borderSecondary),
          16.verticalSpace,
          _InfoRow(label: text.manageBillingPeriod, value: billingPeriod),
          12.verticalSpace,
          _InfoRow(label: text.manageNextBillingDate, value: nextBilling),
          12.verticalSpace,
          _InfoRow(label: text.manageAutoRenew, value: autoRenewLabel),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) return '--';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }

  _StatusConfig _statusConfig(SubscriptionStatus status, TranslationsMonetization text) {
    switch (status) {
      case SubscriptionStatus.active:
        return _StatusConfig(
          label: text.manageStatusActive,
          color: AppCustomColor.successGreen,
          background: AppCustomColor.backgroundSuccess,
        );
      case SubscriptionStatus.grace:
        return _StatusConfig(
          label: text.manageStatusGrace,
          color: AppCustomColor.brandPrimary,
          background: AppCustomColor.brandPrimary50,
        );
      case SubscriptionStatus.onHold:
        return _StatusConfig(
          label: text.manageStatusOnHold,
          color: AppCustomColor.errorRed,
          background: AppCustomColor.backgroundError,
        );
      case SubscriptionStatus.canceled:
        return _StatusConfig(
          label: text.manageStatusCanceled,
          color: AppCustomColor.textSecondary,
          background: AppCustomColor.surfaceMuted,
        );
      case SubscriptionStatus.expired:
        return _StatusConfig(
          label: text.manageStatusExpired,
          color: AppCustomColor.errorRed,
          background: AppCustomColor.backgroundError,
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppText(
            label,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary, height: 1.4),
          ),
        ),
        12.horizontalSpace,
        Flexible(
          child: AppText(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: AppText(
        label,
        maxLines: 1,
        style: AppStyle.text12.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusConfig {
  _StatusConfig({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;
}
