part of '../../week_recap.dart';

/// The small uppercase labels. Bundled from the design's own declaration
/// (`font-family:'Space Mono'`), OFL, Vietnamese verified.
const String _kWeekRecapMonoFont = 'Space Mono';

/// Every handwritten value: the lesson titles, the encouragement line, the
/// favourite course, the four stamp digits and the habit list.
///
/// The design names this family but the export never carried the file — only the
/// `@font-face` pointing at `assets/SVN-LumiosMarker.otf`, which the designer
/// supplied separately. It is the Vietnamese cut and ships a SINGLE Regular
/// weight, so every caller below asks for [FontWeight.w400]: requesting 300 or
/// 700 from a one-weight family buys a synthetic fake, not a real cut, and the
/// design's own `font-weight:300` resolved to the same Regular in the browser.
const String _kWeekRecapHandFont = 'Lumios Marker';

/// The title's NUMBER. The design names Billock for it, and Billock is
/// latin-only — fine, it only ever draws two digits.
const String _kWeekRecapNumberFont = 'Billock';

/// The title's WORD ("Tuần") — the design's own face:
/// `font-family:"Forward Serif"; font-weight:600; font-size:30px`.
///
/// 2026-08-21 settled this after trying every candidate on the simulator with
/// the user: MTD raw (too thin), MTD + ink stroke matching the number (one
/// unified hand — workable, but not the design), Forward Serif. Design
/// fidelity won; the number stays Billock. If the unified-brush look is ever
/// wanted back: MTD at 65.12 design-px, box top 31.87px, ink stroke
/// 1.0px + [WeekRecapSlots.inkBoost].
///
/// Two standing caveats on this face's one available file (the personal-use
/// Bold): its `0`/`1` glyphs are a "PERSONAL USE ONLY" watermark, so it must
/// NEVER render the week number, and the licence must be bought (or the face
/// swapped) before a store build.
const String _kWeekRecapTitleFont = 'Forward Serif';

/// The pinned quote. A different hand from the body's Lumios Marker, which is
/// what makes it read as a quote pinned to the page rather than more of the
/// same writing.
const String _kWeekRecapQuoteFont = 'MTD Adventures';

/// The scrapbook artwork — ONE file for every locale.
///
/// The stripped art (2026-08-20) carries no text at all: not the title, not the
/// calendar, not even the fixed labels. Everything readable is drawn from l10n
/// over the top, which is what dissolved the earlier per-locale artwork plan —
/// and the mixed-language poster CJK readers were getting under the `en`
/// fallback along with it.
String weekRecapArtworkAsset() => 'assets/images/week_recap/wrap_bg.jpg';

/// "Hành trình tuần qua" as one shareable 9:16 page.
///
/// A fixed-aspect box with the artwork behind and every dynamic value placed on
/// it by fraction. It renders identically at any width, which is what lets the
/// share path capture it at 1080x1920 off the same widget the reader is looking
/// at.
///
/// Missing data leaves the artwork showing through rather than drawing a
/// placeholder: the notepad is ruled paper, so a blank line reads as "not
/// written yet", while a dash would read as a bug. Counts are the exception —
/// a zero is printed, because an empty stamp looks like it is still loading.
class WeekRecapPoster extends StatelessWidget {
  const WeekRecapPoster({super.key, required this.recap, this.boundaryKey});

  final WeekRecapEntity recap;

  /// Set by the share bar so the poster can be captured to an image.
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / WeekRecapSlots.referenceWidth;

        return AspectRatio(
          aspectRatio: WeekRecapSlots.aspectRatio,
          child: Container(
            color: AppCustomColor.weekRecapPaper,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  weekRecapArtworkAsset(),
                  fit: BoxFit.cover,
                  // The paper colour behind is the fallback: a missing artwork
                  // must still leave a readable page, not a grey error box on
                  // top of the reader's week.
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                ..._fixedLabels(context, scale),
                ..._weekTitle(context, scale),
                _calendar(scale),
                ..._moodChips(width),
                ..._lessonRows(scale),
                _encouragement(context, scale),
                ..._favourite(context, scale),
                ..._stats(scale),
                ..._habits(context, scale),
                _watermark(scale),
              ],
            ),
          ),
        );
      },
    );

    final key = boundaryKey;

    return key == null ? content : RepaintBoundary(key: key, child: content);
  }

  /// "Tuần 01" — two faces on one tilt, each with the design's white halo.
  ///
  /// Split because the design splits it: the word is a serif, the number is
  /// Billock, and they sit at different origins and sizes. Drawing it as one
  /// string in one font is what made it read as "not the design".
  ///
  /// Flutter has no text-stroke property, so each halo is the same string
  /// painted once with a stroke Paint behind the fill (`paint-order:stroke
  /// fill` in the markup).
  List<Widget> _weekTitle(BuildContext context, double scale) {
    final l10n = context.l10n.weekRecap;

    // BOTH halos first, THEN both inks — four slots, not two. With one slot
    // per text, the number's white halo (painted after the whole word) sat on
    // top of the word's ink and amputated the 'n' exit swash that MTD sweeps
    // toward the digits ("chữ tuần bị cắt đuôi"). The design never showed
    // this only because its Forward Serif word has no tail reaching that far —
    // its two divs overlap the same way. Halo-under-ink-for-everything is
    // what the sticker actually is: one white blob with the whole title
    // written on it.
    Widget pass({required bool halo, required bool word}) => _haloText(
      rect: word ? WeekRecapSlots.titleWord : WeekRecapSlots.titleNumber,
      text: word ? l10n.posterTitleWord : recap.weekNumber.toString().padLeft(2, '0'),
      family: word ? _kWeekRecapTitleFont : _kWeekRecapNumberFont,
      fontSize: (word ? WeekRecapSlots.titleWordFontSize : WeekRecapSlots.titleNumberFontSize) * scale,
      haloRatio: word ? WeekRecapSlots.titleWordHaloRatio : WeekRecapSlots.titleNumberHaloRatio,
      trimRatio: word ? WeekRecapSlots.titleWordTrimRatio : WeekRecapSlots.titleNumberTrimRatio,
      inkStrokeRatio: word ? WeekRecapSlots.titleWordInkStrokeRatio : WeekRecapSlots.titleNumberInkStrokeRatio,
      letterSpacingRatio: word ? 0 : WeekRecapSlots.titleNumberLetterSpacingRatio,
      align: word ? Alignment.topRight : Alignment.topLeft,
      haloPass: halo,
    );

    return [
      pass(halo: true, word: true),
      pass(halo: true, word: false),
      pass(halo: false, word: true),
      pass(halo: false, word: false),
    ];
  }

  Widget _haloText({
    required Rect rect,
    required String text,
    required String family,
    required double fontSize,
    required double haloRatio,
    required double trimRatio,
    required double inkStrokeRatio,
    double letterSpacingRatio = 0,

    /// TOP-anchored, always. CSS `top:` places the block's top edge, so
    /// centring vertically shifts the glyphs up by half the leading — with a
    /// tall display face (Billock) that was enough to push the number clean off
    /// the poster's top edge, where the Stack's clip ate it. Nothing threw; the
    /// title simply lost half of itself.
    required Alignment align,

    /// true = draw ONLY the white halo; false = only the ink passes. The two
    /// halves are separate slots so both halos can go under both inks — see
    /// [_weekTitle]. Geometry is identical in both, so the layers register.
    required bool haloPass,
  }) {
    final base = TextStyle(
      fontFamily: family,
      // Falls back to a font we KNOW carries these glyphs. Billock is a display
      // face with 138 glyphs; if the engine cannot use it the number would
      // otherwise render as nothing at all — which is exactly how the title
      // lost its digits once, silently. A widget test cannot catch that: tests
      // substitute a stub font, so real font metrics never run there.
      fontFamilyFallback: const [_kWeekRecapMonoFont, AppFont.mulish],
      // NO fontWeight. Both display faces ship a single file that already IS the
      // weight the design used, and each reports usWeightClass 400 — so asking
      // for w700 made CoreText SYNTHESISE the bold: it inflated every stem
      // (measured 1.54x the artwork's) and made the stroke passes wildly
      // over-sensitive, to where 0.3px more trim erased the whole word.
      fontSize: fontSize,
      letterSpacing: fontSize * letterSpacingRatio,
      height: 1,
    );

    return _slot(
      rect,
      Transform.rotate(
        angle: WeekRecapSlots.titleRotationDeg * pi / 180,
        child: Align(
          alignment: align,
          child: Stack(
            children: [
              // 1. The outer glow, under everything (its own pass/slot).
              if (haloPass) _titleLayer(text, base, stroke: fontSize * haloRatio),
              // 2. The ink, at the font's own weight.
              if (!haloPass)
                Text(
                  text,
                  maxLines: 1,
                  style: base.copyWith(color: AppCustomColor.weekRecapTitleInk),
                ),
              // 2b. A navy stroke over the fill. Two jobs share it: the word's
              //     weight correction (match the number's measured ink) and the
              //     poster-wide renderer compensation — see the slots table.
              if (!haloPass && inkStrokeRatio > 0) _titleLayer(text, base, stroke: fontSize * inkStrokeRatio, color: AppCustomColor.weekRecapTitleInk),
              // 3. A thin white shave on top, which is what thins the navy —
              //    the only way to do it without a lighter cut of the face.
              //    OFF (ratio 0) since the baked-title era; keep it that way.
              if (!haloPass && trimRatio > 0) _titleLayer(text, base, stroke: fontSize * trimRatio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleLayer(String text, TextStyle base, {required double stroke, Color? color}) => Text(
    text,
    maxLines: 1,
    style: base.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..color = color ?? AppCustomColor.weekRecapTitleHalo,
    ),
  );

  /// The seven fixed labels the stripped artwork no longer carries.
  ///
  /// Editorial copy, not data — but drawn from l10n rather than baked so one
  /// artwork serves five locales and a copy change never means new art. The
  /// small caps are Space Mono like every stamped label; the quote is the
  /// reader's-hand face, its tail sitting on the red underline baked at the
  /// top right.
  List<Widget> _fixedLabels(BuildContext context, double scale) {
    final l10n = context.l10n.weekRecap;
    final captions = [
      l10n.statStreakLabel,
      l10n.statHabitLabel,
      l10n.statLessonLabel,
      l10n.statMinutesLabel,
    ];

    // The stamped uppercase labels: Space Mono 700, set SOLID and UNTRACKED,
    // which is how the design sets every one of them. The blanket 0.06em this
    // helper used to add was the poster's most visible drift — Space Mono
    // advances 0.6em, so the tracking lands almost entirely as extra width and
    // made each label 10% too wide, walking "NÂNG CẤP BẢN THÂN" off its tape
    // and "THÓI QUEN ĐÃ GIỮ:" past the edge of its sheet. The three labels that
    // ARE tracked in the design carry their own value and do not use this.
    // No colour here — WeekRecapInkText owns it.
    TextStyle mono(double size) => TextStyle(
      fontFamily: _kWeekRecapMonoFont,
      fontWeight: FontWeight.w700,
      fontSize: size * scale,
      height: WeekRecapSlots.lineHeightSolid,
    );

    return [
      // "NÂNG CẤP BẢN THÂN", on the tilted tape sticker.
      _slot(
        WeekRecapSlots.badge,
        Transform.rotate(
          angle: WeekRecapSlots.badgeRotationDeg * pi / 180,
          // Pivot on the left edge, where the text starts — the design rotates
          // an auto-width div, so its origin is the words, not a wide box.
          alignment: Alignment.centerLeft,
          child: Align(
            alignment: Alignment.centerLeft,
            child: WeekRecapInkText(
              l10n.posterBadge.toUpperCase(),
              style: mono(WeekRecapSlots.badgeFontSize),
              color: AppCustomColor.weekRecapDarkInk,
              scale: scale,
            ),
          ),
        ),
      ),
      // The pinned quote, ending over the baked red underline.
      _slot(
        WeekRecapSlots.quote,
        Align(
          alignment: Alignment.topRight,
          child: WeekRecapInkText(
            l10n.posterQuote,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _kWeekRecapQuoteFont,
              // NO fontWeight, for the same reason the title sets none: MTD
              // Adventures ships a single file reporting usWeightClass 400, so
              // the w700 that used to sit here bought a CoreText synthetic bold
              // rather than a real cut. The design declares the face over a
              // `font-weight:400 700` range precisely so the browser does not
              // synthesise either.
              fontSize: WeekRecapSlots.quoteFontSize * scale,
              // 0.75, the design's own line-height — a script face at 1.45
              // leading spilled the second line out of the slot and ellipsised
              // "the first step".
              height: WeekRecapSlots.lineHeightQuote,
            ),
            color: AppCustomColor.weekRecapQuoteInk,
            scale: scale,
          ),
        ),
      ),
      // "BÀI HỌC TUẦN QUA", on the notepad's tape strip.
      _slot(
        WeekRecapSlots.lessonsLabel,
        Align(
          alignment: Alignment.centerLeft,
          child: WeekRecapInkText(
            l10n.posterLessonsLabel.toUpperCase(),
            style: mono(WeekRecapSlots.lessonsLabelFontSize),
            color: AppCustomColor.weekRecapLabelRed,
            scale: scale,
          ),
        ),
      ),
      // The four stamp captions. Left-anchored at the design's own x, and each
      // leaning with its own stamp — the collage tilts all four differently, so
      // one shared rotation put three of them off their paper.
      for (var index = 0; index < captions.length; index++)
        _slot(
          Rect.fromLTWH(
            WeekRecapSlots.statCaptionLeft[index],
            WeekRecapSlots.statCaptionTop[index],
            0.22,
            0.016,
          ),
          Transform.rotate(
            angle: WeekRecapSlots.statCaptionRotationDeg[index] * pi / 180,
            alignment: Alignment.centerLeft,
            child: Align(
              alignment: Alignment.centerLeft,
              child: WeekRecapInkText(
                captions[index].toUpperCase(),
                style: mono(WeekRecapSlots.statCaptionFontSize),
                color: AppCustomColor.weekRecapDarkInk,
                scale: scale,
              ),
            ),
          ),
        ),
      // "THÓI QUEN ĐÃ GIỮ:", heading the ruled sheet.
      //
      // Chỉ vẽ khi thật sự có dòng bên dưới (xem [_habits], vốn đã có điều
      // kiện): tính năng Thói quen đã bị gỡ khỏi app, nên tuần nào server
      // không trả thói quen nào thì tiêu đề này sẽ đứng trơ một mình.
      if (recap.habits.isNotEmpty)
        _slot(
          WeekRecapSlots.habitsHeading,
          Align(
            alignment: Alignment.centerLeft,
            child: WeekRecapInkText(
              l10n.habitsHeading.toUpperCase(),
              style: mono(WeekRecapSlots.habitsHeadingFontSize),
              color: AppCustomColor.weekRecapLabelRed,
              scale: scale,
            ),
          ),
        ),
    ];
  }

  Widget _calendar(double scale) => _slot(
    WeekRecapSlots.calendar,
    WeekRecapCalendar(days: recap.days, scale: scale),
  );

  /// One chip per day that has a mood, centred on its date cell.
  ///
  /// Days without a mood get nothing at all, which is what leaves their date
  /// number visible — the design's own behaviour, and why a seven-day week
  /// showed only six chips in the mock.
  List<Widget> _moodChips(double width) {
    final chips = <Widget>[];
    for (var index = 0; index < WeekRecapSlots.weekDays; index++) {
      if (index >= recap.days.length) break;
      final mood = recap.days[index].mood;
      if (mood == null) continue;

      final centreX = WeekRecapSlots.moodFirstCentreX + WeekRecapSlots.moodPitchX * index;
      final size = WeekRecapSlots.moodSize;
      chips.add(
        _slot(
          Rect.fromLTWH(
            centreX - size / 2,
            WeekRecapSlots.moodTop,
            size,
            size * WeekRecapSlots.aspectRatio,
          ),
          WeekRecapMoodChip(mood: mood, size: size * width),
        ),
      );
    }

    return chips;
  }

  List<Widget> _lessonRows(double scale) {
    final rows = <Widget>[];
    for (var index = 0; index < WeekRecapSlots.lessonRows; index++) {
      if (index >= recap.lessons.length) break;
      final lesson = recap.lessons[index];
      final radians = WeekRecapSlots.lessonRotationDeg[index] * pi / 180;

      if (lesson.image.isNotEmpty) {
        rows.add(
          _slot(
            Rect.fromLTWH(
              WeekRecapSlots.lessonThumbLeft,
              WeekRecapSlots.lessonThumbTop[index],
              WeekRecapSlots.lessonThumbWidth,
              // Square, expressed in the poster's WIDTH: a fraction of its
              // height would come out 16/9 too tall.
              WeekRecapSlots.lessonThumbWidth * WeekRecapSlots.aspectRatio,
            ),
            Transform.rotate(
              angle: radians,
              child: Container(
                padding: EdgeInsets.all(2 * scale),
                color: AppCustomColor.backgroundWhite,
                child: CachedNetworkImage(
                  imageUrl: lesson.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ColoredBox(color: AppCustomColor.weekRecapPaper),
                  errorWidget: (context, url, error) => const ColoredBox(color: AppCustomColor.weekRecapPaper),
                ),
              ),
            ),
          ),
        );
      }

      rows.add(
        _slot(
          Rect.fromLTWH(
            WeekRecapSlots.lessonTextLeft,
            WeekRecapSlots.lessonTextTop[index],
            WeekRecapSlots.lessonTextWidth,
            0.04,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeekRecapInkText(
                lesson.courseTitle.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kWeekRecapMonoFont,
                  // 400, the design's weight. w500 resolved to the Regular file
                  // anyway — Space Mono only ships 400 and 700 here — but it
                  // read as an intent this row never had.
                  fontWeight: FontWeight.w400,
                  fontSize: WeekRecapSlots.lessonCourseFontSize * scale,
                  letterSpacing: WeekRecapSlots.lessonCourseFontSize * scale * WeekRecapSlots.trackingLessonCourse,
                  height: WeekRecapSlots.lineHeightSmallCaps,
                ),
                color: AppCustomColor.weekRecapCourseLabel,
                scale: scale,
              ),
              SizedBox(height: 2 * scale),
              WeekRecapInkText(
                lesson.lessonTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kWeekRecapHandFont,
                  fontWeight: FontWeight.w400,
                  fontSize: WeekRecapSlots.lessonTitleFontSize * scale,
                  height: WeekRecapSlots.lineHeightSolid,
                ),
                color: AppCustomColor.weekRecapLessonInk,
                scale: scale,
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  /// The sentence in the speech bubble, chosen by how many days were shown up
  /// for. Built here rather than sent by the server: it is copy, it has to exist
  /// in five locales, and the numbers it quotes are already on this poster.
  Widget _encouragement(BuildContext context, double scale) {
    final l10n = context.l10n.weekRecap;
    final days = recap.stats.activeDays;
    final text = switch (days) {
      >= WeekRecapSlots.weekDays => l10n.encouragementPerfect,
      >= 5 => l10n.encouragementStrong(days: days),
      >= 3 => l10n.encouragementSteady(days: days),
      _ => l10n.encouragementGentle(days: days),
    };

    return _slot(
      WeekRecapSlots.encouragement,
      Center(
        child: WeekRecapInkText(
          text,
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: _kWeekRecapHandFont,
            fontWeight: FontWeight.w400,
            fontSize: WeekRecapSlots.encouragementFontSize * scale,
            height: WeekRecapSlots.lineHeightSmallCaps,
          ),
          color: AppCustomColor.weekRecapBodyInk,
          scale: scale,
        ),
      ),
    );
  }

  List<Widget> _favourite(BuildContext context, double scale) {
    final course = recap.favouriteCourse;
    if (course == null) return const [];

    return [
      if (course.image.isNotEmpty)
        _slot(
          WeekRecapSlots.favouriteImage,
          CachedNetworkImage(
            imageUrl: course.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ColoredBox(color: AppCustomColor.weekRecapPaper),
            errorWidget: (context, url, error) => const ColoredBox(color: AppCustomColor.weekRecapPaper),
          ),
        ),
      _slot(
        WeekRecapSlots.favouriteText,
        Column(
          // CENTER, not stretch: each text is a WeekRecapInkText — a Stack —
          // and a stretched Stack leaves its intrinsic-width Text children
          // parked at the left edge, which un-centred this block ("căn giữa").
          // With center, the Stack shrink-wraps to the text and the Column
          // centres it in the slot, like the design's text-align:center.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WeekRecapInkText(
              context.l10n.weekRecap.favouriteCourseLabel.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kWeekRecapMonoFont,
                fontWeight: FontWeight.w700,
                fontSize: WeekRecapSlots.favouriteLabelFontSize * scale,
                letterSpacing: WeekRecapSlots.favouriteLabelFontSize * scale * WeekRecapSlots.trackingFavouriteLabel,
                height: WeekRecapSlots.lineHeightSmallCaps,
              ),
              color: AppCustomColor.weekRecapFavouriteLabel,
              scale: scale,
            ),
            SizedBox(height: 1 * scale),
            WeekRecapInkText(
              course.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _kWeekRecapHandFont,
                fontWeight: FontWeight.w400,
                fontSize: WeekRecapSlots.favouriteTitleFontSize * scale,
                height: WeekRecapSlots.lineHeightSolid,
              ),
              color: AppCustomColor.weekRecapDarkInk,
              scale: scale,
            ),
          ],
        ),
      ),
    ];
  }

  /// The four stamps. Order and colour are the artwork's, so the list is
  /// positional rather than a map — the captions are painted into the image and
  /// cannot be reordered from here.
  List<Widget> _stats(double scale) {
    final values = [
      recap.stats.streakDays,
      recap.stats.habitsKept,
      recap.stats.keypoints,
      recap.stats.minutes,
    ];
    const colors = [
      AppCustomColor.weekRecapStatStreak,
      AppCustomColor.weekRecapStatHabits,
      AppCustomColor.weekRecapStatLessons,
      AppCustomColor.weekRecapStatMinutes,
    ];

    return List.generate(values.length, (index) {
      // Only the last stamp is tilted, matching the artwork's pinned clock card.
      final isLast = index == values.length - 1;
      final label = WeekRecapInkText(
        '${values[index]}',
        style: TextStyle(
          fontFamily: _kWeekRecapHandFont,
          fontWeight: FontWeight.w400,
          fontSize: WeekRecapSlots.statFontSize * scale,
          // 0.75, from the design. A roomy em box at line-height 1 is what sent
          // the digits' feet into the captions below.
          height: WeekRecapSlots.statLineHeight,
        ),
        color: colors[index],
        scale: scale,
      );

      return _slot(
        Rect.fromLTWH(
          WeekRecapSlots.statCentreX[index] - WeekRecapSlots.statBoxWidth / 2,
          WeekRecapSlots.statTop[index],
          WeekRecapSlots.statBoxWidth,
          WeekRecapSlots.statBoxHeight,
        ),
        Align(
          // Top-centre, not centre: the design positions the glyph's TOP at
          // `statTop`, and centring it in a box tall enough for a 50px digit
          // would drop it off its stamp.
          alignment: Alignment.topCenter,
          child: isLast
              ? Transform.rotate(
                  angle: WeekRecapSlots.statLastRotationDeg * pi / 180,
                  child: label,
                )
              : label,
        ),
      );
    });
  }

  List<Widget> _habits(BuildContext context, double scale) {
    final rows = <Widget>[];
    for (var index = 0; index < WeekRecapSlots.habitRows; index++) {
      if (index >= recap.habits.length) break;
      rows.add(
        _slot(
          Rect.fromLTWH(
            WeekRecapSlots.habitLeft,
            WeekRecapSlots.habitTop[index],
            WeekRecapSlots.habitWidth,
            0.028,
          ),
          _bulletLine(
            text: recap.habits[index].title,
            fontSize: WeekRecapSlots.habitFontSize * scale,
            color: AppCustomColor.weekRecapBodyInk,
            scale: scale,
          ),
        ),
      );
    }

    // Always, not only when habits overflow the three ruled lines. In the design
    // this is a FIXED fourth entry sitting in the same list as the habits — a
    // closing note in the reader's own hand, not an "and N more" indicator. It
    // stays code-drawn rather than baked so it localises with everything else.
    rows.add(
      _slot(
        Rect.fromLTWH(
          WeekRecapSlots.habitLeft,
          WeekRecapSlots.habitClosingTop,
          WeekRecapSlots.habitWidth,
          0.024,
        ),
        _bulletLine(
          text: context.l10n.weekRecap.habitsClosingNote,
          fontSize: WeekRecapSlots.habitClosingFontSize * scale,
          color: AppCustomColor.weekRecapFaintInk,
          scale: scale,
        ),
      ),
    );

    return rows;
  }

  /// The poster signs off with the app's icon and its name.
  ///
  /// It used to be "#MeUp" — a hashtag pointing at a feed the product does not
  /// run, on an image whose whole job is to be recognised in someone else's
  /// story. The mark is the launcher icon itself, so what signs the poster is
  /// the same square the reader has on their home screen; its rounded corners
  /// and transparent ground are baked into the file, which is why nothing here
  /// clips or draws a tile.
  Widget _watermark(double scale) {
    final mark = WeekRecapSlots.watermarkMarkSize * scale;

    return _slot(
      Rect.fromLTWH(
        0,
        1 - WeekRecapSlots.watermarkBottom - WeekRecapSlots.watermarkHeight,
        1,
        WeekRecapSlots.watermarkHeight,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAsset.images.common.mainIcon.path,
            width: mark,
            height: mark,
            // The poster is captured to a shareable image; a missing asset has
            // to cost the signature, never draw a broken-image box into it.
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          SizedBox(width: WeekRecapSlots.watermarkGap * scale),
          WeekRecapInkText(
            // Not localised, and not read from the flavour's display name: this
            // is the brand's own spelling, and a dev build must not sign a
            // shared poster "Meup Dev".
            'MeUp',
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontWeight: FontWeight.w800,
              fontSize: WeekRecapSlots.watermarkFontSize * scale,
              letterSpacing: WeekRecapSlots.watermarkFontSize * scale * WeekRecapSlots.trackingWordmark,
              height: WeekRecapSlots.lineHeightSolid,
            ),
            // The poster's own dark ink, not the brand violet: on cream paper
            // the name reads as printed next to the mark, and a second violet
            // beside the icon makes the pair look like one smeared shape.
            color: AppCustomColor.weekRecapDarkInk,
            scale: scale,
          ),
        ],
      ),
    );
  }

  /// One ruled line of the habit list: a bullet, a gap, then the text.
  ///
  /// The design draws all four lines — the three habits AND the "and more"
  /// note — from one loop, so they share the bullet and the handwriting font and
  /// differ only in size and ink. Dropping the bullet from any of them, or
  /// setting the last one in the sans, breaks a list that reads as one hand.
  Widget _bulletLine({
    required String text,
    required double fontSize,
    required Color color,
    required double scale,
  }) {
    final style = TextStyle(
      fontFamily: _kWeekRecapHandFont,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      height: WeekRecapSlots.lineHeightSolid,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeekRecapInkText('\u2022', style: style, color: color, scale: scale),
        SizedBox(width: 6 * scale),
        Expanded(
          child: WeekRecapInkText(
            text,
            overflow: TextOverflow.ellipsis,
            style: style,
            color: color,
            scale: scale,
          ),
        ),
      ],
    );
  }

  /// Places a child by fractions of the poster box.
  Widget _slot(Rect rect, Widget child) => Positioned.fill(
    child: Align(
      alignment: Alignment.topLeft,
      child: _PosterSlotBox(rect: rect, child: child),
    ),
  );
}

/// One text on the poster, drawn twice: a hair-width same-colour stroke under
/// the plain fill.
///
/// This is the renderer compensation, not a style: Flutter's rasterizer draws
/// ink ~6-7% thinner than the browser the design is approved in (CoreText's
/// font smoothing emboldens there — measured per face, see
/// [WeekRecapSlots.inkBoost]). Every visible string on the poster and its
/// calendar goes through here so the whole page carries the same ink; a Text
/// added directly will read one hair lighter than its neighbours.
///
/// [style] must NOT set `color` — it is passed separately because the stroke
/// layer needs it inside a `foreground` Paint, and TextStyle forbids setting
/// both `color` and `foreground` on one style.
class WeekRecapInkText extends StatelessWidget {
  const WeekRecapInkText(
    this.text, {
    super.key,
    required this.style,
    required this.color,
    required this.scale,
    this.maxLines = 1,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Color color;

  /// Poster width over [WeekRecapSlots.referenceWidth] — the boost is ink,
  /// so it scales with the poster like every other stroke on it.
  final double scale;

  final int maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    Text layer(TextStyle s) => Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: s,
    );

    return Stack(
      children: [
        layer(
          style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = WeekRecapSlots.inkBoost * scale
              ..strokeJoin = StrokeJoin.round
              ..color = color,
          ),
        ),
        layer(style.copyWith(color: color)),
      ],
    );
  }
}

class _PosterSlotBox extends StatelessWidget {
  const _PosterSlotBox({required this.rect, required this.child});

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.topLeft,
      widthFactor: rect.width,
      heightFactor: rect.height,
      child: FractionalTranslation(
        translation: Offset(rect.left / rect.width, rect.top / rect.height),
        child: child,
      ),
    );
  }
}
