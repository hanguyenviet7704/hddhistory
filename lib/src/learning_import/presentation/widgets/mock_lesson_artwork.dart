part of '../../learning_import.dart';

/// **MOCK ARTWORK — TEMPORARY. Delete this file when covers become real.**
///
/// A generated lesson has no picture. The import job produces text; nothing in
/// the pipeline draws, picks or fetches an image, and `user_lessons` has no
/// field to keep one in. Left as-is, every surface that shows these lessons —
/// the My Creations list, the lesson's roadmap — was a column of titles next to
/// empty squares, visibly poorer than the catalogue screens they are modelled
/// on, for a reason that has nothing to do with the lesson's quality.
///
/// So these are stand-ins: real course artwork, bundled, assigned by id. They
/// are **not** the lesson's own art and will show the same handful of pictures
/// across unrelated lessons.
///
/// Two honest ways out, either of which makes this file go away:
/// 1. generate a cover during the import job and store it on `user_lessons`, or
/// 2. use the seeded stand-in tile the course grid draws (`CoverArt`), which
///    derives a stable colour and initial from an id and never pretends to be
///    a photograph of anything.

/// The roadmap header's cover.
const String kMockUserLessonCourseCover =
    'assets/images/app/mock_user_lesson_course.png';

/// Per-row / per-node covers.
const List<String> kMockUserLessonCovers = [
  'assets/images/app/mock_user_lesson_1.png',
  'assets/images/app/mock_user_lesson_2.png',
  'assets/images/app/mock_user_lesson_3.png',
];

/// A stable pick for [id].
///
/// Hashed rather than taken by list position: a lesson must keep the same
/// picture when the list is re-sorted, another lesson is deleted, or the app is
/// reopened — art that reshuffles under the reader is worse than no art.
String mockUserLessonCover(String id) {
  if (id.isEmpty) return kMockUserLessonCovers.first;

  final hash = id.codeUnits.fold<int>(0, (sum, unit) => (sum + unit) & 0xFFFF);

  return kMockUserLessonCovers[hash % kMockUserLessonCovers.length];
}
