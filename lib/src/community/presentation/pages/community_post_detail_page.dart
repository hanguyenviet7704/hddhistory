part of '../../community.dart';

/// One post and its thread (design `S-04`).
///
/// Pops with the updated post so the feed card behind it reflects the likes and
/// comments added here instead of going stale.
class CommunityPostDetailPage extends StatelessWidget {
  const CommunityPostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityPostCubit, CommunityPostState>(
      builder: (context, state) {
        final cubit = context.read<CommunityPostCubit>();
        final post = state.post;

        return Scaffold(
          backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
          appBar: _CommunityAppBar(
            title: l10n.postTitle,
            onBack: () => Navigator.of(context).maybePop(
              CommunityPostScreenResult(post: post),
            ),
          ),
          body: state.status == CommunityStatus.loading && post == null
              ? const Center(child: CircularProgressIndicator())
              : post == null
              ? _CommunityMessage(
                  title: l10n.errorTitle,
                  body: state.errorMessage ?? l10n.errorBody,
                  actionLabel: l10n.retry,
                  onAction: () => cubit.loadPost(postId),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _CommunityThreadList(
                        header: _PostHeaderBlock(post: post),
                        state: state,
                      ),
                    ),
                    if (state.canComment)
                      CommunityComposerBar(
                        isSubmitting: state.isSubmitting,
                        replyingToName: state.replyTarget == null ? null : cubit.replyToName,
                        onCancelReply: cubit.cancelReply,
                        onSubmit: cubit.submitComment,
                      )
                    else
                      _ClosedComposerNote(state: state),
                  ],
                ),
        );
      },
    );
  }
}

/// The post itself, above its thread.
///
/// Not a card: the design lets the post run flush to the page edges with a hair
/// rule under it, so the thread below reads as a continuation of it rather than
/// as a second, separate list.
class _PostHeaderBlock extends StatelessWidget {
  const _PostHeaderBlock({required this.post});

  final CommunityPostEntity post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityPostCubit>();
    final topic = post.topic;

    return Container(
      padding: EdgeInsets.only(bottom: 16.h),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppCustomColor.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topic != null) ...[
            _TopicPill(topic: topic),
            SizedBox(height: 10.h),
          ],
          Row(
            children: [
              CommunityAvatar(author: post.author, size: 26),
              SizedBox(width: 10.w),
              Expanded(
                child: AppText(
                  post.author.isOfficial
                      ? l10n.officialAuthorName
                      : (post.author.name.isEmpty
                            ? l10n.deletedAuthorName
                            : post.author.name),
                  style: AppStyle.textBold14.copyWith(
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                  maxLines: 1,
                ),
              ),
              if (post.isPinned) ...[
                Icon(Icons.push_pin, size: 12.sp, color: AppCustomColor.streakActive),
                SizedBox(width: 8.w),
              ],
              AppText(
                communityRelativeTime(context, post.createdAt),
                style: AppStyle.text12.copyWith(
                  color: studyThemeOnBg(context, AppCustomColor.communityMuted),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppText(
            post.body,
            style: AppStyle.text14.copyWith(
              color: studyThemeOnBg(context, AppCustomColor.textSecondary),
              height: 1.6,
            ),
          ),
          if (post.attachedCourseId != null)
            CommunityAttachedCourseCard(courseId: post.attachedCourseId!),
          ...post.images.map(
            (image) => Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: DCachedImage(url: image, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.only(top: 11.h),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppCustomColor.surfaceMuted)),
            ),
            child: Row(
              children: [
                _CountAction(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  count: post.likeCount,
                  isActive: post.isLiked,
                  onTap: () => _gatedPost(
                    context,
                    cubit.state.memberStatus,
                    () => cubit.togglePostReaction(CommunityReactionKind.like),
                  ),
                ),
                SizedBox(width: 20.w),
                // Not a button: this screen IS the comments, so the count is a
                // read-out rather than a way in.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 17.sp,
                      color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                    ),
                    SizedBox(width: 6.w),
                    AppText(
                      '${post.commentCount}',
                      style: AppStyle.text12.copyWith(
                        color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20.w),
                _CountAction(
                  icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  count: post.saveCount,
                  isActive: post.isSaved,
                  onTap: () => _gatedPost(
                    context,
                    cubit.state.memberStatus,
                    () => cubit.togglePostReaction(CommunityReactionKind.save),
                  ),
                ),
                const Spacer(),
                _IconTap(
                  icon: Icons.more_horiz,
                  color: studyThemeOnBg(context, AppCustomColor.communityMuted),
                  onTap: () => showCommunityItemMenu(
                    context,
                    isMine: post.isMine,
                    onHide: () async {
                      await AppDI.injector.get<HideCommunityItemUseCase>()(
                        targetType: CommunityTargetType.post,
                        targetId: post.id,
                      ).run();
                      if (context.mounted) {
                        Navigator.of(context).maybePop(
                          const CommunityPostScreenResult(removed: true),
                        );
                      }
                    },
                    onReport: () => _gatedPost(
                      context,
                      cubit.state.memberStatus,
                      () => showCommunityReportSheet(
                        context,
                        onSubmit: (reason) => cubit.report(
                          targetType: CommunityTargetType.post,
                          targetId: post.id,
                          reason: reason,
                        ),
                      ),
                    ),
                    onDelete: () async {
                      final deleted = await cubit.deletePost();
                      if (!context.mounted) return;
                      DMessage.showMessage(
                        message: deleted ? l10n.deletePostDone : l10n.errorBody,
                        type: deleted ? MessageType.success : MessageType.error,
                      );
                      // The feed has to hear about this: popping with the post
                      // alone would put the deleted card straight back.
                      if (deleted) {
                        Navigator.of(context).maybePop(
                          const CommunityPostScreenResult(removed: true),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The topic chip above a post on the detail screen: a bordered pill, quieter
/// than the feed card's dotted chip because here it is a way back out rather
/// than a label on a row being scanned.
class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.topic});

  final CommunityPostTopicEntity topic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => CommunityTopicRoute(topicId: topic.id).push(context),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            borderRadius: BorderRadius.circular(99.r),
            border: Border.all(color: AppCustomColor.borderDefault),
          ),
          child: AppText(
            topic.name,
            style: AppStyle.textBold10.copyWith(color: AppCustomColor.streakTextMuted),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// The comment list, shared by the post screen and the weekly-question screen.
class _CommunityThreadList extends StatefulWidget {
  const _CommunityThreadList({required this.header, required this.state});

  final Widget header;
  final CommunityPostState state;

  @override
  State<_CommunityThreadList> createState() => _CommunityThreadListState();
}

class _CommunityThreadListState extends State<_CommunityThreadList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<CommunityPostCubit>().loadComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityPostCubit>();
    final state = widget.state;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      children: [
        widget.header,
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: AppText(
            l10n.commentCount(count: state.answerCount),
            style: AppStyle.textBold14.copyWith(
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
        ),
        if (state.commentsStatus == CommunityStatus.loading && state.comments.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.comments.isEmpty)
          _CommunityMessage(title: l10n.emptyCommentsTitle, body: l10n.emptyCommentsBody),
        ...state.comments.map(
          (comment) => CommunityCommentTile(
            comment: comment,
            onLike: () => _gatedPost(
              context,
              state.memberStatus,
              () => cubit.toggleCommentLike(comment),
            ),
            onReply: () => cubit.startReply(comment),
            onMenu: () => _showCommentMenu(context, cubit, comment),
            onReplyLike: (reply) => _gatedPost(
              context,
              state.memberStatus,
              () => cubit.toggleCommentLike(reply),
            ),
            onReplyReply: (reply) => cubit.startReply(reply, parent: comment),
            onReplyMenu: (reply) => _showCommentMenu(context, cubit, reply),
          ),
        ),
        if (state.isLoadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _showCommentMenu(
    BuildContext context,
    CommunityPostCubit cubit,
    CommunityCommentEntity comment,
  ) {
    showCommunityItemMenu(
      context,
      isMine: comment.isMine,
      onHide: () => cubit.hideComment(comment),
      onReport: () => _gatedPost(
        context,
        cubit.state.memberStatus,
        () => showCommunityReportSheet(
          context,
          onSubmit: (reason) => cubit.report(
            targetType: CommunityTargetType.comment,
            targetId: comment.id,
            reason: reason,
          ),
        ),
      ),
      onDelete: () => cubit.deleteComment(comment),
    );
  }
}

/// What sits where the composer would be when this reader cannot write.
///
/// For a guest this is the way IN, not a dead end: the whole strip is tappable
/// and opens the auth screen. A thread is exactly where someone decides they
/// want to answer, so that is where signing in has to be one tap away.
class _ClosedComposerNote extends StatelessWidget {
  const _ClosedComposerNote({required this.state});

  final CommunityPostState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final status = state.memberStatus;
    final isGuest = status.requiresLogin;

    final String message;
    if (!status.canPost) {
      message = isGuest
          ? l10n.guestBody
          : (status.reason?.trim().isNotEmpty == true
                ? status.reason!
                : l10n.mutedBodyFallback);
    } else if (state.isWeekly) {
      message = l10n.weeklyClosed;
    } else {
      message = l10n.commentsLocked;
    }

    return GestureDetector(
      onTap: isGuest ? () => communityRequireAccount(context, status) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context, opacity: 0.94),
          border: Border(top: BorderSide(color: AppCustomColor.borderDefault)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                message,
                style: AppStyle.text12.copyWith(
                  color: studyThemeCardMuted(context, AppCustomColor.streakTextMuted),
                ),
                textAlign: TextAlign.center,
              ),
              if (isGuest) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: AppText(
                    l10n.guestAction,
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.textWhite),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain back-and-title bar, used by every pushed community screen.
class _CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CommunityAppBar({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(52.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18.sp,
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
      title: AppText(
        title,
        style: AppStyle.textBold16.copyWith(
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
    );
  }
}


/// Same gate as the feed's, for the screens driven by [CommunityPostCubit].
///
/// Replying is gated by the composer being replaced with a sign-in prompt; the
/// hearts and the report menu still need this, because they stay visible and
/// tappable for a guest — which is how they learn an account is needed.
Future<void> _gatedPost(
  BuildContext context,
  CommunityMemberStatusEntity status,
  void Function() action,
) async {
  if (await communityRequireAccount(context, status)) action();
}
