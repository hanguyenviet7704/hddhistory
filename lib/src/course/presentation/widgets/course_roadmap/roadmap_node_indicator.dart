part of '../../../course.dart';

class RoadmapNodeIndicator extends StatelessWidget {
  final String iconUrl;
  final bool isLocked;

  const RoadmapNodeIndicator({
    super.key,
    this.iconUrl = '',
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: isLocked ? AppCustomColor.neutral100 : AppCustomColor.brandPrimary50,
        shape: BoxShape.circle,
      ),
      child: DCachedImage(
        url: iconUrl,
        fit: BoxFit.contain,
      ),
    );
  }
}
