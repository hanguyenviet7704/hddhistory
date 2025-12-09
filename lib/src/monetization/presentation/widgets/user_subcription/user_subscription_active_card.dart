part of '../../../monetization.dart';

class UserSubscriptionActiveCard extends StatelessWidget {
  const UserSubscriptionActiveCard({super.key, required this.subscription});

  final IapSubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final text = t.monetization;
    final planName = _planName(subscription.productId, text);
    final statusLabel = _statusLabel(subscription.status, text);
    final nextBilling = _nextBillingText(
      productId: subscription.productId,
      date: subscription.currentPeriodEnd,
      context: context,
      text: text,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 36.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            planName,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textSecondary,
              height: 1.5,
            ),
          ),
          6.verticalSpace,
          AppText(
            statusLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppStyle.text12.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.brandPrimary,
              height: 1.5,
            ),
          ),
          8.verticalSpace,
          AppText(
            nextBilling,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w500,
              color: AppCustomColor.textSecondary,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }

  String _planName(String productId, TranslationsMonetizationEn text) {
    final id = productId.toLowerCase();
    if (id.contains('year')) return text.managePlanYearly;
    if (id.contains('month')) return text.managePlanMonthly;
    if (id.contains('week')) return text.managePlanWeekly;
    if (id.contains('life')) return text.managePlanLifetime;
    return text.manageDefaultPlan;
  }

  String _nextBillingText({
    required String productId,
    required DateTime? date,
    required BuildContext context,
    required TranslationsMonetizationEn text,
  }) {
    final id = productId.toLowerCase();
    if (id.contains('life')) return text.manageNoNextBilling;
    if (date == null) return text.manageNextBillingUnknown;

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = DateFormat.yMMMMd(locale).format(date.toLocal());
    return text.manageNextBillingOn(date: formatted);
  }

  String _statusLabel(SubscriptionStatus status, TranslationsMonetizationEn text) {
    switch (status) {
      case SubscriptionStatus.active:
        return text.manageStatusActive;
      case SubscriptionStatus.grace:
        return text.manageStatusGrace;
      case SubscriptionStatus.onHold:
        return text.manageStatusOnHold;
      case SubscriptionStatus.canceled:
        return text.manageStatusCanceled;
      case SubscriptionStatus.expired:
        return text.manageStatusExpired;
    }
  }
}
