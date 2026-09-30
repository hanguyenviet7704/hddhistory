import { Injectable, Logger } from '@nestjs/common';

import { runWithConcurrency } from '@utils/concurrency';
import { CloudflareService } from 'src/modules/file/cloudflare/cloudflare.service';

import {
  clipFileToken,
  clipObjectKey,
  clipRefKey,
  clipTextHash,
} from '../voiceover/audio-clip.util';
import { buildNarrationSegments } from '../voiceover/narration-text.util';
import { KeypointAudioClipRepository } from '../voiceover/repository/keypoint-audio-clip.repository';
import { KeypointAudioClip } from '../voiceover/schema/keypoint-audio-clip.schema';
import { TtsService, VOICEOVER_LANGS } from '../voiceover/tts.service';
import { VOICEOVER_CACHE_CONTROL } from '../voiceover/voiceover-merge.util';
import { PublishedContentRepository } from './repository/published-content.repository';

type Doc = Record<string, any>;

/** One card that a tag needs and nobody has recorded yet. */
interface MissingCard {
  keypointId: string;
  lang: string;
  index: number;
  text: string;
  textHash: string;
  voice: string;
}

export interface VersionDubSnapshot {
  state: 'idle' | 'running' | 'done';
  courseId: string | null;
  tag: string | null;
  total: number;
  done: number;
  failed: number;
  startedAt?: string;
  finishedAt?: string;
  lastErrors: string[];
}

/**
 * A run is capped so one click cannot spend an unbounded amount of TTS credit.
 * Five languages × a course's cards is normally far under this; hitting it
 * means something is wrong (a whole catalogue re-hashed, say) and stopping to
 * look is the right answer.
 */
const MAX_CARDS_PER_RUN = 1500;

const CONCURRENCY = 4;

/**
 * Records the cards a TAG needs, reading its text from the tag itself.
 *
 * Nothing here touches `published_content` or the working tree's
 * `keypoint.audio`: clips are addressed by the hash of the text they read, so
 * dubbing an old tag's words simply adds rows that only that tag's words
 * resolve to. The working tree, holding different words, sees no change.
 *
 * Deliberately cards only — no whole-keypoint file, no `nextup`, no merged
 * concatenation. Cards are what the app plays (`merged` is an optimisation it
 * falls back from), and the three others each need machinery that lives in
 * `VoiceoverModule`, which this module cannot import without closing a
 * dependency cycle through `CourseModule`. See
 * `plans/260916-audio-theo-tag/README.md` section 6.
 */
@Injectable()
export class VersionDubService {
  private readonly logger = new Logger(VersionDubService.name);

  constructor(
    private readonly tts: TtsService,
    private readonly cloudflareService: CloudflareService,
    private readonly clipRepository: KeypointAudioClipRepository,
    private readonly publishedContentRepository: PublishedContentRepository,
  ) {}

  // In-memory, one process — the same trade-off the dub and merge jobs make.
  private run: VersionDubSnapshot = {
    state: 'idle',
    courseId: null,
    tag: null,
    total: 0,
    done: 0,
    failed: 0,
    lastErrors: [],
  };

  snapshot(): VersionDubSnapshot {
    return { ...this.run, lastErrors: [...this.run.lastErrors] };
  }

  /**
   * Start recording everything `tag` is missing. Fire-and-forget: the caller
   * polls [snapshot]. A run already in progress is returned as-is rather than
   * doubled — two runs would synthesise the same cards twice and pay twice.
   */
  async start(
    courseId: string,
    versionId: string,
    tag: string,
  ): Promise<VersionDubSnapshot> {
    if (this.run.state === 'running') return this.snapshot();

    const missing = (await this.findMissing(versionId)).slice(
      0,
      MAX_CARDS_PER_RUN,
    );

    this.run = {
      state: 'running',
      courseId,
      tag,
      total: missing.length,
      done: 0,
      failed: 0,
      startedAt: new Date().toISOString(),
      lastErrors: [],
    };

    void this.dubAll(missing).finally(() => {
      this.run.state = 'done';
      this.run.finishedAt = new Date().toISOString();
    });

    return this.snapshot();
  }

  private async dubAll(missing: MissingCard[]): Promise<void> {
    const clips: Partial<KeypointAudioClip>[] = [];

    await runWithConcurrency(
      missing.map(card => async () => {
        try {
          const clip = await this.dubCard(card);
          clips.push(clip);
          this.run.done += 1;
        } catch (err: any) {
          this.run.failed += 1;
          this.recordError(
            `${card.keypointId}/${card.lang}#${card.index}: ${err?.message}`,
          );
        }
      }),
      CONCURRENCY,
    );

    if (!clips.length) return;

    try {
      await this.clipRepository.insertMissing(clips);
    } catch (err: any) {
      // The audio is on R2 either way; a failed row write just means the next
      // run re-records those cards. Loud, but not fatal.
      this.logger.error(
        `Version dub: clip rows failed to save: ${err?.message}`,
        err?.stack,
      );
      this.recordError(`clip rows failed to save: ${err?.message}`);
    }
  }

  private async dubCard(card: MissingCard): Promise<Partial<KeypointAudioClip>> {
    const mp3 = await this.tts.synthesizeMp3(
      card.text,
      card.lang,
      undefined,
      card.voice,
    );
    const { url } = await this.cloudflareService.uploadExternalFile({
      originalName: `${card.keypointId}-${card.lang}-${card.index}.mp3`,
      mimeType: 'audio/mpeg',
      body: mp3,
      size: mp3.length,
      key: clipObjectKey(
        card.keypointId,
        card.lang,
        'card',
        clipFileToken(card.textHash, card.voice),
        card.index,
      ),
      cacheControl: VOICEOVER_CACHE_CONTROL,
    });

    return {
      keypointId: card.keypointId,
      lang: card.lang,
      kind: 'card',
      textHash: card.textHash,
      url,
      voice: card.voice,
      index: card.index,
    };
  }

  /** Every card of the tag that has words and no recording. */
  private async findMissing(versionId: string): Promise<MissingCard[]> {
    const [keypoints, learningItems] = await Promise.all([
      this.publishedContentRepository.findAllOfType(versionId, 'keypoint'),
      this.publishedContentRepository.findAllOfType(versionId, 'learningItem'),
    ]);

    const itemsByKeypoint = new Map<string, Doc[]>();
    for (const item of learningItems) {
      const key = String(item.keypointId ?? '');
      if (!key) continue;
      const bucket = itemsByKeypoint.get(key);
      if (bucket) bucket.push(item);
      else itemsByKeypoint.set(key, [item]);
    }

    const ids = keypoints.map(keypoint => String(keypoint._id));
    const clips = await this.clipRepository.findByKeypointIds(ids);
    const have = new Set<string>();
    // The narrator this keypoint's other cards were read by. Re-recording one
    // card with a different voice than its neighbours is the one way to make a
    // keypoint sound broken while every cell reads `done`.
    const voiceOf = new Map<string, string>();
    for (const clip of clips) {
      have.add(
        clipRefKey({
          keypointId: clip.keypointId,
          lang: clip.lang,
          kind: clip.kind,
          textHash: clip.textHash,
        }),
      );
      if (clip.voice) voiceOf.set(`${clip.keypointId}|${clip.lang}`, clip.voice);
    }

    const missing: MissingCard[] = [];
    for (const keypoint of keypoints) {
      const keypointId = String(keypoint._id);
      const items = (itemsByKeypoint.get(keypointId) ?? [])
        .slice()
        .sort((a, b) => (a.index ?? 0) - (b.index ?? 0));

      for (const lang of VOICEOVER_LANGS) {
        const cards = buildNarrationSegments(items, lang);
        if (!cards.some(Boolean)) continue;

        const voice =
          voiceOf.get(`${keypointId}|${lang}`) ??
          (await this.tts.resolveVoiceName(lang));

        cards.forEach((text, index) => {
          if (!text) return;
          const textHash = clipTextHash(text);
          if (have.has(clipRefKey({ keypointId, lang, kind: 'card', textHash }))) {
            return;
          }
          missing.push({ keypointId, lang, index, text, textHash, voice });
        });
      }
    }

    return missing;
  }

  private recordError(message: string): void {
    this.run.lastErrors = [message, ...this.run.lastErrors].slice(0, 5);
  }
}
