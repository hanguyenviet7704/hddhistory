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
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(22.w, 6.h, 22.w, 30.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UploadBar(onTap: () => _pickImage(context, cubit)),
                        // Quiet sync affordance only — the bundled/previous
                        // catalogue is already rendering below, so this never
                        // blocks the picker (offline-first requirement).
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
                            onPick: cubit.selectPreset,
                          ),
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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    cubit.selectUploadedImage(File(picked.path));
    if (context.mounted) Navigator.of(context).pop();
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
