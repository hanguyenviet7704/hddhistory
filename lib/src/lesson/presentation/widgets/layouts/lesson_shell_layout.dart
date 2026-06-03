part of '../../../lesson.dart';

class LessonShellLayout extends StatefulWidget {
  const LessonShellLayout({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.showModeToggle,
    required this.readBody,
    required this.audioBody,
    required this.isLoading,
    this.bottom,
    this.trailing,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final bool showModeToggle;
  final Widget readBody;
  final Widget audioBody;
  final Widget? bottom;
  final Widget? trailing;
  final bool isLoading;

  @override
  State<LessonShellLayout> createState() => _LessonShellLayoutState();
}

class _LessonShellLayoutState extends State<LessonShellLayout> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _lessonShellIndexForMode(widget.selectedMode),
    );
  }

  @override
  void didUpdateWidget(covariant LessonShellLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    final targetIndex = _lessonShellIndexForMode(widget.selectedMode);
    if (_tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.brandPrimary50,
      body: SafePage(
        child: Unfocused(
          child: Column(
            children: [
              8.verticalSpace,
              LessonShellHeader(
                selectedMode: widget.selectedMode,
                onModeSelected: widget.onModeSelected,
                onClose: widget.onClose,
                showModeToggle: widget.showModeToggle,
                canSwitchModes: !widget.isLoading,
                trailing: widget.trailing,
              ),
              12.verticalSpace,
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: widget.showModeToggle
                          ? TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _LessonShellTabPage(child: widget.readBody),
                                _LessonShellTabPage(child: widget.audioBody),
                              ],
                            )
                          : _LessonShellTabPage(child: widget.readBody),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !widget.isLoading,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: widget.isLoading ? const _LessonLoadingOverlay() : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.bottom != null && widget.selectedMode.isRead) LessonStickyBottomAction(child: widget.bottom!),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonShellTabPage extends StatefulWidget {
  const _LessonShellTabPage({
    required this.child,
  });

  final Widget child;

  @override
  State<_LessonShellTabPage> createState() => _LessonShellTabPageState();
}

class _LessonShellTabPageState extends State<_LessonShellTabPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

int _lessonShellIndexForMode(LessonEntryMode mode) => mode.isAudio ? 1 : 0;
