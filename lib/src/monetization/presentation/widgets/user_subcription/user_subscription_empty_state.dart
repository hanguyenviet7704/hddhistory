part of '../../../monetization.dart';

class UserSubscriptionEmptyState extends StatelessWidget {
  const UserSubscriptionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Center(
        child: AppText(
          t.monetization.manageNoActiveSubscription,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w500,
            color: AppCustomColor.textTertiary,
            height: 1.75,
          ),
        ),
      ),
    );
  }
}
