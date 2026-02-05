part of '../../setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();
    context.read<IapCubit>().loadIapProducts();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  void _trackView() {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackSettingDetailScrView();
    _hasTrackedView = true;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _hasTrackedScroll) return;
    if (_scrollController.position.pixels <= 0) return;
    AppService.instance.appTrackingService.trackSettingScroll();
    _hasTrackedScroll = true;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: CupertinoScaffold(
        topRadius: const Radius.circular(24),
        transitionBackgroundColor: AppCustomColor.backgroundWhite,
        body: SafePage(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 48.h),
            physics: const BouncingScrollPhysics(),
            children: [
              SettingHeader(),
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
                        onTap: () {
                          AppService.instance.appTrackingService.trackSettingLanguageClick();
                          const ChangeLanguageRoute().go(context);
                        },
                      ),
                      if (user.iapSubscriptions.isNotEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icCreditCard,
                          title: context.text.setting.settingRowUpgradePremium,
                          onTap: () {
                            AppService.instance.appTrackingService.trackSettingPremiumClick();
                            const ManageSubscriptionRoute().go(context);
                          },
                        ),
                      ],
                      if (user.iapSubscriptions.isEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icSet,
                          title: context.text.setting.settingRowRestorePurchase,
                          onTap: () {
                            AppService.instance.appTrackingService.trackSettingRestorePurchClick();
                            context.read<IapCubit>().restorePurchases();
                          },
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
                        onTap: () {
                          AppService.instance.appTrackingService.trackSettingTermClick();
                          'https://meup.training/terms-and-conditions.html'.launchURL();
                        },
                      ),
                      if (!user.anonymous)
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icLogOut,
                          title: context.text.setting.settingLogOut,
                          titleColor: AppCustomColor.errorRed,
                          iconColor: AppCustomColor.errorRed,
                          iconBackgroundColor: AppCustomColor.errorRed.op(.08),
                          showChevron: false,
                          onTap: () {
                            AppService.instance.appTrackingService.trackSettingLogoutClick();
                            context.read<AuthBloc>().add(const AuthEvent.logout());
                          },
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

class SettingHeader extends StatelessWidget {
  const SettingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.back(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppCustomColor.textTertiary,
            size: 24.w,
          ),
        ),
        AppText(
          context.text.setting.settingTitle,
          style: AppStyle.textBold16.copyWith(
            color: AppCustomColor.textPrimary,
            height: 1.25,
          ),
        ),
        SizedBox(width: 24.w),
      ],
    );
  }
}
