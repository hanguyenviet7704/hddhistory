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

        return CommunityFlatSurface(
          child: Scaffold(
          backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
          appBar: _PostAppBar(
            topic: post?.topic,
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
          ),
        );
      },
    );
  }
}

/// Marks a subtree whose text is drawn DIRECTLY on the study background, with
/// no card between the two — a post and its thread, and the weekly question and
/// its answers.
///
/// Confession shows the reader's background at full strength, exactly like Habit
/// and Home. Text on a card can keep the design's dark ink because the card
/// carries it; text on the background itself cannot, and has to go through
/// [studyThemeOnBg] so it flips light on a dark preset. A couple of widgets
/// ([CommunityAuthorLine], `_CountAction`) are drawn on BOTH kinds of surface,
/// so the surface announces itself once around the screen rather than every
/// intermediate widget carrying a flag it does not use.
class CommunityFlatSurface extends InheritedWidget {
  const CommunityFlatSurface({super.key, required super.child});

  /// True when [context] is on the background rather than on a card. Wrap the
  /// Scaffold, not its body — an `appBar:` is not a descendant of the body.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommunityFlatSurface>() != null;

  // Presence is the whole message and it never changes for a given screen.
  @override
  bool updateShouldNotify(CommunityFlatSurface oldWidget) => false;
}

/// Avatar width plus its gap: everything under the author line lines up with
/// the name, exactly as on the feed card.
const double _postBodyIndent = CommunityBylineRow.indent;

/// The post screen's header: back, then the ROOM this post is in (design
/// `S-04`).
///
/// Left-aligned and naming the room rather than a centred "Bài viết": the room
/// is the context a reader needs on the way in, and it doubles as the way back
/// into it. Falls back to "Bài viết" for a post written without a room, which
/// is the design's own second branch.
class _PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PostAppBar({required this.topic, this.onBack});

  final CommunityPostTopicEntity? topic;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(52.h);

  @override
  Widget build(BuildContext context) {
    final room = topic;
    final image = room?.imageUrl;
    final slot = communityRoomSlot(room?.id ?? '');

    return AppBar(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 44.w,
      leading: GestureDetector(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        // Center, or the glyph inflates: AppBar hands `leading` a TIGHT box
        // (44 here), and SvgPicture's own width/height lose to it.
        child: Center(
          child: CommunityGlyph(
            AppAsset.svg.app.icCommunityBack,
            // 18, not the design's 21: at 21 the design's 2.2 stroke lands a
            // 1.9pt chevron, which reads heavier than every other icon on the
            // screen. 18 keeps the drawn height it had before while taking the
            // design's shape.
            size: 18,
            color: studyThemeOnBg(context, AppCustomColor.textPrimary),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: room == null
            ? null
            : () => CommunityTopicRoute(topicId: room.id).push(context),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            if (room != null) ...[
              // The room's picture when it has one; otherwise the tinted house
              // glyph that stands for a room everywhere else in the forum, so a
              // room with no image still reads as a room and not as a gap.
              ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: image != null && image.isNotEmpty
                    ? DCachedImage(url: image, width: 28.w, height: 28.w, fit: BoxFit.cover)
                    : Container(
                        width: 28.w,
                        height: 28.w,
                        alignment: Alignment.center,
                        color: AppCustomColor.communityRoomTints[slot],
                        child: CommunityGlyph(
                          AppAsset.svg.app.icCommunityRoom,
                          size: 15,
                          color: AppCustomColor.communityRoomInks[slot],
                        ),
                      ),
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: AppText(
                room?.name ?? context.l10n.community.postTitle,
                style: AppStyle.textBold14.copyWith(
                  fontSize: 15.sp,
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
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
    return Container(
      padding: EdgeInsets.only(top: 6.h, bottom: 16.h),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: studyThemeOnBg(context, AppCustomColor.communityRule)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A quiet marker above the headline (design `S-04`). Decoration, so
          // it is hidden from screen readers rather than read out as an
          // unlabelled image.
          ExcludeSemantics(
            child: Container(
              width: 60.w,
              height: 60.w,
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppCustomColor.communityChipBackground,
              ),
              child: CommunityGlyph(
                AppAsset.svg.app.icCommunityBubble,
                size: 39,
                color: AppCustomColor.communityChipInk,
              ),
            ),
          ),
          // The headline leads, above the author line — the same order as the
          // feed card, so opening a post does not reshuffle what it said.
          if (post.subject.trim().isNotEmpty) ...[
            AppText(
              post.subject,
              style: AppStyle.textBold18.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                height: 1.28,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          // The same byline the feed card draws — the design uses one
          // attribution on both screens. No pin here: being pinned orders the
          // FEED, and repeating it on the post says nothing about the post.
          CommunityBylineRow(author: post.author, createdAt: post.createdAt),
          // 1, as in the design: the avatar hangs into the gutter below rather
          // than pushing the body away from the name it belongs to.
          SizedBox(height: 1.h),
          // Everything under the author line hangs off the avatar's right edge
          // (design `S-04`), so the post reads as one block belonging to one
          // person rather than as a header with a wall beneath it. Same indent
          // as the feed card, so opening a post does not re-flow what it said.
          Padding(
            padding: EdgeInsets.only(left: _postBodyIndent.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  post.body,
                  style: AppStyle.text14.copyWith(
                    fontSize: 13.5.sp,
                    color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                    height: 1.55,
                  ),
                ),
                if (post.attachedCard != null) ...[
                  SizedBox(height: 13.h),
                  CommunityInsightCard(
                    card: post.attachedCard!,
                    onTap: () => showCommunityInsightShareSheet(
                      context,
                      card: post.attachedCard!,
                    ),
                  ),
                ],
                if (post.attachedCourseId != null) ...[
                  SizedBox(height: 13.h),
                  CommunityAttachedCourseCard(courseId: post.attachedCourseId!),
                ],
                ...post.images.map(
                  (image) => Padding(
                    padding: EdgeInsets.only(top: 13.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: DCachedImage(url: image, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                _PostActionRow(post: post),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tim · số bình luận · chuông · dấu ba chấm, dưới bài viết (design `S-04`).
///
/// Tách ra khỏi khối bài viết vì nó phải nằm TRONG phần thụt lề cùng thân bài,
/// và nhét cả trăm dòng này vào giữa một Column đã dài thì không đọc nổi nữa.
class _PostActionRow extends StatelessWidget {
  const _PostActionRow({required this.post});

  final CommunityPostEntity post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityPostCubit>();

    return Row(

              children: [
                _CountAction(
                  asset: post.isLiked
                      ? AppAsset.svg.app.icCommunityHeartFill
                      : AppAsset.svg.app.icCommunityHeart,
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
                    CommunityGlyph(
                      AppAsset.svg.app.icCommunityBubble,
                      size: 16,
                      color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                    ),
                    SizedBox(width: 6.w),
                    AppText(
                      '${post.commentCount}',
                      style: AppStyle.text12.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20.w),
                // The bell, not a bookmark: this subscribes the reader to the
                // thread, exactly as it does on the feed card, and the "Đang
                // theo dõi" tab lists the posts it is lit on.
                _CountAction(
                  asset: post.isSaved
                      ? AppAsset.svg.app.icCommunityBellFill
                      : AppAsset.svg.app.icCommunityBell,
                  count: post.saveCount,
                  isActive: post.isSaved,
                  onTap: () => _gatedPost(
                    context,
                    cubit.state.memberStatus,
                    () => cubit.togglePostReaction(CommunityReactionKind.save),
                  ),
                  tooltip: post.isSaved ? l10n.unfollowThread : l10n.followThread,
                ),
                const Spacer(),
                _IconTap(
                  asset: AppAsset.svg.app.icCommunityMore,
                  color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                  onTap: () => showCommunityItemMenu(
                    context,
                    isMine: post.isMine,
                    onHide: () async {
                      await AppDI.injector
                          .get<HideCommunityItemUseCase>()(
                            targetType: CommunityTargetType.post,
                            targetId: post.id,
                          )
                          .run();
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
    final cubit = context.read<CommunityPostCubit>();
    final state = widget.state;

    return ListView(
      controller: _scrollController,
      // The post and its thread run FLAT on the study background, with no card
      // between them — every ink inside is therefore on-background ink (see
      // [CommunityFlatSurface]), exactly as Habit and Home do it.
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      children: _threadColumn(context, cubit, state),
    );
  }

  /// The post (or the weekly question) and its thread.
  List<Widget> _threadColumn(
    BuildContext context,
    CommunityPostCubit cubit,
    CommunityPostState state,
  ) {
    final l10n = context.l10n.community;

    return [
        // No "N bình luận" heading here: design `S-04` runs straight from the
        // post into its thread, and the weekly question prints its own count
        // inside its header block — one here made that screen say it twice.
        widget.header,
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
    ];
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
      message = isGuest ? l10n.guestBody : (status.reason?.trim().isNotEmpty == true ? status.reason! : l10n.mutedBodyFallback);
    } else if (state.isWeekly) {
      message = l10n.weeklyClosed;
    } else {
      message = l10n.commentsLocked;
    }

    return GestureDetector(
      // Same reasoning as the feed banner: this strip IS the sign-in button.
      onTap: isGuest ? _openCommunityAuth : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
        decoration: BoxDecoration(
          // The same veil as the page: the design's composer strip is the page
          // ground with a lighter pill floating on it, not a white plank.
          color: studyThemeCardColor(context, opacity: 0.94),
          border: const Border(top: BorderSide(color: AppCustomColor.communityRule)),
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

/// Plain back-and-title bar for the pushed community screens that do not name
/// something in their header — the weekly question and the notification list.
class _CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CommunityAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => Size.fromHeight(52.h);

  @override
  Widget build(BuildContext context) {
    final ink = studyThemeOnBg(context, AppCustomColor.textPrimary);

    return AppBar(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        // Center, or the glyph inflates — see the post header's leading.
        child: Center(
          child: CommunityGlyph(AppAsset.svg.app.icCommunityBack, size: 18, color: ink),
        ),
      ),
      title: AppText(
        title,
        style: AppStyle.textBold16.copyWith(fontSize: 15.sp, color: ink),
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
