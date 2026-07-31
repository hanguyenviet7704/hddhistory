part of '../../../onboard_v2.dart';

class _OnboardV2CarouselCard extends StatelessWidget {
  const _OnboardV2CarouselCard({
    required this.asset,
    required this.values,
  });

  final String asset;
  final _OnboardV2CarouselSlotValues values;

  @override
  Widget build(BuildContext context) {
    final opacity = values.opacity.clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(values.x.w, 0),
      child: Transform.rotate(
        angle: values.rotation,
        child: Transform.scale(
          scale: values.scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 148.w,
              height: 180.h,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Color.lerp(
                    AppCustomColor.borderDefault,
                    AppCustomColor.brandPrimary.withValues(alpha: 0.12),
                    values.emphasis,
                  )!,
                ),
                boxShadow: values.shadows,
              ),
              // [asset] is a config-driven source: a network url (admin-uploaded
              // deck image) or a bundled asset path (mapper fallback). DCachedImage
              // handles both (http → CachedNetworkImage, else → Image.asset).
              child: DCachedImage(url: asset, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardV2CarouselSlotValues {
  const _OnboardV2CarouselSlotValues({
    required this.x,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.z,
    required this.emphasis,
  });

  static final farLeft = _OnboardV2CarouselSlotValues(
    x: -180,
    scale: 0.64,
    rotation: _degToRad(-16),
    opacity: 0,
    z: 0,
    emphasis: 0,
  );
  static final left = _OnboardV2CarouselSlotValues(
    x: -84,
    scale: 0.82,
    rotation: _degToRad(-9),
    opacity: 1,
    z: 1,
    emphasis: 0,
  );
  static final center = _OnboardV2CarouselSlotValues(
    x: 0,
    scale: 1,
    rotation: 0,
    opacity: 1,
    z: 3,
    emphasis: 1,
  );
  static final right = _OnboardV2CarouselSlotValues(
    x: 84,
    scale: 0.82,
    rotation: _degToRad(9),
    opacity: 1,
    z: 1,
    emphasis: 0,
  );
  static final farRight = _OnboardV2CarouselSlotValues(
    x: 180,
    scale: 0.64,
    rotation: _degToRad(16),
    opacity: 0,
    z: 0,
    emphasis: 0,
  );

  final double x;
  final double scale;
  final double rotation;
  final double opacity;
  final double z;
  final double emphasis;

  List<BoxShadow> get shadows {
    final t = emphasis.clamp(0.0, 1.0);
    return [
      BoxShadow(
        color: Color.lerp(const Color(0x33211B40), const Color(0x47211B40), t)!,
        blurRadius: ui.lerpDouble(18, 40, t)!.r,
        spreadRadius: ui.lerpDouble(-8, -12, t)!.r,
        offset: Offset(0, ui.lerpDouble(6, 18, t)!.h),
      ),
      BoxShadow(
        color: Color.lerp(Colors.transparent, const Color(0x14211B40), t)!,
        blurRadius: 0,
        offset: Offset(0, ui.lerpDouble(0, 4, t)!.h),
      ),
    ];
  }

  static _OnboardV2CarouselSlotValues lerp(
    _OnboardV2CarouselSlotValues from,
    _OnboardV2CarouselSlotValues to,
    double t,
  ) {
    return _OnboardV2CarouselSlotValues(
      x: ui.lerpDouble(from.x, to.x, t)!,
      scale: ui.lerpDouble(from.scale, to.scale, t)!,
      rotation: ui.lerpDouble(from.rotation, to.rotation, t)!,
      opacity: ui.lerpDouble(from.opacity, to.opacity, t)!,
      z: ui.lerpDouble(from.z, to.z, t)!,
      emphasis: ui.lerpDouble(from.emphasis, to.emphasis, t)!,
    );
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;
}
