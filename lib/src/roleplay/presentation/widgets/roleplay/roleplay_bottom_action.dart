part of '../../../roleplay.dart';

class RoleplayBottomAction extends StatelessWidget {
  final SectionEntity currentSection;
  final SectionEntity? nextSection;
  final VoidCallback? onPressed;

  const RoleplayBottomAction({
    super.key,
    required this.currentSection,
    required this.nextSection,
    required this.onPressed,
  });

  bool get _isExerciseSection {
    if (currentSection.contents.isEmpty) return false;
    return currentSection.contents.last.type == RoleplaySectionType.exercise;
  }

  @override
  Widget build(BuildContext context) {
    if (_isExerciseSection) {
      final label = currentSection.transition.isNotEmpty ? currentSection.transition : 'Start';
      return _RoleplayPrimaryButton(
        label: label,
        onPressed: onPressed,
      );
    }

    final String label = nextSection?.title.isNotEmpty == true ? nextSection!.title : (currentSection.transition.isNotEmpty ? currentSection.transition : 'Continue');
    final bool hasNext = nextSection != null;
    return _RoleplayNextSectionChip(
      label: label,
      onPressed: hasNext ? onPressed : null,
    );
  }
}

class _RoleplayPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RoleplayPrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppCustomColor.gradientButton,
            ),
            borderRadius: BorderRadius.circular(28.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleplayNextSectionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RoleplayNextSectionChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayRightBubble,
            borderRadius: BorderRadius.circular(60.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                label,
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textPrimary,
                ),
              ),
              12.horizontalSpace,
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppCustomColor.textPrimary,
                size: 16.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
