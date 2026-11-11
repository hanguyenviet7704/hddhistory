part of '../../../lesson.dart';

/// Chrome around the unified keypoint swipe screen: background, close +
/// overflow-menu header, segmented progress pip bar, and the loading overlay.
/// [body] is always [KeypointCardShell] in production — kept as a parameter
/// so widget tests can swap in a stub.
class LessonShellLayout extends StatelessWidget {
  const LessonShellLayout({
    super.key,
    required this.onClose,
    required this.body,
    required this.isLoading,
    this.trailing,
  });

  final VoidCallback onClose;
  final Widget body;
  final Widget? trailing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent only when a custom study background is active (so it
      // shows through); otherwise the stock brand-tinted background is kept.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.brandPrimary50),
      body: ThemedBackground(
        child: SafePage(
          child: Unfocused(
            child: Column(
              children: [
                8.verticalSpace,
                // Pips + narration toggle live INSIDE the header row (design)
                // — see [LessonShellHeader].
                LessonShellHeader(onClose: onClose, trailing: trailing),
                10.verticalSpace,
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: body),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !isLoading,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isLoading ? const _LessonLoadingOverlay() : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
