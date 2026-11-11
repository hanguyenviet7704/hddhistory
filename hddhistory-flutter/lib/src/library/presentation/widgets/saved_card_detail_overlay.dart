part of '../../library.dart';

/// Card detail (design `5b · Library` → "Card detail"): one saved card lifted
/// off the grid onto a dimmed backdrop, flippable, with share / remove / close.
///
/// A route rather than a dialog: it is a full-screen surface with its own back
/// gesture, and the reader arrives at it by tapping a card — the system back
/// must return them to the grid, not to the Library tab.
class SavedCardDetailOverlay extends StatefulWidget {
  const SavedCardDetailOverlay({super.key, required this.card});

  final SavedCardEntity card;

  static Future<void> show(BuildContext context, {required SavedCardEntity card}) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, _, _) => BlocProvider.value(
          value: AppDI.injector.get<SavedCubit>(),
          child: SavedCardDetailOverlay(card: card),
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<SavedCardDetailOverlay> createState() => _SavedCardDetailOverlayState();
}

class _SavedCardDetailOverlayState extends State<SavedCardDetailOverlay> with SingleTickerProviderStateMixin {
  final GlobalKey _shareBoundaryKey = GlobalKey();
  final SavedToastController _toast = SavedToastController();

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _turn = CurvedAnimation(
    parent: _flip,
    curve: const Cubic(0.2, 0.7, 0.25, 1),
  );

  @override
  void dispose() {
    _flip.dispose();
    _toast.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (!widget.card.canFlip || _flip.isAnimating) return;
    AppHaptic.select();
    _flip.value > 0.5 ? _flip.reverse() : _flip.forward();
  }

  Future<void> _share() async {
    final ok = await shareSavedQuoteCard(
      context,
      boundaryKey: _shareBoundaryKey,
      title: widget.card.displayTitle,
    );
    if (!mounted || ok) return;
    _toast.show(context.l10n.library.shareFailed);
  }

  /// Remove closes the overlay: the card the reader is looking at is the thing
  /// being removed, and leaving them staring at it would contradict the action.
  Future<void> _remove() async {
    await context.read<SavedCubit>().removeCard(widget.card.keypointId);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tapping the backdrop closes; the card and the buttons stop the tap.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: ColoredBox(
                  color: _kSavedToastBg.withValues(alpha: 0.55),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 40.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: _toggleFlip,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 290.w),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: RepaintBoundary(
                              key: _shareBoundaryKey,
                              child: SavedFlipCard(card: widget.card, turn: _turn),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  18.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SavedCardActionButton.share(
                        key: const Key('saved-detail-share'),
                        semanticsLabel: l10n.shareLabel,
                        diameter: 42.w,
                        background: AppCustomColor.backgroundWhite.withValues(alpha: 0.95),
                        onTap: () => unawaited(_share()),
                      ),
                      10.horizontalSpace,
                      SavedCardActionButton.bookmark(
                        key: const Key('saved-detail-remove'),
                        semanticsLabel: l10n.unsaveCardLabel,
                        // Always filled here: every card on this screen is saved,
                        // and the button's job is to take it away.
                        isSaved: true,
                        diameter: 42.w,
                        background: AppCustomColor.backgroundWhite.withValues(alpha: 0.95),
                        onTap: () => unawaited(_remove()),
                      ),
                      10.horizontalSpace,
                      SavedCardActionButton(
                        key: const Key('saved-detail-close'),
                        semanticsLabel: context.l10n.common.close,
                        svg: _savedSvg(_kSavedCloseSvg, stroke: AppCustomColor.backgroundWhite),
                        diameter: 42.w,
                        background: AppCustomColor.backgroundWhite.withValues(alpha: 0.22),
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  18.verticalSpace,
                  SavedToastHost(controller: _toast),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
