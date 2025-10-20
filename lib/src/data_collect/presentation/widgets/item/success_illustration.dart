part of '../../../data_collect.dart';

class SuccessIllustration extends StatelessWidget {
  const SuccessIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
      width: 102.58.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DCachedImage(
            url: AppAsset.images.common.birdHappy.path,
            fit: BoxFit.contain,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30.w,
              height: 30.h,
              decoration: const BoxDecoration(
                color: Color(0xFF23AE86), // Success color
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
