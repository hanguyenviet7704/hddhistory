part of '../../community.dart';

/// A saved keypoint card carried inside a post (design `S-01`, the dark block).
///
/// Renders from the snapshot the post carries, never from a lookup: the card is
/// part of what the writer said, so a keypoint later edited or unpublished must
/// not change or blank it out under them.
class CommunityInsightCard extends StatelessWidget {
  const CommunityInsightCard({
    super.key,
    required this.card,
    this.onTap,
    this.onRemove,
  });

  final CommunityAttachedCardEntity card;
  final VoidCallback? onTap;

  /// Set only in the composer, where the attachment can still be taken off.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppCustomColor.communityInsightCard,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stops short of the quote glyph in the corner rather than
                // running under it.
                FractionallySizedBox(
                  widthFactor: 0.76,
                  child: AppText(
                    card.title,
                    style: AppStyle.textBold14.copyWith(
                      fontSize: 15.sp,
                      color: AppCustomColor.backgroundWhite,
                      height: 1.3,
                    ),
                    maxLines: 3,
                  ),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(vertical: 11.h),
                  color: AppCustomColor.backgroundWhite.withValues(alpha: 0.24),
                ),
                AppText(
                  card.back,
                  style: AppStyle.text12.copyWith(
                    fontSize: 12.5.sp,
                    color: AppCustomColor.backgroundWhite.withValues(
                      alpha: 0.86,
                    ),
                    height: 1.55,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            // Rides up over the card's top padding, which is why the Stack
            // does not clip: a negative offset under the default Clip.hardEdge
            // silently ate the glyph.
            Positioned(
              top: -8.h,
              right: onRemove != null ? 30.w : 0,
              child: ExcludeSemantics(
                child: AppText(
                  '“',
                  style: AppStyle.textBold48.copyWith(
                    color: AppCustomColor.backgroundWhite.withValues(
                      alpha: 0.12,
                    ),
                    height: 1,
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: -10.h,
                right: 0,
                child: _RemoveButton(onTap: onRemove!),
              ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: context.l10n.community.attachRemove,
        button: true,
        child: Container(
          width: 24.w,
          height: 24.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppCustomColor.backgroundWhite.withValues(alpha: 0.18),
          ),
          child: CommunityGlyph(
            AppAsset.svg.app.icCommunityClose,
            size: 12,
            color: AppCustomColor.backgroundWhite,
          ),
        ),
      ),
    );
  }
}
