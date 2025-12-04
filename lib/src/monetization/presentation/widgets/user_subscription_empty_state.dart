part of '../../monetization.dart';

class UserSubscriptionEmptyState extends StatelessWidget {
  const UserSubscriptionEmptyState({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppCustomColor.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 72.w,
                width: 72.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.workspace_premium_outlined, color: AppCustomColor.brandPrimary, size: 36.w),
              ),
              16.verticalSpace,
              AppText(
                t.monetization.manageEmptyTitle,
                textAlign: TextAlign.center,
                style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary, height: 1.3),
              ),
              10.verticalSpace,
              AppText(
                t.monetization.manageEmptyDescription,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        24.verticalSpace,
        AppButton.primary(
          fullWidthBtn: true,
          height: 56.h,
          child: t.monetization.manageUpgradeCta,
          onPressed: onUpgrade,
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
