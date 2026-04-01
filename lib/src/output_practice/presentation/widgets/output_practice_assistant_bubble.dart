part of '../../output_practice.dart';

class OutputPracticeAssistantBubble extends StatelessWidget {
  const OutputPracticeAssistantBubble({
    super.key,
    required this.name,
    required this.content,
    required this.avatarUrl,
  });

  final String name;
  final String content;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(3.w, 3.w, 12.w, 3.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OutputPracticeAvatar(url: avatarUrl),
                8.horizontalSpace,
                AppText(
                  name,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppCustomColor.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          8.verticalSpace,
          Container(
            constraints: BoxConstraints(maxWidth: 0.83.sw),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2.r),
                topRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFEBF0F7),
                  blurRadius: 4,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: AppText(
              content,
              maxLines: 100,
              softWrap: true,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPracticeAvatar extends StatelessWidget {
  const _OutputPracticeAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 14.r,
        backgroundColor: AppCustomColor.textPrimary,
        child: AppText(
          'A',
          style: AppStyle.text12.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return CacheNetworkGraphic(
      url: url,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(28.r),
      width: 28.w,
      height: 28.w,
    );
  }
}
