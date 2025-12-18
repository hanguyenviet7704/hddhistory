part of '../../setting.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<IapCubit>().loadIapProducts();
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: CupertinoScaffold(
        topRadius: const Radius.circular(24),
        transitionBackgroundColor: AppCustomColor.backgroundWhite,
        body: SafeBody(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 48.h),
            physics: const BouncingScrollPhysics(),
            children: [
              SettingProfileCard(),
              24.verticalSpace,
              BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                selector: (state) => state.user,
                builder: (context, user) {
                  if (user.iapSubscriptions.isNotEmpty) return SizedBox.shrink();

                  return SettingPreminumCard(
                    onUpgrade: () => const PaywallRoute().push(context),
                  );
                },
              ),
              24.verticalSpace,
              BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                selector: (state) => state.user,
                builder: (context, user) {
                  return SettingSectionCard(
                    title: context.text.setting.settingSectionHeaderGeneral,
                    children: [
                      SettingOptionTile(
                        iconAsset: AppAsset.svg.app.icGlobe,
                        title: context.text.setting.settingRowLanguage,
                        trailingText: context.select((LocaleCubit cubit) => cubit.state.label),
                        onTap: () => const ChangeLanguageRoute().go(context),
                      ),
                      if (user.iapSubscriptions.isNotEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icCreditCard,
                          title: context.text.setting.settingRowUpgradePremium,
                          onTap: () => const ManageSubscriptionRoute().go(context),
                        ),
                      ],
                      if (user.iapSubscriptions.isEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icSet,
                          title: context.text.setting.settingRowRestorePurchase,
                          onTap: () => context.read<IapCubit>().restorePurchases(),
                        ),
                      ],
                    ],
                  );
                },
              ),
              24.verticalSpace,
              BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                selector: (state) => state.user,
                builder: (context, user) {
                  return SettingSectionCard(
                    title: context.text.setting.settingSectionHeaderAbout,
                    children: [
                      SettingOptionTile(
                        iconAsset: AppAsset.svg.app.icShieldPlus,
                        title: context.text.setting.settingAboutSectionTerm,
                        onTap: 'https://meup.training/terms-and-conditions.html'.launchURL,
                      ),
                      if (!user.anonymous)
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icLogOut,
                          title: context.text.setting.settingLogOut,
                          titleColor: AppCustomColor.errorRed,
                          iconColor: AppCustomColor.errorRed,
                          iconBackgroundColor: AppCustomColor.errorRed.op(.08),
                          showChevron: false,
                          onTap: () => context.read<AuthBloc>().add(const AuthEvent.logout()),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
