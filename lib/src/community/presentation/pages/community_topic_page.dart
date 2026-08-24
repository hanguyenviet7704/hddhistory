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
  CommunityFeedSort _sort = CommunityFeedSort.recent;
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

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _load() async {
    setState(() => _status = CommunityStatus.loading);

    final topicResult = await AppDI.injector.get<GetCommunityTopicUseCase>()(widget.topicId).run();
    final feedResult = await AppDI.injector.get<GetCommunityFeedUseCase>()(
      page: 1,
      topicId: widget.topicId,
      sort: _sort,
    ).run();

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

    final result = await AppDI.injector.get<GetCommunityFeedUseCase>()(
      page: _currentPage + 1,
      topicId: widget.topicId,
      sort: _sort,
      anchorAt: _anchorAt,
    ).run();

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

    final follow = !topic.isFollowing;
    setState(
      () => _topic = topic.copyWith(
        isFollowing: follow,
        followers: (topic.followers + (follow ? 1 : -1)).clamp(0, 1 << 30),
      ),
    );

    final result = await AppDI.injector.get<SetCommunityTopicFollowUseCase>()(
      topicId: topic.id,
      follow: follow,
    ).run();

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
  void _setSort(CommunityFeedSort sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _posts.clear();
      _currentPage = 1;
      _totalPages = 1;
      _anchorAt = null;
    });
    _load();
  }

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

    final result = await AppDI.injector.get<SetCommunityReactionUseCase>()(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      kind: kind,
      active: active,
    ).run();

    if (!mounted) return;
    result.fold((_) => _replacePost(post), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final topic = _topic;

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopicHeader(
              topic: topic,
              onToggleFollow: _toggleFollow,
              // Faces from the posts already on screen — the design's avatar
              // stack, without inventing a "recent members" endpoint for it.
              faces: _faces,
            ),
            _TopicToolbar(
              sort: _sort,
              onSort: _setSort,
              onCompose: () async {
                final created = await const CommunityComposeRoute().push<bool>(context);
                if (created == true) await _load();
              },
            ),
            Expanded(
              child: _status == CommunityStatus.loading && _posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                        children: [
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
                              onSave: () => _toggleReaction(post, CommunityReactionKind.save),
                              onMenu: () => showCommunityItemMenu(
                                context,
                                isMine: post.isMine,
                                onHide: () async {
                                  await AppDI.injector.get<HideCommunityItemUseCase>()(
                                    targetType: CommunityTargetType.post,
                                    targetId: post.id,
                                  ).run();
                                  if (!mounted) return;
                                  setState(() => _posts.removeWhere((item) => item.id == post.id));
                                },
                                onReport: () => showCommunityReportSheet(
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
                                ),
                                onDelete: () async {
                                  final result = await AppDI.injector
                                      .get<DeleteCommunityPostUseCase>()(post.id)
                                      .run();
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

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({
    required this.topic,
    required this.onToggleFollow,
    this.faces = const [],
  });

  final CommunityTopicEntity? topic;
  final VoidCallback onToggleFollow;
  final List<CommunityAuthorEntity> faces;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18.sp,
                color: AppCustomColor.communityTopicHeading,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          AppText(
            topic?.name ?? '',
            style: AppStyle.textBold20.copyWith(
              color: AppCustomColor.communityTopicHeading,
              height: 1.3,
            ),
            maxLines: 3,
          ),
          if ((topic?.description ?? '').isNotEmpty) ...[
            SizedBox(height: 6.h),
            AppText(
              topic!.description,
              style: AppStyle.text13.copyWith(color: AppCustomColor.streakTextMuted),
              maxLines: 4,
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            children: [
              if (faces.isNotEmpty) ...[
                _FaceStack(faces: faces),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: AppText(
                  topic == null
                      ? ''
                      : '${l10n.topicMembers(count: topic!.followers)} · ${l10n.topicPostsThisWeek(count: topic!.postsThisWeek)}',
                  style: AppStyle.text12.copyWith(color: AppCustomColor.communityMuted),
                  maxLines: 1,
                ),
              ),
              if (topic != null)
                CommunityFollowButton(
                  isFollowing: topic!.isFollowing,
                  onTap: onToggleFollow,
                ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Sort chips plus the write affordance, between a topic's header and its feed
/// (design `S-03`).
///
/// "Sôi nổi" sorts by the last reply rather than by age, so a thread people are
/// still answering stays up top — that is the whole difference between the two.
class _TopicToolbar extends StatelessWidget {
  const _TopicToolbar({
    required this.sort,
    required this.onSort,
    required this.onCompose,
  });

  final CommunityFeedSort sort;
  final void Function(CommunityFeedSort sort) onSort;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 4.h),
      child: Row(
        children: [
          _SortChip(
            label: l10n.sortRecent,
            isActive: sort == CommunityFeedSort.recent,
            onTap: () => onSort(CommunityFeedSort.recent),
          ),
          SizedBox(width: 8.w),
          _SortChip(
            label: l10n.sortActive,
            isActive: sort == CommunityFeedSort.active,
            onTap: () => onSort(CommunityFeedSort.active),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCompose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(99.r),
                border: Border.all(color: AppCustomColor.borderBrand),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 14.sp, color: AppCustomColor.streakActive),
                  SizedBox(width: 6.w),
                  AppText(
                    l10n.composeCta,
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.streakActive),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
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


/// Overlapping author avatars on a topic header (design `S-03`).
///
/// Each carries a ring in the header's own tint so the overlap reads as depth
/// rather than as smudged circles.
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
