import { execFile } from 'child_process';
import { createReadStream, createWriteStream, promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { Readable } from 'stream';
import { pipeline } from 'stream/promises';
import { promisify } from 'util';

import { Injectable, Logger } from '@nestjs/common';

import { CloudflareService } from 'src/modules/file/cloudflare/cloudflare.service';

import { clipFileToken, clipObjectKey } from './audio-clip.util';
import { KeypointAudioClipRepository } from './repository/keypoint-audio-clip.repository';
import { KeypointAudioClip } from './schema/keypoint-audio-clip.schema';
import {
  appendVersion,
  buildCues,
  computeMergeHash,
  computeTheoryCueSlots,
  TheoryCueSlot,
  VOICEOVER_CACHE_CONTROL,
} from './voiceover-merge.util';
import { IMergedKeypointAudio } from '../keypoint/interface/keypoint.interface';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';

const execFileAsync = promisify(execFile);

// Overridable for machines where the binaries are not on PATH; the production
// image installs both via apk (see Dockerfile).
const FFMPEG = process.env.FFMPEG_PATH || 'ffmpeg';
const FFPROBE = process.env.FFPROBE_PATH || 'ffprobe';

export interface KeypointMergeResult {
  keypointId: string;
  merged: string[]; // langs freshly concatenated
  reused: string[]; // langs whose hash matched `previous`
  skipped: string[]; // langs with no audible theory clip at all
  failed: Array<{ lang: string; message: string }>;
}

export interface MergeAllSnapshot {
  state: 'idle' | 'running' | 'done';
  total: number;
  done: number;
  failed: number;
  startedAt?: string;
  finishedAt?: string;
  lastErrors: string[];
}

@Injectable()
export class VoiceoverMergeService {
  private readonly logger = new Logger(VoiceoverMergeService.name);

  constructor(
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly cloudflareService: CloudflareService,
    private readonly audioClipRepository: KeypointAudioClipRepository,
  ) {}

  // In-memory, one process — same trade-off the dub job already makes.
  private mergeAll: MergeAllSnapshot = {
    state: 'idle',
    total: 0,
    done: 0,
    failed: 0,
    lastErrors: [],
  };

  snapshot(): MergeAllSnapshot {
    return { ...this.mergeAll, lastErrors: [...this.mergeAll.lastErrors] };
  }

  /**
   * Fire-and-forget backfill over every keypoint that has per-card segments.
   * Sequential on purpose (one keypoint at a time): each merge already walks
   * several clips per language, and this shares the event loop with live
   * traffic. A run already in progress is returned as-is (no double-start).
   */
  async startMergeAll(opts?: { force?: boolean }): Promise<MergeAllSnapshot> {
    if (this.mergeAll.state === 'running') return this.snapshot();

    const ids = await this.keypointRepository.findIdsWithSegments();
    this.mergeAll = {
      state: 'running',
      total: ids.length,
      done: 0,
      failed: 0,
      startedAt: new Date().toISOString(),
      lastErrors: [],
    };

    void (async () => {
      for (const id of ids) {
        try {
          const r = await this.mergeAndPersist(id, { force: opts?.force });
          if (r.failed.length) {
            this.mergeAll.failed++;
            this.recordError(`${id}: ${r.failed[0].message}`);
          } else {
            this.mergeAll.done++;
          }
        } catch (err: any) {
          this.mergeAll.failed++;
          this.recordError(`${id}: ${err?.message}`);
        }
      }
      this.mergeAll.state = 'done';
      this.mergeAll.finishedAt = new Date().toISOString();
    })();

    return this.snapshot();
  }

  private recordError(message: string) {
    this.mergeAll.lastErrors = [message, ...this.mergeAll.lastErrors].slice(
      0,
      5,
    );
  }

  /**
   * Builds `audio.merged` for every language that has per-card segments and
   * persists it with a targeted `$set` (never replacing the rest of `audio`).
   * `opts.previous` is the merged map that existed BEFORE the caller replaced
   * `audio` (generateForKeypoint's $set wipes it) — hash-matching languages
   * are carried over instead of re-concatenated. Left out (backfill), the
   * keypoint's own current `audio.merged` plays that role.
   */
  async mergeAndPersist(
    keypointId: string,
    opts?: {
      previous?: Record<string, IMergedKeypointAudio>;
      force?: boolean;
    },
  ): Promise<KeypointMergeResult> {
    const result: KeypointMergeResult = {
      keypointId,
      merged: [],
      reused: [],
      skipped: [],
      failed: [],
    };

    const keypoint: any = await this.keypointRepository.findById(keypointId);
    const audio = keypoint?.audio ?? {};
    const segmentsByLang: Record<string, string[]> = audio.segments ?? {};
    const langs = Object.keys(segmentsByLang);
    if (!langs.length) return result;

    const items = await this.learningItemRepository.findNarratableByKeypoint(
      keypointId,
    );
    const slots = computeTheoryCueSlots(items);
    const previous = opts?.previous ?? audio.merged ?? {};
    const voices: Record<string, string> = audio.voices ?? {};

    const merged: Record<string, IMergedKeypointAudio> = {};
    for (const lang of langs) {
      const segmentUrls = segmentsByLang[lang] ?? [];
      const segmentHashes: string[] = audio.segmentHash?.[lang] ?? [];
      const audibleSlots = slots.filter((s) => segmentUrls[s.segmentIndex]);
      if (!audibleSlots.length) {
        result.skipped.push(lang);
        continue;
      }

      const hash = computeMergeHash(voices[lang] ?? '', slots, segmentHashes);
      const prior: IMergedKeypointAudio | undefined = previous[lang];
      if (!opts?.force && prior?.url && prior.hash === hash) {
        merged[lang] = prior;
        result.reused.push(lang);
        continue;
      }

      try {
        merged[lang] = await this.mergeLang(
          keypointId,
          lang,
          slots,
          audibleSlots,
          segmentUrls,
          hash,
          voices[lang] ?? '',
        );
        result.merged.push(lang);
      } catch (err: any) {
        // One bad language must not sink the others; segments stay the app's
        // fallback for this lang until the next run.
        this.logger.error(
          `Merge failed (keypoint=${keypointId}, lang=${lang}): ${err?.message}`,
          err?.stack,
        );
        result.failed.push({ lang, message: err?.message ?? 'error' });
        if (prior?.url) merged[lang] = prior; // keep last good file
      }
    }

    await this.keypointRepository.findOneAndUpdate(
      { _id: keypointId },
      { $set: { 'audio.merged': merged } },
    );

    // Mirror into the content-addressed store — including languages that were
    // REUSED rather than re-merged, so a keypoint nobody has touched since the
    // store landed still gets its row.
    await this.recordMergedClips(keypointId, merged, voices);

    return result;
  }

  /**
   * Record merged files in `keypoint_audio_clips`.
   *
   * `textHash` here is `computeMergeHash`'s composite, not the hash of any one
   * text — a concatenation has no text of its own, and the composite is exactly
   * what the read path recomputes from a tag's theory slots.
   *
   * Never fatal, for the same reason as the dub path's own write: the merge is
   * already on R2 and in Mongo.
   */
  private async recordMergedClips(
    keypointId: string,
    merged: Record<string, IMergedKeypointAudio>,
    voices: Record<string, string>,
  ): Promise<void> {
    const clips: Partial<KeypointAudioClip>[] = Object.entries(merged)
      .filter(([, value]) => value?.url && value?.hash)
      .map(([lang, value]) => ({
        keypointId,
        lang,
        kind: 'merged' as const,
        textHash: value.hash,
        url: value.url,
        durationMs: value.durationMs,
        cues: value.cues,
        voice: voices[lang] ?? '',
        index: -1,
      }));

    if (!clips.length) return;

    try {
      await this.audioClipRepository.insertMissing(clips);
    } catch (err: any) {
      this.logger.error(
        `Audio clip store write failed for merge (keypoint=${keypointId}): ${err?.message}`,
        err?.stack,
      );
    }
  }

  /** Download audible clips → ffprobe each → concat (-c copy) → upload. */
  private async mergeLang(
    keypointId: string,
    lang: string,
    allSlots: TheoryCueSlot[],
    audibleSlots: TheoryCueSlot[],
    segmentUrls: string[],
    hash: string,
    voice: string,
  ): Promise<IMergedKeypointAudio> {
    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hddhistory-merge-'));
    try {
      const durationsMs = new Map<number, number>();
      const localFiles: string[] = [];
      for (const slot of audibleSlots) {
        const url = segmentUrls[slot.segmentIndex];
        const local = path.join(tmpDir, `${slot.segmentIndex}.mp3`);
        // Streamed to disk, never buffered whole, and hard-capped at 30s: a
        // catalogue-wide run makes thousands of these — buffering them in RAM
        // pushed the pod over its memory limit mid-backfill, and one hung
        // download (fetch has NO default timeout) froze the whole loop.
        const res = await fetch(url, { signal: AbortSignal.timeout(30000) });
        if (!res.ok || !res.body) {
          throw new Error(`clip ${slot.segmentIndex} HTTP ${res.status}`);
        }
        // `fromWeb` exists at runtime on Node 18 but this repo's @types/node
        // predates its typing — hence the cast.
        await pipeline((Readable as any).fromWeb(res.body), createWriteStream(local));
        durationsMs.set(slot.segmentIndex, await this.probeDurationMs(local));
        localFiles.push(local);
      }

      const listFile = path.join(tmpDir, 'list.txt');
      await fs.writeFile(
        listFile,
        localFiles.map((f) => `file '${f}'`).join('\n'),
      );
      const outFile = path.join(tmpDir, 'merged.mp3');
      // Same codec/bitrate across clips (one TTS provider) → stream copy, no
      // re-encode; the cue offsets are then exactly the per-clip frame
      // durations probed above.
      await execFileAsync(FFMPEG, [
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        listFile,
        '-c',
        'copy',
        outFile,
      ]);

      const { cues, durationMs } = buildCues(allSlots, durationsMs);
      const actualMs = await this.probeDurationMs(outFile);
      if (Math.abs(actualMs - durationMs) > 250) {
        this.logger.warn(
          `Merged duration drift keypoint=${keypointId} lang=${lang}: cues=${durationMs}ms file=${actualMs}ms`,
        );
      }

      const { size } = await fs.stat(outFile);
      const { url } = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${lang}-merged.mp3`,
        mimeType: 'audio/mpeg',
        // Streamed for the same reason the downloads are — the merged file is
        // the biggest object of the whole run (whole-keypoint audio).
        body: createReadStream(outFile),
        size,
        // Keyed by the merge hash, so a re-merge writes a NEW object instead
        // of replacing the one a published tag still plays.
        key: clipObjectKey(
          keypointId,
          lang,
          'merged',
          clipFileToken(hash, voice),
        ),
        cacheControl: VOICEOVER_CACHE_CONTROL,
      });

      // Versioned by the merge hash: the app re-fetches this ~900KB file on
      // every listen, so it must be cacheable, and the R2 key is reused by
      // every re-merge, so the url must change when the audio does.
      return { url: appendVersion(url, hash), durationMs, hash, cues };
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  }

  /**
   * Concatenate a keypoint's per-card clips into the ONE whole-keypoint file
   * kept at `audio.url`, and return its versioned url.
   *
   * This is the free alternative to synthesising the whole keypoint a second
   * time. With Edge that second synthesis costs nothing, so `VoiceoverService`
   * still does it there; with a per-character provider it very nearly DOUBLES
   * the bill (measured: the catalogue's Vietnamese is ~920k characters of cards
   * against ~890k for the whole-keypoint files), and the bytes are identical
   * either way — same narrator, same text, same order.
   *
   * Differs from [mergeAndPersist] in what goes in: this takes EVERY audible
   * card (theory pages and exercise questions alike) because `audio.url` is the
   * whole narration, while the merged file is theory-only and carries cues.
   *
   * `-c copy`, so the inputs must share a codec, sample rate and bitrate. They
   * do: a provider switch changes `audio.voices[lang]`, which makes `sameVoice`
   * false and re-dubs every card of the language in one run. The caller must
   * still refuse to build this when a card fell back to an older clip — see the
   * `plan.failure` guard in `VoiceoverService`.
   */
  async concatSegmentsToWhole(
    keypointId: string,
    lang: string,
    segmentUrls: string[],
    versionHash: string,
    voice: string,
  ): Promise<string> {
    const audible = segmentUrls.filter(Boolean);
    if (!audible.length) {
      throw new Error(`No audible clips to concat (lang=${lang})`);
    }

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hddhistory-whole-'));
    try {
      const localFiles: string[] = [];
      for (let index = 0; index < audible.length; index++) {
        const local = path.join(tmpDir, `${index}.mp3`);
        // Streamed and deadlined for the same reasons as the merge path: a
        // catalogue run makes thousands of these, and `fetch` has no default
        // timeout, so one hung download would freeze the whole run.
        const res = await fetch(audible[index], {
          signal: AbortSignal.timeout(30000),
        });
        if (!res.ok || !res.body) {
          throw new Error(`clip ${index} HTTP ${res.status}`);
        }
        await pipeline(
          (Readable as any).fromWeb(res.body),
          createWriteStream(local),
        );
        localFiles.push(local);
      }

      const listFile = path.join(tmpDir, 'list.txt');
      await fs.writeFile(
        listFile,
        localFiles.map((f) => `file '${f}'`).join('\n'),
      );
      const outFile = path.join(tmpDir, 'whole.mp3');
      await execFileAsync(FFMPEG, [
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        listFile,
        '-c',
        'copy',
        outFile,
      ]);

      const { size } = await fs.stat(outFile);
      const { url } = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${lang}.mp3`,
        mimeType: 'audio/mpeg',
        body: createReadStream(outFile),
        size,
        // The SAME R2 key the synthesised whole-keypoint file uses, so older
        // app builds keep reading one url whichever way it was produced —
        // which means it has to be derived identically, voice included.
        key: clipObjectKey(
          keypointId,
          lang,
          'whole',
          clipFileToken(versionHash, voice),
        ),
        cacheControl: VOICEOVER_CACHE_CONTROL,
      });
      return appendVersion(url, versionHash);
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  }

  private async probeDurationMs(file: string): Promise<number> {
    const { stdout } = await execFileAsync(FFPROBE, [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      file,
    ]);
    const seconds = parseFloat(stdout.trim());
    if (!Number.isFinite(seconds)) {
      throw new Error(`ffprobe gave no duration for ${file}`);
    }
    return Math.round(seconds * 1000);
  }
}
