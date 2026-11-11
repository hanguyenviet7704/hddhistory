part of '../../community.dart';

/// The `⋯` menu on a post or comment (design `S-01`).
///
/// "Ẩn nội dung này" and "Báo cáo" are two different asks and are kept
/// visually apart: hiding is a private preference, reporting hands the item to
/// the team. Own content gets "Xoá" instead of both.
///
/// Every row closes the sheet through a [Builder]'s context rather than through
/// the CALLER's, and that is not a style preference. [showDModalBottomSheet]
/// pushes on `AppConfig.instance.context` — the ROOT navigator — while the
/// context handed to this function belongs to a page inside a shell branch.
/// `Navigator.of(callerContext).maybePop()` therefore aimed at the wrong
/// navigator entirely: on the feed (the branch's first route) it had nothing to
/// pop, so tapping "Ẩn nội dung này" left the sheet sitting there and looked
/// like the button did nothing; on the thread screen it popped THE PAGE out
/// from under the still-open sheet, and the hide callback's own pop then took a
/// second route with it. A `Builder` under the sheet's own route resolves to the
/// navigator the sheet is actually on.
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
    bodyWidget: Builder(
      builder: (sheetContext) {
        void close() => Navigator.of(sheetContext).maybePop();

        return SafeArea(
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
                          close();
                          onDelete();
                        },
                      ),
                    ]
                  : [
                      _MenuRow(
                        icon: Icons.visibility_off_outlined,
                        label: l10n.menuHide,
                        onTap: () {
                          close();
                          onHide();
                          // Said here rather than at each of the four call
                          // sites: hiding is optimistic everywhere (the item is
                          // dropped locally and the server is told after), so
                          // there is no later moment that knows better, and one
                          // place means the answer cannot go missing from one
                          // of them again.
                          DMessage.showMessage(
                            message: l10n.hideDone,
                            type: MessageType.success,
                          );
                        },
                      ),
                      _MenuRow(
                        icon: Icons.flag_outlined,
                        label: l10n.menuReport,
                        isDestructive: true,
                        onTap: () {
                          close();
                          onReport();
                        },
                      ),
                    ],
            ),
          ),
        );
      },
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
