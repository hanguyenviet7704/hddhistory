part of '../../lesson.dart';

/// A stretch of narrated copy carrying the inline emphasis it was authored
/// with. Produced by [KeypointRichText.runs].
class KeypointTextRun {
  const KeypointTextRun({required this.text, required this.bold, required this.italic});

  final String text;
  final bool bold;
  final bool italic;
}

/// Turns the CMS's lightly-marked-up theory copy (`<b>`, `<i>`, `<br>`, `<p>`,
/// HTML entities) into either plain text or styled runs.
///
/// Both sides of the reading highlight go through here on purpose: the timing
/// estimate counts characters of [plainText], and the renderer lays out
/// [runs] whose concatenated text is byte-identical to that same plain text.
/// If only one side stripped markup, sentence indices would refer to different
/// strings and the highlight would land on the wrong words.
///
/// Deliberately not `flutter_widget_from_html_core` (already a dependency):
/// that renders its own widget subtree, which leaves no way to paint a
/// highlight across an arbitrary character range inside a paragraph.
abstract final class KeypointRichText {
  static final _tagPattern = RegExp(r'<[^>]*>');

  /// Tags that end the current line rather than contributing text.
  static bool _isBreak(String tag) {
    return tag.startsWith('<br') ||
        tag.startsWith('</p') ||
        tag.startsWith('</div') ||
        tag.startsWith('</li') ||
        tag.startsWith('</h');
  }

  static bool _opensBold(String tag) => tag == '<b>' || tag.startsWith('<b ') || tag.startsWith('<strong');
  static bool _closesBold(String tag) => tag == '</b>' || tag.startsWith('</strong');
  static bool _opensItalic(String tag) => tag == '<i>' || tag.startsWith('<i ') || tag.startsWith('<em');
  static bool _closesItalic(String tag) => tag == '</i>' || tag.startsWith('</em');

  static String _decodeEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  /// Splits [source] into emphasis runs. Content with no markup at all comes
  /// back as a single unstyled run, so callers never need to special-case it.
  static List<KeypointTextRun> runs(String source) {
    final result = <KeypointTextRun>[];
    var boldDepth = 0;
    var italicDepth = 0;
    var cursor = 0;

    void addText(String text) {
      if (text.isEmpty) return;
      result.add(KeypointTextRun(text: text, bold: boldDepth > 0, italic: italicDepth > 0));
    }

    for (final match in _tagPattern.allMatches(source)) {
      if (match.start > cursor) addText(_decodeEntities(source.substring(cursor, match.start)));
      cursor = match.end;

      final tag = match.group(0)!.toLowerCase();
      if (_isBreak(tag)) {
        addText('\n');
      } else if (_opensBold(tag)) {
        boldDepth++;
      } else if (_closesBold(tag)) {
        boldDepth = math.max(0, boldDepth - 1);
      } else if (_opensItalic(tag)) {
        italicDepth++;
      } else if (_closesItalic(tag)) {
        italicDepth = math.max(0, italicDepth - 1);
      }
    }
    if (cursor < source.length) addText(_decodeEntities(source.substring(cursor)));

    return _collapseBlankLines(result);
  }

  /// `<br><br>` (and `</p><p>`) are how the CMS spaces paragraphs; keep at most
  /// one blank line so a card doesn't open with a gap.
  static List<KeypointTextRun> _collapseBlankLines(List<KeypointTextRun> input) {
    final text = input.map((run) => run.text).join();
    if (!text.contains('\n\n\n')) return input;
    // Rare enough that rebuilding is cheaper than tracking state above.
    final collapsed = <KeypointTextRun>[];
    var newlineStreak = 0;
    for (final run in input) {
      if (run.text == '\n') {
        newlineStreak++;
        if (newlineStreak > 2) continue;
      } else {
        newlineStreak = 0;
      }
      collapsed.add(run);
    }
    return collapsed;
  }

  /// The narrated text with all markup removed — what a TTS voice would read,
  /// and the string sentence indices are computed against.
  static String plainText(String source) => runs(source).map((run) => run.text).join();
}
