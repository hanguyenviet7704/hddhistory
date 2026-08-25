part of '../../community.dart';

/// One comment and its replies (design `S-04`).
///
/// Exactly two levels: a reply to a reply still lands under the same top-level
/// comment, with the answered person's name carried as an "@name" prefix. A
/// deeper tree on a phone becomes unreadable at the third indent.
///
/// Comment text sits flush on the page, NOT in a chat bubble — the design reads
/// as a forum thread, and a bubble per comment turns the same content into a
/// chat transcript. The thread is drawn instead by the connector rail down the
/// left: a vertical line under a comment that has replies, and an L-curve into
/// each reply.
class CommunityCommentTile extends StatelessWidget {
  const CommunityCommentTile({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onMenu,
    required this.onReplyLike,
    required this.onReplyReply,
    required this.onReplyMenu,
  });

  final CommunityCommentEntity comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onMenu;
  final void Function(CommunityCommentEntity reply) onReplyLike;
  final void Function(CommunityCommentEntity reply) onReplyReply;
  final void Function(CommunityCommentEntity reply) onReplyMenu;

  @override
  Widget build(BuildContext context) {
    final replies = comment.replies;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IntrinsicHeight so the rail can stretch to the row: inside a
          // ListView the row's height constraint is unbounded, and a flexible
          // child in an unbounded Column is a layout error, not a stretch.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32.w,
                  child: Column(
                    children: [
                      CommunityAvatar(author: comment.author, size: 32),
                      // The rail only exists when there is something below to
                      // join it to.
                      if (replies.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 2.w,
                              height: double.infinity,
                              color: AppCustomColor.communityRule,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: _CommentBody(
                    comment: comment,
                    onLike: onLike,
                    onReply: onReply,
                    onMenu: onMenu,
                  ),
                ),
              ],
            ),
          ),
          ...replies.asMap().entries.map((entry) {
            final index = entry.key;
            final reply = entry.value;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The elbow: down from the parent, then right into this
                  // reply. Keeps running down while another reply follows.
                  SizedBox(
                    width: 32.w,
                    child: CustomPaint(
                      painter: _ReplyRailPainter(
                        hasNext: index < replies.length - 1,
                        color: AppCustomColor.communityRule,
                        // Meets the reply's 28px avatar at its centre.
                        elbowY: 14.h,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommunityAvatar(author: reply.author, size: 28),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _CommentBody(
                            comment: reply,
                            isReply: true,
                            onLike: () => onReplyLike(reply),
                            onReply: () => onReplyReply(reply),
                            onMenu: () => onReplyMenu(reply),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// The L-curve joining a reply to its parent, matching the design's
/// `border-left + border-bottom + border-bottom-left-radius` corner.
class _ReplyRailPainter extends CustomPainter {
  _ReplyRailPainter({
    required this.hasNext,
    required this.color,
    required this.elbowY,
  });

  final bool hasNext;
  final Color color;

  /// Where the elbow meets the reply — its avatar's centre, not the middle of
  /// the row, which drifts down as the reply gets longer.
  final double elbowY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double left = 15;
    final double radius = elbowY < 14 ? elbowY : 14;
    final double elbowBottom = elbowY;

    // Down to just above the corner, round the corner, then right.
    final path = ui.Path()
      ..moveTo(left, 0)
      ..lineTo(left, elbowBottom - radius)
      ..arcToPoint(
        Offset(left + radius, elbowBottom),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(size.width, elbowBottom);
    canvas.drawPath(path, paint);

    // A reply that is not the last keeps the rail running past its elbow.
    if (hasNext) {
      canvas.drawLine(
        const Offset(left, 0),
        Offset(left, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ReplyRailPainter oldDelegate) =>
      oldDelegate.hasNext != hasNext ||
      oldDelegate.color != color ||
      oldDelegate.elbowY != elbowY;
}

class _CommentBody extends StatelessWidget {
  const _CommentBody({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onMenu,
    this.isReply = false,
  });

  final CommunityCommentEntity comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onMenu;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final replyToName = comment.replyToName;
    final name = comment.author.isOfficial
        ? l10n.officialAuthorName
        : (comment.author.name.isEmpty ? l10n.deletedAuthorName : comment.author.name);

    final time = communityRelativeTime(context, comment.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: AppText(
                name,
                style: AppStyle.textBold14.copyWith(
                  fontSize: isReply ? 13.sp : 13.5.sp,
                  color: AppCustomColor.textPrimary,
                ),
                maxLines: 1,
              ),
            ),
            // The team is marked by a badge, not by a differently coloured name:
            // a purple name reads as a link, and the badge is what the design
            // uses to say "this is the team answering".
            if (comment.author.isOfficial) ...[
              SizedBox(width: 7.w),
              const CommunityOfficialBadge(),
            ],
            // A top-level comment stamps its time right after the name; a reply
            // carries it down into its action row instead. That is the design's
            // own split, and it works: the parent needs the timestamp where the
            // eye already is, while a reply is read as an answer to the comment
            // above it and its age matters less than its author.
            if (!isReply) ...[
              SizedBox(width: 7.w),
              AppText(
                '· $time',
                style: AppStyle.text12.copyWith(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: isReply ? 2.h : 3.h),
        RichText(
          text: TextSpan(
            children: [
              if (replyToName != null && replyToName.isNotEmpty)
                TextSpan(
                  text: '@$replyToName ',
                  style: (isReply ? AppStyle.textBold14 : AppStyle.textBold14).copyWith(
                    color: AppCustomColor.brandPrimary,
                  ),
                ),
              TextSpan(
                text: comment.body,
                style: AppStyle.text14.copyWith(
                  fontSize: isReply ? 13.5.sp : 14.sp,
                  color: AppCustomColor.communityCommentInk,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isReply ? 6.h : 7.h),
        Row(
          children: [
            if (isReply) ...[
              AppText(
                time,
                style: AppStyle.text12.copyWith(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
                ),
              ),
              SizedBox(width: 14.w),
            ],
            _CommentMetaAction(
              asset: comment.isLiked
                  ? AppAsset.svg.app.icCommunityHeartFill
                  : AppAsset.svg.app.icCommunityHeart,
              label: '${comment.likeCount}',
              isActive: comment.isLiked,
              onTap: onLike,
              compact: isReply,
            ),
            SizedBox(width: isReply ? 14.w : 16.w),
            // A count, not the word "reply": the design puts a comment glyph
            // with the number of answers here, which doubles as the affordance
            // to add one.
            _CommentMetaAction(
              asset: AppAsset.svg.app.icCommunityBubble,
              label: '${comment.replyCount}',
              onTap: onReply,
              compact: isReply,
            ),
            const Spacer(),
            // Kept although design `S-04` draws no overflow on a comment: it is
            // the only way to report or hide one, and post-moderation is the
            // whole safety model of the forum.
            GestureDetector(
              onTap: onMenu,
              behavior: HitTestBehavior.opaque,
              child: CommunityGlyph(
                AppAsset.svg.app.icCommunityMore,
                size: 16,
                color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentMetaAction extends StatelessWidget {
  const _CommentMetaAction({
    required this.asset,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  /// One step down, for a reply's row — the design draws a reply's actions
  /// smaller than its parent's so the indent is not the only thing separating
  /// the two levels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppCustomColor.brandPrimary
        : studyThemeCardMuted(context, AppCustomColor.streakTextMuted);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommunityGlyph(asset, size: compact ? 14 : 15, color: color),
          SizedBox(width: compact ? 5.w : 6.w),
          AppText(
            label,
            style: AppStyle.text12.copyWith(
              fontSize: compact ? 12.sp : 12.5.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
