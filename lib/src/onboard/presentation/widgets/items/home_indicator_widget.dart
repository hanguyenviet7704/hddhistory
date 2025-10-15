part of '../../../onboard.dart';

class HomeIndicatorWidget extends StatelessWidget {
  const HomeIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: Center(
        child: Container(
          width: 144.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(100.r),
          ),
        ),
      ),
    );
  }
}
