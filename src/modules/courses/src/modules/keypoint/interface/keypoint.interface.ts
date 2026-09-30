import { ITranslation } from '@utils/interface/common.interface';

export interface IMergedAudioCue {
  learningItemId: string;
  documentIndex: number;
  startMs: number;
  /** 0 for a theory card with no narratable text (image-only). */
  durMs: number;
}

/// The keypoint's theory narration as ONE concatenated file per language,
/// plus the cue map that tells the app where each card starts. Cues carry
/// card IDENTITY (learningItemId + documentIndex), never a positional index —
/// this is what frees the app from mirroring `buildSegments`' numbering.
export interface IMergedKeypointAudio {
  url: string;
  durationMs: number;
  /** computeMergeHash() over voice + theory-slot segment hashes — merge is
   *  skipped when unchanged. */
  hash: string;
  cues: IMergedAudioCue[];
}

export interface IKeypointAudio {
  /// The keypoint dubbed as ONE file — what app builds released before per-card
  /// narration play, and what `hasUsableAudio` keys off. Still generated
  /// alongside [segments] so those builds keep hearing the whole keypoint;
  /// droppable once no released build reads it.
  url?: ITranslation;
  text?: ITranslation;

  /// Per-CARD clips keyed by language: `segments[lang][i]` narrates card `i`
  /// (`''` for a card with no narratable text, so indexes stay aligned with the
  /// app's cards). The app loads only the current card's clip, which is why
  /// narration lands exactly on the page being read.
  segments?: Record<string, string[]>;

  /// Per-card text hashes parallel to [segments] — lets one edited card be
  /// re-dubbed without re-synthesising the whole keypoint.
  segmentHash?: Record<string, string[]>;

  /// The spoken "Tiếp theo: <tên keypoint>" line per language — played by the
  /// app between two keypoints when background listening chains into this one.
  /// Hash-guarded like everything else so a rerun only re-synthesises after a
  /// title (or narrator) change.
  nextUp?: ITranslation;
  nextUpHash?: Record<string, string>;

  /// Narrator the audio was synthesised with ('female' | 'male'), chosen by an
  /// admin at generation time. Persisted next to the audio so a later
  /// regeneration keeps the same narrator unless one is explicitly picked, and
  /// so switching narrator forces a re-synthesis even when the text is
  /// unchanged.
  voice?: string;

  /// One merged theory-narration file per language — see IMergedKeypointAudio.
  merged?: Record<string, IMergedKeypointAudio>;
}

export interface IKeypoint {
  title: ITranslation;
  description?: ITranslation;
  audio?: IKeypointAudio;
  estimateCompleTime?: ITranslation;
  estimateCompleTimeNumber?: number;
  tag: string[];
  image: string;
  index: number;
  learningItems?: any;
}

export interface IKeypointBrief {
  _id: string;
  title?: ITranslation;
  description?: ITranslation;
  estimateCompleTime?: ITranslation;
  estimateCompleTimeNumber?: number;
}
