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
      color: AppCustomColor.scrimOverlay,
      child: SizedBox.expand(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapOutside,
              child: ColoredBox(color: AppCustomColor.scrimOverlay),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Unfocused(child: child),
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
