part of '../../community.dart';

/// The Confession hub — the fifth nav tab (design `S-01` / `S-01b` / `S-02`).
///
/// Three tabs in one screen: everything, the threads this reader follows, and
/// the room list. The first two are the same feed under a different filter, so
/// they share a scroll controller and a cubit; the third is its own list. All
/// three share the header, the composer entry and the notification bell, and
/// all are driven by [CommunityFeedCubit] so switching costs no refetch.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

enum _CommunityTab { feed, following, rooms }

extension _CommunityTabX on _CommunityTab {
  /// The two feed tabs differ only by filter — the rooms tab has no feed at all.
  bool get isFeed => this != _CommunityTab.rooms;

  CommunityFeedScope get scope => this == _CommunityTab.following ? CommunityFeedScope.following : CommunityFeedScope.all;
}

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  _CommunityTab _tab = _CommunityTab.feed;

  /// Held here, not in the header: the header rebuilds on every tab change and
  /// fresh GlobalKeys each time would leave the tour pointing at nothing.
  final CommunityTourAnchors _tourAnchors = CommunityTourAnchors();

  /// Which beat of the first-run tour is on screen, or null when it is not
  /// running. Started from the member status, which the feed refreshes on
  /// every entry to the tab.
  CommunityTourStep? _tourStep;

  /// True once this mount has decided about the tour, so a later status refresh
  /// (or the reader finishing it) cannot start it a second time.
  bool _tourResolved = false;

  CommunityFeedCubit get _cubit => context.read<CommunityFeedCubit>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The route listener also calls this on later entries; the cubit decides
    // whether that means a fetch or nothing at all.
    _cubit.ensureLoaded();
    _claimRoute();
    // The status may already be loaded (re-entering the tab), in which case no
    // change ever reaches the listener above.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeStartTour(_cubit.state.memberStatus);
    });
  }

  /// Tells the app which screen is on top.
  ///
  /// A tab switch does NOT fire the route observer, so nothing else does this
  /// for us: whatever the previous tab set stays set. That is how the AI Coach
  /// bubble — which renders only for Home and Habit and reads exactly this name
  /// — ended up floating over Confession, on top of the chat button. Claimed on
  /// mount AND on every arrival, because a deep link opens straight here with no
  /// index change at all.
  void _claimRoute() {
    // After the frame: PageCubit is read by widgets already building this pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PageCubit>().setCurrentRouteName(RouteNamed.community);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_tab.isFeed) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _cubit.loadMore();
    }
  }

  /// The community shell branch. Returning to the tab has to re-check the feed
  /// from here: this page stays alive inside its branch navigator, so initState
  /// does not run again on a tab switch.
  static const int _communityBranchIndex = 6;

  /// Opens the tour the first time the status says this reader has not seen it.
  ///
  /// Driven from the status rather than from `initState`: the flag arrives with
  /// the feed's own load, so on a cold entry it is simply not known yet when
  /// this page first builds.
  void _maybeStartTour(CommunityMemberStatusEntity status) {
    if (_tourResolved || status.tourSeen) return;
    _tourResolved = true;
    // After the frame: the tour measures the header chips, and they have no
    // size until this build has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _tourStep = CommunityTourStep.welcome);
    });
  }

  /// One tap on the tour's button: move to the next beat, or finish.
  ///
  /// Finishing stamps the flag server-side and, on the last step, hands the
  /// reader straight to the composer — the design ends on "Viết bài đầu tiên",
  /// which is an invitation and has to actually open something.
  Future<void> _advanceTour() async {
    final current = _tourStep;
    if (current == null) return;

    final next = current.next;
    if (next != null) {
      setState(() {
        _tourStep = next;
        _tab = _CommunityTab.values[next.underlyingTabIndex ?? 0];
      });
      if (_tab.isFeed) _cubit.setScope(_tab.scope);

      return;
    }

    setState(() {
      _tourStep = null;
      _tab = _CommunityTab.feed;
    });
    _cubit.setScope(_CommunityTab.feed.scope);
    unawaited(_cubit.markTourSeen());

    final allowed = await communityRequireAccount(context, _cubit.state.memberStatus);
    if (!allowed || !mounted) return;

    final created = await const CommunityComposeRoute().push<bool>(context);
    if (created == true) await _cubit.refresh();
  }

  /// Switching tab also switches what the feed is filtered by.
  ///
  /// The scope lives in the cubit rather than in this widget's state because
  /// the empty states and the "see all posts" action both have to move it, and
  /// they sit further down the tree than the header does.
  void _onTabChanged(_CommunityTab tab) {
    setState(() => _tab = tab);
    if (tab.isFeed) _cubit.setScope(tab.scope);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex != _communityBranchIndex) return;
        _claimRoute();
        // ensureLoaded decides whether this is a fetch, a silent refresh, or
        // nothing at all — flicking between tabs must not cost a request.
        unawaited(_cubit.ensureLoaded());
      },
      child: BlocListener<CommunityFeedCubit, CommunityFeedState>(
        listenWhen: (previous, current) => previous.memberStatus.tourSeen != current.memberStatus.tourSeen,
        listener: (context, state) => _maybeStartTour(state.memberStatus),
        child: Scaffold(
          // Transparent under a custom study background so the shell's
          // ThemedBackground shows through, exactly like Home/Explore/Library.
          backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    _CommunityHeader(tab: _tab, onTabChanged: _onTabChanged, anchors: _tourAnchors),
                    Expanded(
                      child: _tab.isFeed
                          ? _CommunityFeedList(
                              scrollController: _scrollController,
                              onSeeAll: () => _onTabChanged(_CommunityTab.feed),
                            )
                          : const _CommunityRoomsList(),
                    ),
                  ],
                ),
                // Above the floating nav pill, bottom-right (design `S-03`). Only
                // on the hub: inside a post or a room the reader is already
                // somewhere, and the design drops it there too.
                Positioned(
                  right: 18.w,
                  bottom: floatingNavBarHeight(context) + 16.h,
                  child: CommunityChatFabLoader(key: _tourAnchors.chatBubble, room: communityDefaultChatRoom),
                ),
                // The first-run tour, last in the Stack so it covers the hub —
                // including the bubble it points at on its fifth beat.
                //
                // A DIRECT child of the Stack: `Positioned` handed to anything
                // else (a listener, a builder) is a ParentDataWidget in the wrong
                // place and throws the moment the tour opens.
                if (_tourStep != null)
                  Positioned.fill(
                    child: CommunityTour(
                      step: _tourStep!,
                      anchors: _tourAnchors,
                      onNext: () => unawaited(_advanceTour()),
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

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.tab, required this.onTabChanged, required this.anchors});

  final _CommunityTab tab;
  final void Function(_CommunityTab tab) onTabChanged;

  /// Where the first-run tour points. Held by the page so the keys survive the
  /// header rebuilding on every tab change.
  final CommunityTourAnchors anchors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Container(
      // An opaque strip here would punch a grey band across the top of the
      // reader's background.
      color: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  l10n.title,
                  style: AppStyle.textBold22.copyWith(
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                ),
              ),
              // No bookmark shortcut any more: following a thread IS the save,
              // and the "Đang theo dõi" tab is where those live now.
              const _NotificationBell(),
              SizedBox(width: 8.w),
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () async {
                    // Captured before the awaits: both the auth screen and the
                    // composer are full-screen pushes, so this context can be
                    // gone by the time either returns.
                    final cubit = context.read<CommunityFeedCubit>();
                    final allowed = await communityRequireAccount(
                      context,
                      cubit.state.memberStatus,
                    );
                    if (!allowed || !context.mounted) return;

                    final created = await const CommunityComposeRoute().push<bool>(context);
                    if (created == true) await cubit.refresh();
                  },
                  child: Container(
                    key: anchors.compose,
                    width: 32.w,
                    height: 32.w,
                    alignment: Alignment.center,
                    // Always live, never greyed: a guest tapping this is how
                    // they reach the sign-in screen. A disabled-looking button
                    // says "broken", which is the opposite of the invitation
                    // this is meant to be.
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.brandPrimary,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18.sp,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _TabChip(
                key: anchors.tabAll,
                label: l10n.tabAll,
                isActive: tab == _CommunityTab.feed,
                onTap: () => onTabChanged(_CommunityTab.feed),
              ),
              SizedBox(width: 8.w),
              _TabChip(
                key: anchors.tabFollowing,
                label: l10n.tabFollowing,
                isActive: tab == _CommunityTab.following,
                onTap: () => onTabChanged(_CommunityTab.following),
              ),
              SizedBox(width: 8.w),
              _TabChip(
                key: anchors.tabRooms,
                label: l10n.tabTopics,
                isActive: tab == _CommunityTab.rooms,
                onTap: () => onTabChanged(_CommunityTab.rooms),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CommunityFeedCubit, CommunityFeedState, int>(
      selector: (state) => state.unreadNotifications,
      builder: (context, unread) => GestureDetector(
        onTap: () async {
          await const CommunityNotificationRoute().push(context);
          if (!context.mounted) return;
          // Opening the inbox marks everything read, so the badge here has to
          // be told rather than waiting for the next feed refresh.
          context.read<CommunityFeedCubit>().setUnreadNotifications(0);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none,
                size: 21.sp,
                color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
              ),
              if (unread > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.errorRed,
                      border: Border.all(
                        color: studyThemeHasCustomBg(context) ? Colors.transparent : AppCustomColor.backgroundGray,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({super.key, required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isActive ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(99.r),
          border: isActive ? null : Border.all(color: AppCustomColor.borderDefault),
        ),
        child: AppText(
          label,
          style: AppStyle.textBold12.copyWith(
            color: isActive ? AppCustomColor.textWhite : AppCustomColor.streakTextMuted,
          ),
        ),
      ),
    );
  }
}

class _CommunityFeedList extends StatelessWidget {
  const _CommunityFeedList({
    required this.scrollController,
    required this.onSeeAll,
  });

  final ScrollController scrollController;

  /// Moves the reader back to the "Tất cả" TAB, not just the scope: the two are
  /// the same thing now, and changing one without the other would leave the
  /// header highlighting a tab the list is not showing.
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CommunityStatus.failure && state.posts.isEmpty) {
          return _CommunityMessage(
            title: l10n.errorTitle,
            body: state.errorMessage ?? l10n.errorBody,
            actionLabel: l10n.retry,
            onAction: () => context.read<CommunityFeedCubit>().load(),
          );
        }

        final cubit = context.read<CommunityFeedCubit>();
        final posts = [...state.pinned, ...state.posts];

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, floatingNavBarHeight(context) + 24.h),
            children: [
              CommunityMutedBanner(
                status: state.memberStatus,
                // An explicit sign-in button goes straight there; showing the
                // "you need to sign in" notice to someone who just tapped
                // "Đăng nhập" would be telling them what they already said.
                onSignIn: _openCommunityAuth,
              ),
              if (state.weekly != null)
                CommunityWeeklyCard(
                  weekly: state.weekly!,
                  onTap: () => const CommunityWeeklyRoute().push(context),
                ),
              if (state.isEmpty)
                _CommunityMessage(
                  title: state.isFollowingNothing ? l10n.emptyFollowingTitle : l10n.emptyFeedTitle,
                  body: state.isFollowingNothing ? l10n.emptyFollowingBody : l10n.emptyFeedBody,
                  actionLabel: state.isFollowingNothing ? l10n.emptyFollowingAction : null,
                  onAction: state.isFollowingNothing ? onSeeAll : null,
                ),
              ...posts.map(
                (post) => CommunityPostCard(
                  post: post,
                  onOpen: () => _openPost(context, post),
                  onLike: () => _gated(
                    context,
                    state.memberStatus,
                    () => cubit.toggleReaction(post, CommunityReactionKind.like),
                  ),
                  onFollowThread: () => _gated(
                    context,
                    state.memberStatus,
                    () => cubit.toggleReaction(post, CommunityReactionKind.save),
                  ),
                  onTopic: (topic) => CommunityTopicRoute(topicId: topic.id).push(context),
                  onCard: (card) => showCommunityInsightShareSheet(context, card: card),
                  onMenu: () => showCommunityItemMenu(
                    context,
                    isMine: post.isMine,
                    onHide: () => cubit.hidePost(post),
                    onReport: () => _gated(
                      context,
                      state.memberStatus,
                      () => showCommunityReportSheet(
                        context,
                        onSubmit: (reason) => cubit.reportPost(post, reason),
                      ),
                    ),
                    onDelete: () async {
                      final deleted = await cubit.deleteOwnPost(post);
                      DMessage.showMessage(
                        message: deleted ? l10n.deletePostDone : l10n.errorBody,
                        type: deleted ? MessageType.success : MessageType.error,
                      );
                    },
                  ),
                ),
              ),
              if (state.isLoadingMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPost(BuildContext context, CommunityPostEntity post) async {
    final cubit = context.read<CommunityFeedCubit>();
    final result = await CommunityPostRoute(
      postId: post.id,
    ).push<CommunityPostScreenResult?>(context);

    if (result == null) return;
    // Deleted or hidden in there — the row has to go, not be refreshed.
    if (result.removed) {
      cubit.removePost(post.id);
      return;
    }
    // Likes and comments may have moved while the thread was open; a stale card
    // under the reader's finger is the thing this avoids.
    final updated = result.post;
    if (updated != null) cubit.applyPostUpdate(updated);
  }
}

/// The "Phòng" tab (design `S-02`): the rooms this reader keeps, the rest as a
/// grid, and the way to ask for one that does not exist.
///
/// Favourites are rows and the rest are tiles on purpose — a row carries the
/// freshness line ("14 bài mới hôm nay") that makes a kept room worth opening,
/// while a tile carries the name and the size, which is what you judge an
/// unfamiliar room by.
class _CommunityRoomsList extends StatelessWidget {
  const _CommunityRoomsList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      buildWhen: (previous, current) => previous.topics != current.topics || previous.topicsStatus != current.topicsStatus || previous.memberStatus != current.memberStatus,
      builder: (context, state) {
        if (state.topicsStatus == CommunityStatus.loading && state.topics.all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<CommunityFeedCubit>();
        final favourites = state.topics.following;
        final explore = state.topics.all.where((topic) => !favourites.any((kept) => kept.id == topic.id)).toList();
        final isEmpty = favourites.isEmpty && explore.isEmpty;

        return RefreshIndicator(
          onRefresh: cubit.loadTopics,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20.w,
              8.h,
              20.w,
              floatingNavBarHeight(context) + 24.h,
            ),
            children: [
              if (favourites.isNotEmpty) ...[
                _SectionLabel(label: l10n.sectionFavourites),
                ...favourites.map(
                  (topic) => CommunityFavouriteRoomRow(
                    topic: topic,
                    onTap: () => CommunityTopicRoute(topicId: topic.id).push(context),
                  ),
                ),
                SizedBox(height: 26.h),
              ],
              if (explore.isNotEmpty) ...[
                _SectionLabel(label: l10n.sectionExploreRooms),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  // A room name runs to three lines, so the tile is taller than
                  // it is wide. childAspectRatio, not a fixed height: the tile
                  // has to grow with the reader's text scale.
                  childAspectRatio: 0.98,
                  children: explore
                      .map(
                        (topic) => CommunityRoomTile(
                          topic: topic,
                          onTap: () => CommunityTopicRoute(
                            topicId: topic.id,
                          ).push(context),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 24.h),
              ],
              if (isEmpty)
                _CommunityMessage(
                  title: l10n.emptyTopicsTitle,
                  body: l10n.emptyTopicsBody,
                ),
              _RoomSuggestPrompt(memberStatus: state.memberStatus),
            ],
          ),
        );
      },
    );
  }
}

/// "Không thấy phòng bạn cần?" — the card at the bottom of the room list.
class _RoomSuggestPrompt extends StatelessWidget {
  const _RoomSuggestPrompt({required this.memberStatus});

  final CommunityMemberStatusEntity memberStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            l10n.roomSuggestPromptTitle,
            style: AppStyle.textBold14.copyWith(
              color: AppCustomColor.communityTopicHeading,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            l10n.roomSuggestPromptBody,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.streakTextMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _gated(
              context,
              memberStatus,
              () => showCommunityRoomSuggestSheet(context),
            ),
            child: Container(
              height: 38.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: AppText(
                l10n.roomSuggestCta,
                style: AppStyle.textBold12.copyWith(
                  color: AppCustomColor.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      // A plain dark heading, not an uppercase eyebrow: the design gives these
      // the weight of a section title because they separate two different
      // KINDS of list, not two parts of one.
      child: AppText(
        label,
        style: AppStyle.textBold14.copyWith(
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
    );
  }
}

/// Shared empty / error block, so every one of the community's several empty
/// states reads the same way.
class _CommunityMessage extends StatelessWidget {
  const _CommunityMessage({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Align, so this sizes to its content whatever it is handed.
    //
    // It is used in two very different places: inside a ListView (unbounded
    // height, so a plain Container shrink-wraps) and straight as a Scaffold
    // `body` (TIGHT height, where the same Container was stretched into a
    // full-screen white slab with two lines at the top of it). `heightFactor: 1`
    // makes it size to the child in both, and the child's own
    // `width: double.infinity` keeps the card full width rather than
    // shrink-wrapping to the text once the constraints are loosened.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 24.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              title,
              style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            AppText(
              body,
              style: AppStyle.text12.copyWith(
                color: studyThemeCardMuted(context, AppCustomColor.streakTextMuted),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 14.h),
              GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: AppText(
                  actionLabel!,
                  style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Runs [action] only once the reader is allowed to write.
///
/// Wrapping the write rather than hiding the button: a guest should still see
/// the heart and the follow chip — tapping is how they find out an account is
/// needed, and hiding them would make the forum look read-only.
Future<void> _gated(
  BuildContext context,
  CommunityMemberStatusEntity status,
  void Function() action,
) async {
  if (await communityRequireAccount(context, status)) action();
}
