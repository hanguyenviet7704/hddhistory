part of '../../community.dart';

/// The weekly-question card pinned at the top of the feed (design `S-01`).
class CommunityWeeklyCard extends StatelessWidget {
  const CommunityWeeklyCard({super.key, required this.weekly, required this.onTap});

  final CommunityWeeklyEntity weekly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final daysLeft = weekly.daysLeft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary50,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppCustomColor.communityWeeklyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    weekly.weekNumber == null
                        ? l10n.weeklyLabel
                        : l10n.weeklyLabelWithWeek(week: weekly.weekNumber!),
                    style: AppStyle.textBold10.copyWith(
                      color: AppCustomColor.streakActive,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                  ),
                ),
                if (daysLeft != null && daysLeft > 0)
                  AppText(
                    l10n.weeklyDaysLeft(count: daysLeft),
                    style: AppStyle.textBold10.copyWith(color: AppCustomColor.communityMuted),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            AppText(
              weekly.title,
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.communityTopicHeading,
                height: 1.4,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: AppText(
                    l10n.weeklyAnswered(count: weekly.answerCount),
                    style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
                    maxLines: 1,
                  ),
                ),
                // A filled pill, as the design draws it: this card's whole job
                // is to pull the reader into the week's thread, so the call to
                // action has to look like a button rather than a caption.
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: AppText(
                    l10n.weeklyJoin,
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.textWhite),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
