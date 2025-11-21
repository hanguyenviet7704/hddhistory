part of '../../../roleplay.dart';

class RoleplayFeedbackChart extends StatelessWidget {
  const RoleplayFeedbackChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayPointCubit, RoleplayPointState, List<KeypointEntity>>(
      selector: (state) => state.points,
      builder: (context, points) {
        final bool canRenderChart = points.length >= 3;
        return Container(
          padding: EdgeInsets.only(top: 20.h, bottom: 8.h),
          alignment: Alignment.center,
          child: SizedBox.square(
            dimension: 255.h,
            child: canRenderChart ? _RoleplayRadarChart(points: points) : _RoleplayChartPlaceholder(),
          ),
        );
      },
    );
  }
}

class _RoleplayRadarChart extends StatelessWidget {
  const _RoleplayRadarChart({required this.points});

  final List<KeypointEntity> points;
  static const int _tickCount = 5;

  @override
  Widget build(BuildContext context) {
    final chartData = RadarChartData(
      dataSets: [
        RadarDataSet(
          dataEntries: points.map((point) => RadarEntry(value: point.point.toDouble())).toList(),
          fillGradient: LinearGradient(
            colors: [
              AppCustomColor.brandPrimary.op(0.18),
              AppCustomColor.brandPrimary.op(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: AppCustomColor.brandPrimary,
          borderWidth: 2.w,
          entryRadius: 0,
        ),
      ],
      radarShape: RadarShape.polygon,
      radarBorderData: BorderSide(color: AppCustomColor.roleplayFeedbackRadarGrid, width: 1.5),
      gridBorderData: BorderSide(color: AppCustomColor.roleplayFeedbackRadarGrid, width: 1),
      tickBorderData: BorderSide(color: AppCustomColor.roleplayFeedbackRadarGrid.op(0.4), width: 1),
      radarBackgroundColor: Colors.white.op(0.4),
      tickCount: _tickCount,
      titleTextStyle: const TextStyle(color: Colors.transparent),
      ticksTextStyle: const TextStyle(color: Colors.transparent),
      getTitle: (index, angle) => const RadarChartTitle(text: 'zz'),
      radarTouchData: RadarTouchData(enabled: true),
      titlePositionPercentageOffset: 0.2,
      borderData: FlBorderData(show: false),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dots = _buildColorDots(size);
        return Stack(
          fit: StackFit.expand,
          children: [
            RadarChart(chartData, duration: Duration.zero),
            ...dots,
          ],
        );
      },
    );
  }

  List<Widget> _buildColorDots(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(center.dx, center.dy) * 0.8;
    final List<double> values = points.map((point) => point.point.toDouble()).toList();
    final double maxValue = values.reduce(math.max);
    final double minValue = values.reduce(math.min);
    final double tickSpace = _getTickSpace(maxValue, minValue);
    final double centerValue = maxValue == minValue ? 0 : minValue - tickSpace;
    final double denominator = (maxValue - centerValue).abs() < 0.0001 ? 0.001 : maxValue - centerValue;
    final double angleStep = (2 * math.pi) / points.length;

    return List<Widget>.generate(points.length, (index) {
      final double scaledPoint = radius * ((values[index] - centerValue) / denominator);
      final double angle = angleStep * index - math.pi / 2;
      final double dx = center.dx + scaledPoint * math.cos(angle);
      final double dy = center.dy + scaledPoint * math.sin(angle);
      final Color color = AppCustomColor.gradientRoleplay[index % AppCustomColor.gradientRoleplay.length];

      return Positioned(
        left: dx - 6.w,
        top: dy - 6.w,
        child: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.w),
            boxShadow: [
              BoxShadow(
                color: color.op(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    });
  }

  double _getTickSpace(double maxValue, double minValue) {
    if ((maxValue - minValue).abs() < 0.0001) {
      return (maxValue - 0) / (_tickCount + 1);
    }
    return (maxValue - minValue) / _tickCount;
  }
}

class _RoleplayChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.borderDefault),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAsset.svg.common.info,
            width: 32.w,
            height: 32.w,
            colorFilter: ColorFilter.mode(AppCustomColor.textTertiary, BlendMode.srcIn),
          ),
          12.verticalSpace,
          AppText(
            context.text.common.emptyList,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
