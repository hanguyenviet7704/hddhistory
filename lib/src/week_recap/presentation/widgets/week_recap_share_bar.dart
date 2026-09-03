part of '../../week_recap.dart';

/// Pixel width of a shared poster.
///
/// 1080 is the width every story surface expects, and the poster's own design
/// space is [WeekRecapSlots.referenceWidth] wide — so capturing at that ratio
/// gives a true 1080x1920 whatever the phone's own width happens to be.
const double _kWeekRecapExportWidth = 1080;

/// The four ways out of the poster: save it, put it on a story, or hand it to
/// the system sheet.
class WeekRecapShareBar extends StatefulWidget {
  const WeekRecapShareBar({super.key, required this.boundaryKey});

  final GlobalKey boundaryKey;

  @override
  State<WeekRecapShareBar> createState() => _WeekRecapShareBarState();
}

class _WeekRecapShareBarState extends State<WeekRecapShareBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.weekRecap;

    return Padding(
      // Tight on purpose: every point here is a point the poster above cannot
      // use, and the page's bottom safe-area inset already pads below.
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Same buttons as the course-share sheet, from the same widget: a
          // reader who has shared a course should not meet a different-looking
          // row when they share their week.
          ShareTargetButton(
            key: const Key('week-recap-share-download'),
            label: l10n.shareDownload,
            icon: Icons.file_download_rounded,
            iconColor: AppCustomColor.kpOptionLabel,
            background: ShareTargetButton.plainDisc,
            compact: true,
            enabled: !_busy,
            onTap: _save,
          ),
          ShareTargetButton(
            key: const Key('week-recap-share-instagram'),
            label: l10n.shareIgStory,
            icon: Icons.camera_alt_rounded,
            iconColor: AppCustomColor.textWhite,
            background: ShareTargetButton.instagramDisc,
            compact: true,
            enabled: !_busy,
            onTap: () => _shareToStory(StoryPlatform.instagram),
          ),
          ShareTargetButton(
            key: const Key('week-recap-share-facebook'),
            label: l10n.shareFbStory,
            icon: Icons.facebook_rounded,
            iconColor: AppCustomColor.textWhite,
            background: ShareTargetButton.facebookDisc,
            compact: true,
            enabled: !_busy,
            onTap: () => _shareToStory(StoryPlatform.facebook),
          ),
          ShareTargetButton(
            key: const Key('week-recap-share-more'),
            label: l10n.shareMore,
            icon: Icons.more_horiz_rounded,
            iconColor: AppCustomColor.kpOptionLabel,
            background: ShareTargetButton.plainDisc,
            compact: true,
            enabled: !_busy,
            onTap: _shareSheet,
          ),
        ],
      ),
    );
  }

  /// Captures the live poster, so what is shared is exactly what is on screen.
  Future<Uint8List?> _capture() async {
    final media = AppDI.injector.get<IMediaService>();

    return media.captureWidgetWithRepaintBoundary(
      widget.boundaryKey,
      targetWidth: _kWeekRecapExportWidth,
    );
  }

  Future<void> _save() async {
    await _guard(() async {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Poster capture returned nothing');
      await AppDI.injector.get<IMediaService>().saveImageToGallery(bytes);
      if (!mounted) return;
      DMessage.showMessage(
        message: context.l10n.weekRecap.shareSaved,
        type: MessageType.success,
      );
    });
  }

  Future<void> _shareSheet() async {
    await _guard(() async {
      if (!mounted) return;
      final media = AppDI.injector.get<IMediaService>();
      final origin = media.getSharePositionOrigin(context);
      final message = context.l10n.weekRecap.shareMessage;
      await media.captureAndShareWithRepaintBoundary(
        widget.boundaryKey,
        shareText: '$message\n${StoreUrl.shareFooter}',
        fileName: 'meup-week-recap.png',
        pixelRatio: 3,
        sharePositionOrigin: origin,
      );
    });
  }

  /// Instagram and Facebook stories, handed over through the existing
  /// `meup/story_share` channel — the same bridge a shared course card uses.
  ///
  /// Falls back to the system sheet when the app is not installed or the native
  /// side refuses: the reader asked to share, and a dead tap is worse than the
  /// other route.
  Future<void> _shareToStory(StoryPlatform platform) async {
    await _guard(() async {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Poster capture returned nothing');

      final handed = await AppDI.injector.get<IStoryShareService>().shareToStory(
        platform: platform,
        pngBytes: bytes,
      );
      if (handed || !mounted) return;
      await _shareSheet();
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      LogDev.warning('Week recap share failed: $error');
      if (mounted) {
        DMessage.showMessage(
          message: context.l10n.weekRecap.shareFailed,
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
