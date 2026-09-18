part of '../../onboard_v2.dart';

/// S11 "Make it yours" — màn cuối của onboarding. A full-screen study-theme picker that reuses the existing
/// [StudyThemeCubit] catalogue instead of introducing a parallel one: the
/// same singleton backs the in-app "Change background" sheet
/// (`change_background_sheet.dart`), so whatever the user picks here is
/// exactly what they land on.
///
/// S10 (kết quả) không kết thúc onboarding — nó ghi khoá đã chọn lên
/// [OnboardV2Cubit] (`chosenCourse`, null = xem kho khoá học) rồi bàn giao sang
/// đây; "Start Explore" bên dưới mới đánh dấu hoàn tất onboarding, ghi thứ tự
/// skillset theo nhánh đã chọn ([OnboardV2State.selectedSkillsetIds]) và điều
/// hướng thẳng về Home.
class OnboardV2PickThemePage extends StatefulWidget {
  const OnboardV2PickThemePage({super.key});

  @override
  State<OnboardV2PickThemePage> createState() => _OnboardV2PickThemePageState();
}

class _OnboardV2PickThemePageState extends State<OnboardV2PickThemePage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // The catalogue is DB-only (no bundled seed) — make sure it's fetched so
    // the theme grid has something to show once the anonymous onboarding
    // session can reach `/study-themes`.
    final studyThemeCubit = context.read<StudyThemeCubit>();
    if (studyThemeCubit.state.catalog.isEmpty) {
      unawaited(studyThemeCubit.loadCatalog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final studyState = context.watch<StudyThemeCubit>().state;
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // No back arrow is shown (terminal screen, no progress header) but a
        // hardware/gesture back should still stay inside onboarding rather than
        // exit it — see OnboardV2Cubit.goBack.
        context.read<OnboardV2Cubit>().goBack();
      },
      child: OnboardV2ScreenShell(
        key: const Key('onboard_v2_pick_theme_page'),
        backgroundColor: AppCustomColor.backgroundWhite,
        cta: _buildCta(state, onboardingL10n),
        child: Column(
          children: [
            12.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV2P9TitlePrefix', fallback: onboardingL10n.onboardingV2P9TitlePrefix),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
            ),
            OnboardV2GradientText(
              onbCopy(onboardData, 'onboardingV2P9TitleHighlight', fallback: onboardingL10n.onboardingV2P9TitleHighlight),
              textAlign: TextAlign.center,
              style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
            ),
            12.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV2P9Subtitle', fallback: onboardingL10n.onboardingV2P9Subtitle),
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
            ),
            24.verticalSpace,
            _ThemeGrid(
              // Onboarding shows only FREE themes; premium ones are locked
              // behind the paywall and appear later in the in-app picker.
              catalog: studyState.catalog.where((p) => !p.isPremium).toList(),
              selectedId: studyState.preset.id,
              soundOn: studyState.soundOn,
              onSelect: _selectPreset,
              onToggleSound: () => context.read<StudyThemeCubit>().setSound(!studyState.soundOn),
            ),
            20.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV2P9Helper', fallback: onboardingL10n.onboardingV2P9Helper),
              textAlign: TextAlign.center,
              style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPreset(StudyThemePreset preset) {
    AppHaptic.select();
    context.read<StudyThemeCubit>().selectPreset(preset);
  }

  Widget _buildCta(OnboardV2State state, Translations$onboarding$en onboardingL10n) {
    final label = onbCopy(state.onboardData, 'onboardingV2P9Cta', fallback: onboardingL10n.onboardingV2P9Cta);
    return OnboardV2BottomCta(
      label: label,
      isLoading: _isNavigating,
      onPressed: _isNavigating ? null : () => unawaited(_startExplore()),
    );
  }

  /// Performs the handoff that used to fire directly from P8's CTA. The
  /// flow now always ends at Home (S10's chosen course/browse-catalog
  /// choice already drives Home's ordering via `selectedSkillsetIds` — there
  /// is no separate course/roadmap destination to resolve here). The study
  /// theme itself needs no extra work here — [StudyThemeCubit.selectPreset]
  /// already applied (and, for a persistable preset, persisted) it the
  /// moment the user tapped a tile; the bundled default preset applies just
  /// as well if they never tapped one at all.
  Future<void> _startExplore() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final selectedTheme = context.read<StudyThemeCubit>().state.preset;
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P9StartExploreClick,
      parameters: {'theme_id': selectedTheme.id, 'theme_category': selectedTheme.category},
    );

    final cubit = context.read<OnboardV2Cubit>();
    // Reliably persist isOnboarded=true (awaited + retried) before leaving
    // onboarding, so check-onboarding recognises this device on reinstall.
    // Started here to run alongside the prewarm below; awaited just before
    // we navigate away.
    final onboardedSave = cubit.markUserOnboarded();
    // Home đã prewarm từ S9; chờ cho xong (hoặc timeout) để Home không lạnh.
    await cubit.prewarmHomeData().timeout(const Duration(seconds: 6), onTimeout: () {});
    if (!mounted) return;
    // Cap the wait so a slow/offline network can't trap the CTA on a spinner;
    // the retry keeps running in the background past the timeout.
    await onboardedSave.timeout(const Duration(seconds: 6), onTimeout: () {});
    if (!mounted) return;
    _dispatchHome();
  }

  void _dispatchHome() {
    try {
      final onboardCubit = context.read<OnboardV2Cubit>();
      final userCubit = context.read<UserCubit>();
      // isOnboarded is now persisted (awaited + retried) in _startExplore
      // before reaching here — see OnboardV2Cubit.markUserOnboarded — so there's
      // no fire-and-forget call at this point anymore.
      userCubit.setOnboardingSkillsetOrder(onboardCubit.state.selectedSkillsetIds);
      OnboardV2Tracking.track(TrackingKey.onboardV2Complete, parameters: {'chosen_course_id': onboardCubit.state.chosenCourse?.id});
      HomeRoute().go(context);
      // .go() to a branch root doesn't re-fire the route observer, so without
      // this PageCubit.currentRouteName stays on whatever it was before
      // onboarding — see all other Home entry points (e.g. UserCubit.initApp).
      context.read<PageCubit>().setCurrentRouteName(RouteNamed.home);
      userCubit.setIsUserPassOnboarding(false);
      _maybeShowPostOnboardingPaywall(onboardCubit.state.showPaywallAfterOnboarding);
    } catch (error) {
      LogDev.warning('[OnboardV2PickThemePage] route dispatch failed: $error');
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  /// Admin Onboarding Config toggle: the FULL paywall opens ON TOP of the
  /// destination the handoff just routed to, one frame later — so closing it
  /// lands the brand-new user exactly where onboarding meant to leave them.
  /// Premium accounts (a returning subscriber re-onboarding) are skipped.
  void _maybeShowPostOnboardingPaywall(bool enabled) {
    if (!enabled) return;
    if (AppDI.injector.get<ProfileCubit>().state.user.isPremium) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shellContext = AppConfig.instance.context;
      if (shellContext == null || !shellContext.mounted) return;
      AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.onboarding);
      unawaited(const PaywallRoute().push(shellContext));
    });
  }
}

/// Flat 3-column grid of the study-theme catalogue (design: reuse the
/// existing "Change background" preset tiles, just without the sheet's
/// category grouping — onboarding wants one dense grid, not several
/// category headers).
class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.catalog,
    required this.selectedId,
    required this.soundOn,
    required this.onSelect,
    required this.onToggleSound,
  });

  final List<StudyThemePreset> catalog;
  final String selectedId;
  final bool soundOn;
  final ValueChanged<StudyThemePreset> onSelect;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    if (catalog.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      key: const Key('onboard_v2_theme_grid'),
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.w,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1 / 1.2,
      children: [
        for (final preset in catalog)
          _ThemePresetTile(
            key: ValueKey('onboard_v2_theme_tile_${preset.id}'),
            preset: preset,
            selected: preset.id == selectedId,
            soundOn: soundOn,
            onTap: () => onSelect(preset),
            onToggleSound: onToggleSound,
          ),
      ],
    );
  }
}

/// A single theme thumbnail — mirrors `_PresetTile` in
/// `change_background_sheet.dart` (colour/image/video rendering, brand-ring +
/// check badge when selected) plus a mute/unmute badge on the selected Live
/// preset, since onboarding is the only place a user meets a "Live" (video +
/// ambient audio) background before it is already playing behind the app.
class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    super.key,
    required this.preset,
    required this.selected,
    required this.soundOn,
    required this.onTap,
    required this.onToggleSound,
  });

  final StudyThemePreset preset;
  final bool selected;
  final bool soundOn;
  final VoidCallback onTap;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: preset.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: _gradient,
            image: _assetImage,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Network thumbnail (DB-managed preset) — rendered as a widget
              // (not a DecorationImage) so it goes through the shared
              // memory/disk cached image loader.
              if (_networkThumbUrl != null)
                Positioned.fill(child: DCachedImage(url: _networkThumbUrl!, fit: BoxFit.cover)),
              // Live (video) presets get a centred play badge so they read as
              // motion, not a static photo.
              if (preset.mode == StudyThemeMode.video)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(Icons.play_arrow_rounded, size: 18.w, color: Colors.white),
                    ),
                  ),
                ),
              if (selected && preset.isLive && preset.hasAudio)
                Positioned(
                  left: 6.w,
                  top: 6.w,
                  child: _SoundBadge(soundOn: soundOn, onTap: onToggleSound),
                ),
              if (selected) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppCustomColor.brandPrimary, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  right: 6.w,
                  bottom: 6.w,
                  child: Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(color: AppCustomColor.brandPrimary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(Icons.check_rounded, size: 14.w, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A LinearGradient needs >= 2 stops — expand a solid (1-colour) preset and
  /// fall back to the bundled default preset's gradient for a malformed
  /// (empty) one, so a bad catalogue entry can never crash the paint.
  LinearGradient? get _gradient {
    if (preset.mode == StudyThemeMode.image || preset.mode == StudyThemeMode.video) return null;
    final colors = preset.gradient.isEmpty
        ? PresetCatalog.defaultPreset.gradient
        : preset.gradient.length == 1
            ? [preset.gradient.first, preset.gradient.first]
            : preset.gradient;
    return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
  }

  /// Remote thumbnail url, preferring a dedicated poster over the full image.
  /// Null for bundled presets (which only ever set `*Asset` fields).
  String? get _networkThumbUrl {
    final url = preset.thumbUrl ?? preset.imageUrl;
    return (url == null || url.trim().isEmpty) ? null : url;
  }

  /// Bundled-asset thumbnail. Only used when there's no network thumbnail —
  /// a preset never mixes an asset and a remote url.
  DecorationImage? get _assetImage {
    if (_networkThumbUrl != null) return null;
    final asset = preset.thumbAsset ?? preset.imageAsset;
    if (asset == null) return null;
    return DecorationImage(image: AssetImage(asset), fit: BoxFit.cover);
  }
}

/// Mute/unmute affordance over the selected Live preset's tile. Tapping it
/// toggles the same [StudyThemeCubit.soundOn] the in-app "Change background"
/// sheet controls, so the choice carries over 1:1 once onboarding finishes.
class _SoundBadge extends StatelessWidget {
  const _SoundBadge({required this.soundOn, required this.onTap});

  final bool soundOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: soundOn ? context.l10n.studyTheme.soundOnLabel : context.l10n.studyTheme.soundOffLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: Center(
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 14.w,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
