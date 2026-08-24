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

  static const Color _rail = Color(0xFFE7E8F0);

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
                            child: Container(width: 2.w, height: double.infinity, color: _rail),
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
                        color: _rail,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: AppText(
                name,
                style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
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
          ],
        ),
        SizedBox(height: 3.h),
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
                style: (isReply ? AppStyle.text13 : AppStyle.text14).copyWith(
                  color: AppCustomColor.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 7.h),
        Row(
          children: [
            AppText(
              communityRelativeTime(context, comment.createdAt),
              style: AppStyle.text12.copyWith(color: AppCustomColor.communityMuted),
            ),
            SizedBox(width: 16.w),
            _CommentMetaAction(
              icon: comment.isLiked ? Icons.favorite : Icons.favorite_border,
              label: '${comment.likeCount}',
              isActive: comment.isLiked,
              onTap: onLike,
            ),
            SizedBox(width: 16.w),
            // A count, not the word "reply": the design puts a comment glyph
            // with the number of answers here, which doubles as the affordance
            // to add one.
            _CommentMetaAction(
              icon: Icons.mode_comment_outlined,
              label: '${comment.replyCount}',
              onTap: onReply,
            ),
            const Spacer(),
            GestureDetector(
              onTap: onMenu,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.more_horiz,
                size: 16.sp,
                color: AppCustomColor.communityMuted,
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
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppCustomColor.brandPrimary : AppCustomColor.streakTextMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(width: 6.w),
          AppText(label, style: AppStyle.text12.copyWith(color: color)),
        ],
      ),
    );
  }
}
