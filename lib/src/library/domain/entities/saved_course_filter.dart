part of '../../library.dart';

/// The three chips on the Saved screen (design `5b · Library` → "Saved").
///
/// The bucket is computed server-side from the reader's progress, so a saved
/// course moves between chips as they study it — nothing is stored on the
/// bookmark itself.
enum SavedCourseFilter {
  /// Saved but never opened.
  upNext('up_next'),
  inProgress('in_progress'),
  finished('finished');

  const SavedCourseFilter(this.query);

  /// The `status` query value the API expects.
  final String query;
}
