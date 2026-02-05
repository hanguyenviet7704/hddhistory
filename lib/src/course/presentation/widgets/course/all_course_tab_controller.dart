part of '../../../course.dart';

class AllCourseTabController extends ChangeNotifier {
  AllCourseTabController({required int initialCategoryIndex})
      : _activeCategoryIndex = initialCategoryIndex {
    sectionPositionsListener.itemPositions.addListener(_handleSectionPositionsChanged);
  }

  final ItemScrollController sectionScrollController = ItemScrollController();
  final ItemPositionsListener sectionPositionsListener = ItemPositionsListener.create();
  final ItemScrollController categoryScrollController = ItemScrollController();

  int _activeCategoryIndex;
  bool _didInitialScroll = false;
  int? _lockedCategoryIndex;
  Timer? _scrollUnlockTimer;

  int get activeCategoryIndex => _activeCategoryIndex;

  void ensureInitialized(int totalSections) {
    if (totalSections <= 0 || _didInitialScroll) return;
    _didInitialScroll = true;
    _activeCategoryIndex = _clampIndex(_activeCategoryIndex, totalSections);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(_activeCategoryIndex, jump: true);
      _scrollCategoryTo(_activeCategoryIndex);
    });
  }

  void onCategoryTap(int index) {
    _setActiveCategory(index);
    _scrollCategoryTo(index);
    _scrollToSection(index);
  }

  void _scrollToSection(int index, {bool jump = false}) {
    if (!sectionScrollController.isAttached) return;

    if (jump) {
      sectionScrollController.jumpTo(index: index, alignment: 0);
      return;
    }

    _lockCategoryDuringScroll(index);
    sectionScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _scrollCategoryTo(int index) {
    if (!categoryScrollController.isAttached) return;

    categoryScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _handleSectionPositionsChanged() {
    final positions = sectionPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final bestIndex = _mostVisibleIndex(positions);
    if (bestIndex == null) return;

    if (_lockedCategoryIndex != null) {
      if (bestIndex != _lockedCategoryIndex) return;
      _lockedCategoryIndex = null;
      _scrollUnlockTimer?.cancel();
    }

    if (bestIndex != _activeCategoryIndex) {
      _setActiveCategory(bestIndex);
      _scrollCategoryTo(bestIndex);
    }
  }

  void _setActiveCategory(int index) {
    if (_activeCategoryIndex == index) return;
    _activeCategoryIndex = index;
    notifyListeners();
  }

  int? _mostVisibleIndex(Iterable<ItemPosition> positions) {
    int? bestIndex;
    double bestVisibility = 0;

    for (final position in positions) {
      final visibility = _visibleFraction(position);
      if (visibility > bestVisibility) {
        bestVisibility = visibility;
        bestIndex = position.index;
      }
    }

    return bestIndex;
  }

  double _visibleFraction(ItemPosition position) {
    final visibleStart = math.max(0.0, position.itemLeadingEdge);
    final visibleEnd = math.min(1.0, position.itemTrailingEdge);
    final visible = visibleEnd - visibleStart;
    return visible > 0 ? visible : 0;
  }

  void _lockCategoryDuringScroll(int index) {
    _lockedCategoryIndex = index;
    _scrollUnlockTimer?.cancel();
    _scrollUnlockTimer = Timer(const Duration(milliseconds: 350), () {
      _lockedCategoryIndex = null;
    });
  }

  int _clampIndex(int index, int total) {
    return index.clamp(0, total - 1);
  }

  @override
  void dispose() {
    _scrollUnlockTimer?.cancel();
    sectionPositionsListener.itemPositions.removeListener(_handleSectionPositionsChanged);
    super.dispose();
  }
}
