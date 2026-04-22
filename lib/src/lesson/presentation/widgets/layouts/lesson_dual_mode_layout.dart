part of '../../../lesson.dart';

class LessonDualModeLayout extends StatefulWidget {
  const LessonDualModeLayout({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.readBody,
    required this.audioBody,
    required this.isLoading,
    this.bottom,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final Widget readBody;
  final Widget audioBody;
  final Widget? bottom;
  final bool isLoading;

  @override
  State<LessonDualModeLayout> createState() => _LessonDualModeLayoutState();
}

class _LessonDualModeLayoutState extends State<LessonDualModeLayout> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _indexForMode(widget.selectedMode),
    );
  }

  @override
  void didUpdateWidget(covariant LessonDualModeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    final targetIndex = _indexForMode(widget.selectedMode);
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
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafePage(
        child: Unfocused(
          child: Column(
            children: [
              8.verticalSpace,
              _LessonDualModeHeader(
                selectedMode: widget.selectedMode,
                onClose: widget.onClose,
                onModeSelected: widget.onModeSelected,
                canSwitchModes: !widget.isLoading,
              ),
              20.verticalSpace,
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _LessonModeTabPage(child: widget.readBody),
                          _LessonModeTabPage(child: widget.audioBody),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BlocSelector<LessonCubit, LessonState, bool>(
                        selector: (state) => state.isBottomButtonVisible,
                        builder: (context, isVisible) {
                          if (widget.selectedMode.isAudio || widget.bottom == null) {
                            return const SizedBox.shrink();
                          }
                          return _AnimatedLessonBottomBar(
                            isVisible: isVisible,
                            child: widget.bottom!,
                          );
                        },
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonModeTabPage extends StatefulWidget {
  const _LessonModeTabPage({
    required this.child,
  });

  final Widget child;

  @override
  State<_LessonModeTabPage> createState() => _LessonModeTabPageState();
}

class _LessonModeTabPageState extends State<_LessonModeTabPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _LessonDualModeHeader extends StatelessWidget {
  const _LessonDualModeHeader({
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.canSwitchModes,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final bool canSwitchModes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20.w,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: Center(
                  child: SvgPicture.asset(
                    AppAsset.svg.app.icClose,
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFAAB8CD),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _LessonModeToggle(
            selectedMode: selectedMode,
            onModeSelected: canSwitchModes ? onModeSelected : null,
          ),
        ],
      ),
    );
  }
}

class _LessonModeToggle extends StatelessWidget {
  const _LessonModeToggle({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode>? onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onModeSelected == null ? 0.6 : 1,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F6),
          borderRadius: BorderRadius.circular(160.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LessonModeTab(
              label: context.l10n.lesson.audioReadLabel,
              iconAsset: AppAsset.svg.app.icMenu,
              isSelected: selectedMode.isRead,
              onTap: onModeSelected == null ? null : () => onModeSelected!(LessonEntryMode.read),
            ),
            SizedBox(width: 3.w),
            _LessonModeTab(
              label: context.l10n.lesson.audioListenLabel,
              iconAsset: AppAsset.svg.app.icMusicNote,
              isSelected: selectedMode.isAudio,
              onTap: onModeSelected == null ? null : () => onModeSelected!(LessonEntryMode.audio),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonModeTab extends StatelessWidget {
  const _LessonModeTab({
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? const Color(0xFF0D121C) : const Color(0xFFAAB8CD);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30.h,
        padding: EdgeInsets.only(left: 12.w, right: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.backgroundWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(160.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20.w,
              height: 20.w,
              colorFilter: ColorFilter.mode(
                foregroundColor,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 8.w),
            AppText(
              label,
              style: (isSelected ? AppStyle.textBold14 : AppStyle.text14).copyWith(
                color: foregroundColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _indexForMode(LessonEntryMode mode) => mode.isAudio ? 1 : 0;
