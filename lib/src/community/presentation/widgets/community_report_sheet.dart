part of '../../community.dart';

/// Reason picker for a report.
///
/// Reporting is post-moderation: the item stays up until the team looks at it,
/// so the confirmation says that rather than implying it has been removed.
void showCommunityReportSheet(
  BuildContext context, {
  required Future<bool> Function(CommunityReportReason reason) onSubmit,
}) {
  final l10n = context.l10n.community;

  final reasons = <CommunityReportReason, String>{
    CommunityReportReason.spam: l10n.reportSpam,
    CommunityReportReason.harassment: l10n.reportHarassment,
    CommunityReportReason.adult: l10n.reportAdult,
    CommunityReportReason.misinformation: l10n.reportMisinformation,
    CommunityReportReason.privacy: l10n.reportPrivacy,
    CommunityReportReason.other: l10n.reportOther,
  };

  showDModalBottomSheet(
    initialChildSize: 0.55,
    maxChildSize: 0.75,
    bodyWidget: SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              l10n.reportTitle,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
            SizedBox(height: 6.h),
            AppText(
              l10n.reportSubtitle,
              style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
            ),
            SizedBox(height: 12.h),
            ...reasons.entries.map(
              (entry) => GestureDetector(
                onTap: () async {
                  Navigator.of(context).maybePop();
                  final sent = await onSubmit(entry.key);
                  DMessage.showMessage(
                    message: sent ? l10n.reportSent : l10n.reportFailed,
                    type: sent ? MessageType.success : MessageType.error,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          entry.value,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18.sp,
                        color: AppCustomColor.communityMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
