part of '../../../onboard_v2.dart';

class OnboardV2PathMap extends StatelessWidget {
  const OnboardV2PathMap({
    super.key,
    required this.activePaths,
    this.resolvedPaths = const <OnboardPathEntity>[],
  });

  final List<OnboardingPath> activePaths;

  /// API-resolved (or offline-fallback) path content — see
  /// [OnboardV2PathResolver]. Defaults to empty, which renders the legacy
  /// enum's shortTitle/icon unchanged (used by widget tests that construct
  /// this widget without onboard data).
  final List<OnboardPathEntity> resolvedPaths;

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
    final resolvedByKey = {for (final resolvedPath in resolvedPaths) resolvedPath.key: resolvedPath};

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
                    child: _buildNode(entry.key, activeSet.contains(entry.key), resolvedByKey[entry.key.trackingId]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNode(OnboardingPath path, bool active, OnboardPathEntity? resolvedPath) {
    final resolvedShortTitle = resolvedPath?.shortTitle.trim();
    final label = (resolvedShortTitle != null && resolvedShortTitle.isNotEmpty) ? resolvedShortTitle : path.shortTitle;
    final iconKey = resolvedPath?.iconKey.trim();
    final iconUrl = resolvedPath?.iconUrl ?? '';

    return OnboardV2PathMapNode(
      key: ValueKey('onboard_v2_path_map_node_${path.name}'),
      label: label,
      iconPath: OnboardV2IconResolver.resolve(
        iconUrl: iconUrl,
        iconKey: (iconKey != null && iconKey.isNotEmpty) ? iconKey : OnboardV2IconResolver.iconKeyForLegacyPath(path),
        selected: active,
      ),
      active: active,
    );
  }
}
