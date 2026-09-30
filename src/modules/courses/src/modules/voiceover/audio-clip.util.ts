import { createHash } from 'crypto';

/**
 * Which of a keypoint's four audio artefacts a clip is.
 *
 * `card` narrates one theory card, `whole` the whole keypoint as one file
 * (what app builds released before per-card narration play), `nextup` the
 * spoken "Tiếp theo: …" line, and `merged` the concatenation the app streams
 * with its cue map.
 */
export type AudioClipKind = 'card' | 'whole' | 'nextup' | 'merged';

export const AUDIO_CLIP_KINDS: AudioClipKind[] = [
  'card',
  'whole',
  'nextup',
  'merged',
];

/**
 * sha256 of the narrated text.
 *
 * Byte-identical to what the dub path has always written into `audio.hash` and
 * `audio.segmentHash` — deliberately, so `backfill-audio-clips` can reuse the
 * hashes already on every keypoint instead of re-deriving text for 433
 * keypoints × 5 languages, and so a clip inserted by the backfill answers the
 * same lookup as one inserted by a fresh dub.
 *
 * The narrator is NOT part of it: it is stored beside the hash instead (see
 * [clipFileToken]), which is also how the existing dub path tracks it.
 */
export const clipTextHash = (text: string): string =>
  createHash('sha256').update(text).digest('hex');

/**
 * The part of an R2 key that makes the object immutable.
 *
 * Every voiceover key used to be a pure function of keypoint + language
 * (+ card index), so a re-dub PUT straight over the bytes an older tag was
 * still pointing at — `?v=<hash>` on the url only ever fooled caches, it never
 * selected a version in the bucket. Putting the token IN THE KEY is what makes
 * "a tag freezes its audio" true rather than nominal.
 *
 * Covers the narrator as well as the text: the same sentence read by a
 * different voice is a different recording and must not land on the same key.
 */
export const clipFileToken = (textHash: string, voice: string): string =>
  createHash('sha256')
    .update(`${textHash}|${voice ?? ''}`)
    .digest('hex')
    .slice(0, 12);

/**
 * Where one clip's bytes live.
 *
 * `index` is carried in the card key for browsability only — it is NOT part of
 * a clip's identity (see `KeypointAudioClip`), so the same text re-used at a
 * different position resolves to the clip already stored rather than being
 * dubbed again at a second key.
 */
export const clipObjectKey = (
  keypointId: string,
  lang: string,
  kind: AudioClipKind,
  token: string,
  index = 0,
): string => {
  const base = `voiceover/${keypointId}`;
  switch (kind) {
    case 'card':
      return `${base}/${lang}/${index}-${token}.mp3`;
    case 'whole':
      return `${base}/${lang}-${token}.mp3`;
    case 'nextup':
      return `${base}/${lang}-nextup-${token}.mp3`;
    case 'merged':
      return `${base}/${lang}/merged-${token}.mp3`;
  }
};

/** The lookup key a clip is identified by. Index is deliberately absent. */
export interface AudioClipRef {
  keypointId: string;
  lang: string;
  kind: AudioClipKind;
  textHash: string;
}

/** Map key for an in-memory index of clips, matching [AudioClipRef]. */
export const clipRefKey = (ref: AudioClipRef): string =>
  `${ref.keypointId}|${ref.lang}|${ref.kind}|${ref.textHash}`;

/** A clip row as it is stored, before ids and timestamps. */
export interface AudioClipRow {
  keypointId: string;
  lang: string;
  kind: AudioClipKind;
  textHash: string;
  url: string;
  voice: string;
  index: number;
  durationMs?: number | null;
  cues?: unknown[];
}

/**
 * Read a keypoint's existing `audio` sub-document as clip rows.
 *
 * The backfill's whole job, and the reason it needs no file copying: the hashes
 * and urls are already there, and from the release that put the text token in
 * the R2 key nothing writes to the old un-hashed keys any more, so their bytes
 * are frozen for good.
 *
 * A url with no hash beside it is SKIPPED rather than guessed: a recording whose
 * text is unknown can never be matched to a tag, and inventing a hash for it
 * would make the store answer confidently with the wrong audio.
 */
export const clipRowsFromKeypointAudio = (
  keypointId: string,
  audio: Record<string, any> | undefined | null,
): AudioClipRow[] => {
  if (!audio) return [];

  const voices: Record<string, string> = audio.voices ?? {};
  const legacyVoice: string = audio.voice ?? '';
  const rows: AudioClipRow[] = [];

  const push = (
    lang: string,
    kind: AudioClipKind,
    textHash: unknown,
    url: unknown,
    extra: Partial<AudioClipRow> = {},
  ) => {
    if (typeof url !== 'string' || !url) return;
    if (typeof textHash !== 'string' || !textHash) return;
    rows.push({
      keypointId,
      lang,
      kind,
      textHash,
      url,
      voice: voices[lang] ?? legacyVoice,
      index: -1,
      ...extra,
    });
  };

  // Every language this keypoint has ANY audio for — not a fixed list, so one
  // dubbed before a locale existed contributes exactly what it has.
  const langs = new Set<string>([
    ...Object.keys(audio.segments ?? {}),
    ...Object.keys(audio.url ?? {}),
    ...Object.keys(audio.nextUp ?? {}),
    ...Object.keys(audio.merged ?? {}),
  ]);

  for (const lang of langs) {
    const segments: string[] = audio.segments?.[lang] ?? [];
    const segmentHashes: string[] = audio.segmentHash?.[lang] ?? [];
    segments.forEach((url, index) =>
      push(lang, 'card', segmentHashes[index], url, { index }),
    );

    push(lang, 'whole', audio.hash?.[lang], audio.url?.[lang]);
    push(lang, 'nextup', audio.nextUpHash?.[lang], audio.nextUp?.[lang]);

    const merged = audio.merged?.[lang];
    push(lang, 'merged', merged?.hash, merged?.url, {
      durationMs: merged?.durationMs ?? null,
      cues: merged?.cues ?? [],
    });
  }

  return rows;
};
