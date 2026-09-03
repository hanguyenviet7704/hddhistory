import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meup/meup.dart';

/// Renders the poster to `build/week_recap_poster.png` with the REAL display
/// faces loaded, so the title's geometry can be measured instead of eyeballed.
///
/// Why this exists: every other way of checking the title was unreliable. A
/// plain widget test substitutes a stub font, so it can only pin slot geometry —
/// it cannot see what Forward Serif's ascent or Billock's digit widths actually
/// do. Screenshotting the simulator can, but locating the poster inside a
/// screenshot needs the poster's frame, and reading that off the paper edges was
/// 98px out (the translucent header counts as "not white"), which showed up as a
/// uniform vertical error in every slot. Here the poster IS the image, so its
/// box is exact.
///
/// The title constants in WeekRecapSlots were solved against the original
/// artwork — Birthday (4).png, the export whose title was still baked in. Its
/// ink, as fractions of the poster:
///
///   word   "Tuần"  x 0.298..0.559   y 0.061..0.119   stem 0.00926
///   number "01"    x 0.599..0.704   y 0.065..0.111   stem 0.00988
///
/// Re-measure this PNG against those numbers after touching the title.
void main() {
  const out = 'build/week_recap_poster.png';
  const fonts = {
    'Forward Serif': 'assets/fonts/ForwardSerif/ForwardSerif-Bold.otf',
    'Billock': 'assets/fonts/Billock/Billock-Regular.ttf',
    'Lumios Marker': 'assets/fonts/LumiosMarker/SVN-LumiosMarker.otf',
    'MTD Adventures': 'assets/fonts/MTDAdventures/MTDAdventures-Regular.otf',
    'Space Mono': 'assets/fonts/SpaceMono/SpaceMono-Regular.ttf',
  };

  setUpAll(() async {
    initializeDateFormatting();
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key);
      try {
        loader.addFont(rootBundle.load(entry.value));
        await loader.load();
      } catch (e) {
        // A missing face is worth saying out loud: the render would silently
        // fall back and every measurement taken from it would be wrong.
        // ignore: avoid_print
        print('WARN could not load ${entry.key} from ${entry.value}: $e');
      }
    }
  });

  testWidgets('renders the poster with the real display faces', (tester) async {
    LocaleSettings.setLocaleRaw('vi');
    final key = GlobalKey();
    final monday = DateTime(2026, 8, 10);
    final recap = WeekRecapEntity(
      id: 'w1',
      weekNumber: 1,
      weekStart: monday,
      weekEnd: monday.add(const Duration(days: 6)),
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('vi'),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 350,
                  height: 350 / (1080 / 1920),
                  child: WeekRecapPoster(recap: recap),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(out)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());

    expect(File(out).lengthSync(), greaterThan(0));
  });
}
