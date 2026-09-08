part of '../../community.dart';

/// A room in the "Khám phá phòng" grid (design `S-02`).
///
/// The tint is chosen by the room's own id, not by its position in the list, so
/// a room keeps the same colour when the list is re-sorted or a new room lands
/// above it.
/// Which tint a room gets, derived from its id.
///
/// By id, not by list position: the room list is re-sorted (favourites move out
/// of the grid, a new room lands anywhere) and a room that changes colour
/// between visits stops being recognisable.
int communityRoomSlot(String topicId) {
  if (topicId.isEmpty) return 0;

  return topicId.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
      AppCustomColor.communityRoomTints.length;
}

class CommunityRoomTile extends StatelessWidget {
  const CommunityRoomTile({super.key, required this.topic, required this.onTap});

  final CommunityTopicEntity topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final slot = communityRoomSlot(topic.id);
    final tint = AppCustomColor.communityRoomTints[slot];
    final ink = AppCustomColor.communityRoomInks[slot];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // No minHeight: the grid cell already imposes one, and a taller
        // constraint inside it can only overflow at large text scales.
        padding: EdgeInsets.fromLTRB(13.w, 14.h, 13.w, 12.h),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(Icons.home_outlined, size: 17.sp, color: ink),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: AppText(
                topic.name,
                style: AppStyle.textBold12.copyWith(
                  color: AppCustomColor.communityTopicHeading,
                  height: 1.32,
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 8.h),
            // One number only (design `S-02`). The follower count went with it:
            // in a grid cell this narrow it competed with the number that
            // actually tells the reader whether the room is worth opening.
            AppText(
              l10n.topicDiscussions(count: topic.postsThisWeek),
              style: AppStyle.textBold10.copyWith(
                color: AppCustomColor.streakTextMuted,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// A followed room as a row in the "Yêu thích" list (design `S-02`).
///
/// The freshness line is the one thing that makes this list worth opening, so
/// it carries the live dot: green when the room had posts today, muted when it
/// did not.
class CommunityFavouriteRoomRow extends StatelessWidget {
  const CommunityFavouriteRoomRow({
    super.key,
    required this.topic,
    required this.onTap,
  });

  final CommunityTopicEntity topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final slot = communityRoomSlot(topic.id);
    final tint = AppCustomColor.communityRoomTints[slot];
    final ink = AppCustomColor.communityRoomInks[slot];
    // The dot now tracks TODAY, not the week: the line beside it says "hôm
    // nay", and a green dot on a room whose last post was Monday is a promise
    // the text next to it does not keep.
    final isLive = topic.postsToday > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 9.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppCustomColor.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(Icons.home_outlined, size: 20.sp, color: ink),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    topic.name,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppCustomColor.successGreen,
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Flexible(
                        child: AppText(
                          // "· 0 hôm nay" is a sentence with no news in it, so
                          // a quiet room drops the second half and keeps the
                          // number that is still worth reading.
                          isLive
                              ? '${l10n.topicDiscussions(count: topic.postsThisWeek)} · '
                                    '${l10n.topicPostsToday(count: topic.postsToday)}'
                              : l10n.topicDiscussions(
                                  count: topic.postsThisWeek,
                                ),
                          style: AppStyle.textBold12.copyWith(
                            color: isLive
                                ? AppCustomColor.successGreen
                                : AppCustomColor.communityMuted,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              size: 18.sp,
              color: AppCustomColor.communityMuted,
            ),
          ],
        ),
      ),
    );
  }
}
