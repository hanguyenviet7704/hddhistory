part of '../../onboard.dart';

class ChatBubbleWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconPath;

  const ChatBubbleWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main chat bubble content
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(AppAsset.svg.common.star, width: 32.w, height: 32.w),
              8.verticalSpace,
              AppText(
                title,
                style: AppStyle.text20.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0D121C),
                  height: 1.5,
                ),
                maxLines: 2,
              ),
              8.verticalSpace,
              AppText(
                subtitle,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF364152),
                  height: 1.5,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        // Chat bubble arrow/tail
        Container(
          padding: EdgeInsets.only(right: 40.w),
          alignment: Alignment.centerRight,
          child: Transform.rotate(
            angle: 3.14159, // 180 degrees
            child: SizedBox(
              width: 25.865.w,
              height: 16.h,
              child: CustomPaint(
                painter: ChatArrowPainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
