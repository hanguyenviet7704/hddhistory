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
  /// Placeholder text in the input row and the form fields.
  static const Color textPlaceholder = Color(0xFF9AA0AE);
  /// Placeholder text in a DISABLED input row (under the rating toast).
  static const Color textDisabled = Color(0xFFB4B8C4);

  /// The chip steps' box — a shade lighter than the selected state.
  static const Color choiceBackground = Color(0xFFF7F6FE);
  /// The course card in the thread, and the typing dots.
  static const Color courseCardBackground = Color(0xFFEFEDFD);
  static const Color courseImageFallback = Color(0xFFE4DEF8);
  static const Color courseMeta = Color(0xFF7C8AA4);
  static const Color courseAuthor = Color(0xFF3A4250);
  static const Color typingDot = Color(0xFFB4A9EE);

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

  /// The rating toast, lifting off the input area.
  static List<BoxShadow> get toastShadow => [
    BoxShadow(
      color: const Color(0xFF0D121C).withValues(alpha: 0.16),
      blurRadius: 24.r,
      offset: Offset(0, 8.h),
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
