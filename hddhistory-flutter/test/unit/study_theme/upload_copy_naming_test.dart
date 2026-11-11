import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The rule this guards: **a new upload must land on a new PATH.**
///
/// `FileImage`'s identity is its path, so reusing one fixed name meant the
/// second photo compared EQUAL to the one already on screen — `Image` never
/// re-resolved and `ImageCache` kept serving the first photo's bitmap until the
/// app was killed. The test works on the naming/pruning contract rather than on
/// `StudyThemeCubit` itself, because the cubit needs DI, hydrated storage and a
/// real documents directory to build.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('study-theme-upload'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Mirrors `StudyThemeCubit._persistUploadCopy` + `_pruneUploadCopies`.
  const prefix = 'study_theme_upload';
  File persist(File src, int stampMs) {
    final dot = src.path.lastIndexOf('.');
    final ext = dot >= 0 ? src.path.substring(dot) : '.img';
    final copy = src.copySync('${dir.path}/$prefix$stampMs$ext');
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (entity.path == copy.path) continue;
      if (!entity.uri.pathSegments.last.startsWith(prefix)) continue;
      entity.deleteSync();
    }
    return copy;
  }

  File source(String name, String content) =>
      File('${dir.path}/$name')..writeAsStringSync(content);

  test('a second upload gets a different path from the first', () {
    final first = persist(source('a.jpg', 'photo-1'), 1000);
    final second = persist(source('b.jpg', 'photo-2'), 2000);

    expect(second.path, isNot(first.path));
    expect(second.readAsStringSync(), 'photo-2');
  });

  test('the previous copy is pruned, so copies cannot pile up', () {
    persist(source('a.jpg', 'photo-1'), 1000);
    final second = persist(source('b.jpg', 'photo-2'), 2000);

    final copies = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith(prefix))
        .map((f) => f.path)
        .toList();
    expect(copies, [second.path]);
  });

  test('a legacy fixed-name copy is pruned too', () {
    // What a build before 2026-08-13 left behind.
    File('${dir.path}/$prefix.jpg').writeAsStringSync('legacy');

    final fresh = persist(source('b.jpg', 'photo-2'), 2000);

    expect(File('${dir.path}/$prefix.jpg').existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
  });

  test('keeps the extension so the decoder still recognises the file', () {
    expect(persist(source('a.png', 'x'), 1000).path, endsWith('.png'));
    // No extension on the source → a neutral one rather than none.
    expect(persist(source('noext', 'x'), 1001).path, endsWith('.img'));
  });
}
