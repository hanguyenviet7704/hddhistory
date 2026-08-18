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
    AppService.instance.appTrackingService.trackSettingScrView();
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
    AppHaptic.select();
    unawaited(_handleNotificationToggle(value));
  }

  Future<void> _handleNotificationToggle(bool value) async {
    AppService.instance.appTrackingService.trackSettingNotifToggle(value);

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
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      body: CupertinoScaffold(
        topRadius: const Radius.circular(24),
        transitionBackgroundColor: AppCustomColor.backgroundWhite,
        // ThemedBackground sits INSIDE the CupertinoScaffold, not around it, and
        // that is the whole trick: CupertinoScaffold always paints an opaque
        // `Container(color: transitionBackgroundColor)` under its body, so the
        // shell's background never showed through here no matter what colour the
        // Scaffold above used — Settings was the one screen that ignored the
        // reader's theme. Painting the background above that container fixes it
        // while leaving `transitionBackgroundColor` (which also decides the
        // status-bar style of sheets pushed from here, e.g. the theme picker
        // itself) exactly as it was. No-ops on the default preset.
        body: ThemedBackground(
          child: SafePage(
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
                          AppService.instance.appTrackingService.trackSettingLanguageClick(context.read<LocaleCubit>().state.label);
                          const ChangeLanguageRoute().go(context);
                        },
                      ),
                      // Theme moved HERE from Home's header (design `6 ·
                      // Profile` → Settings): Home's slot now carries the
                      // avatar, and a background you change once a month
                      // belongs with the other once-a-month switches.
                      BlocBuilder<StudyThemeCubit, StudyThemeState>(
                        bloc: AppDI.injector.get<StudyThemeCubit>(),
                        buildWhen: (previous, current) => previous.preset.id != current.preset.id,
                        builder: (context, themeState) {
                          return SettingOptionTile(
                            iconAsset: AppAsset.svg.app.icChangeTheme,
                            title: context.l10n.setting.settingRowTheme,
                            trailingText: themeState.preset.name.trim().isEmpty ? 'Default' : themeState.preset.name,
                            onTap: () => ChangeBackgroundSheet.show(context, source: 'settings'),
                          );
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
                      BlocBuilder<HapticSettingCubit, bool>(
                        builder: (context, hapticEnabled) {
                          return SettingSwitchTile(
                            iconAsset: AppAsset.svg.app.icHaptic,
                            title: context.l10n.setting.settingHapticLabel,
                            value: hapticEnabled,
                            onChanged: (v) {
                              AppService.instance.appTrackingService.trackSettingHapticToggle(v);
                              context.read<HapticSettingCubit>().setEnabled(v);
                            },
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
                      // Debug-only shortcut to replay onboarding — the splash
                      // skips it once onboarded (or when dev remote-config
                      // disables it), so there's no other way to reach it on a
                      // set-up device. Stripped from release by kDebugMode.
                      if (kDebugMode)
                        SettingOptionTile(
                          iconAsset: AppAsset.svg.app.icShieldPlus,
                          title: '[DEBUG] Xem Onboarding',
                          onTap: () => const OnboardV2Route().go(context),
                        ),
                    ],
                  );
                },
              ),
              8.verticalSpace,
              const _AccountSection(),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// Confirm-before-logout sheet. Reuses existing l10n (`settingLogOut`,
/// `common.cancel`) so it adds no new localization keys. Returns true only
/// when the user explicitly confirms.
Future<bool> _confirmLogout(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              sheetContext.l10n.setting.settingLogOut,
              textAlign: TextAlign.center,
              style: AppStyle.text20.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            24.verticalSpace,
            DButton(
              text: sheetContext.l10n.setting.settingLogOut,
              size: Size(double.infinity, 54.h),
              backgroundColor: AppCustomColor.errorRed,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            12.verticalSpace,
            DButton(
              text: sheetContext.l10n.common.cancel,
              buttonType: DButtonType.text,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textSecondary),
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class SettingHeader extends StatelessWidget {
  const SettingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            AppHaptic.select();
            AppService.instance.appTrackingService.trackSettingBackClick();
            context.back();
          },
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            // Title bar sits on the page background, so it follows the study
            // theme — light ink on a dark custom background.
            color: studyThemeOnBg(context, AppCustomColor.textTertiary),
            size: 24.w,
          ),
        ),
        AppText(
          context.l10n.setting.settingTitle,
          style: AppStyle.textBold20.copyWith(
            color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            height: 1.5,
          ),
        ),
        SizedBox(width: 24.w),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account actions — their own card at the bottom (design `Settings`)
// ---------------------------------------------------------------------------

/// Sign in for a guest; sign out + delete account once signed in.
///
/// Kept apart from the "Giới thiệu" card the sign-out row used to live in: these
/// are the destructive/session actions, and the design separates them so a
/// mis-tap next to "Điều khoản" is less likely.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, UserEntity>(
      selector: (state) => state.user,
      builder: (context, user) {
        // A guest has no session to end and nothing deletable behind a login,
        // so the card collapses to the one action that applies.
        if (user.anonymous) {
          return SettingSectionCard(
            children: [
              SettingOptionTile(
                key: const Key('setting-sign-in-row'),
                iconWidget: Icon(
                  Icons.login_rounded,
                  size: 22.w,
                  color: AppCustomColor.brandPrimary,
                ),
                title: context.l10n.auth.authLogIn,
                titleColor: AppCustomColor.brandPrimary,
                onTap: () {
                  AppHaptic.select();
                  const RegisterRoute().push(context);
                },
              ),
            ],
          );
        }

        return SettingSectionCard(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) => previous.status != current.status,
              builder: (context, authState) {
                final bool isBusy = authState.status == AuthStatus.loading;
                return SettingOptionTile(
                  key: const Key('setting-sign-out-row'),
                  iconAsset: AppAsset.svg.app.icLogOut,
                  title: context.l10n.setting.settingLogOut,
                  titleColor: AppCustomColor.errorRed,
                  iconColor: AppCustomColor.errorRed,
                  showChevron: false,
                  isLoading: isBusy,
                  onTap: () async {
                    // Confirm first — logout instantly dropped the session on a
                    // single tap before, with no undo.
                    final authBloc = context.read<AuthBloc>();
                    final confirmed = await _confirmLogout(context);
                    if (!confirmed) return;
                    AppService.instance.appTrackingService.trackSettingLogoutClick();
                    authBloc.add(const AuthEvent.logout());
                  },
                );
              },
            ),
            SettingOptionTile(
              key: const Key('setting-delete-account-row'),
              iconWidget: Icon(
                Icons.delete_outline_rounded,
                size: 22.w,
                color: AppCustomColor.errorRed,
              ),
              title: context.l10n.setting.settingProfileDesstructiveButton,
              titleColor: AppCustomColor.errorRed,
              showChevron: false,
              onTap: () {
                AppHaptic.select();
                final authBloc = context.read<AuthBloc>();
                final userId = user.id;
                // The dialog awaits this callback before dismissing, so a failed
                // deletion stays on screen instead of looking like it worked.
                // Dialog, event and API were all left in place when the entry
                // point was removed in Aug 2026 — this only restores the way in
                // (App Store 5.1.1(v) requires one).
                ProfileDeleteDialog.show(
                  context,
                  onConfirm: () async {
                    if (userId.isEmpty) return;
                    authBloc.add(AuthEvent.deleteAccountPermanently(userId));
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
