part of '../../../onboard_v2.dart';

class OnboardV2ProgressHeader extends StatelessWidget {
  const OnboardV2ProgressHeader({
    super.key,
    required this.activeSegments,
    required this.showBack,
    required this.onBack,
  });

  final int activeSegments;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const Key('onboard_v2_back_button'),
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, size: 24.w, color: AppCustomColor.textTertiary),
              ),
            ),
          SizedBox(
            width: 240.w,
            child: Row(
              children: List.generate(5, (index) {
                final active = index < activeSegments;
                return Expanded(
                  child: Container(
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: active ? AppCustomColor.textPrimary : AppCustomColor.borderSecondary,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
