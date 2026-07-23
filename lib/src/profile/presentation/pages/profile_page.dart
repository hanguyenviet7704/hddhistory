part of '../../profile.dart';

// ---------------------------------------------------------------------------
// Shared design tokens for the redesigned Profile + Achievements screens
// (design: flat lavender background, soft white cards — mirrors the same
// treatment already shipped on Home, see home_page.dart's _homeCardShadow /
// _homeBackground). Declared once here; visible to every `part of
// profile.dart` file in this library (e.g. achievements_full_page.dart).
// ---------------------------------------------------------------------------

/// Flat lavender page background behind the white cards (design #F4F4FB).
const Color _profileBackground = Color(0xFFF4F4FB);

/// Muted secondary text/icon color used throughout this design (design
/// #9AA4B2) — close to but distinct from the shared textTertiary token, so
/// it's kept as a scoped one-off rather than widened into AppCustomColor.
const Color _profileMutedTextColor = Color(0xFF9AA4B2);

/// Progress-bar track color used by both the Learning Progress rows and the
/// Achievements badge grid (design #E7E9F2).
const Color _profileProgressTrackColor = Color(0xFFE7E9F2);

/// Soft shadow shared by every white card on this redesign (design:
/// `0 6px 18px rgba(37,37,37,.05)`).
List<BoxShadow> get _profileCardShadow => [
  BoxShadow(
    color: const Color(0x0D252525),
    offset: Offset(0, 6.h),
    blurRadius: 18.r,
  ),
];

/// Rotating pastel tint palette for the Learning Progress category icon
/// tiles — the API has no per-skillset color, so tiles cycle through a small
/// set of existing soft theme tokens for visual variety instead of one flat
/// tint everywhere.
const List<Color> _profileCategoryTints = [
  AppCustomColor.backgroundBrandSoft,
  AppCustomColor.backgroundError,
  AppCustomColor.backgroundSuccess,
  AppCustomColor.brandPrimary50,
  AppCustomColor.backgroundGray,
  AppCustomColor.surfaceMuted,
];

/// Inlined design icons (verbatim from the design SVGs / markup) so they match
/// 1:1 without an asset-bundle rebuild.
const String _kMyCourseSvg =
    '''<svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H9a2 2 0 0 1 2 2v13a1.5 1.5 0 0 0-1.5-1.5h-4A1.5 1.5 0 0 1 4 16V5.5Z" stroke="#4B44CA" stroke-width="1.8" stroke-linejoin="round"/><path d="M20 5.5A1.5 1.5 0 0 0 18.5 4H15a2 2 0 0 0-2 2v13a1.5 1.5 0 0 1 1.5-1.5h4A1.5 1.5 0 0 0 20 16V5.5Z" stroke="#4B44CA" stroke-width="1.8" stroke-linejoin="round"/></svg>''';
const String _kStreakGraySvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.40039 19.4798C6.40039 25.6687 11.7915 28 16.9462 28C21.959 28 25.6004 23.1179 25.6004 18.7426C25.6004 12.1567 19.2634 3.77267 16.4733 4.00471C13.5413 4.32689 15.0073 10.8672 13.5413 11.1435C12.7373 11.3736 12.8792 8.50939 11.4605 8.28833C10.2782 8.10411 6.40039 11.6964 6.40039 19.4798Z" fill="#DDE3EB"></path><path d="M12.9023 21.2009C12.9023 23.094 14.6995 24.4395 16.4706 24.4395C18.1874 24.4395 19.3023 22.6378 19.3023 21.2009C19.3023 19.0381 17.3978 16.4395 16.1517 16.4395C14.7904 16.4395 12.9023 19.4312 12.9023 21.2009Z" fill="#AAB8CD"></path></svg>''';
const String _kClockSvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_6577_16697)"><path opacity="0.4" d="M16 28C18.3578 28 20.5375 27.2219 22.2906 25.9094L23.9406 27.5594C24.5266 28.1453 25.4781 28.1453 26.0641 27.5594C26.65 26.9734 26.65 26.0219 26.0641 25.4359L24.4141 23.7859C25.7266 22.0328 26.5047 19.8578 26.5047 17.4953C26.5 11.7016 21.7984 7 16 7C10.2016 7 5.5 11.7016 5.5 17.5C5.5 19.8578 6.27812 22.0375 7.59062 23.7906L5.94063 25.4406C5.35469 26.0266 5.35469 26.9781 5.94063 27.5641C6.52656 28.15 7.47812 28.15 8.06406 27.5641L9.71406 25.9141C11.4672 27.2266 13.6422 28.0047 16 28.0047V28ZM17.125 12.625V17.0359L19.0469 18.9578C19.4875 19.3984 19.4875 20.1109 19.0469 20.5469C18.6062 20.9828 17.8938 20.9875 17.4578 20.5469L15.2078 18.2969C14.9969 18.0859 14.8797 17.8 14.8797 17.5V12.625C14.8797 12.0016 15.3813 11.5 16.0047 11.5C16.6281 11.5 17.1297 12.0016 17.1297 12.625H17.125Z" fill="#AAB8CD"></path><path d="M4.69844 10.8625L11.5 5.19062C10.7031 4.45 9.63437 4 8.4625 4C5.99687 4 4 5.99687 4 8.4625C4 9.34375 4.25781 10.1641 4.69844 10.8578V10.8625ZM16 11.5C15.3766 11.5 14.875 12.0016 14.875 12.625V17.5C14.875 17.8 14.9922 18.0859 15.2031 18.2969L17.4531 20.5469C17.8938 20.9875 18.6062 20.9875 19.0422 20.5469C19.4781 20.1062 19.4828 19.3937 19.0422 18.9578L17.1203 17.0359V12.625C17.1203 12.0016 16.6187 11.5 15.9953 11.5H16ZM20.5 5.19062L27.3016 10.8625C27.7422 10.1687 28 9.34375 28 8.4625C28 5.99687 26.0031 4 23.5375 4C22.3656 4 21.2969 4.45 20.5 5.19062Z" fill="#AAB8CD"></path></g><defs><clipPath id="clip0_6577_16697"><rect width="24" height="24" fill="white" transform="translate(4 4)"></rect></clipPath></defs></svg>''';

/// Heading/title helper. Uses the app's default font (Mulish, `AppFont.mulish`)
/// so Profile matches the rest of the app (e.g. the Habit screens) — the earlier
/// Poppins display font was dropped for a single consistent typeface.
TextStyle _poppins(
  double size,
  FontWeight weight, {
  Color color = AppCustomColor.textPrimary,
  double? height,
}) =>
    TextStyle(fontFamily: AppFont.mulish, fontSize: size.sp, fontWeight: weight, color: color, height: height);

/// Opens the full-screen Achievements list. Pushed on the ROOT navigator (not
/// a go_router route — see the class doc on [AchievementsFullPage]) so it
/// covers the bottom nav and pops back to exactly where the user was.
void _openAchievements(BuildContext context) {
  AppService.instance.appTrackingService.trackProfileAchieveSeeall();
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AchievenmentProgressCubit>(),
        child: const AchievementsFullPage(),
      ),
    ),
  );
}

/// Opens the "My course" library ([MyCoursesPage]) standalone. It normally
/// lives nested under the Course tab's shell branch; pushing its go_router path
/// from the Profile tab would switch the visible bottom-nav branch to Course as
/// a side effect. Pushing it directly on the root navigator instead keeps the
/// user on the Profile tab underneath and pops straight back to it.
///
/// Provides HomeCubit + CourseRoadmapCubit + ProgressCubit — the page reads
/// skillsets/progress for its grouped enrolled-course sections and their
/// completion %.
void _openMyCourses(BuildContext context) {
  AppService.instance.appTrackingService.trackProfileMycourseClick();
  MyCoursesPage.open(context);
}

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
      // The streak card is new on this page — make sure it has fresh data
      // even when the user opens Profile without visiting Home first.
      unawaited(_prefetchLearningStreak());
    });
  }

  // LearningStreakCubit isn't provided in ProfileRoute's BlocProvider tree
  // (only ProfileCubit/IapCubit/AchievenmentProgressCubit/AuthBloc are — see
  // routes_shell_setting_data.dart), so it's read via the DI singleton
  // instead of context.read, mirroring HomeCubit/UserCubit access from
  // habit_domain_icon.dart. `triggerSource: homeChip` reuses the same
  // dedupe/freshness window Home's own prefetch uses, so visiting Home then
  // Profile within ~30s doesn't double-fetch.
  Future<void> _prefetchLearningStreak() async {
    final userId = AppDI.injector.get<UserCubit>().state.user.id;
    await AppDI.injector.get<LearningStreakCubit>().loadUserLearningStreak(
      triggerSource: LearningStreakTriggerSource.homeChip,
      requestedUserId: userId,
      timeout: const Duration(seconds: 2),
      emitLoading: false,
      allowSafeDefaultOnFailure: true,
    );
  }

  void _trackView() {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackProfileScrView();
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
    unawaited(_prefetchLearningStreak());
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
      child: Scaffold(
        key: const Key('profile-page'),
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, _profileBackground),
        body: SafeBody(
          child: Column(
            children: [
              // Identity row is the only "sticky" part of the design — it
              // sits outside the scroll view so it never moves, while
              // everything else (premium banner through Library) scrolls
              // underneath it.
              const _ProfileIdentityHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView(
                    controller: _scrollController,
                    // Clear the floating nav bar so the last row isn't covered.
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, floatingNavBarHeight(context) + 20.h),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const _PremiumBanner(),
                      AppText(
                        context.l10n.setting.settingProfileProgressSection,
                        style: _poppins(20, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                      ),
                      14.verticalSpace,
                      const _StreakCard(),
                      14.verticalSpace,
                      const _StatCardsRow(),
                      30.verticalSpace,
                      const _AchievementsAndProgressSection(),
                      30.verticalSpace,
                      const _LibrarySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identity header: avatar • name • email • settings gear (fixed, not scrolling)
// ---------------------------------------------------------------------------

class _ProfileIdentityHeader extends StatelessWidget {
  const _ProfileIdentityHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 14.h),
      child: BlocSelector<ProfileCubit, ProfileState, UserEntity>(
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
                    onTap: () {
                      AppHaptic.select();
                      const RegisterRoute().push(context);
                    },
                    child: _ProfileAvatar(user: user),
                  ),
                )
              else
                _ProfileAvatar(user: user),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      _resolveName(user, context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _poppins(20, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                    ),
                    4.verticalSpace,
                    AppText(
                      _resolveEmail(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.text13.copyWith(
                        color: studyThemeOnBg(context, _profileMutedTextColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              14.horizontalSpace,
              Semantics(
                label: context.l10n.setting.settingTitle,
                button: true,
                child: GestureDetector(
                  key: const Key('profile-settings-button'),
                  onTap: () {
                    AppHaptic.select();
                    AppService.instance.appTrackingService.trackProfileSettingsClick();
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
                      colorFilter: ColorFilter.mode(
                        studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _resolveName(UserEntity user, BuildContext context) {
    final trimmed = user.name.trim();
    return trimmed.isNotEmpty ? trimmed : context.l10n.setting.settingGuestName;
  }

  String _resolveEmail(UserEntity user) => user.email.trim();
}

// ---------------------------------------------------------------------------
// Avatar: network image with ClipOval, or initial-letter fallback
// ---------------------------------------------------------------------------

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final double size = 52.w;

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
        style: _poppins(20, FontWeight.w700, color: AppCustomColor.backgroundWhite),
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
// Premium banner: shown only when the user is not premium
// ---------------------------------------------------------------------------

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.user.isPremium,
      builder: (context, isPremium) {
        // Keep a small breathing gap so the "Progress" title never sits
        // flush under the identity header when the banner is hidden.
        if (isPremium) return SizedBox(height: 8.h);

        final text = context.l10n.setting;

        return Padding(
          padding: EdgeInsets.only(bottom: 30.h),
          child: Semantics(
            button: true,
            label: text.settingPremiumTitle,
            child: GestureDetector(
              key: const Key('profile-premium-banner'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                AppService.instance.appTrackingService.trackProfileUpgradeClick(source: 'profile_banner');
                AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.profile);
                const PaywallRoute().push(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary,
                  borderRadius: BorderRadius.circular(18.r),
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
                            style: _poppins(15, FontWeight.w700, color: AppCustomColor.backgroundWhite),
                          ),
                          2.verticalSpace,
                          AppText(
                            text.settingPremiumSubtitle,
                            style: AppStyle.text12.copyWith(
                              color: const Color(0xFFD6D3F7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    14.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundWhite,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: AppText(
                        text.settingPremiumUpgradeCta,
                        style: AppStyle.textBold12.copyWith(
                          fontSize: 13.sp,
                          color: AppCustomColor.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Streak card — reuses StreakWeekBar. Display-only: tapping it no longer opens
// the streak detail (removed per request).
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningStreakCubit, LearningStreakState>(
      bloc: AppDI.injector.get<LearningStreakCubit>(),
      builder: (context, state) {
        final streak = state.selectedItem;
        final label = context.l10n.learningStreak.streakDays(count: streak.currentStreak);
        return Semantics(
          label: label,
          child: Container(
            key: const Key('profile-streak-card'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: studyThemeCardColor(context),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: _profileCardShadow,
            ),
            child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 26.w,
                        height: 33.h,
                        child: SvgPicture.asset(AppAsset.svg.app.icFlameActive, fit: BoxFit.contain),
                      ),
                      10.horizontalSpace,
                      AppText(label, style: _poppins(24, FontWeight.w700)),
                    ],
                  ),
                  16.verticalSpace,
                  StreakWeekBar(weekStudy: streak.normalizedWeekStudy),
                ],
              ),
            ),
          );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stat cards row: best streak · this week
// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningStreakCubit, LearningStreakState>(
      bloc: AppDI.injector.get<LearningStreakCubit>(),
      builder: (context, state) {
        final streak = state.selectedItem;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: _kStreakGraySvg,
                value: context.l10n.learningStreak.daysShort(count: streak.bestStreak),
                label: context.l10n.learningStreak.bestStreakLabel,
              ),
            ),
            14.horizontalSpace,
            Expanded(
              child: _StatCard(
                icon: _kClockSvg,
                value: context.l10n.learningStreak.minutesShort(count: streak.studyTime),
                label: context.l10n.learningStreak.thisWeekLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: _profileCardShadow,
      ),
      child: Row(
        children: [
          SvgPicture.string(icon, width: 32.w, height: 32.w, fit: BoxFit.contain),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  value,
                  maxLines: 1,
                  // Shrink-to-fit so a longer value (e.g. "141 phút") isn't
                  // clipped to "141 ph…" in this narrow half-width card.
                  enableFitScaleDown: true,
                  style: _poppins(19, FontWeight.w700),
                ),
                AppText(
                  label,
                  maxLines: 1,
                  // Shrink-to-fit so a longer label (e.g. "Chuỗi dài nhất")
                  // isn't clipped to "Chuỗi dài nh…" in this narrow half-width
                  // card, while keeping both stat cards a single line / equal height.
                  enableFitScaleDown: true,
                  style: AppStyle.text12.copyWith(color: _profileMutedTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievements + Learning Progress — both derive from AchievenmentProgressCubit
// so they share one loading/failure treatment.
// ---------------------------------------------------------------------------

class _AchievementsAndProgressSection extends StatelessWidget {
  const _AchievementsAndProgressSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
      buildWhen: (previous, current) => previous.status != current.status || previous.achievenments != current.achievenments,
      builder: (context, state) {
        final bool isLoading = state.status == AchievenmentProgressStatus.loading && state.achievenments.isEmpty;
        final bool isFailure = state.status == AchievenmentProgressStatus.failure && state.achievenments.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeaderRow(
              title: context.l10n.setting.achievementsTitle,
              trailingLabel: context.l10n.setting.settingProfileAchievementsSeeAll,
              onTrailingTap: () => _openAchievements(context),
            ),
            14.verticalSpace,
            if (isLoading)
              const _InlineSectionLoader()
            else if (isFailure)
              _InlineSectionError(
                message: state.errorMessage,
                onRetry: () => context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses(),
              )
            else
              _AchievementsSummaryCard(achievenments: state.achievenments),
            if (!isLoading && !isFailure) _LearningProgressSection(achievenments: state.achievenments),
          ],
        );
      },
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.trailingLabel,
    required this.onTrailingTap,
  });

  final String title;
  final String trailingLabel;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppText(title, style: _poppins(20, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary))),
        ),
        Semantics(
          button: true,
          label: trailingLabel,
          child: GestureDetector(
            key: const Key('profile-achievements-see-all-button'),
            onTap: () {
              AppHaptic.select();
              onTrailingTap();
            },
            child: AppText(
              trailingLabel,
              style: AppStyle.textBold14.copyWith(color: AppCustomColor.brandPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineSectionLoader extends StatelessWidget {
  const _InlineSectionLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineSectionError extends StatelessWidget {
  const _InlineSectionError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: _profileCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.w, color: AppCustomColor.textTertiary),
          12.verticalSpace,
          AppText(
            message ?? '',
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
          ),
          12.verticalSpace,
          OutlinedButton(
            onPressed: () {
              AppHaptic.select();
              onRetry();
            },
            child: AppText(
              context.l10n.monetization.retry,
              style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievements summary card: trophy illustration + total badges earned
// ---------------------------------------------------------------------------

class _AchievementsSummaryCard extends StatelessWidget {
  const _AchievementsSummaryCard({required this.achievenments});

  final List<AchievenmentResponseEntity> achievenments;

  int get _earnedBadges => achievenments.fold(0, (sum, a) => sum + a.completedCourse);
  int get _totalBadges => achievenments.fold(0, (sum, a) => sum + a.totalCourse);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.setting.settingProfileAchievementsSeeAll,
      child: GestureDetector(
        key: const Key('profile-achievements-summary-card'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          _openAchievements(context);
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _profileCardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/app/achievements_badges.png', width: 132.w, fit: BoxFit.contain),
              16.horizontalSpace,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      // Design shows earned / total (e.g. "3/12"), not just the
                      // earned count.
                      '$_earnedBadges/$_totalBadges',
                      textAlign: TextAlign.center,
                      style: _poppins(30, FontWeight.w700),
                    ),
                    AppText(
                      context.l10n.setting.settingProfileBadgesEarnedLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppStyle.text13.copyWith(color: _profileMutedTextColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Learning Progress — one row per skillset with courses, derived from
// completedCourse/totalCourse (no precomputed per-category % exists).
// ---------------------------------------------------------------------------

class _LearningProgressSection extends StatelessWidget {
  const _LearningProgressSection({required this.achievenments});

  final List<AchievenmentResponseEntity> achievenments;

  @override
  Widget build(BuildContext context) {
    final visible = achievenments.where((a) => a.totalCourse > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        30.verticalSpace,
        AppText(
          context.l10n.setting.settingProfileLearningProgressSection,
          style: _poppins(20, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
        14.verticalSpace,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _profileCardShadow,
          ),
          // The progress denominator is the skillset's whole catalog size, which
          // lives in HomeCubit — rebuild when it arrives so the bars aren't stuck
          // on the (much smaller) achievement fallback if skillsets load late.
          child: BlocBuilder<HomeCubit, HomeState>(
            bloc: AppDI.injector.get<HomeCubit>(),
            buildWhen: (prev, curr) => prev.skillsets != curr.skillsets,
            builder: (context, homeState) {
              return Column(
                children: [
                  for (int i = 0; i < visible.length; i++)
                    _CategoryRow(
                      achievement: visible[i],
                      catalogCount: homeState.skillsets
                              .where((s) => s.id == visible[i].skillsetId)
                              .firstOrNull
                              ?.courses
                              .length ??
                          0,
                      tint: _profileCategoryTints[i % _profileCategoryTints.length],
                      showDivider: i < visible.length - 1,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.achievement,
    required this.catalogCount,
    required this.tint,
    required this.showDivider,
  });

  final AchievenmentResponseEntity achievement;

  /// Total number of courses in this skillset's Explore catalog (from HomeCubit).
  /// This is the progress denominator — see [build].
  final int catalogCount;
  final Color tint;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    // Progress is measured over the skillset's WHOLE catalog (every course shown
    // in Explore), each course counting as one unit in [0,1]: a completed course
    // = 1.0, an in-progress course = its keypoint fraction, an untouched course
    // = 0.
    //
    // The achievement API only returns rows for the courses the user has STARTED
    // (achievement.totalCourse counts just those), so dividing by it made a user
    // who finished the 2 courses they touched read as 100% even though the
    // skillset has 9 courses. The denominator must be the catalog size from
    // HomeCubit; fall back to achievement.totalCourse only if the skillset isn't
    // loaded yet, so the bar never divides by zero or disappears.
    final int denominator = catalogCount > 0 ? catalogCount : achievement.totalCourse;
    final double fraction;
    if (denominator > 0) {
      final double completedUnits = achievement.courses.fold<double>(0, (sum, c) {
        if (c.isCompleted) return sum + 1.0;
        if (c.totalKeypoints > 0) return sum + (c.completedKeypoints / c.totalKeypoints).clamp(0.0, 1.0);
        return sum;
      });
      fraction = (completedUnits / denominator).clamp(0.0, 1.0);
    } else {
      fraction = 0.0;
    }
    final int percent = (fraction.clamp(0.0, 1.0) * 100).round();
    final String name = achievement.skillsetTitle.text;

    return Column(
      children: [
        Semantics(
          button: true,
          label: '$name $percent%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openInExplore(context),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  _CategoryIcon(skillsetId: achievement.skillsetId, tint: tint),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _poppins(13, FontWeight.w600),
                        ),
                        9.verticalSpace,
                        _CategoryProgressBar(progress: fraction),
                      ],
                    ),
                  ),
                  8.horizontalSpace,
                  // Chevron affordance (design: each Learning Progress row opens
                  // its skillset in Explore). Matches the Library "My Course" row.
                  Icon(Icons.chevron_right_rounded, size: 22.w, color: _profileMutedTextColor),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) Container(width: double.infinity, height: 1, color: AppCustomColor.borderDefault),
      ],
    );
  }

  /// Tapping a Learning-Progress category jumps to the Explore tab scrolled to
  /// that same skillset section (design: Profile progress → the category in
  /// Explore). The scroll target index is this skillset's position in the
  /// Explore catalog (HomeCubit.skillsets — the exact list AllCourseTab renders
  /// and jumpToSkillset scrolls). No-op if the skillset isn't in the catalog.
  ///
  /// jumpToSkillset is called explicitly here (not left to CourseRoute's
  /// selectedTabIndex): the Explore branch is kept alive by the StatefulShell,
  /// so re-entering it does NOT re-run CoursePage.initState — only an explicit
  /// scroll request (bumped nonce) lands the user on the category on re-entry.
  void _openInExplore(BuildContext context) {
    final homeCubit = AppDI.injector.get<HomeCubit>();
    final index = homeCubit.state.skillsets.indexWhere((s) => s.id == achievement.skillsetId);
    if (index < 0) return;
    AppHaptic.select();
    homeCubit.selectSkillsetIndex(index);
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('profile_progress')
      ..jumpToSkillset(index);
    // Explicit route name (not just an index): a cross-branch `.go()` into an
    // already-built branch fires no didPush, so the observer won't set it — this
    // lights the Explore tab and keeps the nav guard consistent. Also sets
    // currentIndex to the Explore branch (3) via the route→tab mapping.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.course);
    CourseRoute(selectedTabIndex: index).go(context);
  }
}

/// 44×44 tinted icon tile for a Learning Progress row. Uses the skillset's
/// onboarding-intro icon when the skillsetId resolves against HomeCubit's
/// skillsets; falls back to a neutral generic icon so a missing/unknown
/// skillset never breaks the row.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.skillsetId, required this.tint});

  final String skillsetId;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final skillsets = AppDI.injector.get<HomeCubit>().state.skillsets;
    final imageUrl = skillsets.where((s) => s.id == skillsetId).firstOrNull?.image ?? '';

    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12.r)),
      alignment: Alignment.center,
      child: CacheNetworkGraphic(
        url: imageUrl,
        width: 28.w,
        height: 28.w,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Thin flexible progress bar that fills the width of its parent — unlike
/// [UserAchievementProgressBar] (fixed width), this row needs to stretch
/// across the remaining row space next to the icon tile.
class _CategoryProgressBar extends StatelessWidget {
  const _CategoryProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        height: 6.h,
        color: _profileProgressTrackColor,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(height: 6.h, color: AppCustomColor.brandPrimary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Library — My Course row, opens the existing Change-Course page
// ---------------------------------------------------------------------------

class _LibrarySection extends StatelessWidget {
  const _LibrarySection();

  @override
  Widget build(BuildContext context) {
    final myCourseLabel = context.l10n.allcourse.allcourseMyCourse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.l10n.setting.settingProfileLibrarySection,
          style: _poppins(20, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
        14.verticalSpace,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _profileCardShadow,
          ),
          child: Semantics(
            button: true,
            label: myCourseLabel,
            child: GestureDetector(
              key: const Key('profile-library-my-course-row'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                _openMyCourses(context);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    SvgPicture.string(_kMyCourseSvg, width: 26.w, height: 26.w),
                    14.horizontalSpace,
                    Expanded(
                      child: AppText(
                        myCourseLabel,
                        style: _poppins(15, FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 22.w, color: _profileMutedTextColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
