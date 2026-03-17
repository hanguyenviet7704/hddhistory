part of '../../setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<IapCubit>().loadIapProducts();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackView();
      _refreshNotificationState();
    });
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

  void _refreshNotificationState() {
    context.read<NotificationCubit>().refreshPermissionState(
      syncAuthorizedPreference: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _refreshNotificationState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _onNotificationToggle(bool value) {
    if (value) {
      AppService.instance.appTrackingService.trackSettingNotificationToggleOn();
    } else {
      AppService.instance.appTrackingService.trackSettingNotificationToggleOff();
    }
    context.read<NotificationCubit>().toggleFromSettings(value);
  }

  String _resolveNotificationSubtitle(BuildContext context, NotificationState state) {
    if (!state.hasLoadedPermissionState) {
      return '${context.l10n.setting.notificationEffectiveStatusLabel}: ${context.l10n.setting.notificationStatusDisabled}';
    }
    final permissionLabel = switch (state.permissionStatus) {
      NotificationPermissionStatus.authorized => context.l10n.setting.notificationPermissionAuthorized,
      NotificationPermissionStatus.provisional => context.l10n.setting.notificationPermissionProvisional,
      NotificationPermissionStatus.denied => context.l10n.setting.notificationPermissionDenied,
      NotificationPermissionStatus.notDetermined when state.isCapabilityUnavailable => context.l10n.setting.notificationPermissionNotApplicable,
      NotificationPermissionStatus.notDetermined => context.l10n.setting.notificationPermissionNotDetermined,
      NotificationPermissionStatus.unsupported => context.l10n.setting.notificationPermissionNotApplicable,
    };
    final effectiveStatus = state.isEffectivelyEnabled ? context.l10n.setting.notificationStatusEnabled : context.l10n.setting.notificationStatusDisabled;
    return '${context.l10n.setting.notificationEffectiveStatusLabel}: $effectiveStatus | ${context.l10n.setting.notificationPermissionStatusLabel}: $permissionLabel';
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
                    title: context.l10n.setting.settingSectionHeaderGeneral,
                    children: [
                      SettingOptionTile(
                        iconAsset: AppAsset.svg.app.icGlobe,
                        title: context.l10n.setting.settingRowLanguage,
                        trailingText: context.select((LocaleCubit cubit) => cubit.state.label),
                        onTap: () {
                          AppService.instance.appTrackingService.trackSettingLanguageClick();
                          const ChangeLanguageRoute().go(context);
                        },
                      ),
                      BlocBuilder<NotificationCubit, NotificationState>(
                        builder: (context, notificationState) {
                          return SettingSwitchTile(
                            iconAsset: AppAsset.svg.app.icBell,
                            title: context.l10n.setting.settingRowNoti,
                            subtitle: _resolveNotificationSubtitle(context, notificationState),
                            value: notificationState.isEffectivelyEnabled,
                            isLoading: notificationState.isLoading,
                            onChanged: notificationState.isCapabilityUnavailable || notificationState.isLoading ? null : _onNotificationToggle,
                          );
                        },
                      ),
                      if (user.iapSubscriptions.isNotEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icCreditCard,
                          title: context.l10n.setting.settingRowUpgradePremium,
                          onTap: () {
                            AppService.instance.appTrackingService.trackSettingPremiumClick();
                            const ManageSubscriptionRoute().go(context);
                          },
                        ),
                      ],
                      if (user.iapSubscriptions.isEmpty) ...[
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icSet,
                          title: context.l10n.setting.settingRowRestorePurchase,
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
                    title: context.l10n.setting.settingSectionHeaderAbout,
                    children: [
                      SettingOptionTile(
                        iconAsset: AppAsset.svg.app.icShieldPlus,
                        title: context.l10n.setting.settingAboutSectionTerm,
                        onTap: () {
                          AppService.instance.appTrackingService.trackSettingTermClick();
                          'https://meup.training/terms-and-conditions.html'.launchURL();
                        },
                      ),
                      if (!user.anonymous)
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icLogOut,
                          title: context.l10n.setting.settingLogOut,
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
          context.l10n.setting.settingTitle,
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
