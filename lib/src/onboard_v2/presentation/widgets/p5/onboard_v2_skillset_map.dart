part of '../../../onboard_v2.dart';

class OnboardV2SkillsetMap extends StatelessWidget {
  const OnboardV2SkillsetMap({super.key, required this.activeIntroduces});

  final List<SkillsetOnboardingIntroduce> activeIntroduces;

  static const _nodeFrames = <SkillsetOnboardingIntroduce, ({double left, double top})>{
    SkillsetOnboardingIntroduce.whatILearnFades: (left: 117.5, top: 13.0),
    SkillsetOnboardingIntroduce.myThoughtsCircle: (left: 231.0, top: 74.0),
    SkillsetOnboardingIntroduce.myFeelingsFeelLoud: (left: 4.84375, top: 74.0),
    SkillsetOnboardingIntroduce.nothingFeelsNew: (left: 231.0, top: 213.25),
    SkillsetOnboardingIntroduce.iTalkToMany: (left: 117.5, top: 283.0),
    SkillsetOnboardingIntroduce.imBusyAllDay: (left: 4.84375, top: 213.25),
  };

  @override
  Widget build(BuildContext context) {
    final activeSet = activeIntroduces.toSet();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 335.w,
          height: 395.w,
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: const OnboardV2SkillsetMapPainter())),
                for (final entry in _nodeFrames.entries)
                  Positioned(
                    left: entry.value.left.w,
                    top: entry.value.top.w,
                    width: 100.w,
                    height: 100.w,
                    child: OnboardV2SkillsetMapNode(
                      key: ValueKey('onboard_v2_skillset_map_node_${entry.key.name}'),
                      label: entry.key.shortTitle,
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
