part of '../../learning_import.dart';

/// **FALLBACK ARTWORK** — the pictures a generated lesson shows when the server
/// dealt it none.
///
/// Covers are real now (2026-08-13): the API deals every new lesson a
/// `coverUrl` (and each keypoint a node thumbnail) from admin-uploaded pools —
/// see the "Kho ảnh bài tự tạo" panel on the admin's User-imports page. These
/// bundled assets remain for the two cases the pool cannot cover: lessons
/// created before it existed, and a pool the admin has emptied. So this file
/// stays, demoted from stand-in to safety net; [userLessonCoverArt] and
/// [userLessonKeypointArt] are the only places that decide which kind wins.

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

/// The lesson's REAL cover when the server dealt one from the admin pool,
/// else the bundled mock. The result feeds [DCachedImage], which renders
/// http urls and asset paths alike — so a caller never branches on which
/// kind it got.
String userLessonCoverArt(UserLessonEntity lesson) =>
    lesson.coverUrl.isNotEmpty ? lesson.coverUrl : mockUserLessonCover(lesson.id);

/// Keypoint node [index]'s art: the server-dealt thumbnail when the keypoint
/// exists and carries one, else the mock rotation the roadmap always drew.
String userLessonKeypointArt(UserLessonEntity lesson, int index) {
  if (index < lesson.keypoints.length) {
    final coverUrl = lesson.keypoints[index].coverUrl;
    if (coverUrl.isNotEmpty) return coverUrl;
  }

  return kMockUserLessonCovers[index % kMockUserLessonCovers.length];
}
