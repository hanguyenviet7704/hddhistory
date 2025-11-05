part of '../../../course.dart';

class KeypointsSectionHeader extends StatelessWidget {
  const KeypointsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // "Key points" title
        AppText(
          'Key points',
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        // "How it works" button (UI only, action to be added later)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              'How it works',
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textQuaternary,
                fontWeight: FontWeight.w600,
              ),
            ),
            8.horizontalSpace,
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppCustomColor.textQuaternary,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppText(
                  'i',
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textQuaternary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
