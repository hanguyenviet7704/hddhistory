part of '../../learning_import.dart';

/// Turns a generated lesson into the entities the CATALOGUE reader consumes.
///
/// This exists so an imported lesson gets the real reading experience instead of
/// an imitation of it. The first version of this feature shipped its own deck
/// screen — a copy of the catalogue's, minus everything the copy did not get
/// around to — and the two drifted the moment either changed.
///
/// The insight that made reuse possible: [LessonRoute] takes no ids. It renders
/// whatever [CourseLessonCubit] holds. So a lesson does not have to LIVE in the
/// catalogue to be read by the catalogue's screen; it only has to be shaped like
/// one by the time it reaches the cubit. Nothing here is written to a server and
/// none of these ids exist in any collection.
///
/// The shape it targets:
/// ```
/// UserLessonEntity        →  LessonEntity     (courseId: '')
///  └─ keypoint            →    KeypointEntity
///      └─ all its cards   →      ONE theory LearningItemEntity
///          └─ card        →        DocumentEntity
///              └─ block   →          ContentDocumentEntity
/// ```
///
/// One learning item per keypoint rather than one per card, because the reader
/// draws one card per DOCUMENT — so a keypoint's cards are the documents of a
/// single item, which is exactly how authored theory content is laid out too.
abstract final class UserLessonCourseMapper {
  /// Marks every id this mapper mints.
  ///
  /// Load-bearing rather than cosmetic: it is what
  /// [LessonEntityImportedX.isImported] reads, and therefore what keeps a
  /// generated lesson out of the roadmap, the progress writes and the Live
  /// Activity. A `::` cannot occur in a Mongo ObjectId, so no catalogue id can
  /// ever collide with one of these.
  static const String idMarker = '::user-lesson::';

  static LessonEntity toLesson(UserLessonEntity lesson) {
    return LessonEntity(
      id: '${lesson.id}$idMarker',
      // Empty ON PURPOSE, and checked for in several places: a generated lesson
      // belongs to no course, and `LessonCubit`'s Live Activity calls already
      // bail out on an empty courseId. Inventing one here would start a "Đang
      // học" card pointing at a course that does not exist.
      courseId: '',
      title: _multi(lesson.outputLocale, lesson.title),
      description: _multi(lesson.outputLocale, lesson.description),
      estimateCompleTimeNumber: lesson.estimatedMinutes,
      keypoints: [
        for (final (index, keypoint) in lesson.keypoints.indexed)
          _toKeypoint(lesson, keypoint, index),
      ],
    );
  }

  /// The learning items of ONE keypoint — what `LessonCubit` would otherwise
  /// have fetched from `courses-learning-items`.
  ///
  /// Returns a single-item list (or an empty one for a keypoint with no cards,
  /// which the reader already handles: its deck builds no cards and the done
  /// card owns completion).
  static List<LearningItemEntity> learningItemsOf(
    UserLessonEntity lesson,
    int keypointIndex,
  ) {
    if (keypointIndex < 0 || keypointIndex >= lesson.keypoints.length) {
      return const [];
    }
    final keypoint = lesson.keypoints[keypointIndex];
    if (keypoint.sections.isEmpty) return const [];

    return [
      LearningItemEntity(
        id: _itemId(lesson.id, keypointIndex),
        keypointId: _keypointId(lesson.id, keypointIndex),
        type: LearningItemType.theory,
        index: 0,
        title: _multi(lesson.outputLocale, keypoint.title),
        documents: [
          for (final (index, section) in keypoint.sections.indexed)
            _toDocument(lesson.outputLocale, section, index),
        ],
      ),
    ];
  }

  /// Index of the keypoint a synthesised id belongs to, or -1 for any id this
  /// mapper did not mint.
  static int keypointIndexOf(String keypointId) {
    if (!keypointId.contains(idMarker)) return -1;

    return int.tryParse(keypointId.split(idMarker).last) ?? -1;
  }

  /// The user-lesson id behind a synthesised lesson or keypoint id.
  static String lessonIdOf(String id) {
    if (!id.contains(idMarker)) return '';

    return id.split(idMarker).first;
  }

  static KeypointEntity _toKeypoint(
    UserLessonEntity lesson,
    LessonKeypointEntity keypoint,
    int index,
  ) {
    return KeypointEntity(
      id: _keypointId(lesson.id, index),
      title: _multi(lesson.outputLocale, keypoint.title),
      // The recap card that ends a keypoint flips to `description` when the
      // keypoint has no authored takeaway item — and a generated one never has
      // one. Leaving this empty is what made that card refuse to flip.
      description: _multi(lesson.outputLocale, keypoint.takeaway),
      index: index,
      audio: _toAudio(lesson, index),
    );
  }

  /// Narration in the catalogue's own shape.
  ///
  /// `segments` is left empty — the per-card clip path exists in the catalogue
  /// for historical reasons and a generated lesson has no history to be
  /// compatible with. The cue's `(learningItemId, documentIndex)` pair is
  /// synthesised from the same functions that built the item: the card index the
  /// server sent IS the document index, because one keypoint is one item.
  ///
  /// `url` carries the same file as `merged` rather than being left blank, and
  /// that is not redundancy. `LessonPage._syncAudioKeypoint` gates narration on
  /// `keypoint.hasUsableAudio`, which reads `url` and nothing else — filling
  /// only `merged` produced a keypoint the player would happily have read aloud
  /// and the page never asked it to. A dubbed catalogue keypoint carries both
  /// fields too, so this matches rather than works around it.
  ///
  /// Returns null when this keypoint was never dubbed, which the reader treats
  /// as an ordinary silent keypoint.
  static KeypointAudioEntity? _toAudio(UserLessonEntity lesson, int index) {
    final audio = lesson.audio?.forKeypoint(index);
    if (audio == null || audio.url.isEmpty) return null;

    final itemId = _itemId(lesson.id, index);

    return KeypointAudioEntity(
      url: _multi(lesson.outputLocale, audio.url),
      merged: {
        // Keyed by the lesson's own language. `resolvedMerged` falls back across
        // every locale, so a reader whose app is in another language still hears
        // it — which is right: there is only one narration to hear.
        lesson.outputLocale: MergedKeypointAudioEntity(
          url: audio.url,
          durationMs: audio.durationMs,
          cues: [
            for (final cue in audio.cues)
              MergedAudioCueEntity(
                learningItemId: itemId,
                documentIndex: cue.cardIndex,
                startMs: cue.startMs,
                durMs: cue.durMs,
              ),
          ],
        ),
      },
    );
  }

  /// One card as one document.
  ///
  /// The card's own heading becomes a `title` content block and the body becomes
  /// `text` blocks, which is exactly how authored theory documents are built —
  /// so the reader styles a generated card and an authored one identically,
  /// without a branch anywhere.
  static DocumentEntity _toDocument(
    String locale,
    LessonSectionEntity section,
    int index,
  ) {
    final contents = <ContentDocumentEntity>[
      if (section.title.isNotEmpty)
        ContentDocumentEntity(
          id: 0,
          type: ContentDocumentType.title,
          data: DocumentDataEntity(content: _multi(locale, section.title)),
        ),
      for (final (blockIndex, block) in section.blocks.indexed)
        ContentDocumentEntity(
          id: blockIndex + 1,
          type: block.type == LessonBlockTypeEntity.heading
              ? ContentDocumentType.title
              : ContentDocumentType.text,
          data: DocumentDataEntity(content: _multi(locale, block.text)),
        ),
    ];

    return DocumentEntity(id: index, document: contents);
  }

  static String _keypointId(String lessonId, int index) =>
      '$lessonId$idMarker$index';

  /// The learning item shares its keypoint's id shape with an `i` suffix, so an
  /// item id is traceable back to its keypoint by eye in a log line.
  static String _itemId(String lessonId, int index) =>
      '$lessonId$idMarker${index}i';

  /// A generated lesson exists in exactly ONE language, so only that slot is
  /// filled. `BaseMultiLanguage.text` falls back through every other locale, so
  /// a reader whose app is in a different language still sees the text rather
  /// than a blank.
  static BaseMultiLanguage _multi(String locale, String value) {
    return switch (locale) {
      'vi' => BaseMultiLanguage(vi: value),
      'zh' => BaseMultiLanguage(zh: value),
      'ja' => BaseMultiLanguage(ja: value),
      'ko' => BaseMultiLanguage(ko: value),
      _ => BaseMultiLanguage(en: value),
    };
  }
}

extension LessonEntityImportedX on LessonEntity {
  /// Whether this lesson was generated from the user's own material.
  ///
  /// Read at every fork where the catalogue would otherwise reach for something
  /// a generated lesson does not have — a roadmap to return to, a course to
  /// record progress against. Derived from the id rather than stored as a flag
  /// because the id is what survives every `copyWith` the reader performs.
  bool get isImported => id.contains(UserLessonCourseMapper.idMarker);
}
