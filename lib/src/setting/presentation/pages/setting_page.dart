part of '../../setting.dart';

enum SettingNotificationToggleAction { openSystemSettings, toggleInAppPreference }

@visibleForTesting
SettingNotificationToggleAction resolveSettingNotificationToggleAction({
  required TargetPlatform platform,
  required NotificationState state,
  required bool value,
}) {
  if (platform != TargetPlatform.iOS || !state.hasLoadedPermissionState) {
    return SettingNotificationToggleAction.toggleInAppPreference;
  }

  if (value) {
    return state.canRequestPermission ? SettingNotificationToggleAction.toggleInAppPreference : SettingNotificationToggleAction.openSystemSettings;
  }

  return state.isPermissionGranted ? SettingNotificationToggleAction.openSystemSettings : SettingNotificationToggleAction.toggleInAppPreference;
}

@immutable
@visibleForTesting
class SettingNotificationRefreshRequest {
  const SettingNotificationRefreshRequest({
    required this.syncAuthorizedPreference,
    required this.syncPreferenceToPermissionState,
  });

  final bool syncAuthorizedPreference;
  final bool syncPreferenceToPermissionState;
}

@visibleForTesting
SettingNotificationRefreshRequest resolveSettingNotificationRefreshRequest({
  required bool hasPendingSystemSettingsSync,
}) {
  final syncPreferenceToPermissionState = hasPendingSystemSettingsSync;
  return SettingNotificationRefreshRequest(
    syncAuthorizedPreference: !syncPreferenceToPermissionState,
    syncPreferenceToPermissionState: syncPreferenceToPermissionState,
  );
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedView = false;
  bool _hasPendingSystemSettingsSync = false;

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
    final refreshRequest = resolveSettingNotificationRefreshRequest(
      hasPendingSystemSettingsSync: _hasPendingSystemSettingsSync,
    );
    _hasPendingSystemSettingsSync = false;
    context.read<NotificationCubit>().refreshPermissionState(
      syncAuthorizedPreference: refreshRequest.syncAuthorizedPreference,
      syncPreferenceToPermissionState: refreshRequest.syncPreferenceToPermissionState,
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
    unawaited(_handleNotificationToggle(value));
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      AppService.instance.appTrackingService.trackSettingNotificationToggleOn();
    } else {
      AppService.instance.appTrackingService.trackSettingNotificationToggleOff();
    }

    final notificationCubit = context.read<NotificationCubit>();
    final resolvedState = notificationCubit.state.hasLoadedPermissionState
        ? notificationCubit.state
        : await notificationCubit.refreshPermissionState(
            syncAuthorizedPreference: !_hasPendingSystemSettingsSync,
          );
    if (!mounted) return;
    final toggleAction = resolveSettingNotificationToggleAction(
      platform: defaultTargetPlatform,
      state: resolvedState,
      value: value,
    );

    if (toggleAction == SettingNotificationToggleAction.openSystemSettings) {
      _hasPendingSystemSettingsSync = true;
      await notificationCubit.openSettingsFromSettings();
      return;
    }

    await notificationCubit.toggleFromSettings(value);
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
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 48.h),
            physics: const BouncingScrollPhysics(),
            children: [
              SettingHeader(),
              8.verticalSpace,
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
                        BlocBuilder<IapCubit, IapState>(
                          buildWhen: (previous, current) => previous.status != current.status,
                          builder: (context, iapState) {
                            final bool isRestoring = iapState.status == MonetizationStatus.restoring;
                            return SettingOptionTile(
                              iconAsset: AppAsset.svg.app.icSet,
                              title: context.l10n.setting.settingRowRestorePurchase,
                              isLoading: isRestoring,
                              onTap: () {
                                AppService.instance.appTrackingService.trackSettingRestorePurchClick();
                                context.read<IapCubit>().restorePurchases();
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              8.verticalSpace,
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
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (previous, current) => previous.status != current.status,
                          builder: (context, authState) {
                            final bool isLoggingOut = authState.status == AuthStatus.loading;
                            return SettingOptionTile(
                              iconAsset: AppAsset.svg.app.icLogOut,
                              title: context.l10n.setting.settingLogOut,
                              titleColor: AppCustomColor.errorRed,
                              iconColor: AppCustomColor.errorRed,
                              iconBackgroundColor: AppCustomColor.errorRed.op(.08),
                              showChevron: false,
                              isLoading: isLoggingOut,
                              onTap: () {
                                AppService.instance.appTrackingService.trackSettingLogoutClick();
                                context.read<AuthBloc>().add(const AuthEvent.logout());
                              },
                            );
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
          style: AppStyle.textBold20.copyWith(
            color: AppCustomColor.textPrimary,
            height: 1.5,
          ),
        ),
        SizedBox(width: 24.w),
      ],
    );
  }
}
