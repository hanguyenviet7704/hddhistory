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
  static const Color neutral100 = Color(0xFFEEF2F6);
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
  static const Color backgroundBrandSoft = Color(0xFFF2F1FE);
  static const Color borderDefault = Color(0xFFEBF0F7);
  static const Color borderSecondary = Color(0xFFE3E8EF);
  static const Color greyC1 = Color(0xFFC1C5CD);
  static const Color brandPrimary = Color(0xFF554FF0);
  static const Color brandPrimary50 = Color(0xFFEBEAFD);
  static const Color brandPrimary100 = Color(0xFFD6CAFD);
  static const Color brandPrimary200 = Color(0xFFC7C5FA);
  static const Color brandPrimary300 = Color(0xFF917FF6);
  static const Color brandPrimary700 = Color(0xFF362F82);
  static const Color brandPrimary900 = Color(0xFF151123);
  static const Color backgroundBrand = Color(0xFFEBEAFD);
  static const Color paywallAqua = Color(0xFF6BBBD8);
  static const Color paywallBestDeal = Color(0xFFF9D31A);
  // Promo-code block on the paywall. Values come straight from the design
  // (Claude Design "MeUp App" → pin `paywall`); see
  // plans/260727-paywall-redesign/design-spec.md.
  static const Color paywallPromoLink = Color(0xFF6E67D8);
  static const Color paywallPromoLabel = Color(0xFF4B44CA);
  static const Color paywallPromoMuted = Color(0xFF9E99C2);
  static const Color paywallPromoAppliedBg = Color(0xFFE6F4EE);
  static const Color paywallPromoAppliedText = Color(0xFF2B604E);
  static const Color paywallPromoRemove = Color(0xFF6E6A85);
  // Paywall bottom bar, same design source as the promo block above. The CTA
  // gradient ends on `brandPrimary` (#554FF0) and the countdown digit boxes use
  // #4B44CA == `paywallPromoLabel`, so neither gets a duplicate token.
  static const Color paywallCtaGradientStart = Color(0xFF6C63FF);
  static const Color paywallCtaCaption = Color(0xFF9A96AE);
  static const Color paywallCtaCaptionStrong = Color(0xFF3A3355);
  static const Color paywallSaleStripStart = Color(0xFF7B71EC);
  static const Color paywallSaleStripEnd = Color(0xFF655CE6);
  static const Color paywallSaleStripMuted = Color(0xFFD8D5F7);
  static const Color iconPrimary = Color(0xFF344054);
  static const Color contentTertiary = Color(0xFFF1EDE5);
  static const Color surfaceMuted = Color(0xFFEFF3FA);
  static const Color neutral300 = Color(0xFFCDD5DF);
  static const Color roleplayAnswerBackground = Color(0xFFDFEEFB);
  static const Color roleplayExplanationBackground = Color(0x29000000);

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
  static const Color streakActive = Color(0xFF4B44CA);
  static const Color streakTextMuted = Color(0xFF5F6F86);
  static const Color roleplayIntroDotInactive = Color(0xFFF2F1FE);
  // Design `6 · Profile`: the pencil disc beside the name on the identity header.
  static const Color profileEditPencilBg = Color(0xFFE8E7FA);
  static const Color feedbackGradientMid = Color(0xFF7667F3);
  static const Color feedbackGradientEnd = Color(0xFF5E5ACB);
  static const Color feedbackStarActive = Color(0xFFF7C52B);
  static const Color feedbackStarInactive = Color(0xFFE3E8EF);
  static const Color feedbackThankYouOverlay = Color(0xB3FFFFFF);
  static const Color feedbackThankYouTint = Color(0xB3E5DEFC);

  // Community (design `13 · Community`). Only the two values with no near
  // equivalent in the palette: the design's #554FF0 is `brandPrimary`, #4B44CA
  // is `streakActive`, #0D121C is `textPrimary`, #5F6F86 is `streakTextMuted`,
  // and its #F6F6FB page ground is `backgroundGray` — reused rather than
  // duplicated a shade apart.
  static const Color communityMuted = Color(0xFF9AA4B2);
  // Heading colour on a topic page's header block.
  static const Color communityTopicHeading = Color(0xFF211B40);
  // Edge of the weekly-question card. Lighter than `borderBrand` (#C7C5FA),
  // which reads as a selected state next to this card's tinted fill.
  static const Color communityWeeklyBorder = Color(0xFFDAD7F7);

  // Onboarding (P3 redesign) — exact Figma hex values that don't already
  // match an existing token. Where a design value coincided with an existing
  // token (e.g. brand `#554FF0` == brandPrimary, border `#E3E8EF` ==
  // borderSecondary) the onboarding feature reuses that token instead of
  // duplicating it here.
  static const Color onboardingSplashBackground = Color(0xFFF2F1FA);
  // Warm peach behind the Welcome screen's card deck (design screen 2).
  static const Color onboardingWelcomeBackground = Color(0xFFF8EBE3);
  static const Color onboardingGradientStart = Color(0xFF5B4FE8);
  static const Color onboardingGradientEnd = Color(0xFFC56B6B);
  static const Color ctaDisabledBackground = Color(0xFFD7D5E8);
  static const Color ctaDisabledText = Color(0xFF9A97B5);
  static const Color textMuted = Color(0xFF9AA4B2);
  static const Color inputFill = Color(0xFFF0F3F9);

  // Keypoint v2 — the swipeable theory + exercise card deck. Exact values from
  // Claude Design "MeUp" → `Keypoint v2.dc.html` / `Keypoint Swipe Lab`. Where a
  // design value already had a token it is reused instead of duplicated here:
  // brand `#554FF0` == brandPrimary, empty gap-slot dash `#C7C5FA` ==
  // brandPrimary200, gap-slot label `#4B44CA` == streakActive, muted caption
  // `#9AA4B2` == textMuted, heading `#0D121C` == textPrimary, arrange badges
  // `#41AE8C`/`#E34646` == successGreen/errorRed.
  // Week recap ("Hành trình tuần qua") — the scrapbook poster and the chrome
  // around it. Source: Claude Design "MeUp App" -> pins `week-wrap`,
  // `wrap-list`, `week-wrap-monday`, `week-wrap-locked`; see
  // meup-api/plans/260820-week-recap/README.md.
  //
  // The poster inks are LOCKED TO THE ARTWORK, not to the app theme: the
  // poster is a printed page on cream paper and looks the same in dark mode,
  // so these must not follow a theme swap. Feature-neutral tokens are reused
  // where the design matched one (`textPrimary` #0D121C, `textMuted` #9AA4B2,
  // `brandPrimary` #554FF0). Three values coincide with tokens named for other
  // features (#7C8AA4 practiceModeSubtext, #EEF1F6 kpMissedSurface) — those get
  // their own names here rather than borrowing an unrelated feature's.
  // Share-row brand fills, shared by the course-share sheet and the week-recap
  // poster (see ShareTargetButton). The icon ink and the label ink reuse
  // existing tokens whose values already match — #2B3242 == kpOptionLabel,
  // #3A4250 == kpOptionText — rather than adding a third name for each.
  static const Color shareInstagramStart = Color(0xFF8A3AB9);
  static const Color shareInstagramMid = Color(0xFFE95950);
  static const Color shareInstagramEnd = Color(0xFFFCAF45);
  static const Color shareFacebookBlue = Color(0xFF1877F2);
  /// rgba(20,20,60,.08) — lifts a white disc off a white sheet.
  static const Color shareTargetShadow = Color(0x1414143C);
  static const Color weekRecapCourseLabel = Color(0xFF2E4A6B);
  static const Color weekRecapFavouriteLabel = Color(0xFFC0392B);
  static const Color weekRecapLessonInk = Color(0xFF3A3020);
  static const Color weekRecapBodyInk = Color(0xFF4A4033);
  static const Color weekRecapDarkInk = Color(0xFF2A2A2A);
  static const Color weekRecapFaintInk = Color(0xFF8A7B5E);
  static const Color weekRecapQuoteInk = Color(0xFF390909);
  static const Color weekRecapTitleInk = Color(0xFF172D58);
  static const Color weekRecapTitleHalo = Color(0xFFEBE9E7);
  static const Color weekRecapLabelRed = Color(0xFFA32A2A);
  static const Color weekRecapCalendarMuted = Color(0xFF6B6B6B);
  static const Color weekRecapStatStreak = Color(0xFF6E6151);
  static const Color weekRecapStatHabits = Color(0xFFB8935A);
  static const Color weekRecapStatLessons = Color(0xFF9E2B2B);
  static const Color weekRecapStatMinutes = Color(0xFFE0A81E);
  static const Color weekRecapMoodGood = Color(0xFFCFE9D8);
  static const Color weekRecapMoodOk = Color(0xFFFCE3B6);
  static const Color weekRecapMoodLow = Color(0xFFF7CDD7);
  static const Color weekRecapMoodInk = Color(0xFF5E6152);
  // Stands in behind the poster while its artwork decodes, so the page opens on
  // paper rather than on a white flash.
  static const Color weekRecapPaper = Color(0xFFF1E7D6);
  static const Color weekRecapBannerStart = Color(0xFF5B4BE0);
  static const Color weekRecapBannerMid = Color(0xFF8B6BF0);
  static const Color weekRecapBannerEnd = Color(0xFFC58BEA);
  static const Color weekRecapPillInk = Color(0xFF4B3EDB);
  static const Color weekRecapPopupBody = Color(0xFF7C8AA4);
  static const Color weekRecapMutedAction = Color(0xFF8A93A6);
  static const Color weekRecapRowBorder = Color(0xFFEEF1F6);
  static const Color weekRecapRowSubtitle = Color(0xFF8891A3);
  static const Color weekRecapTileBorder = Color(0xFFEDF0F5);

  static const Color kpBodyText = Color(0xFF3D3D46);
  // Answer-option chrome, straight from `_Keypoint Swipe Lab` (the design file
  // that owns BOTH practice decks and the reading deck's exercise cards). The
  // resting border used to be #EEF1F6 — the same near-white as the card it sits
  // on, so an untouched option read as a flat block of text rather than as
  // something you tap.
  static const Color kpOptionBorder = Color(0xFFD5DBE6);
  // Body ink shared by the verdict's explanation and the arrange/gap rows.
  static const Color kpOptionText = Color(0xFF3A4250);
  // The choice option's own label sits a shade darker than that body ink — the
  // design separates the two, and reusing one token for both is how the
  // explanation nearly got dragged along with this fix.
  static const Color kpOptionLabel = Color(0xFF2B3242);
  // Picked, before grading: a lilac wash + darker ink. The card carried the
  // brand border alone, which at 2px is easy to miss on a small option.
  static const Color kpOptionSelectedSurface = Color(0xFFF3F2FE);
  static const Color kpOptionSelectedText = Color(0xFF2B2A6B);
  static const Color kpCorrectSurface = Color(0xFFEAF9F1);
  static const Color kpCorrectBorder = Color(0xFF35B37E);
  static const Color kpCorrectText = Color(0xFF1F8A5B);
  static const Color kpWrongSurface = Color(0xFFFDECEA);
  static const Color kpWrongBorder = Color(0xFFF0564B);
  static const Color kpWrongText = Color(0xFFE0483C);
  static const Color kpResultCorrectSurface = Color(0xFFE7F7EE);
  static const Color kpMissedSurface = Color(0xFFEEF1F6);
  static const Color kpMissedBorder = Color(0xFF2E3648);
  static const Color kpMissedBadge = Color(0xFF8B96AB);
  static const Color kpDimText = Color(0xFFA6AFBE);
  static const Color kpDimBorder = Color(0xFFE4E8EF);
  static const Color kpCheckDisabled = Color(0xFFC3C0F2);
  static const Color kpArrangeText = Color(0xFF2B3242);
  static const Color kpArrangeHandle = Color(0xFFC3C9D6);
  static const Color kpArrangeHandleCorrect = Color(0xFF8BD3B0);
  static const Color kpArrangeHandleWrong = Color(0xFFF3A69E);
  // Per-exercise-type accents: the design tints each card's instruction line
  // violet (single choice, text gap) or green (multiple choice, arrange), and
  // reuses the violet for a filled gap's dashed outline.
  static const Color kpAccentViolet = Color(0xFF8A82E8);
  static const Color kpAccentGreen = Color(0xFF3AA07E);
  static const Color kpGapFilledSurface = Color(0xFFEDEAFE);
  static const Color kpChipPlaceholder = Color(0xFFF1F3F8);
  static const Color kpCorrectAnswerSurface = Color(0xFFF3F5F9);

  // Habit tracker state pill — design "5 · Habit" → Habit tab. Two states:
  // checked in today (green) and still waiting (amber). The green reuses the
  // keypoint result tokens (`kpCorrectSurface` / `kpCorrectText` /
  // `kpCorrectBorder`); the palette had no amber surface/text/dot trio, so it
  // gets one here. The design's own hex for this pill sits past the 256 KiB read
  // cap on the design file — these are picked from its warm accent family and
  // should be replaced if the exact values turn up.
  static const Color habitStateTodoSurface = Color(0xFFFFF3E2);
  static const Color habitStateTodoText = Color(0xFFB2711A);
  static const Color habitStateTodoDot = Color(0xFFE9A23B);

  // Keypoint peek card — the deck's terminal quote card (design
  // `_Keypoint Swipe Lab` → `c.isPeek`). Exact design hex.
  static const Color kpPeekQuoteMark = Color(0xFFF0EEFC);
  static const Color kpPeekDivider = Color(0xFFCFCBF2);
  static const Color kpPeekSource = Color(0xFF5F6F86);
  static const Color kpPeekHint = Color(0xFF7C74B0);

  // Back face of the recap flip card (design `_MeUp App` → RECAP). Exact hex.
  static const Color kpRecapBackSurface = Color(0xFF211B40);

  // Practice hub mode tiles (design "3 · Learning" → Practice — pick a mode).
  // Quiz reuses brandPrimary50; the roleplay/video tints sit in the truncated
  // tail of the design file, so these are picked from its screenshot family and
  // should be replaced if the exact values turn up.
  static const Color practiceRoleplayTint = Color(0xFFFDEBF2);
  static const Color practiceRoleplayIcon = Color(0xFFD96BA0);
  static const Color practiceComingSoonChip = Color(0xFFEEF1F6);
  static const Color practiceModeSubtext = Color(0xFF7C8AA4);
  static const Color practiceChevron = Color(0xFFB4BDCB);
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
