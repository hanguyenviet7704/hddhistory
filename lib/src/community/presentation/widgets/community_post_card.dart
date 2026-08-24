part of '../../community.dart';

/// One post in the feed (design `S-01`).
///
/// The whole card opens the thread; the topic chip, the attached course, and
/// each action button stop the tap so they do their own job instead.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onSave,
    required this.onMenu,
    this.onTopic,
  });

  final CommunityPostEntity post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onMenu;
  final void Function(CommunityPostTopicEntity topic)? onTopic;

  @override
  Widget build(BuildContext context) {
    final topic = post.topic;

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
              SizedBox(height: 10.h),
            ],
            Row(
              children: [
                CommunityAvatar(author: post.author),
                SizedBox(width: 10.w),
                Expanded(
                  child: CommunityAuthorLine(
                    author: post.author,
                    createdAt: post.createdAt,
                    isPinned: post.isPinned,
                  ),
                ),
                _IconTap(
                  icon: Icons.more_horiz,
                  color: AppCustomColor.communityMuted,
                  onTap: onMenu,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            AppText(
              post.body,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              maxLines: 8,
            ),
            if (post.attachedCourseId != null)
              CommunityAttachedCourseCard(courseId: post.attachedCourseId!),
            if (post.images.isNotEmpty) ...[
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: DCachedImage(
                  url: post.images.first,
                  width: double.infinity,
                  height: 180.h,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                _CountAction(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  count: post.likeCount,
                  isActive: post.isLiked,
                  onTap: onLike,
                ),
                SizedBox(width: 18.w),
                _CountAction(
                  icon: Icons.mode_comment_outlined,
                  count: post.commentCount,
                  onTap: onOpen,
                ),
                SizedBox(width: 18.w),
                _CountAction(
                  icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  count: post.saveCount,
                  isActive: post.isSaved,
                  onTap: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.successGreen,
                ),
              ),
              SizedBox(width: 6.w),
              AppText(
                topic.name,
                style: AppStyle.textBold12.copyWith(
                  color: studyThemeCardMuted(context, AppCustomColor.streakTextMuted),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountAction extends StatelessWidget {
  const _CountAction({
    required this.icon,
    required this.count,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final bool isActive;

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
          Icon(icon, size: 17.sp, color: color),
          SizedBox(width: 6.w),
          AppText(
            '$count',
            style: AppStyle.textBold12.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Icon(
          icon,
          size: 18.sp,
          color: color ?? AppCustomColor.streakTextMuted,
        ),
      ),
    );
  }
}
