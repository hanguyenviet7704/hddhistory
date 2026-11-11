part of '../../../setting.dart';

class SettingPreminumCard extends StatelessWidget {
  const SettingPreminumCard({super.key, this.onUpgrade});

  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final text = context.l10n.setting;
    void handleUpgrade() {
      AppService.instance.appTrackingService.trackSettingPremiumClick();
      AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.settingPre);
      if (onUpgrade != null) {
        onUpgrade!();
        return;
      }
      const PaywallRoute().push(context);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.settingPremiumTitle,
                  style: AppStyle.textBold16.copyWith(
                    color: AppCustomColor.textWhite,
                    height: 1.2,
                  ),
                ),
                6.verticalSpace,
                Text(
                  text.settingPremiumSubtitle,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textWhite.withValues(alpha: 0.84),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          _UpgradeButton(
            label: text.settingPremiumUpgradeCta,
            onTap: handleUpgrade,
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100.r),
      child: InkWell(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        borderRadius: BorderRadius.circular(100.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            label,
            style: AppStyle.textBold14.copyWith(
              color: AppCustomColor.brandPrimary,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
