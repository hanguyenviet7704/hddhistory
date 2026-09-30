/**
 * Which shade of a habit's short situation to use.
 *
 * A variant is a cache key, not a prompt template: the same habit asked of
 * someone who just succeeded should not read like the one asked of someone who
 * watched the moment pass. Keeping them as separate cached rows is what lets ⑤
 * "ĐỔI THAY" compare like with like — the same `situationId` three weeks apart.
 */
export enum CoachSituationVariant {
  /** ① end of lesson, and ② short/medium scripts. */
  DEFAULT = 'default',
  /**
   * RETIRED as a cache key (2026-08-26) and replaced by a second TELLING of the
   * same scene (2026-08-27): `promptThirdPerson` on the row itself.
   *
   * The doc is explicit about why it must be the same row — "cùng một
   * tinh_huong_id, chỉ khác cách kể; đổi biến thể KHÔNG đổi nội dung cảnh, đổi
   * thì mất khả năng đối chiếu về sau". A separate row would have broken the
   * pairing the recap compares. Kept in the enum only so old rows still parse.
   */
  THIRD_PERSON = 'third_person',
  /** ③A after "I did it". */
  AFTER_DONE = 'after_done',
  /** ③A after "the occasion came and I didn't". */
  AFTER_MISSED = 'after_missed',
  /** ③A after "no occasion yet". */
  AFTER_NONE = 'after_none',
  /** ② "just practise, no conversation". */
  PRACTICE = 'practice',
}

/**
 * Which corner of life a scene is set in — the doc's `nhom_boi_canh`.
 *
 * Replaces age band + learning goal as the thing that decides WHICH scene a
 * reader meets. The reason is in the doc: nobody is asked their job or their
 * age, so the group is inferred from words they already wrote — the `boi_canh`
 * they typed into a reminder ("khi họp nhóm" → công việc), the sentence they
 * told about a real time, the story in this session. A new reader with no words
 * yet gets NEUTRAL, which is written to fit anybody.
 */
export enum CoachSituationContextGroup {
  WORK = 'cong_viec',
  FAMILY = 'gia_dinh',
  FRIENDS = 'ban_be',
  STUDY = 'hoc_tap',
  SERVICE = 'dich_vu',
  NEUTRAL = 'trung_tinh',
}

export enum CoachSituationSource {
  /** Written by the model on first use and cached. */
  GENERATED = 'generated',
  /** An editor rewrote it in admin. Never regenerated over. */
  EDITED = 'edited',
}
