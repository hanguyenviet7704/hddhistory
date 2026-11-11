part of '../utils.dart';

class FilterTabBar extends StatefulWidget {
  const FilterTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.padding,
    this.autoScrollToSelected = false,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final EdgeInsets? padding;

  /// When true, the strip animates the selected chip into view as
  /// [selectedIndex] changes (used by the Explore scrollspy so the active chip
  /// stays visible). Off by default — existing callers are unchanged.
  final bool autoScrollToSelected;

  @override
  State<FilterTabBar> createState() => _FilterTabBarState();
}

class _FilterTabBarState extends State<FilterTabBar> {
  final ScrollController _controller = ScrollController();
  List<GlobalKey> _itemKeys = const [];

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  void _syncKeys() {
    if (_itemKeys.length != widget.tabs.length) {
      _itemKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant FilterTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (widget.autoScrollToSelected &&
        widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex >= 0 &&
        widget.selectedIndex < _itemKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelectedVisible());
    }
  }

  void _ensureSelectedVisible() {
    final ctx = _itemKeys[widget.selectedIndex].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: widget.tabs.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          return Semantics(
            key: _itemKeys[index],
            label: widget.tabs[index],
            button: true,
            selected: isSelected,
            child: InkWell(
              onTap: () {
                AppHaptic.select();
                widget.onTabSelected(index);
              },
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppCustomColor.brandPrimary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppCustomColor.brandPrimary
                        : AppCustomColor.borderDefault,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  widget.tabs[index],
                  style: AppStyle.text14.copyWith(
                    color: isSelected
                        ? AppCustomColor.backgroundWhite
                        : AppCustomColor.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
