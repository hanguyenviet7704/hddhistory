part of '../../community.dart';

/// Drives the post-detail screen and the weekly-question screen.
///
/// Registered as a factory, not a singleton: two posts open on the navigation
/// stack are two independent threads, and sharing one cubit would make the
/// back gesture reveal the wrong comments.
@injectable
class CommunityPostCubit extends Cubit<CommunityPostState>
    with CubitUseCaseHandlerMixin<CommunityPostState> {
  final GetCommunityPostUseCase _getPostUseCase;
  final GetCommunityWeeklyUseCase _getWeeklyUseCase;
  final GetCommunityCommentsUseCase _getCommentsUseCase;
  final CreateCommunityCommentUseCase _createCommentUseCase;
  final DeleteCommunityCommentUseCase _deleteCommentUseCase;
  final SetCommunityReactionUseCase _setReactionUseCase;
  final HideCommunityItemUseCase _hideUseCase;
  final ReportCommunityItemUseCase _reportUseCase;
  final DeleteCommunityPostUseCase _deletePostUseCase;
  final GetCommunityMemberStatusUseCase _memberStatusUseCase;

  CommunityPostCubit(
    this._getPostUseCase,
    this._getWeeklyUseCase,
    this._getCommentsUseCase,
    this._createCommentUseCase,
    this._deleteCommentUseCase,
    this._setReactionUseCase,
    this._hideUseCase,
    this._reportUseCase,
    this._deletePostUseCase,
    this._memberStatusUseCase,
  ) : super(CommunityPostState.initial());

  static const int _pageSize = 10;

  String? _postId;

  Future<void> loadPost(String postId) async {
    _postId = postId;
    emit(state.copyWith(status: CommunityStatus.loading));

    await Future.wait([
      runUseCase<CommunityPostEntity>(
        usecase: () => _getPostUseCase(postId),
        onFailure: (message) => emit(
          state.copyWith(status: CommunityStatus.failure, errorMessage: message),
        ),
        onSuccess: (post) => emit(
          state.copyWith(status: CommunityStatus.success, post: post),
        ),
      ),
      loadComments(reset: true),
      _refreshMemberStatus(),
    ]);
  }

  /// The weekly question screen. Its answers are ordinary comments on the
  /// question post, so everything below the header is shared with [loadPost].
  Future<void> loadWeekly() async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await _getWeeklyUseCase().run();

    await result.fold(
      (exception) async => emit(
        state.copyWith(
          status: CommunityStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (weekly) async {
        if (weekly == null) {
          // No question open. Not a failure — the screen shows its own empty
          // state, because "chưa có câu hỏi tuần này" is a real answer.
          emit(state.copyWith(status: CommunityStatus.success, weekly: null));
          return;
        }

        _postId = weekly.id;
        emit(state.copyWith(status: CommunityStatus.success, weekly: weekly));

        await Future.wait([loadComments(reset: true), _refreshMemberStatus()]);
      },
    );
  }

  Future<void> _refreshMemberStatus() async {
    final result = await _memberStatusUseCase().run();

    result.fold((_) {}, (status) => emit(state.copyWith(memberStatus: status)));
  }

  Future<void> loadComments({bool reset = false}) async {
    final postId = _postId;
    if (postId == null) return;

    final page = reset ? 1 : state.currentPage + 1;
    if (!reset) {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(state.copyWith(commentsStatus: CommunityStatus.loading));
    }

    final result = await _getCommentsUseCase(
      postId: postId,
      page: page,
      take: _pageSize,
    ).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          commentsStatus: CommunityStatus.failure,
          isLoadingMore: false,
          errorMessage: exception.message,
        ),
      ),
      (thread) => emit(
        state.copyWith(
          commentsStatus: CommunityStatus.success,
          comments: reset ? thread.items : [...state.comments, ...thread.items],
          currentPage: thread.currentPage == 0 ? page : thread.currentPage,
          totalPages: thread.totalPages == 0 ? 1 : thread.totalPages,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Tapping "trả lời" on a reply targets its PARENT, with the reply's author
  /// carried as the "@name" — the thread is two levels deep and stays that way.
  ///
  /// [replyToUserId] is set ONLY when answering a reply. Replying to a
  /// top-level comment already sits directly under it, so tagging its author
  /// would print a redundant "@name" the design never shows.
  void startReply(CommunityCommentEntity target, {CommunityCommentEntity? parent}) {
    emit(state.copyWith(replyTarget: parent ?? target));
    _replyToUserId = parent == null ? null : target.author.id;
    _replyToName = target.author.name;
  }

  void cancelReply() {
    emit(state.copyWith(replyTarget: null));
    _replyToUserId = null;
    _replyToName = null;
  }

  String? _replyToUserId;
  String? _replyToName;

  /// The pause after a comment lands.
  ///
  /// Three seconds against the server's thirty comments per ten minutes. It is
  /// there for the accidental double-send and the held button, not for a
  /// determined spammer — that one is the server's job, and hitting its ceiling
  /// now says so in a sentence a person can read.
  static const Duration _commentCooldown = Duration(seconds: 3);

  Timer? _cooldown;

  @override
  Future<void> close() {
    _cooldown?.cancel();
    return super.close();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    emit(state.copyWith(isCoolingDown: true));

    _cooldown = Timer(_commentCooldown, () {
      if (isClosed) return;
      emit(state.copyWith(isCoolingDown: false));
    });
  }

  String? get replyToName => _replyToName;

  Future<bool> submitComment(String body) async {
    final postId = _postId;
    if (postId == null || body.trim().isEmpty) return false;
    if (state.isSubmitting || state.isCoolingDown) return false;

    // Cleared here so that a `false` from this call means THIS attempt failed,
    // which is what the screen keys its message off.
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _createCommentUseCase(
      postId: postId,
      body: body.trim(),
      parentId: state.replyTarget?.id,
      replyToUserId: _replyToUserId,
    ).run();

    return result.fold(
      (exception) {
        emit(state.copyWith(isSubmitting: false, errorMessage: exception.message));
        return false;
      },
      (thread) {
        // The API answers with the refreshed first page, so the new comment
        // appears exactly where the server put it.
        emit(
          state.copyWith(
            isSubmitting: false,
            comments: thread.items,
            currentPage: thread.currentPage == 0 ? 1 : thread.currentPage,
            totalPages: thread.totalPages == 0 ? 1 : thread.totalPages,
            replyTarget: null,
            post: state.post?.copyWith(
              commentCount: state.post!.commentCount + 1,
            ),
            weekly: state.weekly?.copyWith(
              answerCount: state.weekly!.answerCount + 1,
            ),
            errorMessage: null,
          ),
        );
        _replyToUserId = null;
        _replyToName = null;
        _startCooldown();
        return true;
      },
    );
  }

  Future<void> togglePostReaction(CommunityReactionKind kind) async {
    final post = state.post;
    if (post == null) return;

    final active = kind == CommunityReactionKind.like ? !post.isLiked : !post.isSaved;
    _applyPostReaction(kind, active);

    final result = await _setReactionUseCase(
      targetType: CommunityTargetType.post,
      targetId: post.id,
      kind: kind,
      active: active,
    ).run();

    result.fold((_) => _applyPostReaction(kind, !active), (_) {});
  }

  void _applyPostReaction(CommunityReactionKind kind, bool active) {
    final post = state.post;
    if (post == null) return;

    emit(
      state.copyWith(
        post: kind == CommunityReactionKind.like
            ? post.copyWith(
                isLiked: active,
                likeCount: (post.likeCount + (active ? 1 : -1)).clamp(0, 1 << 30),
              )
            : post.copyWith(
                isSaved: active,
                saveCount: (post.saveCount + (active ? 1 : -1)).clamp(0, 1 << 30),
              ),
      ),
    );
  }

  Future<void> toggleCommentLike(CommunityCommentEntity comment) async {
    final active = !comment.isLiked;
    _applyCommentLike(comment.id, active);

    final result = await _setReactionUseCase(
      targetType: CommunityTargetType.comment,
      targetId: comment.id,
      kind: CommunityReactionKind.like,
      active: active,
    ).run();

    result.fold((_) => _applyCommentLike(comment.id, !active), (_) {});
  }

  void _applyCommentLike(String commentId, bool active) {
    CommunityCommentEntity apply(CommunityCommentEntity comment) {
      final replies = comment.replies.map(apply).toList();
      if (comment.id != commentId) return comment.copyWith(replies: replies);

      return comment.copyWith(
        isLiked: active,
        likeCount: (comment.likeCount + (active ? 1 : -1)).clamp(0, 1 << 30),
        replies: replies,
      );
    }

    emit(state.copyWith(comments: state.comments.map(apply).toList()));
  }

  Future<bool> deleteComment(CommunityCommentEntity comment) async {
    final result = await _deleteCommentUseCase(comment.id).run();

    return result.fold((_) => false, (_) {
      loadComments(reset: true);
      return true;
    });
  }

  Future<bool> deletePost() async {
    final post = state.post;
    if (post == null) return false;

    final result = await _deletePostUseCase(post.id).run();

    return result.isRight();
  }

  Future<void> hideComment(CommunityCommentEntity comment) async {
    await _hideUseCase(
      targetType: CommunityTargetType.comment,
      targetId: comment.id,
    ).run();

    loadComments(reset: true);
  }

  Future<bool> report({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? note,
  }) async {
    final result = await _reportUseCase(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      note: note,
    ).run();

    return result.isRight();
  }
}
