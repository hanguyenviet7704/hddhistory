part of '../../../../onboard_branching.dart';

class OnboardBranchingActivationLabelRow extends StatelessWidget {
  const OnboardBranchingActivationLabelRow({
    super.key,
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: AppText(
            '${index + 1}.',
            style: AppStyle.text14.copyWith(
              color: const Color(0xB3110751),
              fontWeight: FontWeight.w700,
              height: 1.75,
            ),
          ),
        ),
        14.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            textAlign: TextAlign.start,
            style: AppStyle.text14.copyWith(
              color: const Color(0xB3110751),
            ),
          ),
        ),
      ],
    );
  }
}
