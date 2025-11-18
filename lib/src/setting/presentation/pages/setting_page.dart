part of '../../setting.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserEntity user = context.select((UserCubit cubit) => cubit.state.user);

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 48.h),
          physics: const BouncingScrollPhysics(),
          children: [
            SettingProfileCard(user: user),
            SizedBox(height: 24.h),
            SettingSectionCard(
              title: context.text.settingGeneralSection,
              children: [
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icBell,
                  title: context.text.settingNotificationsLabel,
                  trailingText: context.text.settingNotificationsDefaultTime,
                ),
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icGlobe,
                  title: context.text.settingLanguageLabel,
                  trailingText: context.text.settingLanguageDefaultValue,
                ),
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icCreditCard,
                  title: context.text.settingUpgradePremiumLabel,
                ),
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icSet,
                  title: context.text.settingRestorePurchaseLabel,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SettingSectionCard(
              title: context.text.settingAboutSection,
              children: [
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icShieldPlus,
                  title: context.text.settingTermsConditionsLabel,
                ),
                SettingOptionTile(
                  iconAsset: AppAsset.svg.app.icLogOut,
                  title: context.text.settingLogoutLabel,
                  titleColor: AppCustomColor.errorRed,
                  iconColor: AppCustomColor.errorRed,
                  iconBackgroundColor: AppCustomColor.errorRed.op(.08),
                  showChevron: false,
                  onTap: () => context.read<AuthBloc>().add(const AuthEvent.logout()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
