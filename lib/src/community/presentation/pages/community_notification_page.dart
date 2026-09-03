part of '../../community.dart';

/// The community inbox: replies to your posts, and moderation notices.
class CommunityNotificationPage extends StatefulWidget {
  const CommunityNotificationPage({super.key});

  @override
  State<CommunityNotificationPage> createState() => _CommunityNotificationPageState();
}

class _CommunityNotificationPageState extends State<CommunityNotificationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cubit = context.read<CommunityNotificationCubit>();
    // Opening the inbox IS reading it — the badge clears here rather than
    // waiting for each row to be tapped.
    cubit.load().then((_) => cubit.markAllRead());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Paging from a scroll listener rather than from inside itemBuilder: asking
  /// for the next page while the list is building emits state mid-build.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<CommunityNotificationCubit>().load(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      appBar: _CommunityAppBar(title: l10n.notificationsTitle),
      body: BlocBuilder<CommunityNotificationCubit, CommunityNotificationState>(
        builder: (context, state) {
          if (state.status == CommunityStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _CommunityMessage(
                title: l10n.notificationsEmptyTitle,
                body: l10n.notificationsEmptyBody,
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            // Full-bleed rows, no side padding: the design tints the whole row
            // to mark it unread, and a tinted card inset from both edges reads
            // as a different KIND of thing rather than as a state.
            padding: EdgeInsets.only(top: 6.h, bottom: 40.h),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return _NotificationRow(item: state.items[index]);
            },
          );
        },
      ),
    );
  }
}

/// One notification (design `S-05`).
///
/// Reads as a sentence with a name in it — "**Thu Hà** đã thích bài viết của
/// bạn" — because the API now resolves the actor for the whole page in one
/// query. The small coloured disc on the avatar says WHICH kind of thing
/// happened, so the sentence does not have to be read to know that.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final CommunityNotificationEntity item;

  /// What the actor did. The name is drawn separately (in bold), so these
  /// fragments deliberately start mid-sentence.
  String _action(BuildContext context) {
    final l10n = context.l10n.community;

    if (item.type == CommunityNotificationType.likeOnPost && item.otherActorCount > 0) {
      return l10n.notificationLikedPostWithOthers(count: item.otherActorCount);
    }
    // Weekly answers collapse the same way likes do — one row per question.
    if (item.type == CommunityNotificationType.answerOnWeekly && item.otherActorCount > 0) {
      return l10n.notificationWeeklyAnswerWithOthers(count: item.otherActorCount);
    }

    return switch (item.type) {
      CommunityNotificationType.likeOnPost => l10n.notificationLikedPost,
      CommunityNotificationType.commentOnPost => l10n.notificationCommentOnPost,
      CommunityNotificationType.replyToComment => l10n.notificationReplyToComment,
      CommunityNotificationType.commentOnFollowedPost => l10n.notificationCommentOnFollowed,
      CommunityNotificationType.answerOnWeekly => l10n.notificationWeeklyAnswer,
      CommunityNotificationType.messageInRoom => l10n.notificationRoomMessage,
      CommunityNotificationType.officialReply => l10n.notificationOfficialReply,
      CommunityNotificationType.postHidden => l10n.notificationPostHidden,
      CommunityNotificationType.sanctionApplied => l10n.notificationSanction,
      CommunityNotificationType.unknown => l10n.notificationsTitle,
    };
  }

  /// Moderation rows are about the READER, not about somebody else — they carry
  /// no actor and their whole text is the sentence.
  bool get _isModeration => item.type == CommunityNotificationType.postHidden || item.type == CommunityNotificationType.sanctionApplied;

  (IconData, Color) get _badge => switch (item.type) {
    CommunityNotificationType.likeOnPost => (
      Icons.favorite,
      AppCustomColor.errorRed,
    ),
    CommunityNotificationType.replyToComment => (
      Icons.reply_rounded,
      AppCustomColor.brandPrimary,
    ),
    CommunityNotificationType.answerOnWeekly => (
      Icons.help_center_rounded,
      AppCustomColor.brandPrimary,
    ),
    CommunityNotificationType.messageInRoom => (
      Icons.forum_rounded,
      AppCustomColor.brandPrimary,
    ),
    CommunityNotificationType.postHidden || CommunityNotificationType.sanctionApplied => (
      Icons.gavel_rounded,
      AppCustomColor.errorRed,
    ),
    _ => (Icons.mode_comment_rounded, AppCustomColor.communityBadgeComment),
  };

  @override
  Widget build(BuildContext context) {
    final postId = item.postId;
    final roomSlug = item.roomSlug;
    final actor = item.actor;
    final name = actor?.name.trim() ?? '';
    final (badgeIcon, badgeColor) = _badge;

    return GestureDetector(
      // A room row goes to the room; everything else to the post it is about.
      onTap: switch ((roomSlug, postId)) {
        (final String slug, _) when slug.isNotEmpty => () => CommunityChatRoute(room: slug).push(context),
        (_, final String id) when id.isNotEmpty => () => CommunityPostRoute(postId: id).push(context),
        _ => null,
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
        // Unread rows carry a stronger wash; read ones settle to the same panel
        // every other card in the app uses. Read rows used to drop to 0.62 —
        // the most transparent surface in the codebase — and since opening the
        // inbox marks everything read, that was the state the reader actually
        // looked at: a whole screen of grey text over a photograph. The
        // read/unread difference survives at 0.82 vs 0.94, and neither one
        // asks the reader to work for the words.
        decoration: BoxDecoration(
          color: item.isRead ? studyThemeCardColor(context) : studyThemeCardColor(context, opacity: 0.94),
          // A hairline, because these rows are full-bleed with no gap between
          // them: once both states sit near white, one row runs into the next
          // and the list reads as a single block of text.
          border: Border(
            bottom: BorderSide(color: AppCustomColor.communityMuted.withValues(alpha: 0.18)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CommunityAvatar(
                    author: actor ?? const CommunityAuthorEntity(isAnonymous: true),
                    size: 40,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeColor,
                        border: Border.all(
                          color: AppCustomColor.backgroundWhite,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        badgeIcon,
                        size: 10.sp,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RichText, not two AppTexts in a Row: the name and the
                  // action are one sentence and have to wrap as one.
                  Text.rich(
                    TextSpan(
                      children: [
                        if (!_isModeration && name.isNotEmpty)
                          TextSpan(
                            text: '$name ',
                            style: AppStyle.textBold14.copyWith(
                              color: AppCustomColor.textPrimary,
                            ),
                          ),
                        TextSpan(
                          text: _action(context),
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  AppText(
                    communityRelativeTime(context, item.createdAt),
                    style: AppStyle.textBold10.copyWith(
                      color: AppCustomColor.communityMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              SizedBox(width: 8.w),
              Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.only(top: 6.h),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.brandPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
