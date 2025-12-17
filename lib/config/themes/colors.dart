part of 'themes.dart';

mixin AppCustomColor {
  static const List<Color> background = [Color(0xFFFF15F0), Color(0xFFF95C70), Color(0xFFF58822), Color(0xFFD02027)];

  static const List<Color> gradientButton = [Color(0xFFE86423), Color(0xFFF38421), Color(0xFFF7704B), Color(0xFFF86959), Color(0xFFFA4A92)];

  static const List<Color> gradientBackground = [Color(0xFFE35524), Color(0xFFF58921), Color(0xFFF86463), Color(0xFFFF15F0)];

  static const List<Color> gradientAvatarBorder = [Color(0xFFD02027), Color(0xFFF58822), Color(0xFFF95C70), Color(0xFFFF15F0)];

  static const List<Color> gradientRoleplay = [
    Color(0xFFE3E7EF),
    Color(0xFFFFA9A8),
    Color(0xFFF8A1DC),
    Color(0xFFE6A5F2),
    Color(0xFFBEB8FA),
    Color(0xFF93CEF8),
    Color(0xFF79E2D7),
    Color(0xFF98DC98),
    Color(0xFFECB984),
  ];

  static const Color scrimOverlay = Color(0x99364152);

  // New colors from Figma design
  static const Color neutral01 = Color(0xFF1A202C);
  static const Color textPrimary = Color(0xFF0D121C);
  static const Color textSecondary = Color(0xFF364152);
  static const Color textTertiary = Color(0xFF7F8EA4);
  static const Color textQuaternary = Color(0xFFAAB8CD);
  static const Color textBrand = Color(0xFF110751);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F7FB);
  static const Color backgroundError = Color(0xFFFDEAE7);
  static const Color backgroundSuccess = Color(0xFFEAFFEF);
  static const Color borderDefault = Color(0xFFEBF0F7);
  static const Color borderSecondary = Color(0xFFE3E8EF);
  static const Color greyC1 = Color(0xFFC1C5CD);
  static const Color brandPrimary = Color(0xFF554FF0);
  static const Color brandPrimary50 = Color(0xFFEBEAFD);
  static const Color brandPrimary100 = Color(0xFFD6CAFD);
  static const Color brandPrimary200 = Color(0xFFC7C5FA);
  static const Color brandPrimary300 = Color(0xFF917FF6);
  static const Color brandPrimary900 = Color(0xFF151123);
  static const Color backgroundBrand = Color(0xFFEBEAFD);
  static const Color paywallAqua = Color(0xFF6BBBD8);
  static const Color paywallBestDeal = Color(0xFFF9D31A);
  static const Color iconPrimary = Color(0xFF344054);
  static const Color contentTertiary = Color(0xFFF1EDE5);
  static const Color surfaceMuted = Color(0xFFEFF3FA);

  // Strength indicator colors
  static const Color successGreen = Color(0xFF41AE8C);
  static const Color errorRed = Color(0xFFE34646);
  static const Color darkStroke = Color(0xFF110751);
  static const Color buttonDisable = Color(0xFFE3E8EF);
  static const Color roleplayIntroBackground = Color(0xFF70401F);
  static const Color roleplayLeftBubble = Color(0xFFABD3F3);
  static const Color roleplayRightBubble = Color(0xFFF1EDE5);
  static const Color roleplayHintBorder = Color(0xFFE3E8EF);
  static const Color roleplayLeadingSurface = Color(0x99123F54);
  static const Color roleplayFeedbackRadarGrid = Color(0xFFE1E6F5);
  static const Color bottomSheetScrim = Color(0x80151123);
  static const Color borderBrand = Color(0xFFC7C5FA);
  static const Color roleplayIntroDotInactive = Color(0xFFF2F1FE);
}

mixin AppTheme {
  static final ThemeData _theme = AppConfig.instance.context!.watch<ThemeCubit>().state.themeMaterial;

  //* Color scheme
  static Color primaryColor = _theme.colorScheme.primary;
  static Color onPrimary = _theme.colorScheme.onPrimary;
  static Color primaryContainer = _theme.colorScheme.primaryContainer;
  static Color onPrimaryContainer = _theme.colorScheme.onPrimaryContainer;
  static Color secondaryColor = _theme.colorScheme.secondary;
  static Color onSecondary = _theme.colorScheme.onSecondary;
  static Color secondaryContainer = _theme.colorScheme.secondaryContainer;
  static Color onSecondaryContainer = _theme.colorScheme.onSecondaryContainer;
  static Color tertiaryColor = _theme.colorScheme.tertiary;
  static Color onTertiary = _theme.colorScheme.onTertiary;
  static Color tertiaryContainer = _theme.colorScheme.tertiaryContainer;
  static Color onTertiaryContainer = _theme.colorScheme.onTertiaryContainer;
  static Color error = _theme.colorScheme.error;
  static Color onError = _theme.colorScheme.onError;
  static Color surface = _theme.colorScheme.surface;
  static Color onSurface = _theme.colorScheme.onSurface;
  static Color surfaceContainerHighest = _theme.colorScheme.surfaceContainerHighest;
  static Color onSurfaceVariant = _theme.colorScheme.onSurfaceVariant;
  static Color surfaceTint = _theme.colorScheme.surfaceTint;
  static Color inverseSurface = _theme.colorScheme.inverseSurface;
  static Color onInverseSurface = _theme.colorScheme.onInverseSurface;
  static Color scaffoldBackgroundColor = _theme.scaffoldBackgroundColor;
  static Color outline = _theme.colorScheme.outline;
  static Color outlineVariant = _theme.colorScheme.outlineVariant;
  static Color shadow = _theme.colorScheme.shadow;
  static Color scrim = _theme.colorScheme.scrim;

  //* Text theme
  static TextTheme textTheme = _theme.textTheme;
}
