part of '../../output_practice.dart';

class OutputPracticeHeader extends StatelessWidget {
  const OutputPracticeHeader({
    super.key,
    required this.title,
    required this.label,
    required this.onClose,
  });

  final String title;
  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              splashRadius: 18.r,
              icon: Icon(
                Icons.close_rounded,
                color: const Color(0x80362F82),
                size: 24.w,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                label.toUpperCase(),
                style: AppStyle.text12.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0x80362F82),
                  height: 1.75,
                ),
              ),
              AppText(
                title,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xB3110751),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
