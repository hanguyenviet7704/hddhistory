part of '../../output_practice.dart';

class OutputPracticeUserBubble extends StatelessWidget {
  const OutputPracticeUserBubble({
    super.key,
    required this.content,
    required this.userLabel,
    required this.deliveryStatus,
    this.onRetry,
  });

  final String content;
  final String userLabel;
  final OutputPracticeDeliveryStatus deliveryStatus;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final showFailedHint = deliveryStatus == OutputPracticeDeliveryStatus.failed;
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(12.w, 3.w, 3.w, 3.w),
            decoration: BoxDecoration(
              color: const Color(0x223D37A4),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  userLabel,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppCustomColor.textPrimary,
                    height: 1.5,
                  ),
                ),
                8.horizontalSpace,
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: const Color(0xFF3D37A4),
                  child: AppText(
                    userLabel.isNotEmpty ? userLabel[0].toUpperCase() : 'Y',
                    style: AppStyle.text12.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          8.verticalSpace,
          Container(
            constraints: BoxConstraints(maxWidth: 0.8.sw),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF3D37A4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(2.r),
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
            ),
            child: AppText(
              content,
              maxLines: 100,
              softWrap: true,
              style: AppStyle.text14.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.75,
              ),
            ),
          ),
          if (showFailedHint) ...[
            6.verticalSpace,
            GestureDetector(
              onTap: onRetry,
              child: AppText(
                'Retry your message',
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textTertiary,
                  height: 1.75,
                  decoration: onRetry == null ? TextDecoration.none : TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
