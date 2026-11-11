part of '../../community.dart';

/// Drives the community hub: the two feed tabs, the topic list, the weekly
/// card, and the reader's own posting rights.
///
/// Deliberately not hydrated. A forum feed is other people's writing — a cached
/// copy would show a reader posts that were taken down while the app was
/// closed, and the moderation queue exists precisely so that does not happen.
@lazySingleton
class CommunityFeedCubit extends Cubit<CommunityFeedState> with CubitUseCaseHandlerMixin<CommunityFeedState> {
  final GetCommunityFeedUseCase _getFeedUseCase;
  final GetCommunityTopicsUseCase _getTopicsUseCase;
  final SetCommunityTopicFollowUseCase _setFollowUseCase;
  final SetCommunityReactionUseCase _setReactionUseCase;
  final HideCommunityItemUseCase _hideUseCase;
  final ReportCommunityItemUseCase _reportUseCase;
  final DeleteCommunityPostUseCase _deletePostUseCase;
  final GetCommunityMemberStatusUseCase _memberStatusUseCase;
  final GetCommunityUnreadCountUseCase _getUnreadCountUseCase;
  final MarkCommunityTourSeenUseCase _markTourSeenUseCase;

  CommunityFeedCubit(
    this._getFeedUseCase,
    this._getTopicsUseCase,
    this._setFollowUseCase,
    this._setReactionUseCase,
    this._hideUseCase,
    this._reportUseCase,
    this._deletePostUseCase,
    this._memberStatusUseCase,
    this._getUnreadCountUseCase,
    this._markTourSeenUseCase,
  ) : super(CommunityFeedState.initial());

  static const int _pageSize = 10;

  /// How long a loaded feed is trusted before re-entering the tab refetches.
  ///
  /// Short, because the whole point of a forum is that it moves: coming back
  /// after a few minutes and seeing the same four posts reads as broken.
  static const Duration _freshFor = Duration(minutes: 2);

  DateTime? _loadedAt;

  /// Drop everything this holds — called when the ACCOUNT changes.
  ///
  /// This cubit is a lazySingleton, so it survives a guest signing in and keeps
  /// serving the previous session's feed, posting rights and unread badge. Worse
  /// than stale: `ensureLoaded` trusts a copy for two minutes, so returning to
  /// the tab right after signing in did nothing at all and the reader was still
  /// told to sign in. Same reason `HabitCubit` is reset on the same transition.
  void reset() {
    _loadedAt = null;
    emit(CommunityFeedState.initial());
  }

  /// Called from the route listener on every entry to the tab.
  ///
  /// First entry loads; a later one refreshes only once the copy in hand has
  /// gone stale, so flicking between tabs costs nothing.
  Future<void> ensureLoaded() {
    if (state.status == CommunityStatus.loading) return Future.value();
    if (state.status != CommunityStatus.success) return load();

    final loadedAt = _loadedAt;
    if (loadedAt != null && DateTime.now().difference(loadedAt) < _freshFor) {
      return Future.value();
    }

    return load(silent: true);
  }

  /// [silent] is the refresh path: no spinner over a feed that is already
  /// drawn, and a failed refresh leaves the posts in hand rather than replacing
  /// them with an error.
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: CommunityStatus.loading));

    // The topic list, the member status and the unread badge are all wanted on
    // the same screen, so they go out together rather than in a chain.
    await Future.wait([
      _loadFeed(page: 1, silent: silent),
      loadTopics(),
      refreshMemberStatus(),
      refreshUnreadCount(),
    ]);
  }

  Future<void> refresh() => load(silent: true);

  Future<void> _loadFeed({required int page, bool silent = false}) async {
    final result = await _getFeedUseCase(
      page: page,
      take: _pageSize,
      followedOnly: state.scope == CommunityFeedScope.following,
      // Page 1 asks for a new anchor; later pages reuse the one it stamped.
      anchorAt: page == 1 ? null : state.anchorAt,
    ).run();

    result.fold(
      (exception) {
        if (silent) return;
        emit(
          state.copyWith(
            status: CommunityStatus.failure,
            isLoadingMore: false,
            errorMessage: exception.message,
          ),
        );
      },
      (feed) {
        _loadedAt = DateTime.now();
        emit(
          state.copyWith(
            status: CommunityStatus.success,
            pinned: page == 1 ? feed.pinned : state.pinned,
            posts: page == 1 ? feed.items : [...state.posts, ...feed.items],
            weekly: page == 1 ? feed.weekly : state.weekly,
            anchorAt: page == 1 ? feed.anchorAt : state.anchorAt,
            currentPage: feed.currentPage == 0 ? page : feed.currentPage,
            totalPages: feed.totalPages == 0 ? 1 : feed.totalPages,
            isLoadingMore: false,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    await _loadFeed(page: state.currentPage + 1, silent: true);
  }

  /// Switching tabs resets the list: the two tabs are different queries, and
  /// keeping the old rows visible under a new tab label is a lie.
  Future<void> setScope(CommunityFeedScope scope) async {
    if (state.scope == scope) return;

    emit(
      state.copyWith(
        scope: scope,
        status: CommunityStatus.loading,
        posts: const [],
        pinned: const [],
        currentPage: 1,
        totalPages: 1,
        anchorAt: null,
      ),
    );

    await _loadFeed(page: 1);
  }

  Future<void> loadTopics() async {
    await runUseCase<CommunityTopicListEntity>(
      usecase: _getTopicsUseCase.call,
      buildLoadingState: () => state.copyWith(topicsStatus: CommunityStatus.loading),
      onFailure: (_) => emit(state.copyWith(topicsStatus: CommunityStatus.failure)),
      onSuccess: (topics) => emit(
        state.copyWith(topicsStatus: CommunityStatus.success, topics: topics),
      ),
    );
  }

  Future<void> refreshMemberStatus() async {
    final result = await _memberStatusUseCase().run();

    result.fold(
      // A failed status check must not lock the composer: the write itself is
      // guarded server-side, so the worst case is an error on submit instead of
      // a reader who cannot post for no visible reason.
      (_) {},
      (status) => emit(state.copyWith(memberStatus: status)),
    );
  }

  /// The first-run tour is finished — close it now, tell the server after.
  ///
  /// The state moves FIRST and unconditionally: the tour is over the moment the
  /// reader taps through the last step, and a failed request must not leave the
  /// overlay sitting on the screen. The server call is what makes it stick
  /// across devices; if it fails the reader simply meets the tour once more.
  Future<void> markTourSeen() async {
    if (state.memberStatus.tourSeen) return;

    emit(state.copyWith(memberStatus: state.memberStatus.copyWith(tourSeen: true)));
    await _markTourSeenUseCase().run();
  }

  Future<void> refreshUnreadCount() async {
    final result = await _getUnreadCountUseCase().run();

    result.fold(
      (_) {},
      (count) => emit(state.copyWith(unreadNotifications: count)),
    );
  }

  /// Optimistic follow toggle: the chip flips at once and reverts if the call
  /// fails, because a follow that takes a round-trip to show feels broken.
  Future<void> toggleTopicFollow(CommunityTopicEntity topic) async {
    final follow = !topic.isFollowing;
    _applyTopicFollow(topic.id, follow);

    final result = await _setFollowUseCase(topicId: topic.id, follow: follow).run();

    await result.fold(
      (_) async => _applyTopicFollow(topic.id, !follow),
      (_) async {
        // The following tab IS the follow list, so it has to be refetched once
        // that list changes.
        if (state.scope == CommunityFeedScope.following) {
          await _loadFeed(page: 1, silent: true);
        }
      },
    );
  }

  void _applyTopicFollow(String topicId, bool follow) {
    CommunityTopicEntity apply(CommunityTopicEntity topic) => topic.id == topicId
        ? topic.copyWith(
            isFollowing: follow,
            followers: (topic.followers + (follow ? 1 : -1)).clamp(0, 1 << 30),
          )
        : topic;

    final all = [...state.topics.all, ...state.topics.following].map(apply).toList();

    emit(
      state.copyWith(
        topics: CommunityTopicListEntity(
          following: all.where((topic) => topic.isFollowing).toList(),
          all: all.where((topic) => !topic.isFollowing).toList(),
        ),
      ),
    );
  }

  /// Optimistic like / save, same reasoning as the follow chip.
  Future<void> toggleReaction(
    CommunityPostEntity post,
    CommunityReactionKind kind,
  ) async {
    final active = kind == CommunityReactionKind.like ? !post.isLiked : !post.isSaved;
    _applyReaction(post.id, kind, active);

    final result = await _setReactionUseCase(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      kind: kind,
      active: active,
    ).run();

    result.fold((_) => _applyReaction(post.id, kind, !active), (_) {});
  }

  void _applyReaction(String postId, CommunityReactionKind kind, bool active) {
    CommunityPostEntity apply(CommunityPostEntity post) {
      if (post.id != postId) return post;

      if (kind == CommunityReactionKind.like) {
        return post.copyWith(
          isLiked: active,
          likeCount: (post.likeCount + (active ? 1 : -1)).clamp(0, 1 << 30),
        );
      }

      return post.copyWith(
        isSaved: active,
        saveCount: (post.saveCount + (active ? 1 : -1)).clamp(0, 1 << 30),
      );
    }

    emit(
      state.copyWith(
        posts: state.posts.map(apply).toList(),
        pinned: state.pinned.map(apply).toList(),
      ),
    );
  }

  /// Replaces one post in the list with a fresher copy — used when returning
  /// from the detail screen, where likes and comments may have changed.
  void applyPostUpdate(CommunityPostEntity updated) {
    CommunityPostEntity apply(CommunityPostEntity post) => post.id == updated.id ? updated : post;

    emit(
      state.copyWith(
        posts: state.posts.map(apply).toList(),
        pinned: state.pinned.map(apply).toList(),
      ),
    );
  }

  /// "Ẩn nội dung này": drop it locally straight away, since the server will
  /// filter it out of every later page anyway.
  Future<void> hidePost(CommunityPostEntity post) async {
    _removePost(post.id);

    await _hideUseCase(
      targetType: CommunityTargetType.post,
      targetId: post.id,
    ).run();
  }

  Future<bool> reportPost(
    CommunityPostEntity post,
    CommunityReportReason reason, {
    String? note,
  }) async {
    final result = await _reportUseCase(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      reason: reason,
      note: note,
    ).run();

    return result.isRight();
  }

  Future<bool> deleteOwnPost(CommunityPostEntity post) async {
    final result = await _deletePostUseCase(post.id).run();

    return result.fold((_) => false, (_) {
      _removePost(post.id);
      return true;
    });
  }

  /// Drops one row — used when the thread screen reports the post gone.
  void removePost(String postId) => _removePost(postId);

  void _removePost(String postId) {
    emit(
      state.copyWith(
        posts: state.posts.where((post) => post.id != postId).toList(),
        pinned: state.pinned.where((post) => post.id != postId).toList(),
      ),
    );
  }

  void setUnreadNotifications(int count) {
    emit(state.copyWith(unreadNotifications: count));
  }
}
