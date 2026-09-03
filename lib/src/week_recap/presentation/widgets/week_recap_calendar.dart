part of '../../week_recap.dart';

/// The poster's calendar block, drawn rather than baked.
///
/// It has to be code: the month, the year and the seven date numbers all change
/// every week, and the mood chips are positioned ON those date cells. An
/// artwork carrying the numbers would pin every poster ever made to one week in
/// August 2026, and the chips would then sit over the wrong days.
///
/// The artwork keeps the paper, the frame and the two chevrons behind this. The
/// weekday names and the month name are reused from `studyJournal` rather than
/// re-translated: the Profile calendar already ships them in all five locales,
/// and two copies would eventually disagree.
class WeekRecapCalendar extends StatelessWidget {
  const WeekRecapCalendar({
    super.key,
    required this.days,
    required this.scale,
  });

  final List<WeekRecapDayEntity> days;

  /// Poster width over [WeekRecapSlots.referenceWidth].
  final double scale;

  @override
  Widget build(BuildContext context) {
    final anchor = days.isEmpty ? DateTime.now() : days.first.date;
    final weekdays = context.l10n.studyJournal.weekdays.split(',');
    // Month name from `intl`, in the app's current language: "Tháng 8" /
    // "August" / "8月" without 12 hand-written strings per locale.
    //
    // The locale comes from slang, NOT from `parseString` — that helper reads
    // LocaleCubit out of AppDI, and a leaf widget that cannot be built without
    // the whole injector is a widget that cannot be widget-tested. It threw a
    // StateError the moment one tried.
    // UPPERCASE, and Space Mono like every other stamped label on the poster —
    // the design sets `text-transform:uppercase` on this header, so "THÁNG 8",
    // not "Tháng 8". Month name from `intl` in the app's language; the locale
    // comes from slang, NOT from the `parseString` helper, which reads
    // LocaleCubit out of AppDI and made this leaf widget impossible to
    // widget-test (it threw a StateError).
    final month = df.DateFormat('MMMM', LocaleSettings.currentLocale.languageCode)
        .format(anchor)
        .toUpperCase();

    // The artwork keeps the card's chrome — chevrons, divider, seven empty
    // cells — so this is positioned onto it rather than flowed: a Column with
    // its own spacing would drift off the baked rows the moment a font scales.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Untracked and set solid, like every other stamped label on the
        // poster — the design gives this row `line-height:1` and no
        // letter-spacing at all. No colour: WeekRecapInkText owns it, along
        // with the poster-wide renderer-compensation stroke.
        final headerStyle = TextStyle(
          fontFamily: _kWeekRecapMonoFont,
          fontWeight: FontWeight.w700,
          fontSize: WeekRecapSlots.calendarHeaderFontSize * scale,
          height: WeekRecapSlots.lineHeightSolid,
        );

        return Stack(
          children: [
            // Month + year, on the baked chevron row.
            Positioned(
              left: w * WeekRecapSlots.calHeaderInsetX,
              right: w * WeekRecapSlots.calHeaderInsetX,
              top: h * WeekRecapSlots.calHeaderTop,
              height: h * WeekRecapSlots.calHeaderHeight,
              child: Row(
                children: [
                  WeekRecapInkText(
                    month,
                    style: headerStyle,
                    color: AppCustomColor.weekRecapDarkInk,
                    scale: scale,
                  ),
                  const Spacer(),
                  WeekRecapInkText(
                    '${anchor.year}',
                    style: headerStyle,
                    color: AppCustomColor.weekRecapDarkInk,
                    scale: scale,
                  ),
                ],
              ),
            ),
            // Weekday initials, between the baked divider and the cell boxes.
            Positioned(
              left: w * WeekRecapSlots.calCellsInsetLeft,
              right: w * WeekRecapSlots.calCellsInsetRight,
              top: h * WeekRecapSlots.calWeekdayTop,
              height: h * WeekRecapSlots.calWeekdayHeight,
              child: Row(
                children: List.generate(WeekRecapSlots.weekDays, (index) {
                  return Expanded(
                    child: Center(
                      child: WeekRecapInkText(
                        index < weekdays.length ? weekdays[index].trim() : '',
                        style: TextStyle(
                          fontFamily: _kWeekRecapMonoFont,
                          fontWeight: FontWeight.w700,
                          fontSize: WeekRecapSlots.calendarWeekdayFontSize * scale,
                          height: WeekRecapSlots.lineHeightSolid,
                        ),
                        color: AppCustomColor.weekRecapCalendarMuted,
                        scale: scale,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Date numbers, at the feet of the baked cells — the mood chips
            // overlay the cells' upper half, so both stay visible.
            Positioned(
              left: w * WeekRecapSlots.calCellsInsetLeft,
              right: w * WeekRecapSlots.calCellsInsetRight,
              top: h * WeekRecapSlots.calDateTop,
              height: h * WeekRecapSlots.calDateHeight,
              child: Row(
                children: List.generate(WeekRecapSlots.weekDays, (index) {
                  final day = index < days.length ? days[index] : null;

                  return Expanded(
                    child: Center(
                      child: WeekRecapInkText(
                        day == null ? '' : '${day.date.day}',
                        style: TextStyle(
                          fontFamily: _kWeekRecapMonoFont,
                          fontWeight: FontWeight.w700,
                          fontSize: WeekRecapSlots.calendarDateFontSize * scale,
                          height: WeekRecapSlots.lineHeightSolid,
                        ),
                        color: AppCustomColor.weekRecapDarkInk,
                        scale: scale,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One mood chip: a tinted square with a face, laid over its date cell.
///
/// Drawn as a face rather than only a colour so the three levels survive a
/// colour-blind reader and a greyscale screenshot — the poster is made to be
/// shared, and it will be looked at outside the app.
class WeekRecapMoodChip extends StatelessWidget {
  const WeekRecapMoodChip({super.key, required this.mood, required this.size});

  final WeekRecapMood mood;
  final double size;

  Color get _background => switch (mood) {
    WeekRecapMood.good => AppCustomColor.weekRecapMoodGood,
    WeekRecapMood.ok => AppCustomColor.weekRecapMoodOk,
    WeekRecapMood.low => AppCustomColor.weekRecapMoodLow,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: CustomPaint(painter: _MoodFacePainter(mood)),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  const _MoodFacePainter(this.mood);

  final WeekRecapMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final stroke = Paint()
      ..color = AppCustomColor.weekRecapMoodInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * unit
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = AppCustomColor.weekRecapMoodInk;

    canvas.drawCircle(Offset(9 * unit, 10 * unit), 1.3 * unit, fill);
    canvas.drawCircle(Offset(15 * unit, 10 * unit), 1.3 * unit, fill);

    final mouth = ui.Path();
    switch (mood) {
      case WeekRecapMood.good:
        mouth.moveTo(8.5 * unit, 13.6 * unit);
        mouth.cubicTo(
          9.5 * unit,
          14.9 * unit,
          10.6 * unit,
          15.4 * unit,
          12 * unit,
          15.4 * unit,
        );
        mouth.cubicTo(
          13.4 * unit,
          15.4 * unit,
          14.5 * unit,
          14.9 * unit,
          15.5 * unit,
          13.6 * unit,
        );
      case WeekRecapMood.ok:
        mouth.moveTo(8.7 * unit, 14.2 * unit);
        mouth.lineTo(15.3 * unit, 14.2 * unit);
      case WeekRecapMood.low:
        mouth.moveTo(8.5 * unit, 15.2 * unit);
        mouth.cubicTo(
          9.5 * unit,
          13.9 * unit,
          10.6 * unit,
          13.4 * unit,
          12 * unit,
          13.4 * unit,
        );
        mouth.cubicTo(
          13.4 * unit,
          13.4 * unit,
          14.5 * unit,
          13.9 * unit,
          15.5 * unit,
          15.2 * unit,
        );
    }
    canvas.drawPath(mouth, stroke);
  }

  @override
  bool shouldRepaint(_MoodFacePainter oldDelegate) => oldDelegate.mood != mood;
}
