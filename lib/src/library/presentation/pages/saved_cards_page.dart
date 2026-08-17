part of '../../library.dart';

/// "Saved cards" (design `5b · Library` → screens 5, 6 and 7): the recap cards
/// the reader kept, as a grid or as a deck they can swipe and flip.
///
/// Two views over one list, and the choice lives in [SavedState] so leaving the
/// screen and coming back does not silently put them back in the grid.
class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({super.key});

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage> {
  final ScrollController _scrollController = ScrollController();
  final SavedToastController _toast = SavedToastController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SavedCubit>().ensureCardsLoaded());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _toast.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240.h) return;
    unawaited(context.read<SavedCubit>().loadCards(isInit: false));
  }

  void _openCard(SavedCardEntity card) {
    AppHaptic.select();
    SavedCardDetailOverlay.show(context, card: card);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: BlocBuilder<SavedCubit, SavedState>(
        builder: (context, state) {
          return Column(
            children: [
              _SavedCardsHeader(
                isDeck: state.cardsDeckView,
                onViewChanged: (deck) {
                  AppHaptic.select();
                  context.read<SavedCubit>().setCardsDeckView(deck: deck);
                },
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SavedState state) {
    if (state.isCardsInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary));
    }

    if (state.isCardsFailure && state.cards.isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 12.h),
        child: LibraryInlineError(
          message: state.errorMessage,
          onRetry: () => context.read<SavedCubit>().loadCards(isInit: true),
        ),
      );
    }

    if (state.cards.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<SavedCubit>().loadCards(isInit: true),
        child: _LibraryHistoryEmpty(message: context.l10n.library.emptySavedCards),
      );
    }

    // The deck is a fixed-height stack the reader swipes through — it must not
    // page on scroll, and it brings its own toast, so it does not share the
    // grid's scroll plumbing.
    if (state.cardsDeckView) {
      return SavedCardsDeck(cards: state.cards, toast: _toast);
    }

    final showPagingLoader = state.cardsStatus == SavedStatus.loading && state.cards.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => context.read<SavedCubit>().loadCards(isInit: true),
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, floatingNavBarHeight(context) + 20.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          childAspectRatio: 3 / 4,
        ),
        itemCount: state.cards.length + (showPagingLoader ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= state.cards.length) {
            // Occupies a grid cell rather than a row: a GridView has no
            // full-width slot to put a footer spinner in.
            return index == state.cards.length ? const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary)) : const SizedBox.shrink();
          }
          final card = state.cards[index];
          return Semantics(
            button: true,
            label: card.displayTitle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openCard(card),
              child: SavedQuoteCard(
                title: card.displayTitle,
                courseTitle: card.courseTitle.text,
                imageUrl: card.image,
                size: SavedQuoteCardSize.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Back · centred "Saved cards" · the grid/deck segmented control.
class _SavedCardsHeader extends StatelessWidget {
  const _SavedCardsHeader({required this.isDeck, required this.onViewChanged});

  final bool isDeck;
  final void Function(bool deck) onViewChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    final ink = studyThemeOnBg(context, AppCustomColor.textPrimary);

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, MediaQuery.paddingOf(context).top + 14.h, 24.w, 14.h),
      child: SizedBox(
        height: 44.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppText(
              l10n.savedCardsTitle,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                color: ink,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: context.l10n.common.back,
                child: GestureDetector(
                  key: const Key('saved-cards-back-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptic.select();
                    context.back();
                  },
                  child: SizedBox(
                    width: 44.w,
                    height: 44.h,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.w, color: ink),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _SavedCardsViewToggle(isDeck: isDeck, onChanged: onViewChanged),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-up segmented control (design: #F2F3F8 track, 26×24 buttons, 3 padding).
class _SavedCardsViewToggle extends StatelessWidget {
  const _SavedCardsViewToggle({required this.isDeck, required this.onChanged});

  final bool isDeck;
  final void Function(bool deck) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _kSavedTileGrey,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SavedCardsViewToggleButton(
            semanticsLabel: l10n.gridViewLabel,
            icon: Icons.grid_view_rounded,
            isSelected: !isDeck,
            onTap: () => onChanged(false),
          ),
          2.horizontalSpace,
          _SavedCardsViewToggleButton(
            semanticsLabel: l10n.deckViewLabel,
            icon: Icons.filter_none_rounded,
            isSelected: isDeck,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SavedCardsViewToggleButton extends StatelessWidget {
  const _SavedCardsViewToggleButton({
    required this.semanticsLabel,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 30.w,
          height: 26.h,
          decoration: BoxDecoration(
            color: isSelected ? AppCustomColor.backgroundWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(99.r),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 14.w,
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.textQuaternary,
          ),
        ),
      ),
    );
  }
}
