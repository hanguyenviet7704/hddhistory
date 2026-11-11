part of '../../../roleplay.dart';

class RoleplayTransitionText extends StatelessWidget {
  final TransitionEntity transition;

  const RoleplayTransitionText({super.key, required this.transition});

  @override
  Widget build(BuildContext context) {
    final Color lineColor = transition.textColor.toHexColor.op(0.45);
    final Color textColor = transition.textColor.toHexColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _TransitionLine(color: lineColor),
          ),
          8.horizontalSpace,
          AppText(
            transition.content.text,
            style: AppStyle.text12.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.75,
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: _TransitionLine(color: lineColor),
          ),
        ],
      ),
    );
  }
}

class _TransitionLine extends StatelessWidget {
  final Color color;

  const _TransitionLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.op(0),
            color,
            color.op(0),
          ],
          stops: const [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }
}
