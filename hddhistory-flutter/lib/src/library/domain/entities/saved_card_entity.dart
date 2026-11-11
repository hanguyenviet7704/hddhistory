part of '../../library.dart';

/// One saved recap card — the quote card the reader kept from the end of a
/// keypoint (design `5b · Library` → "Saved cards").
///
/// The card has two faces, and they come from different places:
/// - the FRONT is catalogue data ([title], [image], [courseTitle]), re-read on
///   every request so it follows the reader's app language;
/// - the BACK is [recapText], a snapshot taken when they pressed save.
///
/// The back has to be a snapshot: the recap is not a stored field on the
/// keypoint, the app derives it from the lesson's trailing theory item
/// (`resolveTakeawaySummary`). Re-deriving it server-side would be a second
/// implementation of that heuristic, free to drift from the text actually saved.
@freezed
abstract class SavedCardEntity with _$SavedCardEntity {
  const factory SavedCardEntity({
    @Default('') String id,
    @Default('') String keypointId,
    @Default('') String lessonId,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,

    /// The keypoint's own description — the multi-language fallback for the
    /// back face when the lesson had no takeaway item to snapshot.
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,

    /// Recap ở cả năm ngôn ngữ — ảnh chụp lúc lưu, nhưng chụp ĐỦ tiếng, nên
    /// thẻ vẫn đi theo ngôn ngữ app về sau.
    @Default(BaseMultiLanguage()) BaseMultiLanguage recap,

    /// Thẻ lưu TRƯỚC khi [recap] tồn tại: một chuỗi, đúng thứ tiếng đang bật
    /// hôm đó. Giữ lại để những thẻ ấy không thành trống trơn; thẻ lưu mới
    /// luôn có [recap] nên không rơi vào nhánh này.
    @Default('') String recapText,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
  }) = _SavedCardEntity;
}

extension SavedCardEntityX on SavedCardEntity {
  /// What the back face reads. Same precedence the recap card itself uses, so a
  /// card in the Library says exactly what it said at the end of the lesson.
  ///
  /// [recap] trước [recapText]: thẻ mới có đủ năm tiếng nên đi theo ngôn ngữ
  /// app, thẻ cũ chỉ có chuỗi một tiếng và vẫn hiện đúng như trước.
  String get backText {
    final multi = recap.text.trim();
    if (multi.isNotEmpty) return multi;
    if (recapText.isNotEmpty) return recapText;

    return description.text.trim();
  }

  /// Never empty on screen: a keypoint with no title of its own still has to
  /// name itself on a card that is mostly title.
  String get displayTitle => title.text.isNotEmpty ? title.text : courseTitle.text;

  /// A card with nothing on its back is still worth keeping (the front is the
  /// quote), but the deck must not offer a flip that reveals blank.
  bool get canFlip => backText.isNotEmpty;
}
