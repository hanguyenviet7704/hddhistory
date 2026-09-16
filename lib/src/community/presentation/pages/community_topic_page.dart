part of '../../community.dart';

/// One topic's own feed (design `S-03`).
///
/// Keeps its own [CommunityFeedCubit] instance? No — it reuses the hub's cubit
/// for the follow state (so following here shows up there immediately) but
/// holds its topic-scoped page locally: the hub's list must not be replaced by
/// a single topic's posts when the reader backs out.
class CommunityTopicPage extends StatefulWidget {
  const CommunityTopicPage({super.key, required this.topicId});

  final String topicId;

  @override
  State<CommunityTopicPage> createState() => _CommunityTopicPageState();
}

class _CommunityTopicPageState extends State<CommunityTopicPage> {
  final ScrollController _scrollController = ScrollController();

  CommunityTopicEntity? _topic;
  final List<CommunityPostEntity> _posts = [];
  CommunityStatus _status = CommunityStatus.initial;
  final CommunityFeedSort _sort = CommunityFeedSort.recent;
  bool _showStickyTitle = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  DateTime? _anchorAt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Past this the room's name has scrolled out of the card, so the bar takes
  /// it over. The design's own threshold.
  static const double _stickyTitleOffset = 150;

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) _loadMore();

    // setState only when the answer CHANGES: this fires on every scroll frame,
    // and rebuilding the whole feed sixty times a second to re-evaluate one
    // opacity is how a smooth list starts stuttering.
    final showTitle = position.pixels > _stickyTitleOffset;
    if (showTitle != _showStickyTitle) {
      setState(() => _showStickyTitle = showTitle);
    }
  }

  Future<void> _toggleFavourite() => _toggleFollow();

  Future<void> _composeInRoom() async {
    if (!await communityRequireAccount(context, communityMemberStatus)) return;
    if (!mounted) return;

    // Seeded with THIS room, so the composer opens already pointed at it —
    // the reader tapped `+` inside a room, not in the hub.
    final topic = _topic;
    if (topic != null) {
      AppDI.injector.get<CommunityComposeSeed>().set(
        CommunityComposeSeedData(roomId: topic.id),
      );
    }

    final created = await const CommunityComposeRoute().push<bool>(context);
    if (created == true) await _load();
  }

  Future<void> _load() async {
    setState(() => _status = CommunityStatus.loading);

    final topicResult = await AppDI.injector.get<GetCommunityTopicUseCase>()(widget.topicId).run();
    final feedResult = await AppDI.injector
        .get<GetCommunityFeedUseCase>()(
          page: 1,
          topicId: widget.topicId,
          sort: _sort,
        )
        .run();

    if (!mounted) return;

    topicResult.fold((exception) => _errorMessage = exception.message, (topic) => _topic = topic);

    feedResult.fold(
      (exception) => setState(() {
        _status = CommunityStatus.failure;
        _errorMessage = exception.message;
      }),
      (feed) => setState(() {
        _status = CommunityStatus.success;
        _posts
          ..clear()
          ..addAll(feed.items);
        _currentPage = feed.currentPage == 0 ? 1 : feed.currentPage;
        _totalPages = feed.totalPages == 0 ? 1 : feed.totalPages;
        _anchorAt = feed.anchorAt;
      }),
    );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    final result = await AppDI.injector
        .get<GetCommunityFeedUseCase>()(
          page: _currentPage + 1,
          topicId: widget.topicId,
          sort: _sort,
          anchorAt: _anchorAt,
        )
        .run();

    if (!mounted) return;

    result.fold(
      (_) => setState(() => _isLoadingMore = false),
      (feed) => setState(() {
        _isLoadingMore = false;
        _posts.addAll(feed.items);
        _currentPage = feed.currentPage == 0 ? _currentPage + 1 : feed.currentPage;
        _totalPages = feed.totalPages == 0 ? _totalPages : feed.totalPages;
      }),
    );
  }

  Future<void> _toggleFollow() async {
    final topic = _topic;
    if (topic == null) return;
    if (!await communityRequireAccount(context, communityMemberStatus)) return;
    if (!mounted) return;

    final follow = !topic.isFollowing;
    setState(
      () => _topic = topic.copyWith(
        isFollowing: follow,
        followers: (topic.followers + (follow ? 1 : -1)).clamp(0, 1 << 30),
      ),
    );

    final result = await AppDI.injector
        .get<SetCommunityTopicFollowUseCase>()(
          topicId: topic.id,
          follow: follow,
        )
        .run();

    if (!mounted) return;

    result.fold(
      (_) => setState(() => _topic = topic),
      // Keep the hub in step: its topic list and its "đang theo dõi" feed both
      // depend on this.
      (_) => context.read<CommunityFeedCubit>().loadTopics(),
    );
  }

  /// Up to three distinct authors from the loaded posts, in the order they
  /// appear. Empty until the first page arrives, which is why the stack is
  /// allowed to render as nothing.
  List<CommunityAuthorEntity> get _faces {
    final seen = <String>{};
    final faces = <CommunityAuthorEntity>[];

    for (final post in _posts) {
      if (post.author.isOfficial) continue;
      if (!seen.add(post.author.id)) continue;
      faces.add(post.author);
      if (faces.length == 3) break;
    }

    return faces;
  }

  /// Changing the sort changes what page 1 means, so the list is emptied rather
  /// than re-sorted locally — the server decides the order.
  void _replacePost(CommunityPostEntity updated) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updated.id);
      if (index >= 0) _posts[index] = updated;
    });
  }

  Future<void> _toggleReaction(
    CommunityPostEntity post,
    CommunityReactionKind kind,
  ) async {
    if (!await communityRequireAccount(context, communityMemberStatus)) return;
    if (!mounted) return;

    final active = kind == CommunityReactionKind.like ? !post.isLiked : !post.isSaved;
    final optimistic = kind == CommunityReactionKind.like
        ? post.copyWith(
            isLiked: active,
            likeCount: (post.likeCount + (active ? 1 : -1)).clamp(0, 1 << 30),
          )
        : post.copyWith(
            isSaved: active,
            saveCount: (post.saveCount + (active ? 1 : -1)).clamp(0, 1 << 30),
          );
    _replacePost(optimistic);

    final result = await AppDI.injector
        .get<SetCommunityReactionUseCase>()(
          targetType: CommunityTargetType.post,
          targetId: post.id,
          kind: kind,
          active: active,
        )
        .run();

    if (!mounted) return;
    result.fold((_) => _replacePost(post), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final topic = _topic;

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopicStickyBar(
              topic: topic,
              showTitle: _showStickyTitle,
              onToggleFavourite: _toggleFavourite,
              onCompose: _composeInRoom,
            ),
            Expanded(
              child: _status == CommunityStatus.loading && _posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _scrollController,
                        // Clears the floating nav pill, which stays on screen
                        // here (design `S-03`) — a flat inset would put the last
                        // post under it.
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          12.h,
                          20.w,
                          floatingNavBarHeight(context) + 24.h,
                        ),
                        children: [
                          // The room's own card scrolls away with the feed; the
                          // bar above keeps the name once it has.
                          _TopicHeaderCard(
                            topic: topic,
                            // Faces from the posts already on screen — the
                            // design's avatar stack, without inventing a
                            // "recent members" endpoint for it.
                            faces: _faces,
                          ),
                          SizedBox(height: 14.h),
                          if (_status == CommunityStatus.failure && _posts.isEmpty)
                            _CommunityMessage(
                              title: l10n.errorTitle,
                              body: _errorMessage ?? l10n.errorBody,
                              actionLabel: l10n.retry,
                              onAction: _load,
                            )
                          else if (_posts.isEmpty)
                            _CommunityMessage(
                              title: l10n.emptyTopicFeedTitle,
                              body: l10n.emptyTopicFeedBody,
                            ),
                          ..._posts.map(
                            (post) => CommunityPostCard(
                              post: post,
                              onOpen: () async {
                                final result = await CommunityPostRoute(
                                  postId: post.id,
                                ).push<CommunityPostScreenResult?>(context);
                                if (result == null) return;
                                if (result.removed) {
                                  setState(
                                    () => _posts.removeWhere((item) => item.id == post.id),
                                  );
                                  return;
                                }
                                final updated = result.post;
                                if (updated != null) _replacePost(updated);
                              },
                              onLike: () => _toggleReaction(post, CommunityReactionKind.like),
                              onFollowThread: () => _toggleReaction(post, CommunityReactionKind.save),
                              onCard: (card) => showCommunityInsightShareSheet(context, card: card),
                              onMenu: () => showCommunityItemMenu(
                                context,
                                isMine: post.isMine,
                                onHide: () async {
                                  await AppDI.injector
                                      .get<HideCommunityItemUseCase>()(
                                        targetType: CommunityTargetType.post,
                                        targetId: post.id,
                                      )
                                      .run();
                                  if (!mounted) return;
                                  setState(() => _posts.removeWhere((item) => item.id == post.id));
                                },
                                onReport: () async {
                                  if (!await communityRequireAccount(
                                    context,
                                    communityMemberStatus,
                                  )) {
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  showCommunityReportSheet(
                                    context,
                                    onSubmit: (reason) async {
                                      final result = await AppDI.injector
                                          .get<ReportCommunityItemUseCase>()(
                                            targetType: CommunityTargetType.post,
                                            targetId: post.id,
                                            reason: reason,
                                          )
                                          .run();
                                      return result.isRight();
                                    },
                                  );
                                },
                                onDelete: () async {
                                  final result = await AppDI.injector.get<DeleteCommunityPostUseCase>()(post.id).run();
                                  if (!mounted) return;
                                  if (result.isRight()) {
                                    setState(
                                      () => _posts.removeWhere((item) => item.id == post.id),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          if (_isLoadingMore)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar that stays put while the room scrolls (design `S-03`).
///
/// The name and the room glyph fade IN rather than being always present: at the
/// top of the screen they would repeat the card two rows below, and the design
/// keeps only the back arrow and the two actions there.
class _TopicStickyBar extends StatelessWidget {
  const _TopicStickyBar({
    required this.topic,
    required this.showTitle,
    required this.onToggleFavourite,
    required this.onCompose,
  });

  final CommunityTopicEntity? topic;
  final bool showTitle;
  final VoidCallback onToggleFavourite;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final isFavourite = topic?.isFollowing ?? false;
    final slot = communityRoomSlot(topic?.id ?? '');

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 12.h),
      color: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18.sp,
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: AnimatedOpacity(
              opacity: showTitle ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppCustomColor.communityRoomTints[slot],
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      size: 15.sp,
                      color: AppCustomColor.communityRoomInks[slot],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppText(
                      topic?.name ?? '',
                      style: AppStyle.textBold14.copyWith(
                        color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // The heart IS joining the room — the design replaced the old
          // "Tham gia" pill with it, so this is one control, not two.
          GestureDetector(
            onTap: onToggleFavourite,
            behavior: HitTestBehavior.opaque,
            child: Semantics(
              label: isFavourite ? l10n.following : l10n.follow,
              button: true,
              toggled: isFavourite,
              child: Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.backgroundWhite.withValues(alpha: 0.8),
                ),
                child: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  size: 17.sp,
                  color: isFavourite ? AppCustomColor.errorRed : AppCustomColor.streakTextMuted,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onCompose,
            behavior: HitTestBehavior.opaque,
            child: Semantics(
              label: l10n.composeCta,
              button: true,
              child: Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.brandPrimary,
                ),
                child: Icon(
                  Icons.add,
                  size: 17.sp,
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

/// The room's own card, at the top of its feed (design `S-03`).
///
/// A glass panel rather than the old tinted block: it sits over the reader's
/// study background like every other card in the forum, and the tinted block
/// punched a solid slab across the top of their picture.
class _TopicHeaderCard extends StatelessWidget {
  const _TopicHeaderCard({required this.topic, this.faces = const []});

  final CommunityTopicEntity? topic;
  final List<CommunityAuthorEntity> faces;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final room = topic;
    if (room == null) return const SizedBox.shrink();

    // Today, not the week — the line it gates says "hôm nay". Same reasoning
    // as `CommunityFavouriteRoomRow`.
    final isLive = room.postsToday > 0;
    final slot = communityRoomSlot(room.id);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppCustomColor.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppCustomColor.communityRoomTints[slot],
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.home_outlined,
                  size: 23.sp,
                  color: AppCustomColor.communityRoomInks[slot],
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      room.name,
                      style: AppStyle.textBold18.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppCustomColor.successGreen,
                            ),
                          ),
                          SizedBox(width: 7.w),
                        ],
                        Expanded(
                          child: AppText(
                            // Same line, and the same quiet-room rule, as the
                            // "Yêu thích" row this screen is opened from — see
                            // `CommunityFavouriteRoomRow`.
                            isLive
                                ? '${l10n.topicDiscussions(count: room.discussions)} · '
                                      '${l10n.topicPostsToday(count: room.postsToday)}'
                                : l10n.topicDiscussions(
                                    count: room.discussions,
                                  ),
                            style: AppStyle.textBold12.copyWith(
                              color: AppCustomColor.textSecondary,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (room.description.isNotEmpty) ...[
            SizedBox(height: 11.h),
            AppText(
              room.description,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
                height: 1.55,
              ),
              maxLines: 100,
            ),
          ],
          if (faces.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _FaceStack(faces: faces),
          ],
        ],
      ),
    );
  }
}

class _FaceStack extends StatelessWidget {
  const _FaceStack({required this.faces});

  final List<CommunityAuthorEntity> faces;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26.w,
      width: 26.w + (faces.length - 1) * 17.w,
      child: Stack(
        children: faces.asMap().entries.map((entry) {
          return Positioned(
            left: entry.key * 17.w,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppCustomColor.brandPrimary50,
              ),
              child: CommunityAvatar(author: entry.value, size: 22),
            ),
          );
        }).toList(),
      ),
    );
  }
}
