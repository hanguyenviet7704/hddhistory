part of '../../community.dart';

/// The `⋯` menu on a post or comment (design `S-01`).
///
/// "Ẩn nội dung này" and "Báo cáo" are two different asks and are kept
/// visually apart: hiding is a private preference, reporting hands the item to
/// the team. Own content gets "Xoá" instead of both.
void showCommunityItemMenu(
  BuildContext context, {
  required bool isMine,
  required VoidCallback onHide,
  required VoidCallback onReport,
  required VoidCallback onDelete,
}) {
  final l10n = context.l10n.community;

  showDModalBottomSheet(
    initialChildSize: 0.28,
    maxChildSize: 0.34,
    bodyWidget: SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: isMine
              ? [
                  _MenuRow(
                    icon: Icons.delete_outline,
                    label: l10n.menuDelete,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onDelete();
                    },
                  ),
                ]
              : [
                  _MenuRow(
                    icon: Icons.visibility_off_outlined,
                    label: l10n.menuHide,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onHide();
                    },
                  ),
                  _MenuRow(
                    icon: Icons.flag_outlined,
                    label: l10n.menuReport,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onReport();
                    },
                  ),
                ],
        ),
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppCustomColor.errorRed : AppCustomColor.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(width: 12.w),
            AppText(label, style: AppStyle.textBold14.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
