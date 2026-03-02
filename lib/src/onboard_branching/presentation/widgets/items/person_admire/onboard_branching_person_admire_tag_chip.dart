part of '../../../../onboard_branching.dart';

class OnboardBranchingPersonAdmireTagChip extends StatelessWidget {
  const OnboardBranchingPersonAdmireTagChip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: AppText(
        text,
        style: AppStyle.text10.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.75,
        ),
      ),
    );
  }
}
