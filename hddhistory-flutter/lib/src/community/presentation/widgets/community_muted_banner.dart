part of '../../community.dart';

/// Why the composer is closed.
///
/// Shown in place of the write affordances rather than as an error on submit: a
/// reader who is signed out or suspended should find that out before typing a
/// post, not after.
class CommunityMutedBanner extends StatelessWidget {
  const CommunityMutedBanner({super.key, required this.status, this.onSignIn});

  final CommunityMemberStatusEntity status;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    if (status.canPost) return const SizedBox.shrink();

    final l10n = context.l10n.community;
    final mutedUntil = status.mutedUntil;

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: status.requiresLogin
            ? AppCustomColor.backgroundBrandSoft
            : AppCustomColor.backgroundError,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.requiresLogin ? Icons.lock_outline : Icons.info_outline,
            size: 18.sp,
            color: status.requiresLogin
                ? AppCustomColor.streakActive
                : AppCustomColor.errorRed,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  status.requiresLogin ? l10n.guestTitle : l10n.mutedTitle,
                  style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
                ),
                SizedBox(height: 4.h),
                AppText(
                  status.requiresLogin
                      ? l10n.guestBody
                      : (status.reason?.trim().isNotEmpty == true
                            ? status.reason!
                            : l10n.mutedBodyFallback),
                  style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
                ),
                if (!status.requiresLogin && mutedUntil != null) ...[
                  SizedBox(height: 4.h),
                  AppText(
                    l10n.mutedUntil(date: mutedUntil.localeDate),
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.errorRed),
                  ),
                ],
                if (status.requiresLogin && onSignIn != null) ...[
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: onSignIn,
                    child: AppText(
                      l10n.guestAction,
                      style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
