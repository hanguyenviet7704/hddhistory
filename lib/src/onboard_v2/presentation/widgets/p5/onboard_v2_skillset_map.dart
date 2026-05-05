part of '../../../onboard_v2.dart';

class OnboardV2SkillsetMap extends StatelessWidget {
  const OnboardV2SkillsetMap({super.key, required this.activeIntroduces});

  final List<SkillsetOnboardingIntroduce> activeIntroduces;

  static const _positions = <SkillsetOnboardingIntroduce, ({double left, double top, double width})>{
    SkillsetOnboardingIntroduce.whatILearnFades: (left: 145.0, top: 13.0, width: 51.5),
    SkillsetOnboardingIntroduce.myThoughtsCircle: (left: 251.0, top: 74.0, width: 51.5),
    SkillsetOnboardingIntroduce.myFeelingsFeelLoud: (left: 35.6, top: 86.0, width: 36.0),
    SkillsetOnboardingIntroduce.nothingFeelsNew: (left: 255.4, top: 213.3, width: 56.0),
    SkillsetOnboardingIntroduce.iTalkToMany: (left: 136.5, top: 283.0, width: 62.0),
    SkillsetOnboardingIntroduce.imBusyAllDay: (left: 34.8, top: 213.3, width: 41.0),
  };

  @override
  Widget build(BuildContext context) {
    final activeSet = activeIntroduces.toSet();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 335.w,
          height: 395.h,
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: const OnboardV2SkillsetMapPainter())),
                for (final entry in _positions.entries)
                  Positioned(
                    left: entry.value.left.w,
                    top: entry.value.top.h,
                    width: entry.value.width.w,
                    child: OnboardV2SkillsetMapNode(
                      label: entry.key.title.split(' ').first,
                      iconPath: activeSet.contains(entry.key) ? entry.key.image : entry.key.imageDisable,
                      active: activeSet.contains(entry.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
