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
    return Dialog(
      child: Unfocused(child: child),
    );
  }
}
