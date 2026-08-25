part of '../../community.dart';

/// One post in the feed (design `S-01`).
///
/// The whole card opens the thread; the room chip, the attachments and each
/// action button stop the tap so they do their own job instead.
///
/// The layout is title-first on purpose: the headline is what a reader scans,
/// and the author line sits UNDER it with the body indented to the avatar's
/// right edge, so a long thread reads as one block hanging off one person
/// rather than as a header with a wall beneath it.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onFollowThread,
    required this.onMenu,
    this.onTopic,
    this.onCard,
  });

  final CommunityPostEntity post;
  final VoidCallback onOpen;
  final VoidCallback onLike;

  /// The bell: "tell me when this thread gets a new comment".
  final VoidCallback onFollowThread;
  final VoidCallback onMenu;
  final void Function(CommunityPostTopicEntity topic)? onTopic;
  final void Function(CommunityAttachedCardEntity card)? onCard;

  /// Avatar width plus its gap — everything below the author line lines up
  /// with the name, not with the card edge.
  static const double _bodyIndent = CommunityBylineRow.indent;

  @override
  Widget build(BuildContext context) {
    final topic = post.topic;
    final card = post.attachedCard;
    final headline = post.subject.trim();

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppCustomColor.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic != null) ...[
              _TopicChip(topic: topic, onTap: onTopic),
              SizedBox(height: 8.h),
            ],
            // Posts written before the composer had a title field fall back to
            // leading with the body — an empty headline slot would read as a
            // rendering fault.
            if (headline.isNotEmpty) ...[
              AppText(
                headline,
                // Inside a card the ink stays dark whatever the study
                // background is — the card is opaque enough to carry it, and
                // light ink here would vanish on the stock white one.
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
              ),
              SizedBox(height: 8.h),
            ],
            CommunityBylineRow(
              author: post.author,
              createdAt: post.createdAt,
              isPinned: post.isPinned,
            ),
            Padding(
              padding: EdgeInsets.only(left: _bodyIndent.w, top: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.body.trim().isNotEmpty)
                    AppText(
                      post.body,
                      style: AppStyle.text14.copyWith(
                        color: studyThemeCardMuted(
                          context,
                          AppCustomColor.streakTextMuted,
                        ),
                        height: 1.55,
                      ),
                      maxLines: 3,
                    ),
                  if (card != null) ...[
                    SizedBox(height: 12.h),
                    CommunityInsightCard(
                      card: card,
                      onTap: onCard == null ? null : () => onCard!(card),
                    ),
                  ],
                  if (post.attachedCourseId != null) ...[
                    SizedBox(height: 12.h),
                    CommunityAttachedCourseCard(
                      courseId: post.attachedCourseId!,
                    ),
                  ],
                  if (post.images.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: DCachedImage(
                        url: post.images.first,
                        width: double.infinity,
                        height: 150.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _CountAction(
                        asset: post.isLiked
                            ? AppAsset.svg.app.icCommunityHeartFill
                            : AppAsset.svg.app.icCommunityHeart,
                        count: post.likeCount,
                        isActive: post.isLiked,
                        onTap: onLike,
                      ),
                      SizedBox(width: 20.w),
                      _CountAction(
                        asset: AppAsset.svg.app.icCommunityBubble,
                        count: post.commentCount,
                        onTap: onOpen,
                      ),
                      SizedBox(width: 20.w),
                      // The bell, not a bookmark: this subscribes the reader to
                      // the thread, and the "Đang theo dõi" tab lists exactly
                      // the posts it is lit on.
                      _CountAction(
                        asset: post.isSaved
                            ? AppAsset.svg.app.icCommunityBellFill
                            : AppAsset.svg.app.icCommunityBell,
                        count: post.saveCount,
                        isActive: post.isSaved,
                        onTap: onFollowThread,
                        tooltip: post.isSaved ? context.l10n.community.unfollowThread : context.l10n.community.followThread,
                      ),
                      const Spacer(),
                      _IconTap(
                        asset: AppAsset.svg.app.icCommunityMore,
                        color: studyThemeCardMuted(
                          context,
                          AppCustomColor.streakTextMuted,
                        ),
                        onTap: onMenu,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The room a post was written in, as the chip above its title.
class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic, this.onTap});

  final CommunityPostTopicEntity topic;
  final void Function(CommunityPostTopicEntity topic)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(topic),
      // Align keeps the chip at its own width: a Container with an alignment
      // set stretches to fill the row instead.
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppCustomColor.communityChipBackground,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: AppText(
            topic.name,
            style: AppStyle.textBold10.copyWith(
              color: AppCustomColor.communityChipInk,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _CountAction extends StatelessWidget {
  const _CountAction({
    required this.asset,
    required this.count,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  /// The glyph to draw — the caller picks the filled variant for the lit state,
  /// because the design fills the heart and the bell rather than only
  /// recolouring their outline.
  final String asset;
  final int count;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // On the background the muted ink has to flip light for a dark preset;
    // inside a glass card over a photo the design's slate washes out instead.
    final muted = CommunityFlatSurface.of(context)
        ? studyThemeOnBg(context, AppCustomColor.streakTextMuted)
        : studyThemeCardMuted(context, AppCustomColor.streakTextMuted);
    final color = isActive
        ? studyThemeAccentOnBg(context, AppCustomColor.brandPrimary)
        : muted;

    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommunityGlyph(asset, size: 16, color: color),
          SizedBox(width: 6.w),
          AppText(
            '$count',
            // The counts are quiet in the design — medium, not bold: the glyph
            // carries the meaning and the number only qualifies it.
            style: AppStyle.text12.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );

    final label = tooltip;
    if (label == null) return button;

    // The bell is the one action whose meaning is not obvious from its shape,
    // and it is also the one the design gives no label.
    return Semantics(label: label, button: true, child: button);
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.asset, required this.onTap, this.color});

  final String asset;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: CommunityGlyph(
          asset,
          size: 17,
          color: color ?? AppCustomColor.streakTextMuted,
        ),
      ),
    );
  }
}
