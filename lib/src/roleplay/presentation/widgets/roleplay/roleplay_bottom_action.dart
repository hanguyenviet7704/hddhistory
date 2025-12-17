part of '../../../roleplay.dart';

class RoleplayBottomAction extends StatelessWidget {
  final RoleplayEntity currentSection;

  const RoleplayBottomAction({
    super.key,
    required this.currentSection,
  });

  bool get _isExerciseSection {
    if (currentSection.contents.isEmpty) return false;
    return currentSection.contents.last.type == RoleplayContentType.exercise;
  }

  String get _transitionLabel {
    if (currentSection.transition.text.isNotEmpty) return currentSection.transition.text;
    if (_isExerciseSection) return 'Start';
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<RoleplayCubit>().goToNextSection(),
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
        child: AppText(
          _transitionLabel,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w600,
            color: currentSection.textColor.toHexColor,
          ),
        ),
      ),
    );
  }
}
