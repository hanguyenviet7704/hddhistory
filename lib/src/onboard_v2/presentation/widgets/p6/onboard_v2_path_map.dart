part of '../../../onboard_v2.dart';

class OnboardV2PathMap extends StatelessWidget {
  const OnboardV2PathMap({super.key, required this.activePaths});

  final List<OnboardingPath> activePaths;

  static const _nodeFrames = <OnboardingPath, ({double left, double top})>{
    OnboardingPath.learnBetter: (left: 117.5, top: 13.0),
    OnboardingPath.thinkBetter: (left: 231.0, top: 74.0),
    OnboardingPath.feelBetter: (left: 4.84375, top: 74.0),
    OnboardingPath.exploreBetter: (left: 231.0, top: 213.25),
    OnboardingPath.connectBetter: (left: 117.5, top: 283.0),
    OnboardingPath.workBetter: (left: 4.84375, top: 213.25),
  };

  @override
  Widget build(BuildContext context) {
    final activeSet = activePaths.toSet();
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
                Positioned.fill(child: CustomPaint(painter: const OnboardV2PathMapPainter())),
                for (final entry in _nodeFrames.entries)
                  Positioned(
                    left: entry.value.left.w,
                    top: entry.value.top.w,
                    width: 100.w,
                    height: 100.w,
                    child: OnboardV2PathMapNode(
                      key: ValueKey('onboard_v2_path_map_node_${entry.key.name}'),
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
