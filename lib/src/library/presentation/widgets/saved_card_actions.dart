part of '../../library.dart';

/// Share and bookmark glyphs inlined verbatim from the design markup, the same
/// treatment the Library's My Creations glyph gets: the paths ARE the design,
/// and keeping them here means no asset-bundle rebuild to match it 1:1.
///
/// `%STROKE%` / `%FILL%` are substituted so one string serves the hollow and
/// filled bookmark, and the tinted and on-dark share button.
const String _kSavedShareSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 16V4m0 0L7.8 8.2M12 4l4.2 4.2" stroke="%STROKE%" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M5 14.5V18a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-3.5" stroke="%STROKE%" stroke-width="2" stroke-linecap="round"/></svg>''';

const String _kSavedBookmarkSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="%FILL%" xmlns="http://www.w3.org/2000/svg"><path d="M6.5 4.5h11a1 1 0 0 1 1 1v14.2a.8.8 0 0 1-1.25.67L12 16.9l-5.25 3.47a.8.8 0 0 1-1.25-.67V5.5a1 1 0 0 1 1-1z" stroke="%STROKE%" stroke-width="1.9" stroke-linejoin="round"/></svg>''';

const String _kSavedCloseSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.5 6.5l11 11M17.5 6.5l-11 11" stroke="%STROKE%" stroke-width="2.2" stroke-linecap="round"/></svg>''';

String _savedSvg(String template, {required Color stroke, Color? fill}) {
  return template.replaceAll('%STROKE%', _hex(stroke)).replaceAll('%FILL%', fill == null ? 'none' : _hex(fill));
}

String _hex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A round action beside a saved card (design: 38 on the deck and the recap
/// card, 42 on the detail overlay).
///
/// Public because the recap card at the end of a keypoint lives in the `lesson`
/// feature and draws the same two buttons — the pair must not be reimplemented
/// there and allowed to drift.
class SavedCardActionButton extends StatelessWidget {
  const SavedCardActionButton({
    super.key,
    required this.semanticsLabel,
    required this.svg,
    required this.onTap,
    this.diameter,
    this.background,
    this.dropShadow = false,
  });

  /// Share, in the tint on a light disc.
  factory SavedCardActionButton.share({
    Key? key,
    required String semanticsLabel,
    required VoidCallback onTap,
    double? diameter,
    Color? background,
    bool dropShadow = false,
  }) {
    return SavedCardActionButton(
      key: key,
      semanticsLabel: semanticsLabel,
      svg: _savedSvg(_kSavedShareSvg, stroke: AppCustomColor.brandPrimary),
      onTap: onTap,
      diameter: diameter,
      background: background,
      dropShadow: dropShadow,
    );
  }

  /// The bookmark. Filled once saved — the icon IS the confirmation, which is
  /// why the toggle is optimistic (see [SavedCubit.toggleCard]).
  factory SavedCardActionButton.bookmark({
    Key? key,
    required String semanticsLabel,
    required bool isSaved,
    required VoidCallback onTap,
    double? diameter,
    Color? background,
    bool dropShadow = false,
  }) {
    return SavedCardActionButton(
      key: key,
      semanticsLabel: semanticsLabel,
      svg: _savedSvg(
        _kSavedBookmarkSvg,
        stroke: AppCustomColor.brandPrimary,
        fill: isSaved ? AppCustomColor.brandPrimary : null,
      ),
      onTap: onTap,
      diameter: diameter,
      background: background,
      dropShadow: dropShadow,
    );
  }

  final String semanticsLabel;
  final String svg;
  final VoidCallback onTap;
  final double? diameter;
  final Color? background;

  /// The soft lift the design gives these buttons where they sit over a card
  /// rather than over a flat sheet.
  final bool dropShadow;

  @override
  Widget build(BuildContext context) {
    final size = diameter ?? 38.w;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        // The design's disc is 38, under the 44 minimum — the gesture box is
        // padded out to 44 while the disc keeps its drawn size.
        child: SizedBox(
          width: math.max(size, 44.w),
          height: math.max(size, 44.w),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background ?? AppCustomColor.backgroundWhite.withValues(alpha: 0.9),
                boxShadow: dropShadow
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2D285A).withValues(alpha: 0.12),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: SvgPicture.string(svg, width: size * (18 / 38), height: size * (18 / 38)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark confirmation pill (design: #0D121C, check + 13/700 white).
///
/// In-place rather than the app's global snackbar: the design anchors it to the
/// card being saved — under the deck, above Continue on the recap card — and it
/// answers a tap the reader just made two centimetres away.
class SavedActionToast extends StatelessWidget {
  const SavedActionToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: _kSavedToastBg,
        borderRadius: BorderRadius.circular(99.r),
        boxShadow: [
          BoxShadow(
            color: _kSavedToastBg.withValues(alpha: 0.22),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14.w, color: AppCustomColor.backgroundWhite),
          8.horizontalSpace,
          AppText(
            message,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppCustomColor.backgroundWhite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [SavedActionToast] for a beat and takes it away again.
///
/// A controller rather than a widget flag in each host: three surfaces show the
/// same pill, and each would otherwise carry its own timer, its own cancel on
/// dispose, and its own bug when a second tap arrives mid-fade.
class SavedToastController extends ValueNotifier<String?> {
  SavedToastController() : super(null);

  Timer? _timer;

  void show(String message) {
    _timer?.cancel();
    value = message;
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!_disposed) value = null;
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// Floats the same pill over whatever screen the reader is on.
///
/// For surfaces with no room to reserve for a toast — the roadmap, where the
/// design puts it above the floating CTA rather than in the page's own column.
/// Not the app's global snackbar: that one drops from the top with a close
/// button, which is a heavier answer than "saved" deserves.
void showSavedToastOverlay(BuildContext context, String message, {double? bottomOffset}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      // Clear of the roadmap's floating CTA and the nav pill under it.
      bottom: bottomOffset ?? 172.h,
      child: IgnorePointer(
        child: Center(child: SavedActionToast(message: message)),
      ),
    ),
  );

  overlay.insert(entry);
  Timer(const Duration(milliseconds: 1800), () {
    if (entry.mounted) entry.remove();
  });
}

/// Fades [SavedToastController]'s message in and out wherever it is mounted.
class SavedToastHost extends StatelessWidget {
  const SavedToastHost({super.key, required this.controller});

  final SavedToastController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller,
      builder: (context, message, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: message == null ? const SizedBox.shrink() : SavedActionToast(message: message),
        );
      },
    );
  }
}
