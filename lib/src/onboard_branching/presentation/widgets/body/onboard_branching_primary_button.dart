part of '../../../onboard_branching.dart';

class OnboardBranchingPrimaryButton extends StatelessWidget {
  const OnboardBranchingPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.isLightStyle = false,
    this.showArrow = true,
    this.fullWidth = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;
  final bool isLightStyle;
  final bool showArrow;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !loading;
    final borderRadius = BorderRadius.circular(1000.r);
    final textColor = canTap ? (isLightStyle ? const Color(0xFF110751) : Colors.white) : const Color(0xFF7F8EA4);

    final decoration = canTap
        ? BoxDecoration(
            borderRadius: borderRadius,
            color: isLightStyle ? Colors.white : null,
            gradient: isLightStyle
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF4B44CA),
                      Color(0xFF554FF0),
                      Color(0xFF5D56F4),
                    ],
                  ),
          )
        : BoxDecoration(
            borderRadius: borderRadius,
            color: const Color(0xFFE3E8EF),
          );

    final button = SizedBox(
      height: 54.h,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTap ? onPressed : null,
            borderRadius: borderRadius,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: textColor,
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AppText(
                              text,
                              textAlign: TextAlign.center,
                              style: AppStyle.text16.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (showArrow) ...[
                            6.horizontalSpace,
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20.w,
                              color: textColor,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 174.w,
          maxWidth: 300.w,
        ),
        child: button,
      ),
    );
  }
}
