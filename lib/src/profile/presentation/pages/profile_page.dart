part of '../../profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _hasTrackedView = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;

  @override
  void initState() {
    super.initState();
    context.read<IapCubit>().loadIapProducts();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackView();
      // Recover from a failed/skipped identity load (e.g. it lost the race
      // against skillsets inside HomeCubit's Future.wait) instead of showing
      // a blank identity/premium banner until the user pull-to-refreshes or
      // restarts the app. No-op when data is present.
      unawaited(context.read<ProfileCubit>().ensureProfileLoaded());
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

  Future<void> _onRefresh() async {
    context.read<ProfileCubit>().loadUser();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
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
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 2) {
          // Returning to the Profile tab with a blank identity (initial
          // retry also failed) → try again.
          unawaited(context.read<ProfileCubit>().ensureProfileLoaded());
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBEBBF6), Color(0xFFDFDDFE)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Scaffold(
          key: const Key('profile-page'),
          backgroundColor: Colors.transparent,
          body: SafeBody(
            child: Column(
              children: [
                _ProfileHeader(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    child: BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
                      buildWhen: (previous, current) => previous.status != current.status || previous.achievenments != current.achievenments,
                      builder: (context, state) {
                        final bool isLoading = state.status == AchievenmentProgressStatus.loading && state.achievenments.isEmpty;

                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.status == AchievenmentProgressStatus.failure && state.achievenments.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 48.w, color: AppCustomColor.textTertiary),
                                  16.verticalSpace,
                                  AppText(
                                    state.errorMessage ?? '',
                                    textAlign: TextAlign.center,
                                    style: AppStyle.text14.copyWith(
                                      color: AppCustomColor.textSecondary,
                                    ),
                                  ),
                                  16.verticalSpace,
                                  OutlinedButton(
                                    onPressed: _onRefresh,
                                    child: AppText(
                                      context.l10n.monetization.retry,
                                      style: AppStyle.text14.copyWith(
                                        color: AppCustomColor.brandPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView(
                            controller: _scrollController,
                            // Clear the floating nav bar so the last row isn't covered.
                            // Larger than other pages: this page's content is short
                            // and may not scroll, so the padding must keep the static
                            // card clear of the nav overlay on its own. Derived from
                            // the nav bar's ACTUAL height (varies with the device's
                            // safe-area inset) instead of a flat guess, or it falls
                            // short on devices with a taller inset.
                            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, floatingNavBarHeight(context) + 20.h),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              UserAchievementList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: avatar • name • email • settings icon • premium banner
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileIdentityRow(),
          _PremiumBanner(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identity row: avatar + name/email on left, settings icon on right
// ---------------------------------------------------------------------------

class _ProfileIdentityRow extends StatelessWidget {
  const _ProfileIdentityRow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, UserEntity>(
      selector: (state) => state.user,
      builder: (context, user) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Guests can tap their avatar to open the login screen.
            if (user.anonymous)
              Semantics(
                button: true,
                label: context.l10n.auth.authLogIn,
                child: GestureDetector(
                  key: const Key('profile-avatar-login-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => const RegisterRoute().push(context),
                  child: _ProfileAvatar(user: user),
                ),
              )
            else
              _ProfileAvatar(user: user),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    _resolveName(user, context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.textBold24.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  4.verticalSpace,
                  AppText(
                    _resolveEmail(user),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            16.horizontalSpace,
            Semantics(
              label: context.l10n.setting.settingTitle,
              button: true,
              child: GestureDetector(
                key: const Key('profile-settings-button'),
                onTap: () {
                  AppService.instance.appTrackingService.trackSettingDetailClick();
                  SettingRoute().go(context);
                },
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    AppAsset.svg.app.icSetting,
                    width: 24.w,
                    height: 24.w,
                    colorFilter: const ColorFilter.mode(
                      AppCustomColor.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _resolveName(UserEntity user, BuildContext context) {
    final trimmed = user.name.trim();
    return trimmed.isNotEmpty ? trimmed : context.l10n.setting.settingGuestName;
  }

  String _resolveEmail(UserEntity user) {
    final trimmed = user.email.trim();
    return trimmed.isNotEmpty ? trimmed : '';
  }
}

// ---------------------------------------------------------------------------
// Avatar: network image with ClipOval, or initial-letter fallback
// ---------------------------------------------------------------------------

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final double size = 48.w;

    if (user.avatar.trim().isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: CacheNetworkGraphic(
            url: user.avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final String initial = _buildInitial(context);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppCustomColor.brandPrimary700,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppStyle.textBold20.copyWith(
          color: AppCustomColor.backgroundWhite,
        ),
      ),
    );
  }

  String _buildInitial(BuildContext context) {
    String ref = user.name.trim();
    if (ref.isEmpty) ref = user.email.trim();
    if (ref.isEmpty) ref = context.l10n.setting.settingGuestName;
    return String.fromCharCode(ref.runes.first).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Premium banner: shown only when user is not premium
// ---------------------------------------------------------------------------

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.user.isPremium,
      builder: (context, isPremium) {
        // The banner is what normally separates the identity row from the
        // white sheet below; when it's hidden for premium users, keep a
        // spacer so the email doesn't sit flush against the sheet edge.
        if (isPremium) return SizedBox(height: 16.h);

        final text = context.l10n.setting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            12.verticalSpace,
            Semantics(
              button: true,
              label: text.settingPremiumTitle,
              child: GestureDetector(
                key: const Key('profile-premium-banner'),
                onTap: () {
                  AppService.instance.appTrackingService.trackSettingPremiumClick();
                  AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.profile);
                  const PaywallRoute().push(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.streakActive,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              text.settingPremiumTitle,
                              style: AppStyle.textBold16.copyWith(
                                color: AppCustomColor.backgroundWhite,
                                height: 1.5,
                              ),
                            ),
                            AppText(
                              text.settingPremiumSubtitle,
                              style: AppStyle.text12.copyWith(
                                color: AppCustomColor.backgroundWhite.withValues(alpha: 0.8),
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      ),
                      16.horizontalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: AppCustomColor.backgroundWhite,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: AppText(
                          text.settingPremiumUpgradeCta,
                          style: AppStyle.textBold12.copyWith(
                            color: AppCustomColor.brandPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
