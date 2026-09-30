part of '../../../course.dart';

class _AdditionalContentQuestionPanel extends StatelessWidget {
  final CompletedLevelAdditionalContentRequestPromptStatus status;
  final bool isSubmitting;
  final Future<bool> Function()? onNoSelected;
  final VoidCallback? onYesSelected;

  const _AdditionalContentQuestionPanel({
    required this.status,
    required this.isSubmitting,
    this.onNoSelected,
    this.onYesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundBrandSoft,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            context.l10n.courseroadmap.additionalContentRequestQuestion,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.75,
            ),
            maxLines: 3,
          ),
          8.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AdditionalContentOptionTile(
                  label: context.l10n.courseroadmap.additionalContentRequestNoChoice,
                  iconAsset: status.isRequested ? AppAsset.svg.app.icConfusedFaceDisable : AppAsset.svg.app.icConfusedFace,
                  enabled: !isSubmitting && !status.isRequested,
                  onTap: onNoSelected == null ? null : () => unawaited(onNoSelected!()),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _AdditionalContentOptionTile(
                  label: context.l10n.courseroadmap.additionalContentRequestYesChoice,
                  iconAsset: AppAsset.svg.app.icSmilingFaceWithHearts,
                  selected: status.isRequested,
                  enabled: !isSubmitting && !status.isRequested,
                  onTap: onYesSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdditionalContentOptionTile extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _AdditionalContentOptionTile({
    required this.label,
    required this.iconAsset,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textOpacity = selected ? 1.0 : 0.5;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(8.r),
        border: selected ? Border.all(color: const Color(0xFF94762A), width: 2.w) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && onTap != null
              ? () {
                  AppHaptic.select();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 74.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(iconAsset, width: 29.729.w, height: 29.729.w),
                6.verticalSpace,
                Opacity(
                  opacity: textOpacity,
                  child: AppText(
                    label,
                    textAlign: TextAlign.center,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                    ),
                    maxLines: 2,
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
