part of '../../coach.dart';

/// The Coach's own palette and metrics, lifted straight off the design.
///
/// Deliberately NOT `AppCustomColor`. The rest of the app is built on that set
/// and should stay there, but the Coach is drawn on its own scale — a lilac
/// accent, a lavender-grey ground, 1.5px borders, 99px pills — and mapping it
/// onto the nearest app token repainted the whole surface a shade off. These
/// values are the drawing; a token that happens to match is a coincidence, not
/// a reason to substitute it.
abstract final class CoachStyle {
  /// The accent. `#8B8BF0` is the design's DEFAULT skin — `#554FF0` is one of
  /// four options in its colour picker, not the resting state.
  static const Color skin = Color(0xFF8B8BF0);

  /// The reader's own message bubble, and only that. The one place the deeper
  /// brand blue appears in this surface.
  static const Color userBubble = Color(0xFF554FF0);

  static const Color sheetBackground = Color(0xFFF4F3FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E5F2);
  static const Color inputBackground = Color(0xFFF1F0F8);
  static const Color chipBackground = Color(0xFFF4F3FA);
  static const Color sampleBackground = Color(0xFFEFEEF7);

  static const Color textPrimary = Color(0xFF0D121C);
  static const Color textBody = Color(0xFF3F4552);
  static const Color textChip = Color(0xFF5A6172);
  static const Color textMuted = Color(0xFF7A7F8C);

  /// Selected states — the two-column right side, the schedule chips.
  static const Color selectedBackground = Color(0xFFEFEDFD);
  static const Color selectedBorderSoft = Color(0xFFD9D4F3);
  static const Color selectedText = Color(0xFF3A2F8F);

  /// The Coach's eyes. Nearly black, never pure black.
  static const Color eye = Color(0xFF15161C);

  /// ⑧ runs on its own warm palette — the one screen in the feature that is
  /// allowed to look different from every other, because it IS different.
  static const Color safetyBackground = Color(0xFFFFF6F6);
  static const Color safetyLabel = Color(0xFFC2410C);
  static const Color safetyCardBorder = Color(0xFFFBD5D5);
  static const Color safetyStrong = Color(0xFFB91C1C);
  static const Color safetyDashed = Color(0xFFE2C9C9);

  /// The soft shadow under a message bubble and the course card.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0D121C).withValues(alpha: 0.05),
      blurRadius: 8.r,
      offset: Offset(0, 2.h),
    ),
  ];

  /// The floating bubble sits well above the page and says so.
  static List<BoxShadow> get bubbleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 28.r,
      offset: Offset(0, 12.h),
    ),
  ];

  static List<BoxShadow> get teaserShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 26.r,
      offset: Offset(0, 10.h),
    ),
  ];

  /// The small uppercase caption the design puts over every grouped control.
  static TextStyle sectionLabel({Color? color, double size = 11}) => TextStyle(
    fontSize: size.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05 * size.sp,
    color: color ?? textMuted,
  );
}

/// The two eyes that make the Coach a face rather than an icon.
///
/// A pill with two rounded bars in it, at two sizes: 8x11 on the floating
/// bubble, 5x7 in the sheet header. It is the whole of the Coach's identity in
/// this design — there is no illustration and no mascot anywhere else — so it
/// is a widget rather than an asset, and scales exactly with its container.
class CoachFace extends StatelessWidget {
  final double diameter;
  final double eyeWidth;
  final double eyeHeight;
  final double gap;
  final Color background;

  const CoachFace({
    super.key,
    required this.diameter,
    required this.eyeWidth,
    required this.eyeHeight,
    required this.gap,
    this.background = CoachStyle.skin,
  });

  /// The 60px floating bubble.
  const CoachFace.bubble({super.key, this.background = CoachStyle.skin}) : diameter = 60, eyeWidth = 8, eyeHeight = 11, gap = 7;

  /// The 34px avatar in the sheet header.
  const CoachFace.header({super.key, this.background = CoachStyle.skin}) : diameter = 34, eyeWidth = 5, eyeHeight = 7, gap = 4;

  @override
  Widget build(BuildContext context) {
    final eye = Container(
      width: eyeWidth.w,
      height: eyeHeight.h,
      decoration: BoxDecoration(
        color: CoachStyle.eye,
        borderRadius: BorderRadius.circular(99.r),
      ),
    );

    return Container(
      width: diameter.w,
      height: diameter.w,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          eye,
          SizedBox(width: gap.w),
          eye,
        ],
      ),
    );
  }
}
