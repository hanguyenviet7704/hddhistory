part of '../../feedback.dart';

class FeedbackPopupShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTapOutside;

  const FeedbackPopupShell({
    super.key,
    required this.child,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTapOutside,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: AppCustomColor.scrimOverlay),
            ),
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Unfocused(
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
