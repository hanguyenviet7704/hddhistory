part of '../../week_recap.dart';

/// Every position on the poster, in one table.
///
/// Since 2026-08-20 these are no longer hand-measured: the designer re-laid the
/// poster for the stripped artwork and put EVERY label into the markup with
/// explicit coordinates (`_HDDhistory App.dc.html`, week-wrap section). Rect values
/// here are those percentages verbatim.
///
/// FONT SIZES ARE WRITTEN AS `<design px> * _k`, NEVER AS A LITERAL. The design
/// draws on a 335-wide poster and this table's reference is 350, so every size
/// needs the ratio — and half of them silently did not have it, which left all
/// the handwriting 4.3% smaller than the stamped labels it shares the page with.
/// Keeping the design's own number visible in the expression is what makes the
/// next missing `* _k` obvious on sight.
class WeekRecapSlots {
  const WeekRecapSlots._();

  static const double referenceWidth = 350;
  static const double aspectRatio = 1080 / 1920;

  /// The design's poster box, in CSS px: `width:335px; height:595px`.
  static const double _designWidth = 335;
  static const double _designHeight = 595;

  /// Design px -> this table's 350-wide reference.
  static const double _k = referenceWidth / _designWidth;

  //* The tape sticker above the title. The design's div has NO width — the
  //* text simply starts at 22.2% and flows right — so this box is only a
  //* container and the label is anchored to its LEFT edge, pivoting there too.
  //* Centring inside a 0.30-wide box pushed the words half a box right, off
  //* the tape.
  static const Rect badge = Rect.fromLTWH(0.222, 0.054, 0.34, 0.024);
  static const double badgeRotationDeg = -6;
  static const double badgeFontSize = 7 * _k;

  //* "Tuần" + "01" — two faces, one tilt, both with the white halo.
  //*
  //* Straight from the design now. The previous numbers were solved against the
  //* ORIGINAL artwork, the one whose title was still baked in
  //* (Birthday (4).png) — obsolete since the art was stripped and the designer
  //* moved the title into the markup with its own size and coordinates.
  //*
  //* The word's box keeps a generous width and stays RIGHT-anchored rather than
  //* being cut to fit "Tuần": the string is localised, and "Week"/"週" are not
  //* the same width. The design's box happens to fit its Vietnamese exactly
  //* (measured: "Tuần" at 30px in ForwardSerif-Bold is 92.28px = 27.55% of the
  //* poster, against the design's `width:27.5%`). So the box is widened
  //* leftwards and the design's RIGHT edge, 0.600, is what is preserved.
  //* (zh/ja/ko have no glyph in this face and fall back, as they always did.)
  //*
  //* The top is NOT the design's 8.2% verbatim — it carries the CSS-vs-Flutter
  //* leading correction: with `line-height:1` a browser centres the font's own
  //* ascent+descent (1.38em here) in the line box, giving a half-leading of
  //* (30 - 41.4)/2 = -5.70px and a baseline 24.30px below the top, while
  //* Flutter's `height: 1.0` distributes proportionally, putting the baseline
  //* at (1000/1380) x 30 = 21.74px. The browser draws the ink 2.56px lower, so:
  //* 8.2% x 595 + 2.56 = 51.35px. (For the MTD variant of this title, the
  //* same derivation gives size 65.12 and top 31.87px — see
  //* `_kWeekRecapTitleFont` for when that would come back.)
  static const double _titleWordDesignSize = 30;
  static const double _titleWordRight = 0.600;
  static const double _titleWordWidth = 0.345;
  static const Rect titleWord = Rect.fromLTWH(
    _titleWordRight - _titleWordWidth,
    51.35 / _designHeight,
    _titleWordWidth,
    // Flutter's Text is exactly `fontSize` tall at height 1.0. The face's cap
    // pokes ~6.5px above that box (its ascent alone is 1em) — fine, nothing
    // clips until the poster's own edge.
    _titleWordDesignSize / _designHeight,
  );
  static const double titleWordFontSize = _titleWordDesignSize * _k;

  //* `left:62.1%; top:6.4%` with an auto width. The box is kept at 0.30 so a
  //* three-digit week cannot be clipped; that moves the rotation pivot ~30pt
  //* right of the design's, which at -3 degrees is a 1.6pt vertical difference.
  //*
  //* The top carries the same CSS-vs-Flutter leading correction as the word:
  //* Billock's hhea is 850/-350, so a browser puts the digits 1.88px lower than
  //* Flutter does at the same `top`. 6.4% + 1.88/595 = 6.715%.
  static const Rect titleNumber = Rect.fromLTWH(0.621, 0.06715, 0.30, 45 / _designHeight);
  static const double titleNumberFontSize = 45 * _k;

  /// The title paints in two passes, the design's own:
  ///
  ///  1. `halo`   `-webkit-text-stroke:10px #EBE9E7` with `paint-order:stroke
  ///              fill` — a CENTRED stroke, so half of it lands outside the
  ///              glyph and the fill then covers the inner half. Flutter's
  ///              stroke Paint is centred too, so the same width reproduces it.
  ///              The design's 10px is ABSOLUTE and shared by both faces, so
  ///              each ratio is 10 over that face's own size — never a shared
  ///              fraction, or the larger face grows a fatter outline.
  ///  2. ink fill the face's own weight. NOTE: no `fontWeight` is set — both
  ///              files report usWeightClass 400, so asking for w700 made
  ///              CoreText synthesise a bold that inflated every stem.
  ///
  /// The WORD is deliberately drawn LIGHTER than its file: the only Forward
  /// Serif on disk is the Bold cut, and the user reads it as a notch too heavy
  /// next to Billock's thin brush ("hơi dày"). A 0.6px white `trim` stroke
  /// shaves ~0.6px off the stems; it gets no [inkBoost] (boost and trim would
  /// just cancel). 0.6 is the ceiling checked against this face's distressed
  /// outline on a 0-1px ladder (2026-08-21): from ~1px up the shave opens
  /// white pinholes inside the letter body. If the licensed lighter cut is
  /// ever bought, drop the trim and use the real weight.
  ///
  /// The NUMBER renders at its file's own weight plus the poster-wide
  /// [inkBoost] — which is what the design's render does: its
  /// `font-weight:900` request synthesises nothing over the declared 400-700
  /// range (verified: identical ink to w400, 2.75px, run-length medians on 4x
  /// renders). (The MTD title variant instead needed 1.0px + boost on the
  /// word — see `_kWeekRecapTitleFont`.)
  static const double titleWordHaloRatio = 10 / _titleWordDesignSize;
  static const double titleWordInkStrokeRatio = 0;
  static const double titleWordTrimRatio = 0.6 / _titleWordDesignSize;
  static const double titleNumberHaloRatio = 10 / 45;
  static const double titleNumberLetterSpacingRatio = 0;
  static const double titleNumberInkStrokeRatio = inkBoost / 45;
  static const double titleNumberTrimRatio = 0;

  static const double titleRotationDeg = -3;

  //* The pinned quote, right-aligned; its tail sits on the baked underline.
  static const Rect quote = Rect.fromLTWH(0.612, 0.133, 0.364, 0.052);
  static const double quoteFontSize = 12 * _k;

  //* "BÀI HỌC TUẦN QUA" on the notepad's tape strip.
  static const Rect lessonsLabel = Rect.fromLTWH(0.06, 0.163, 0.44, 0.016);
  static const double lessonsLabelFontSize = 8 * _k;

  //* The calendar card. The artwork keeps its chrome (chevrons, divider, seven
  //* cell boxes); the rows below land on it by card-relative fractions.
  static const Rect calendar = Rect.fromLTWH(0.581, 0.185, 0.362, 0.090);
  static const double calendarHeaderFontSize = 6 * _k;
  static const double calendarWeekdayFontSize = 3.5 * _k;
  static const double calendarDateFontSize = 4 * _k;
  static const double calHeaderTop = 0.09;
  static const double calHeaderHeight = 0.22;
  static const double calHeaderInsetX = 0.163;
  static const double calWeekdayTop = 0.39;
  static const double calWeekdayHeight = 0.13;
  static const double calDateTop = 0.72;
  static const double calDateHeight = 0.18;
  /// The baked cell strip is right-flush in the card: left inset 6.1%, right
  /// 0.4%. Symmetric columns drift half a cell left of the real boxes.
  static const double calCellsInsetLeft = 0.061;
  static const double calCellsInsetRight = 0.004;

  //* Mood chips own the upper half of the cells; dates keep the feet.
  static const double moodFirstCentreX = 0.628;
  static const double moodPitchX = 0.0484;
  static const double moodTop = 0.2365;
  static const double moodSize = 0.030;

  //* Notepad rows.
  static const List<double> lessonThumbTop = [0.196, 0.254, 0.312];
  static const List<double> lessonTextTop = [0.203, 0.261, 0.319];
  static const List<double> lessonRotationDeg = [-3, 2, -2];
  static const double lessonThumbLeft = 0.064;
  static const double lessonThumbWidth = 0.080;
  static const double lessonTextLeft = 0.160;
  static const double lessonTextWidth = 0.370;
  static const double lessonCourseFontSize = 5 * _k;
  static const double lessonTitleFontSize = 9.5 * _k;

  //* The crumpled speech bubble — its BODY, not the tail. The design centres the
  //* sentence in a 12%-tall flex box, so the box height is load-bearing: at 9%
  //* the block centred 1% of the poster too high.
  static const Rect encouragement = Rect.fromLTWH(0.08, 0.42, 0.41, 0.12);
  static const double encouragementFontSize = 11 * _k;

  //* The polaroid. NOT the design's numbers (img height 16.9%, text top
  //* 47.8%): the design only ever rendered a ONE-line course title, and a real
  //* two-line title (label 0.97% + gap + two 10px lines = 4.5% tall) ran off
  //* the card's bottom onto the baked washi tape — measured in the artwork:
  //* card bottom 51.0%, tape band 51.2-52.8%. The photo is cropped 1.2%
  //* shorter (BoxFit.cover just crops tighter) to lift the text block clear:
  //* it now ends at 50.8%, inside the card. ("chỗ này đẩy cao lên", 2026-08-21.)
  static const Rect favouriteImage = Rect.fromLTWH(0.64, 0.303, 0.30, 0.154);
  static const Rect favouriteText = Rect.fromLTWH(0.64, 0.462, 0.30, 0.046);
  static const double favouriteLabelFontSize = 5 * _k;
  static const double favouriteTitleFontSize = 10 * _k;

  //* Stamp digits, straight from the design data (line-height 0.75 is what
  //* keeps them clear of the captions — its absence was the collision).
  static const List<double> statCentreX = [0.151, 0.403, 0.620, 0.837];
  static const List<double> statTop = [0.566, 0.593, 0.568, 0.603];
  static const double statFontSize = 50 * _k;
  static const double statLineHeight = 0.75;
  static const double statBoxWidth = 0.24;
  static const double statBoxHeight = 0.065;
  static const double statLastRotationDeg = 12;

  //* Stamp captions — LEFT-anchored, each leaning with its own stamp.
  //*
  //* The LAST top is 66.9%, not the design's 68%: that caption leans +9° about
  //* its left end, so its right end dips a further ~1% of the poster, and at
  //* 68% the deepest ink landed at ~70.4% — exactly on the baked stamp's
  //* tilted bottom edge (measured in the artwork: the card fades out over
  //* 69.6-70.4%). 66.9% clears the edge and still sits 0.5% under the "60"
  //* digit above. ("phút học bị dính lề dưới", 2026-08-21.)
  static const List<double> statCaptionLeft = [0.118, 0.347, 0.571, 0.766];
  static const List<double> statCaptionTop = [0.640, 0.670, 0.640, 0.669];
  static const List<double> statCaptionRotationDeg = [-8, -6, 4, 9];
  static const double statCaptionFontSize = 8 * _k;

  //* "THÓI QUEN ĐÃ GIỮ:" heading and the ruled lines under it.
  static const Rect habitsHeading = Rect.fromLTWH(0.127, 0.784, 0.65, 0.020);
  static const double habitsHeadingFontSize = 12 * _k;
  static const List<double> habitTop = [0.819, 0.848, 0.877];
  static const double habitLeft = 0.14;
  static const double habitWidth = 0.80;
  static const double habitFontSize = 14 * _k;
  static const double habitClosingTop = 0.909;
  static const double habitClosingFontSize = 10 * _k;

  //* The signature that closes the poster: the app's own icon, then its name.
  //*
  //* The mark is `main_icon.png`, the file the launcher icons are built from —
  //* not a tile rebuilt out of a gradient and a Poppins "?". Same artwork the
  //* reader has on their home screen, and no font to approximate (the design
  //* sets the glyph at 800; the heaviest Poppins bundled is 700).
  //*
  //* Sizes from the design's logo sheet (`9 · Logo.dc.html`, "bản chốt") — the
  //* poster's own markup sits past the 256KiB the design MCP hands back.
  static const double watermarkBottom = 0.015;
  /// A hair taller than the tile (13.6px against 14.9px at the 350 reference):
  /// a row sized exactly to its child overflows the moment rounding goes the
  /// wrong way, and the slot is bottom-anchored so the spare grows upward where
  /// there is nothing to hit.
  static const double watermarkHeight = 0.024;

  /// Icon side. Just under the row's height: the name sits inside it.
  static const double watermarkMarkSize = 13 * _k;

  static const double watermarkGap = 5 * _k;
  static const double watermarkFontSize = 10 * _k;

  //* Line heights, from the design's own `line-height:` declarations. Almost
  //* everything on this poster is set solid; the two that are not are called
  //* out individually. Getting these wrong does not just change the leading —
  //* every one of these blocks is centred or top-anchored in a fixed slot, so
  //* extra leading moves the ink off its patch of artwork.
  static const double lineHeightSolid = 1;
  static const double lineHeightSmallCaps = 1.15;
  static const double lineHeightQuote = 0.75;

  //* Letter spacing, in em, from the design. Only three blocks carry any; the
  //* stamped labels carry NONE. A blanket 0.06em on the mono helper made every
  //* uppercase label 10% wider than its tape or stamp — Space Mono advances
  //* 0.6em, so the tracking lands almost entirely as extra width.
  static const double trackingLessonCourse = 0.02;
  static const double trackingFavouriteLabel = 0.04;
  //* The wordmark's tracking is NEGATIVE — the sheet sets -2px at 64px, which
  //* is what makes "HDDhistory" read as one mark rather than four letters. The old
  //* hashtag carried +0.1em, the opposite.
  static const double trackingWordmark = -2 / 64;

  //* A hair of same-colour stroke under EVERY text on the poster, in px at
  //* [referenceWidth]. Flutter's rasterizer draws ink ~6-7% thinner than the
  //* browser the design is approved in (CoreText font smoothing embolden) —
  //* measured per face on 3x captures, 2026-08-21: Space Mono 1.67 vs 1.56
  //* design-px, Lumios 1.00 vs 0.94, the title 2.67 vs 2.50.
  //*
  //* 0.35, NOT the naive 0.16 the deltas suggest: at phone scale the poster
  //* draws at ~1pt per reference px, so a 0.16 stroke is half a physical
  //* pixel — the inner half hides under the fill and the outer half is a
  //* faint antialiased rim that Impeller all but discards. Measured on device:
  //* zero effect. 0.35 is the smallest value that reliably rasterizes
  //* (~1 physical px at 3x) and visibly returns the missing ink. It
  //* compensates the renderer, not the fonts — do not fold it into any
  //* face-specific stroke.
  static const double inkBoost = 0.35;

  static const int lessonRows = 3;
  static const int habitRows = 3;
  static const int weekDays = 7;
}
