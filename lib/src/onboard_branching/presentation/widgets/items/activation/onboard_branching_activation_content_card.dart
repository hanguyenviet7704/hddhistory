part of '../../../../onboard_branching.dart';

class OnboardBranchingActivationContentCard extends StatelessWidget {
  const OnboardBranchingActivationContentCard({
    super.key,
    required this.content,
  });

  final OnboardingScenarioActivationContentEntity content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (content.icon.trim().isNotEmpty) ...[
            Center(
              child: CacheNetworkGraphic(
                url: content.icon,
                width: 120.w,
                height: 120.w,
                fit: BoxFit.cover,
              ),
            ),
            8.verticalSpace,
          ],
          for (var index = 0; index < content.labels.length; index++) ...[
            OnboardBranchingActivationLabelRow(
              index: index,
              text: content.labels[index].label.text,
            ),
            if (index != content.labels.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(height: 1, color: Color(0xFFE3E8EF)),
              ),
          ],
        ],
      ),
    );
  }
}
