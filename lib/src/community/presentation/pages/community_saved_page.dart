part of '../../community.dart';

/// Posts this reader bookmarked (the header's bookmark icon).
///
/// Its own screen rather than a tab: saving is a private shelf, and mixing it
/// into the public feed's tab strip would suggest otherwise.
class CommunitySavedPage extends StatefulWidget {
  const CommunitySavedPage({super.key});

  @override
  State<CommunitySavedPage> createState() => _CommunitySavedPageState();
}

class _CommunitySavedPageState extends State<CommunitySavedPage> {
  final List<CommunityPostEntity> _posts = [];
  CommunityStatus _status = CommunityStatus.initial;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = CommunityStatus.loading);

    final result = await AppDI.injector.get<GetCommunitySavedPostsUseCase>()(page: 1).run();
    if (!mounted) return;

    result.fold(
      (exception) => setState(() {
        _status = CommunityStatus.failure;
        _errorMessage = exception.message;
      }),
      (page) => setState(() {
        _status = CommunityStatus.success;
        _posts
          ..clear()
          ..addAll(page.items);
      }),
    );
  }

  Future<void> _unsave(CommunityPostEntity post) async {
    // Unsaving from the saved list means the row leaves — keeping it there with
    // a hollow bookmark would read as the tap not working.
    setState(() => _posts.removeWhere((item) => item.id == post.id));

    final result = await AppDI.injector.get<SetCommunityReactionUseCase>()(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      kind: CommunityReactionKind.save,
      active: false,
    ).run();

    if (!mounted) return;
    result.fold((_) => _load(), (_) {});
  }

  void _replacePost(CommunityPostEntity updated) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updated.id);
      if (index >= 0) _posts[index] = updated;
    });
  }

  Future<void> _toggleLike(CommunityPostEntity post) async {
    if (!await communityRequireAccount(context, communityMemberStatus)) return;
    if (!mounted) return;

    final active = !post.isLiked;
    _replacePost(
      post.copyWith(
        isLiked: active,
        likeCount: (post.likeCount + (active ? 1 : -1)).clamp(0, 1 << 30),
      ),
    );

    final result = await AppDI.injector.get<SetCommunityReactionUseCase>()(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      kind: CommunityReactionKind.like,
      active: active,
    ).run();

    if (!mounted) return;
    result.fold((_) => _replacePost(post), (_) {});
  }

  Future<void> _hide(CommunityPostEntity post) async {
    setState(() => _posts.removeWhere((item) => item.id == post.id));

    await AppDI.injector.get<HideCommunityItemUseCase>()(
      targetType: CommunityTargetType.post,
      targetId: post.id,
    ).run();
  }

  Future<bool> _report(
    CommunityPostEntity post,
    CommunityReportReason reason,
  ) async {
    final result = await AppDI.injector.get<ReportCommunityItemUseCase>()(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      reason: reason,
    ).run();

    return result.isRight();
  }

  Future<void> _delete(CommunityPostEntity post) async {
    final result = await AppDI.injector.get<DeleteCommunityPostUseCase>()(post.id).run();
    if (!mounted) return;

    if (result.isRight()) {
      setState(() => _posts.removeWhere((item) => item.id == post.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      appBar: _CommunityAppBar(title: l10n.savedTitle),
      body: _status == CommunityStatus.loading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
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
                      title: l10n.savedEmptyTitle,
                      body: l10n.savedEmptyBody,
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
                        // Unsaved from inside the thread — this list is the
                        // saved list, so the row goes with it.
                        final updated = result.post;
                        if (updated == null) return;
                        if (!updated.isSaved) {
                          setState(
                            () => _posts.removeWhere((item) => item.id == post.id),
                          );
                          return;
                        }
                        _replacePost(updated);
                      },
                      onLike: () => _toggleLike(post),
                      onSave: () => _unsave(post),
                      onMenu: () => showCommunityItemMenu(
                        context,
                        isMine: post.isMine,
                        onHide: () => _hide(post),
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
                            onSubmit: (reason) => _report(post, reason),
                          );
                        },
                        onDelete: () => _delete(post),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
