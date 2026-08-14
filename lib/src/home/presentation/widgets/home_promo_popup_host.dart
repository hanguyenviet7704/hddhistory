part of '../../home.dart';

/// Raises the admin-configured promo popup over Home, at most once per app
/// session.
///
/// Wraps Home rather than living inside it so the fetch and the dialog have a
/// lifetime of their own — the same shape [StreakPopupHost] uses on the shell.
///
/// Who decides what: the SERVER decides whether there is anything to show (kill
/// switch, market, and whether this reader already tapped this campaign); this
/// widget decides only *when* — once per session, after Home has painted.
class HomePromoPopupHost extends StatefulWidget {
  const HomePromoPopupHost({super.key, required this.child});

  final Widget child;

  /// Whether this app session has already had its turn.
  ///
  /// Static and in-memory ON PURPOSE. "Once per session" means once per app
  /// launch, so the flag must die with the process — persisting it would turn
  /// "shown once today" into "shown once ever", which is the rule the reader
  /// dismissing the popup explicitly did NOT ask for (closing means later).
  static bool _shownThisSession = false;

  /// Test seam: a widget test cannot relaunch the app between cases.
  @visibleForTesting
  static void resetSessionLatch() => _shownThisSession = false;

  @override
  State<HomePromoPopupHost> createState() => _HomePromoPopupHostState();
}

class _HomePromoPopupHostState extends State<HomePromoPopupHost> {
  @override
  void initState() {
    super.initState();
    // After the first frame: Home is the first thing the reader should see, and a
    // modal raised during build would land on a screen that has not painted.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeShow()));
  }

  Future<void> _maybeShow() async {
    if (!mounted || HomePromoPopupHost._shownThisSession) return;

    final result = await AppDI.injector.get<GetHomePopupUseCase>().call().run();
    final popup = result.getRight().toNullable();
    // A failed fetch is not worth a log line at warning level and certainly not
    // worth a retry: the popup is promotional, and Home has already loaded.
    if (popup == null || !popup.isVisible || !mounted) return;

    // Latched BEFORE showing, not after: awaiting the dialog would leave the door
    // open for a second Home rebuild to raise a second copy.
    HomePromoPopupHost._shownThisSession = true;
    await _HomePromoPopupDialog.show(context, popup);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The popup itself: one image, a close button, nothing else.
///
/// No title, body or button label — copy is baked into the image by design, which
/// is what keeps admin-entered text out of an app that ships five locales.
class _HomePromoPopupDialog extends StatelessWidget {
  const _HomePromoPopupDialog({required this.popup});

  final HomePopupEntity popup;

  static Future<void> show(BuildContext context, HomePopupEntity popup) {
    return showDialog<void>(
      context: context,
      // Tapping outside closes, exactly like the X: dismissing is "later", and
      // the popup returns next session.
      barrierDismissible: true,
      builder: (_) => _HomePromoPopupDialog(popup: popup),
    );
  }

  void _handleTap(BuildContext context) {
    AppHaptic.select();
    // Record the tap and open the link WITHOUT waiting on the network. Making
    // someone watch a spinner before the offer they just tapped would be worse
    // than the cost of failure here, which is the popup returning next session.
    unawaited(AppDI.injector.get<MarkHomePopupClickedUseCase>().call(popup.campaignKey).run());
    Navigator.of(context).pop();
    if (popup.linkUrl.isNotEmpty) unawaited(openConfiguredLink(popup.linkUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: context.l10n.common.close,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(8.r),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 20.r, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          Semantics(
            button: popup.linkUrl.isNotEmpty,
            image: true,
            label: context.l10n.home.homeBannerSemantic,
            child: GestureDetector(
              onTap: () => _handleTap(context),
              child: CacheNetworkGraphic(
                url: popup.imageUrl,
                borderRadius: BorderRadius.circular(20.r),
                // `contain`, not `cover`: the creative carries the copy, and
                // cropping it to a fixed box would cut words off. The image's own
                // ratio decides the height.
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
