part of '../../habit.dart';

/// Bottom-up route for the full-screen habit tasks (journal check-in, quiz,
/// upgrade). They open over the current context and are dismissed with an X,
/// so they must present like a modal — a MaterialPageRoute's horizontal push
/// read as navigating to a sibling screen, not as a task appearing. Same
/// motion as the DailyCheckIn route's `slideFromBottom`.
Route<T> habitModalRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
      ),
      child: child,
    ),
  );
}
