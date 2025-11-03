part of '../../onboard.dart';

class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeDisplay(),
          _buildDynamicIsland(),
          _buildStatusIcons(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return AppText(
      '9:41',
      style: AppStyle.text16.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A202C),
      ),
    );
  }

  Widget _buildDynamicIsland() {
    return Container(
      width: 125.w,
      height: 37.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 80.w,
            height: 37.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          Container(
            width: 37.w,
            height: 37.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcons() {
    return Row(
      children: [
        Container(
          width: 18.w,
          height: 12.h,
          color: Colors.black,
        ),
        8.horizontalSpace,
        Container(
          width: 17.w,
          height: 11.834.h,
          color: Colors.black,
        ),
        8.horizontalSpace,
        Container(
          width: 27.401.w,
          height: 13.h,
          color: Colors.black,
        ),
      ],
    );
  }
}
