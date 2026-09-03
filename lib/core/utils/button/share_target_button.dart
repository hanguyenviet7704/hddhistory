part of '../utils.dart';

/// One target in a share row: a brand disc with a short label under it.
///
/// Extracted from the course-share sheet so the app has ONE definition of what
/// a share target looks like. The week-recap poster grew a second share row and
/// its own copy immediately drifted — different disc size, no soft shadow on the
/// white discs, Material's outlined glyphs instead of the rounded ones, and no
/// Semantics. A reader who shares a course and then shares their week should not
/// be looking at two different buttons.
///
/// Sizes and brand fills come from the design's own share row
/// (`_Keypoint Tap and Share` -> `shareTargets`).
class ShareTargetButton extends StatelessWidget {
  const ShareTargetButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.onTap,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final BoxDecoration background;
  final VoidCallback onTap;

  /// False while a capture or upload is in flight. The disc dims and stops
  /// responding rather than disappearing, so the row keeps its shape.
  final bool enabled;

  /// A smaller cut of the same button — 44 disc instead of 58 — for rows that
  /// sit under something that must own the screen. The week-recap poster uses
  /// it so the whole 9:16 page fits the viewport without scrolling ("chỉ cần
  /// thu nhỏ phần này", 2026-08-21); the course-share sheet keeps the full
  /// size. One widget, two sizes — not two widgets.
  final bool compact;

  /// Instagram's story composer, as its own brand gradient.
  static const BoxDecoration instagramDisc = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment(-0.5, -1),
      end: Alignment(0.5, 1),
      colors: [
        AppCustomColor.shareInstagramStart,
        AppCustomColor.shareInstagramMid,
        AppCustomColor.shareInstagramEnd,
      ],
      stops: [0, 0.48, 1],
    ),
  );

  static const BoxDecoration facebookDisc = BoxDecoration(
    color: AppCustomColor.shareFacebookBlue,
    shape: BoxShape.circle,
  );

  /// The neutral disc. Picks up the soft drop shadow below, because a white
  /// circle on a white sheet has nothing else to separate it.
  static const BoxDecoration plainDisc = BoxDecoration(
    color: AppCustomColor.backgroundWhite,
    shape: BoxShape.circle,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  AppHaptic.select();
                  onTap();
                }
              : null,
          child: SizedBox(
            width: compact ? 72.w : 80.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 44.r : 58.r,
                  height: compact ? 44.r : 58.r,
                  alignment: Alignment.center,
                  decoration: background.copyWith(
                    boxShadow: background.color == AppCustomColor.backgroundWhite
                        ? [
                            BoxShadow(
                              color: AppCustomColor.shareTargetShadow,
                              offset: Offset(0, 6.h),
                              blurRadius: 16.r,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, size: compact ? 20.r : 25.r, color: iconColor),
                ),
                (compact ? 5 : 9).verticalSpace,
                AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: compact ? 10.sp : 11.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppCustomColor.kpOptionText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
