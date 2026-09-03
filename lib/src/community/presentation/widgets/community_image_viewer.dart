part of '../../community.dart';

/// A post's pictures, full screen — tapped from the thread screen's strip.
///
/// Pushed as an UNNAMED route on the root navigator, which is also what hides
/// the floating nav under it: the route observer treats a nameless push as an
/// overlay and hands the page name back on pop (see `BaseRouterObserver`).
///
/// [PhotoViewGallery] rather than a `PageView` of `InteractiveViewer`s: pinch,
/// pan and swipe-to-the-next-picture fight each other once a picture is zoomed
/// in, and that arbitration is the whole reason `photo_view` is in the pubspec.
/// It had never been imported — `DCachedImage.enablePhotoView` pushes
/// `RouteNamed.imageView`, a route no router ever registered, and nothing in the
/// app sets the flag. This is that feature, finally wired, for community.
Future<void> showCommunityImageViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, _, _) =>
          _CommunityImageViewer(urls: urls, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _CommunityImageViewer extends StatefulWidget {
  const _CommunityImageViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_CommunityImageViewer> createState() => _CommunityImageViewerState();
}

class _CommunityImageViewerState extends State<_CommunityImageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.urls.length) return;
    AppHaptic.select();
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMany = widget.urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (index) => setState(() => _index = index),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            builder: (context, index) => PhotoViewGalleryPageOptions(
              // The full picture, not the display-sized decode the feed uses:
              // this screen exists to look closely, and it is one image at a
              // time rather than a list of them.
              imageProvider: CachedNetworkImageProvider(widget.urls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              // A tap closes, as it does in every gallery people already use.
              // Zooming is a pinch or a double tap, so this cannot be triggered
              // by accident mid-gesture.
              onTapUp: (_, _, _) => Navigator.of(context).maybePop(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 0),
              child: Row(
                children: [
                  _ViewerButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (hasMany)
                    AppText(
                      '${_index + 1}/${widget.urls.length}',
                      style: AppStyle.textBold14.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // The arrows: a swipe already works, but on a picture zoomed in the
          // drag belongs to the picture, and an arrow is the way out of that
          // without pinching back first.
          if (hasMany) ...[
            if (_index > 0)
              _ViewerArrow(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(_index - 1),
              ),
            if (_index < widget.urls.length - 1)
              _ViewerArrow(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(_index + 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ViewerArrow extends StatelessWidget {
  const _ViewerArrow({
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: _ViewerButton(icon: icon, onTap: onTap),
      ),
    );
  }
}

/// The round translucent controls the viewer draws over the picture.
class _ViewerButton extends StatelessWidget {
  const _ViewerButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            // Dark rather than light: it has to hold against a white picture as
            // well as a dark one, and a black scrim under white ink is the pair
            // that survives both.
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24.w, color: Colors.white),
        ),
      ),
    );
  }
}
