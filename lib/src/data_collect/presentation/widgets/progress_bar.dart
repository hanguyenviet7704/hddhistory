part of '../../data_collect.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(
          totalSteps,
          (index) => Expanded(
            child: Container(
              height: 10.h,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8.w : 0),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? const Color(0xFF917FF6) // Brand/Brand/Primary/300
                    : const Color(0xFFE3E8EF), // Neutral/200
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
