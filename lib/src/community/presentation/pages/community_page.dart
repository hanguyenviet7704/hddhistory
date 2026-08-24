part of '../../community.dart';

/// The community hub — the fifth nav tab (design `S-01` / `S-02`).
///
/// Two tabs in one screen: the feed and the topic list. They share the header,
/// the composer entry point and the notification bell, and both are driven by
/// [CommunityFeedCubit] so switching between them costs no refetch of the other.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

enum _CommunityTab { feed, topics }

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  _CommunityTab _tab = _CommunityTab.feed;

  CommunityFeedCubit get _cubit => context.read<CommunityFeedCubit>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The route listener also calls this on later entries; the cubit decides
    // whether that means a fetch or nothing at all.
    _cubit.ensureLoaded();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_tab != _CommunityTab.feed) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _cubit.loadMore();
    }
  }

  /// The community shell branch. Returning to the tab has to re-check the feed
  /// from here: this page stays alive inside its branch navigator, so initState
  /// does not run again on a tab switch.
  static const int _communityBranchIndex = 6;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex != _communityBranchIndex) return;
        // ensureLoaded decides whether this is a fetch, a silent refresh, or
        // nothing at all — flicking between tabs must not cost a request.
        unawaited(_cubit.ensureLoaded());
      },
      child: Scaffold(
        // Transparent under a custom study background so the shell's
        // ThemedBackground shows through, exactly like Home/Explore/Library.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CommunityHeader(
                tab: _tab,
                onTabChanged: (tab) => setState(() => _tab = tab),
              ),
              Expanded(
                child: _tab == _CommunityTab.feed
                    ? _CommunityFeedList(
                        scrollController: _scrollController,
                        onManageTopics: () =>
                            setState(() => _tab = _CommunityTab.topics),
                      )
                    : const _CommunityTopicsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.tab, required this.onTabChanged});

  final _CommunityTab tab;
  final void Function(_CommunityTab tab) onTabChanged;

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
              GestureDetector(
                onTap: () => const CommunitySavedRoute().push(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.bookmark_border,
                    size: 20.sp,
                    color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
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
                label: l10n.tabAll,
                isActive: tab == _CommunityTab.feed,
                onTap: () => onTabChanged(_CommunityTab.feed),
              ),
              SizedBox(width: 8.w),
              _TabChip(
                label: l10n.tabTopics,
                isActive: tab == _CommunityTab.topics,
                onTap: () => onTabChanged(_CommunityTab.topics),
              ),
              const Spacer(),
              if (tab == _CommunityTab.feed) const _ScopeToggle(),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Tất cả" / "Đang theo dõi" — the second axis of the feed, kept next to the
/// tabs rather than inside the list so it does not scroll away.
class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocSelector<CommunityFeedCubit, CommunityFeedState, CommunityFeedScope>(
      selector: (state) => state.scope,
      builder: (context, scope) {
        final isFollowing = scope == CommunityFeedScope.following;

        return GestureDetector(
          onTap: () => context.read<CommunityFeedCubit>().setScope(
            isFollowing ? CommunityFeedScope.all : CommunityFeedScope.following,
          ),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFollowing ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 15.sp,
                color: isFollowing
                    ? studyThemeAccentOnBg(context, AppCustomColor.brandPrimary)
                    : studyThemeOnBg(context, AppCustomColor.streakTextMuted),
              ),
              SizedBox(width: 4.w),
              AppText(
                isFollowing ? l10n.scopeFollowing : l10n.scopeAll,
                style: AppStyle.textBold12.copyWith(
                  color: isFollowing
                      ? studyThemeAccentOnBg(context, AppCustomColor.brandPrimary)
                      : studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                ),
              ),
            ],
          ),
        );
      },
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
                        color: studyThemeHasCustomBg(context)
                            ? Colors.transparent
                            : AppCustomColor.backgroundGray,
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
  const _TabChip({required this.label, required this.isActive, required this.onTap});

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
    required this.onManageTopics,
  });

  final ScrollController scrollController;
  final VoidCallback onManageTopics;

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
                onSignIn: () => communityRequireAccount(context, state.memberStatus),
              ),
              // Only on the following feed: it explains why this list is
              // shorter than "Tất cả", and offers the way to widen it.
              if (state.scope == CommunityFeedScope.following && !state.isFollowingNothing)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          l10n.followNote,
                          style: AppStyle.text12.copyWith(
                            color: studyThemeOnBg(context, AppCustomColor.communityMuted),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: onManageTopics,
                        behavior: HitTestBehavior.opaque,
                        child: AppText(
                          l10n.manageTopics,
                          style: AppStyle.textBold12.copyWith(
                            color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (state.weekly != null)
                CommunityWeeklyCard(
                  weekly: state.weekly!,
                  onTap: () => const CommunityWeeklyRoute().push(context),
                ),
              if (state.isEmpty)
                _CommunityMessage(
                  title: state.isFollowingNothing
                      ? l10n.emptyFollowingTitle
                      : l10n.emptyFeedTitle,
                  body: state.isFollowingNothing
                      ? l10n.emptyFollowingBody
                      : l10n.emptyFeedBody,
                  actionLabel: state.isFollowingNothing ? l10n.emptyFollowingAction : null,
                  onAction: state.isFollowingNothing
                      ? () => cubit.setScope(CommunityFeedScope.all)
                      : null,
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
                  onSave: () => _gated(
                    context,
                    state.memberStatus,
                    () => cubit.toggleReaction(post, CommunityReactionKind.save),
                  ),
                  onTopic: (topic) => CommunityTopicRoute(topicId: topic.id).push(context),
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

class _CommunityTopicsList extends StatelessWidget {
  const _CommunityTopicsList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      buildWhen: (previous, current) =>
          previous.topics != current.topics || previous.topicsStatus != current.topicsStatus,
      builder: (context, state) {
        if (state.topicsStatus == CommunityStatus.loading && state.topics.all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<CommunityFeedCubit>();

        return RefreshIndicator(
          onRefresh: cubit.loadTopics,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, floatingNavBarHeight(context) + 24.h),
            children: [
              if (state.topics.following.isNotEmpty) ...[
                _SectionLabel(label: l10n.sectionFollowing),
                ...state.topics.following.map(
                  (topic) => CommunityTopicRow(
                    topic: topic,
                    onOpen: () => CommunityTopicRoute(topicId: topic.id).push(context),
                    onToggleFollow: () => _gated(
                      context,
                      state.memberStatus,
                      () => cubit.toggleTopicFollow(topic),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              _SectionLabel(label: l10n.sectionAllTopics),
              ...state.topics.all.map(
                (topic) => CommunityTopicRow(
                  topic: topic,
                  onOpen: () => CommunityTopicRoute(topicId: topic.id).push(context),
                  onToggleFollow: () => _gated(
                    context,
                    state.memberStatus,
                    () => cubit.toggleTopicFollow(topic),
                  ),
                ),
              ),
              if (state.topics.all.isEmpty && state.topics.following.isEmpty)
                _CommunityMessage(title: l10n.emptyTopicsTitle, body: l10n.emptyTopicsBody),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AppText(
        label,
        style: AppStyle.textBold10.copyWith(
          color: studyThemeOnBg(context, AppCustomColor.communityMuted),
          letterSpacing: 0.8,
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
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
