part of '../../community.dart';

/// One row of the topics list (design `S-02`): name, reach, follow toggle.
class CommunityTopicRow extends StatelessWidget {
  const CommunityTopicRow({
    super.key,
    required this.topic,
    required this.onOpen,
    required this.onToggleFollow,
  });

  final CommunityTopicEntity topic;
  final VoidCallback onOpen;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    topic.name,
                    style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
                    maxLines: 2,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    // Two facts on one line, as the design writes it: how many
                    // people are here, and whether it is alive this week.
                    '${l10n.topicMembers(count: topic.followers)} · ${l10n.topicPostsThisWeek(count: topic.postsThisWeek)}',
                    style: AppStyle.text12.copyWith(color: AppCustomColor.communityMuted),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            CommunityFollowButton(isFollowing: topic.isFollowing, onTap: onToggleFollow),
          ],
        ),
      ),
    );
  }
}

class CommunityFollowButton extends StatelessWidget {
  const CommunityFollowButton({
    super.key,
    required this.isFollowing,
    required this.onTap,
  });

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isFollowing ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(99.r),
          border: isFollowing
              ? null
              : Border.all(color: AppCustomColor.borderBrand, width: 1.4),
        ),
        child: AppText(
          isFollowing ? l10n.following : l10n.follow,
          style: AppStyle.textBold12.copyWith(
            color: isFollowing ? AppCustomColor.textWhite : AppCustomColor.streakActive,
          ),
        ),
      ),
    );
  }
}
