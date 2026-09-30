import { Injectable } from '@nestjs/common';

import { VOICEOVER_LANGS } from '../voiceover/tts.service';
import {
  AudioClipKind,
  clipRefKey,
  clipTextHash,
} from '../voiceover/audio-clip.util';
import {
  buildNarrationSegments,
  buildNarrationText,
} from '../voiceover/narration-text.util';
import { computeMergeHash, computeTheoryCueSlots } from '../voiceover/voiceover-merge.util';
import { KeypointAudioClipRepository } from '../voiceover/repository/keypoint-audio-clip.repository';
import { KeypointAudioClip } from '../voiceover/schema/keypoint-audio-clip.schema';

type Doc = Record<string, any>;

/** What a keypoint's audio looks like once resolved — the app's own shape. */
interface ResolvedAudio {
  url: Record<string, string>;
  segments: Record<string, string[]>;
  segmentHash: Record<string, string[]>;
  nextUp: Record<string, string>;
  merged: Record<string, unknown>;
}

/**
 * Fills a tagged keypoint's `audio` from the content-addressed clip store.
 *
 * A tag freezes text. Audio is matched to it by hashing THAT TAG's text and
 * looking the hash up, which is what makes one dub serve every tag whose text
 * is identical — and makes a tag whose text changed read as having no audio
 * rather than quietly playing another version's narration.
 *
 * The keypoint document frozen in the tag carries its own `audio` (whatever
 * existed the day it was tagged); that copy is DISCARDED here. Trusting it is
 * the bug this service exists to fix: those urls point at the text of the day
 * the tag was cut, and a later re-dub of the same keypoint used to rewrite the
 * bytes underneath them.
 *
 * See `plans/260916-audio-theo-tag/README.md` section 3.
 */
@Injectable()
export class AudioResolver {
  constructor(private readonly clipRepository: KeypointAudioClipRepository) {}

  /**
   * Resolved audio, keyed by `versionId|keypointId`.
   *
   * A tag is immutable, so a hit can only go stale when someone dubs the
   * missing half of a tag that is already being read — hence a short TTL rather
   * than no expiry. Its real job is the roadmap: without it, every reader of
   * the same tag would re-load that course's entire learning-item tree (five
   * languages of theory bodies) just to re-derive hashes that cannot have
   * changed.
   */
  private readonly cache = new Map<
    string,
    { at: number; audio: ResolvedAudio }
  >();

  private static readonly TTL_MS = 60_000;
  /** Bounded so a catalogue-wide crawl cannot grow this without limit. */
  private static readonly MAX_ENTRIES = 5_000;

  /**
   * Attach resolved audio to each keypoint doc, in place.
   *
   * `loadLearningItems` is lazy on purpose: when every keypoint is already
   * cached it is never called, and the learning-item read — the expensive half
   * of this — does not happen at all. It must return the items of the SAME
   * version as the keypoints; the working tree's items alongside a tag's
   * keypoints would hash today's text against yesterday's content and resolve
   * to the wrong clips.
   */
  async attach(
    keypoints: Doc[],
    versionId: string,
    loadLearningItems: () => Promise<Doc[]>,
  ): Promise<Doc[]> {
    if (!keypoints.length) return keypoints;

    const now = Date.now();
    const pending: Doc[] = [];
    for (const keypoint of keypoints) {
      const hit = this.cache.get(`${versionId}|${String(keypoint._id)}`);
      if (hit && now - hit.at < AudioResolver.TTL_MS) keypoint.audio = hit.audio;
      else pending.push(keypoint);
    }
    if (!pending.length) return keypoints;

    const ids = pending.map(keypoint => String(keypoint._id));
    const [clips, learningItems] = await Promise.all([
      this.clipRepository.findByKeypointIds(ids),
      loadLearningItems(),
    ]);

    // Oldest-first from the repository, so a later row (a re-dub, or a new
    // narrator) overwrites the earlier one and simply wins.
    const byRef = new Map<string, KeypointAudioClip>();
    const voicesOf = new Map<string, Set<string>>();
    // Which keypoints the store knows anything at all about — the rollout guard
    // below turns on exactly where it knows nothing.
    const known = new Set<string>();
    for (const clip of clips) {
      known.add(clip.keypointId);
      byRef.set(
        clipRefKey({
          keypointId: clip.keypointId,
          lang: clip.lang,
          kind: clip.kind,
          textHash: clip.textHash,
        }),
        clip,
      );
      // Keyed by keypoint alone, not by keypoint+language: the merge hash is
      // looked up per language but the candidate narrators are few, and a
      // per-language key here silently missed every merged file (the lookup
      // below has only the keypoint id).
      const voices = voicesOf.get(clip.keypointId) ?? new Set<string>();
      voices.add(clip.voice ?? '');
      voicesOf.set(clip.keypointId, voices);
    }

    const itemsByKeypoint = new Map<string, Doc[]>();
    for (const item of learningItems) {
      const key = String(item.keypointId ?? '');
      if (!key) continue;
      const bucket = itemsByKeypoint.get(key);
      if (bucket) bucket.push(item);
      else itemsByKeypoint.set(key, [item]);
    }

    for (const keypoint of pending) {
      const keypointId = String(keypoint._id);
      // Items must be walked in `index` order: the card numbering the hashes
      // depend on is positional, and `findAllOfType` returns insertion order.
      const items = (itemsByKeypoint.get(keypointId) ?? [])
        .slice()
        .sort((a, b) => (a.index ?? 0) - (b.index ?? 0));

      // ROLLOUT GUARD. A keypoint the store has never heard of is one the
      // backfill has not reached — on the day this ships, that is every
      // keypoint. Resolving it would return nothing and the tag would play in
      // silence, which is far worse than the stale-audio bug this replaces. So
      // where the store is empty, hand back what the tag froze: today's
      // behaviour, unchanged.
      //
      // Deliberately keyed on "no clips for this keypoint AT ALL", not on "no
      // clip for this text": the second would quietly restore the old bug for
      // every edited card.
      if (!known.has(keypointId)) {
        this.remember(`${versionId}|${keypointId}`, keypoint.audio, now);
        continue;
      }

      keypoint.audio = this.resolveOne(
        keypointId,
        items,
        byRef,
        voicesOf.get(keypointId) ?? new Set<string>(),
        keypoint.audio,
      );
      this.remember(`${versionId}|${keypointId}`, keypoint.audio, now);
    }

    return keypoints;
  }

  private remember(key: string, audio: ResolvedAudio, at: number): void {
    // Oldest-inserted first out — Map preserves insertion order, which is all
    // the eviction this needs.
    if (this.cache.size >= AudioResolver.MAX_ENTRIES) {
      const oldest = this.cache.keys().next().value;
      if (oldest !== undefined) this.cache.delete(oldest);
    }
    this.cache.set(key, { at, audio });
  }

  private resolveOne(
    keypointId: string,
    items: Doc[],
    byRef: Map<string, KeypointAudioClip>,
    voices: Set<string>,
    frozenAudio: Doc | undefined,
  ): ResolvedAudio {
    const resolved: ResolvedAudio = {
      url: {},
      segments: {},
      segmentHash: {},
      nextUp: {},
      merged: {},
    };

    const find = (lang: string, kind: AudioClipKind, textHash: string) =>
      byRef.get(clipRefKey({ keypointId, lang, kind, textHash }));

    const slots = computeTheoryCueSlots(items);

    for (const lang of VOICEOVER_LANGS) {
      const segmentTexts = buildNarrationSegments(items, lang);
      if (!segmentTexts.length) continue;

      const segmentHashes = segmentTexts.map(text =>
        text ? clipTextHash(text) : '',
      );
      // An empty string keeps index N meaning card N even when card N is
      // image-only or has no clip — the app reads this array positionally.
      const segmentUrls = segmentHashes.map((hash, index) =>
        hash && segmentTexts[index]
          ? find(lang, 'card', hash)?.url ?? ''
          : '',
      );
      if (segmentUrls.some(Boolean)) {
        resolved.segments[lang] = segmentUrls;
        resolved.segmentHash[lang] = segmentHashes;
      }

      const wholeText = buildNarrationText(items, lang);
      const wholeUrl = wholeText
        ? find(lang, 'whole', clipTextHash(wholeText))?.url
        : undefined;
      if (wholeUrl) resolved.url[lang] = wholeUrl;

      // `nextUp` narrates the NEXT keypoint's title, which this keypoint's own
      // content cannot produce. Its hash was frozen with the tag, so the tag is
      // the only thing that knows which line was recorded — the one place a
      // frozen field is still the right source.
      const nextUpHash = frozenAudio?.nextUpHash?.[lang];
      const nextUpUrl = nextUpHash
        ? find(lang, 'nextup', nextUpHash)?.url
        : undefined;
      if (nextUpUrl) resolved.nextUp[lang] = nextUpUrl;

      // The merge hash folds in the narrator, so it cannot be derived from text
      // alone. Every voice this keypoint has ever been dubbed with is tried —
      // there are one or two — and the newest match wins.
      for (const voice of voices) {
        const merged = find(
          lang,
          'merged',
          computeMergeHash(voice, slots, segmentHashes),
        );
        if (merged) {
          resolved.merged[lang] = {
            url: merged.url,
            durationMs: merged.durationMs ?? 0,
            hash: merged.textHash,
            cues: merged.cues ?? [],
          };
          break;
        }
      }
    }

    return resolved;
  }
}
