part of '../../study_theme.dart';

/// Near-full bottom sheet for picking a study background (design items 3/6/8/9):
/// grab handle + "Background" header, an upload bar, then presets grouped by
/// category in a 3-column grid. Thumbnails always show the true colour (no
/// readability overlay); the applied background carries its own overlay.
class ChangeBackgroundSheet extends StatelessWidget {
  const ChangeBackgroundSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x800B0B10), // design scrim rgba(11,11,16,.5)
      builder: (_) => const ChangeBackgroundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.injector.get<StudyThemeCubit>();
    return Padding(
      // Near-full sheet (design top:52px).
      padding: EdgeInsets.only(top: 52.h),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 14.h, bottom: 4.h),
              child: Center(
                child: Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDADCE4),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22.w, 6.h, 22.w, 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    context.l10n.studyTheme.backgroundTitle,
                    style: AppStyle.textBold20.copyWith(color: const Color(0xFF171735)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: const BoxDecoration(color: Color(0xFFF0F1F6), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(Icons.close_rounded, size: 18.w, color: const Color(0xFF6B6B86)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<StudyThemeCubit, StudyThemeState>(
                bloc: cubit,
                builder: (context, state) {
                  final userIsPremium = AppDI.injector.get<ProfileCubit>().state.user.isPremium;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(22.w, 6.h, 22.w, 30.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Premium upsell banner — hidden once the user is premium.
                        if (!userIsPremium) ...[
                          _UnlockPremiumBanner(onTap: () => const PaywallRoute().push(context)),
                          14.verticalSpace,
                        ],
                        _UploadBar(onTap: () => _pickImage(context, cubit)),
                        // Catalogue is DB-only (no bundled list): a loading
                        // skeleton until the fetch resolves, an empty/retry state
                        // if it came back empty/failed, else the grouped grid.
                        if (state.catalog.isEmpty) ...[
                          24.verticalSpace,
                          if (!state.catalogLoaded || state.catalogLoading)
                            const _ThemeCatalogSkeleton()
                          else
                            _ThemeCatalogEmpty(onRetry: () => cubit.loadCatalog()),
                        ] else ...[
                          // Refreshing over an already-loaded list — thin bar only.
                          if (state.catalogLoading) ...[
                            14.verticalSpace,
                            Semantics(
                              label: context.l10n.studyTheme.syncingBackgrounds,
                              child: const ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                                child: LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: Color(0xFFF0F1F6),
                                  color: Color(0xFF554FF0),
                                ),
                              ),
                            ),
                          ],
                          22.verticalSpace,
                          for (final group in PresetCatalog.groupByCategory(state.catalog))
                            _PresetGroupView(
                              group: group,
                              currentId: state.preset.id,
                              onPick: (preset) => _handlePick(context, cubit, preset, userIsPremium),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, StudyThemeCubit cubit) async {
    // Basic gallery pick so the bar is functional now; crop / size limits are
    // part of the later upload pass. Image-only (design item 6).
    // Downscale/compress on pick so a huge gallery photo doesn't blow memory as
    // a full-screen background (crop UI needs the image_cropper package — a
    // later addition). Image-only (design item 6).
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 88,
    );
    if (picked == null) return;
    await cubit.selectUploadedImage(File(picked.path));
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Free presets apply immediately; a premium preset tapped by a non-premium
  /// user opens the paywall instead of applying (design: "Unlock all themes").
  static void _handlePick(
    BuildContext context,
    StudyThemeCubit cubit,
    StudyThemePreset preset,
    bool userIsPremium,
  ) {
    if (preset.isPremium && !userIsPremium) {
      const PaywallRoute().push(context);
      return;
    }
    cubit.selectPreset(preset);
    // Applied — close the sheet (matches the upload flow, which also pops).
    Navigator.of(context).pop();
  }
}

/// Dashed "upload your own" bar at the top of the sheet (design item 9).
class _UploadBar extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRoundedRectPainter(color: const Color(0xFFC7C9D4), radius: 16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 22.w, color: const Color(0xFF8A8CA0)),
              12.horizontalSpace,
              AppText(
                context.l10n.studyTheme.uploadLabel,
                style: AppStyle.textBold14.copyWith(color: const Color(0xFF8A8CA0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium upsell at the top of the sheet (design: "Unlock all themes").
/// Tapping opens the paywall. Shown only to non-premium users.
class _UnlockPremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _UnlockPremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5B4FE8), Color(0xFF7A5CF0)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0x335B4FE8), blurRadius: 16.r, offset: Offset(0, 6.h)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.auto_awesome_rounded, size: 18.w, color: Colors.white),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.studyTheme.unlockAllThemes,
                    style: AppStyle.textBold14.copyWith(color: Colors.white),
                  ),
                  2.verticalSpace,
                  AppText(
                    context.l10n.studyTheme.goPremiumForFullCollection,
                    style: AppStyle.text12.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22.w, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder for the DB-only catalogue: a title bar + a grid of grey
/// tiles + a centred spinner, shown while the `/study-themes` fetch is in
/// flight (no bundled list to fall back to).
class _ThemeCatalogSkeleton extends StatelessWidget {
  const _ThemeCatalogSkeleton();

  static const _placeholder = Color(0xFFEDEEF3);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120.w,
          height: 14.h,
          decoration: BoxDecoration(color: _placeholder, borderRadius: BorderRadius.circular(4.r)),
        ),
        16.verticalSpace,
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1 / 1.4,
          children: List.generate(
            6,
            (_) => DecoratedBox(
              decoration: BoxDecoration(color: _placeholder, borderRadius: BorderRadius.circular(16.r)),
            ),
          ),
        ),
        24.verticalSpace,
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.brandPrimary),
              ),
              10.verticalSpace,
              AppText(
                context.l10n.studyTheme.syncingBackgrounds,
                style: AppStyle.text12.copyWith(color: const Color(0xFF8A8FA3)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty/failed catalogue state: nothing came back from `/study-themes`. Offers
/// a tap-to-retry (there is no bundled fallback to show instead).
class _ThemeCatalogEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _ThemeCatalogEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40.w, color: const Color(0xFFC7C9D4)),
          12.verticalSpace,
          Semantics(
            button: true,
            label: 'Retry',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary50,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Icon(Icons.refresh_rounded, size: 20.w, color: AppCustomColor.brandPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One titled group + its 3-column grid of preset tiles.
class _PresetGroupView extends StatelessWidget {
  final PresetGroup group;
  final String currentId;
  final ValueChanged<StudyThemePreset> onPick;

  const _PresetGroupView({required this.group, required this.currentId, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            group.category.toUpperCase(),
            style: AppStyle.text12.copyWith(
              color: const Color(0xFF8A8FA3),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.06 * 12,
            ),
          ),
          12.verticalSpace,
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1 / 1.4,
            children: [
              for (final preset in group.items)
                _PresetTile(
                  preset: preset,
                  selected: preset.id == currentId,
                  onTap: () => onPick(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single preset thumbnail. Shows the true colour/image; a selected tile gets
/// a brand ring + check badge (design).
class _PresetTile extends StatelessWidget {
  final StudyThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({required this.preset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            // (not a DecorationImage) so it goes through the shared cached
            // image loader (memory/disk cache + error fallback).
            if (_networkThumbUrl != null)
              Positioned.fill(
                child: DCachedImage(url: _networkThumbUrl!, fit: BoxFit.cover),
              ),
            // Diagonal corner ribbon (design): "PRO" (gold) for premium presets
            // that open the paywall on tap, "FREE" (brand) otherwise. Clipped to
            // the tile's rounded corner by the parent's antiAlias clip.
            Positioned(
              top: 9.w,
              right: -21.w,
              child: Transform.rotate(
                angle: 0.7853981634, // 45°
                child: Container(
                  width: 72.w,
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  alignment: Alignment.center,
                  color: preset.isPremium ? const Color(0xFFE0A32E) : const Color(0xFF554FF0),
                  child: Text(
                    preset.isPremium ? 'PRO' : 'FREE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            // Live (video) presets get a centred play badge over the poster so
            // they read as motion, not a static photo (design item 5).
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
            if (selected) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFF554FF0), width: 3),
                  ),
                ),
              ),
              Positioned(
                right: 6.w,
                bottom: 6.w,
                child: Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: const BoxDecoration(color: Color(0xFF554FF0), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(Icons.check_rounded, size: 14.w, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient? get _gradient {
    if (preset.mode == StudyThemeMode.image || preset.mode == StudyThemeMode.video) return null;
    final colors = preset.gradient.isEmpty
        ? const [Color(0xFFEFEEF9), Color(0xFFE6EBDE)]
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

/// Rounded-rectangle dashed stroke used by the upload bar.
class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRoundedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );
    final path = ui.Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter old) => old.color != color || old.radius != radius;
}
