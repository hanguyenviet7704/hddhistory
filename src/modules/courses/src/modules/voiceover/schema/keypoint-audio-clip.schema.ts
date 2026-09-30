import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IMergedAudioCue } from '../../keypoint/interface/keypoint.interface';
import { AudioClipKind } from '../audio-clip.util';

/**
 * One recording, addressed by the TEXT it narrates instead of by the place it
 * happens to sit.
 *
 * This is what makes audio survive content versioning. `published_content`
 * freezes a tag's text; a clip is matched to it by hashing that tag's own text
 * and looking the hash up here, so:
 *
 * - dubbing once serves EVERY tag whose text is identical — which is exactly
 *   "the theory didn't change, so it doesn't need re-dubbing", with no rule
 *   written anywhere to say so;
 * - a tag whose text did change simply finds nothing and reads as missing,
 *   rather than silently playing the other version's narration.
 *
 * Rows are **never updated**. A re-dub of text that already has a clip is a
 * no-op; a different narrator is a different row (see the unique index).
 */
@Schema({ collection: 'keypoint_audio_clips' })
export class KeypointAudioClip extends AbstractDocument {
  @Prop({ required: true })
  keypointId: string;

  @Prop({ required: true })
  lang: string;

  @Prop({ required: true, type: String })
  kind: AudioClipKind;

  /**
   * sha256 of the narrated text for `card`/`whole`/`nextup`; for `merged` it
   * is `computeMergeHash`'s own composite (narrator + the theory slots' hashes),
   * because a concatenation has no text of its own.
   */
  @Prop({ required: true })
  textHash: string;

  @Prop({ required: true })
  url: string;

  @Prop({ type: Number, default: null })
  durationMs?: number | null;

  /** Only on `merged` — the card cue map the app scrubs with. */
  @Prop({ type: SchemaTypes.Array, default: undefined })
  cues?: IMergedAudioCue[];

  @Prop({ type: String, default: '' })
  voice: string;

  /**
   * Where the card sat when this clip was first dubbed. Provenance only — it
   * is deliberately NOT part of a clip's identity, so a tag that moves an
   * unchanged card still finds its recording.
   */
  @Prop({ type: Number, default: -1 })
  index: number;
}

export const KeypointAudioClipSchema =
  SchemaFactory.createForClass(KeypointAudioClip);

/**
 * Identity. `voice` is part of it so switching narrator adds a recording
 * rather than being refused — resolution then prefers the newest, which is how
 * a narrator change reaches every tag at once.
 */
KeypointAudioClipSchema.index(
  { keypointId: 1, lang: 1, kind: 1, textHash: 1, voice: 1 },
  { unique: true },
);

// The serve path: every clip of the keypoints in one batch, one query.
KeypointAudioClipSchema.index({ keypointId: 1, lang: 1 });
