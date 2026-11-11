part of 'themes.dart';

mixin AppCustomColor {
  static const List<Color> background = [Color(0xFFBB8600), Color(0xFFF95C70), Color(0xFFF58822), Color(0xFFD02027)];

  static const List<Color> gradientButton = [Color(0xFFE86423), Color(0xFFF38421), Color(0xFFF7704B), Color(0xFFF86959), Color(0xFFFA4A92)];

  static const List<Color> gradientBackground = [Color(0xFFE35524), Color(0xFFF58921), Color(0xFFF86463), Color(0xFFBB8600)];

  static const List<Color> gradientAvatarBorder = [Color(0xFFD02027), Color(0xFFF58822), Color(0xFFF95C70), Color(0xFFBB8600)];

  static const List<Color> gradientRoleplay = [
    Color(0xFFE3E7EF),
    Color(0xFFFFA9A8),
    Color(0xFFF8A1DC),
    Color(0xFFF2DBA3),
    Color(0xFFFAE7B8),
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
  static const Color textBrand = Color(0xFF3D2C04);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F7FB);
  static const Color backgroundError = Color(0xFFFDEAE7);
  static const Color backgroundSuccess = Color(0xFFEAFFEF);
  static const Color backgroundBrandSoft = Color(0xFFFDF8EC);
  static const Color borderDefault = Color(0xFFEBF0F7);
  static const Color borderSecondary = Color(0xFFE3E8EF);
  static const Color greyC1 = Color(0xFFC1C5CD);
  // Thang màu thương hiệu: hổ phách (#B8860B). Trước đây là tím (#554FF0) —
  // toàn bộ app tham chiếu qua các hằng số dưới đây nên đổi màu chủ đạo chỉ
  // cần sửa ở chỗ này. `brandPrimary` được dùng làm nền cho chữ trắng ở nút
  // bấm, nên sắc độ này được chọn đủ đậm để giữ tương phản chữ trắng đạt
  // chuẩn (~4.6:1); không thay bằng vàng sáng hơn nếu chưa đổi màu chữ nút.
  static const Color brandPrimary = Color(0xFFB8860B);
  static const Color brandPrimary50 = Color(0xFFFBF3E0);
  static const Color brandPrimary100 = Color(0xFFF5E4B8);
  static const Color brandPrimary200 = Color(0xFFEBD08A);
  static const Color brandPrimary300 = Color(0xFFDCB84A);
  static const Color brandPrimary700 = Color(0xFF7A5807);
  static const Color brandPrimary900 = Color(0xFF3D2C04);
  static const Color backgroundBrand = Color(0xFFFBF3E0);
  static const Color paywallAqua = Color(0xFF6BBBD8);
  static const Color paywallBestDeal = Color(0xFFF9D31A);
  // Promo-code block on the paywall. Values come straight from the design
  // (Claude Design "HDDhistory App" → pin `paywall`); see
  // plans/260727-paywall-redesign/design-spec.md.
  static const Color paywallPromoLink = Color(0xFFA57A0C);
  static const Color paywallPromoLabel = Color(0xFF96690A);
  static const Color paywallPromoMuted = Color(0xFFC4AE7A);
  static const Color paywallPromoAppliedBg = Color(0xFFE6F4EE);
  static const Color paywallPromoAppliedText = Color(0xFF2B604E);
  static const Color paywallPromoRemove = Color(0xFF857A63);
  // Paywall bottom bar, same design source as the promo block above. The CTA
  // gradient ends on `brandPrimary` (#B8860B) and the countdown digit boxes use
  // #96690A == `paywallPromoLabel`, so neither gets a duplicate token.
  static const Color paywallCtaGradientStart = Color(0xFFD9A520);
  static const Color paywallCtaCaption = Color(0xFFA89A78);
  static const Color paywallCtaCaptionStrong = Color(0xFF55442A);
  static const Color paywallSaleStripStart = Color(0xFFC99A18);
  static const Color paywallSaleStripEnd = Color(0xFFA87F0D);
  static const Color paywallSaleStripMuted = Color(0xFFF0E2BC);
  static const Color iconPrimary = Color(0xFF344054);
  static const Color contentTertiary = Color(0xFFF1EDE5);
  static const Color surfaceMuted = Color(0xFFEFF3FA);
  static const Color neutral300 = Color(0xFFCDD5DF);
  static const Color roleplayAnswerBackground = Color(0xFFDFEEFB);
  static const Color roleplayExplanationBackground = Color(0x29000000);

  // Strength indicator colors
  static const Color successGreen = Color(0xFF41AE8C);
  static const Color errorRed = Color(0xFFE34646);
  static const Color darkStroke = Color(0xFF3D2C04);
  static const Color buttonDisable = Color(0xFFE3E8EF);
  static const Color roleplayIntroBackground = Color(0xFF70401F);
  static const Color roleplayLeftBubble = Color(0xFFABD3F3);
  static const Color roleplayRightBubble = Color(0xFFF1EDE5);
  static const Color roleplayHintBorder = Color(0xFFE3E8EF);
  static const Color roleplayLeadingSurface = Color(0x99123F54);
  static const Color roleplayFeedbackRadarGrid = Color(0xFFE1E6F5);
  static const Color bottomSheetScrim = Color(0x803D2C04);
  static const Color borderBrand = Color(0xFFEBD08A);
  static const Color streakActive = Color(0xFF96690A);
  static const Color streakTextMuted = Color(0xFF5F6F86);
  static const Color roleplayIntroDotInactive = Color(0xFFFDF8EC);
  // Design `6 · Profile`: the pencil disc beside the name on the identity header.
  static const Color profileEditPencilBg = Color(0xFFF7EBCF);

  // Onboarding v3 (Claude Design "HDDhistory Onboarding v2", màn S7–S10). Chỉ những
  // giá trị KHÔNG trùng token sẵn có mới nằm ở đây: chữ phụ dùng
  // `streakTextMuted` (#5F6F86) và nhấn mạnh dùng `brandPrimary` (#B8860B).
  /// Nền thẻ 4 bước ở S7.
  static const Color onboardStepCardBg = Color(0xFFF7F8FC);

  /// Nhãn nhỏ + chữ phụ nhạt (eyebrow, phụ đề, giờ chưa chọn).
  static const Color onboardMutedLabel = Color(0xFF9AA4B2);

  /// Khung điện thoại giả bọc bánh xe giờ ở S8.
  static const Color onboardPhoneFrame = Color(0xFFE7EBF2);

  /// Số giờ/phút liền kề (chưa chọn) trong bánh xe S8.
  static const Color onboardWheelIdle = Color(0xFFC7CDD8);

  /// Vòng tròn chờ và dấu tích đã xong ở S9.
  static const Color onboardCheckIdleRing = Color(0xFFC9CEDE);
  static const Color onboardCheckDone = Color(0xFF16A97A);

  /// Thẻ khoá học ở S10 và chấm chỉ vị trí.
  static const Color onboardResultCardBg = Color(0xFFFDF8EC);
  static const Color onboardResultCardBorder = Color(0xFFEFDFB4);
  static const Color onboardResultCardDesc = Color(0xFF6B7280);
  static const Color onboardDotIdle = Color(0xFFD7DBE6);
  static const Color feedbackGradientMid = Color(0xFFD2A11B);
  static const Color feedbackGradientEnd = Color(0xFFA87F0D);
  static const Color feedbackStarActive = Color(0xFFF7C52B);
  static const Color feedbackStarInactive = Color(0xFFE3E8EF);
  static const Color feedbackThankYouOverlay = Color(0xB3FFFFFF);
  static const Color feedbackThankYouTint = Color(0xB3F5E7C6);

  // Community (design `13 · Community`). Only the two values with no near
  // equivalent in the palette: the design's #B8860B is `brandPrimary`, #96690A
  // is `streakActive`, #0D121C is `textPrimary`, #5F6F86 is `streakTextMuted`,
  // and its #F6F6FB page ground is `backgroundGray` — reused rather than
  // duplicated a shade apart.
  static const Color communityMuted = Color(0xFF9AA4B2);
  // Author name above a post's body and on a feed card (design `S-01`/`S-04`).
  // Deliberately NOT `textPrimary`: the headline right above it is #0D121C, and
  // the name has to sit one step under the headline without going muted.
  static const Color communityAuthorName = Color(0xFF3A4250);
  // Comment and reply body ink in a thread (design `S-04`). Darker than the
  // post's own body (#5F6F86 `streakTextMuted`) on purpose — on a screen where
  // the post above has already gone grey, an answer is the newer voice.
  static const Color communityCommentInk = Color(0xFF2C3444);
  // The "N đang online" dot in a chat room's header (design `S-03`). Same value
  // as `communityRoomInks[1]`, named separately because one is a room's tint by
  // position and this one means "there are people in here right now".
  static const Color communityRoomInkGreen = Color(0xFF2F9E6B);
  // The group chat's brand tile and its FAB (design `S-03`) — the amber the
  // gradient runs between. Its own pair rather than `brandPrimary`: the tile is
  // the app mark's ground, not a button.
  static const Color communityChatMarkStart = Color(0xFFD9A520);
  static const Color communityChatMarkEnd = Color(0xFF96690A);
  // The unread badge on the FAB, and the filled heart on a reaction chip.
  static const Color communityChatBadge = Color(0xFFF2545B);
  // Border of a reaction chip under a chat bubble.
  static const Color communityChatChipBorder = Color(0xFFEDEEF4);
  // Placeholder ink on the composer (design `S-06`) — the title hint, the body
  // hint, the room-menu section label. Lighter than `communityMuted`
  // (#9AA4B2), which is real if quiet content: this ink is text not there yet.
  static const Color communityPlaceholder = Color(0xFFB4BCC9);
  // Border and fill of an ATTACHED item inside a post — the course card and the
  // saved-card tile (design `S-01`/`S-04`). Its own pair rather than
  // `borderDefault`/`backgroundGray`: the attachment has to read as a quoted
  // object sitting inside the post, one step apart from the post's own ground.
  static const Color communityAttachBorder = Color(0xFFEAEBF2);
  static const Color communityAttachSurface = Color(0xFFFDFCFA);
  // The hairline under a post and the connector rail down its thread (design
  // `S-04`). A shade warmer than `borderSecondary` (#E3E8EF), the app's general
  // divider: this one belongs to the thread.
  static const Color communityRule = Color(0xFFE7E8F0);
  // Heading colour on a topic page's header block.
  static const Color communityTopicHeading = Color(0xFF40361B);
  // Edge of the weekly-question card. Lighter than `borderBrand` (#EBD08A),
  // which reads as a selected state next to this card's tinted fill.
  static const Color communityWeeklyBorder = Color(0xFFF2E3BC);
  // The room chip above a post's title. A tint of its own rather than
  // `brandPrimary50` (#FBF3E0): the chip sits on a translucent card over the
  // study background, and the darker fill loses its edge there.
  static const Color communityChipBackground = Color(0xFFFDF6E6);
  static const Color communityChipInk = Color(0xFFA57A0C);
  // The kind badge on a notification avatar. Like and moderation reuse
  // `errorRed`; a comment gets its own violet so the three read apart.
  static const Color communityBadgeComment = Color(0xFF91752F);
  // The dark quote card an attached keypoint renders as — the same ink as
  // `communityTopicHeading`, named separately because one is a background and
  // the other is text.
  static const Color communityInsightCard = Color(0xFF40361B);
  // Room tile tints in the "Khám phá phòng" grid, cycled by position so a room
  // keeps its colour between visits.
  static const List<Color> communityRoomTints = [
    Color(0xFFFBF7ED),
    Color(0xFFE4F1EA),
    Color(0xFFFBE9E4),
    Color(0xFFFBE4EC),
    Color(0xFFE6EEFB),
    Color(0xFFFBF6EA),
    Color(0xFFFCF2DE),
  ];
  static const List<Color> communityRoomInks = [
    Color(0xFFB8860B),
    Color(0xFF2F9E6B),
    Color(0xFFD2683F),
    Color(0xFFC4477A),
    Color(0xFF3B6FD4),
    Color(0xFF91752F),
    Color(0xFFB98418),
  ];

  // Onboarding (P3 redesign) — exact Figma hex values that don't already
  // match an existing token. Where a design value coincided with an existing
  // token (e.g. brand `#B8860B` == brandPrimary, border `#E3E8EF` ==
  // borderSecondary) the onboarding feature reuses that token instead of
  // duplicating it here.
  static const Color onboardingSplashBackground = Color(0xFFFDF8EC);
  // Warm peach behind the Welcome screen's card deck (design screen 2).
  static const Color onboardingWelcomeBackground = Color(0xFFF8EBE3);
  static const Color onboardingGradientStart = Color(0xFFC99A18);
  static const Color onboardingGradientEnd = Color(0xFFC56B6B);
  static const Color ctaDisabledBackground = Color(0xFFE3DED0);
  static const Color ctaDisabledText = Color(0xFFA39B85);
  static const Color textMuted = Color(0xFF9AA4B2);
  static const Color inputFill = Color(0xFFF0F3F9);

  // Keypoint v2 — the swipeable theory + exercise card deck. Exact values from
  // Claude Design "HDDhistory" → `Keypoint v2.dc.html` / `Keypoint Swipe Lab`. Where a
  // design value already had a token it is reused instead of duplicated here:
  // brand `#B8860B` == brandPrimary, empty gap-slot dash `#EBD08A` ==
  // brandPrimary200, gap-slot label `#96690A` == streakActive, muted caption
  // `#9AA4B2` == textMuted, heading `#0D121C` == textPrimary, arrange badges
  // `#41AE8C`/`#E34646` == successGreen/errorRed.
  // Week recap ("Hành trình tuần qua") — the scrapbook poster and the chrome
  // around it. Source: Claude Design "HDDhistory App" -> pins `week-wrap`,
  // `wrap-list`, `week-wrap-monday`, `week-wrap-locked`; see
  // hddhistory-api/plans/260820-week-recap/README.md.
  //
  // The poster inks are LOCKED TO THE ARTWORK, not to the app theme: the
  // poster is a printed page on cream paper and looks the same in dark mode,
  // so these must not follow a theme swap. Feature-neutral tokens are reused
  // where the design matched one (`textPrimary` #0D121C, `textMuted` #9AA4B2,
  // `brandPrimary` #B8860B). Three values coincide with tokens named for other
  // features (#7C8AA4 practiceModeSubtext, #EEF1F6 kpMissedSurface) — those get
  // their own names here rather than borrowing an unrelated feature's.
  // Share-row brand fills, shared by the course-share sheet and the week-recap
  // poster (see ShareTargetButton). The icon ink and the label ink reuse
  // existing tokens whose values already match — #2B3242 == kpOptionLabel,
  // #3A4250 == kpOptionText — rather than adding a third name for each.
  static const Color shareInstagramStart = Color(0xFFA38333);
  static const Color shareInstagramMid = Color(0xFFE95950);
  static const Color shareInstagramEnd = Color(0xFFFCAF45);
  static const Color shareFacebookBlue = Color(0xFF1877F2);

  /// rgba(20,20,60,.08) — lifts a white disc off a white sheet.
  static const Color shareTargetShadow = Color(0x143C3114);
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
  static const Color weekRecapBannerStart = Color(0xFF9D781B);
  static const Color weekRecapBannerMid = Color(0xFFD9A216);
  static const Color weekRecapBannerEnd = Color(0xFFDFB64F);
  static const Color weekRecapPillInk = Color(0xFF9C781D);
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
  static const Color kpOptionSelectedSurface = Color(0xFFFEFBF2);
  static const Color kpOptionSelectedText = Color(0xFF6B592A);
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
  static const Color kpCheckDisabled = Color(0xFFE6D5A4);
  static const Color kpArrangeText = Color(0xFF2B3242);
  static const Color kpArrangeHandle = Color(0xFFC3C9D6);
  static const Color kpArrangeHandleCorrect = Color(0xFF8BD3B0);
  static const Color kpArrangeHandleWrong = Color(0xFFF3A69E);
  // Per-exercise-type accents: the design tints each card's instruction line
  // violet (single choice, text gap) or green (multiple choice, arrange), and
  // reuses the violet for a filled gap's dashed outline.
  static const Color kpAccentViolet = Color(0xFFDAAC37);
  static const Color kpAccentGreen = Color(0xFF3AA07E);
  static const Color kpGapFilledSurface = Color(0xFFFEF8EA);
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
  static const Color kpPeekQuoteMark = Color(0xFFFBF3E0);
  static const Color kpPeekDivider = Color(0xFFE8D7A8);
  static const Color kpPeekSource = Color(0xFF5F6F86);
  static const Color kpPeekHint = Color(0xFF9A844F);

  // Back face of the recap flip card (design `_HDDhistory App` → RECAP). Exact hex.
  static const Color kpRecapBackSurface = Color(0xFF40361B);

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
