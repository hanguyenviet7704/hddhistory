import { execFile } from 'child_process';
import { createReadStream, promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { promisify } from 'util';

import { Injectable, Logger } from '@nestjs/common';

import { CloudflareService } from 'src/modules/file/cloudflare/cloudflare.service';

import { UserLessonClipPrefetcher } from './user-lesson-clip-prefetcher';
import {
  buildKeypointNarrationScripts,
  buildSectionCues,
  computeNarrationHash,
} from './user-lesson-narration.util';
import { sanitizeForNarration } from '../../voiceover/narration-text.util';
import { TtsService } from '../../voiceover/tts.service';
import {
  appendVersion,
  VOICEOVER_CACHE_CONTROL,
} from '../../voiceover/voiceover-merge.util';
import { UserLessonAudioStatus } from '../enum/learning-import.enum';
import {
  IUserLessonAudio,
  IUserLessonKeypointAudio,
} from '../interface/learning-import.interface';
import { UserLessonRepository } from '../repository/user-lesson.repository';
import { UserLesson } from '../schema/user-lesson.schema';

const execFileAsync = promisify(execFile);

// Same overrides the catalogue merge uses, so a dev box with a Homebrew ffmpeg
// elsewhere on disk works for both.
const FFMPEG = process.env.FFMPEG_PATH || 'ffmpeg';
const FFPROBE = process.env.FFPROBE_PATH || 'ffprobe';

/**
 * How many sections are synthesised at once.
 *
 * Lower than the catalogue dub's 6: that runs as a deliberate batch with nothing
 * else in flight, while this fires whenever a user finishes an import and can
 * therefore overlap with other users' dubs on the same process.
 */
const SYNTH_CONCURRENCY = 4;

/**
 * Turns a generated lesson's keypoints into one narrated mp3 each, plus a cue
 * per card.
 *
 * INCREMENTAL since plans/260813-progressive-import: keypoints are dubbed as
 * they exist, and each keypoint's audio is committed to the document the moment
 * its file is uploaded — so the first keypoint is listenable while the rest of
 * the lesson is still being written, and a crash mid-run loses only the
 * keypoints it had not reached, never the ones already dubbed. Re-running is
 * always safe: already-dubbed keypoints are skipped by index.
 *
 * Deliberately NOT a copy of `VoiceoverService`. That one carries five locales,
 * per-card clips kept in R2 for a legacy playback path, and cues keyed by
 * learning item. A generated lesson has one locale, one playback path and no
 * learning items, so this is the same idea at about a fifth of the size.
 */
@Injectable()
export class UserLessonVoiceoverService {
  private readonly logger = new Logger(UserLessonVoiceoverService.name);

  constructor(
    private readonly userLessonRepository: UserLessonRepository,
    private readonly ttsService: TtsService,
    private readonly cloudflareService: CloudflareService,
  ) {}

  /**
   * A prefetcher bound to [lang]'s narrator, for synthesizing clips DURING the
   * generation stream. Null when the locale has no narrator — the caller just
   * skips prefetching and the dub path reports the terminal failure itself.
   */
  async createPrefetcher(lang: string): Promise<UserLessonClipPrefetcher | null> {
    if (!this.ttsService.hasVoice(lang)) return null;

    const voice = await this.ttsService.resolveVoiceName(lang);

    return new UserLessonClipPrefetcher(this.ttsService, lang, voice);
  }

  /**
   * Dub every keypoint that exists but has no audio yet. Never throws for
   * TRANSIENT reasons -- callers fire it and forget, and the completion sweep
   * retries whatever this run did not finish.
   *
   * Terminal states are still written eagerly: a locale with no narrator and a
   * lesson with nothing sayable get `FAILED` (nothing will ever change those),
   * so the app is never left showing a spinner for audio that cannot exist.
   * A synthesis blip, by contrast, leaves the status alone — for a lesson on
   * the progressive pipeline that means "the sweep will be back", which is a
   * promise `FAILED` used to break.
   */
  async dubMissingKeypoints(
    lessonId: string,
    prefetch?: UserLessonClipPrefetcher,
  ): Promise<void> {
    let lesson: UserLesson | null = null;
    try {
      lesson = await this.userLessonRepository.findAny(lessonId);
      if (!lesson) {
        this.logger.warn(`Dub skipped: user lesson ${lessonId} is gone`);

        return;
      }

      await this.run(lesson, prefetch);
    } catch (error: any) {
      this.logger.error(
        `Dub failed for user lesson ${lessonId}: ${error?.message}`,
        error?.stack,
      );
      // Only a lesson OUTSIDE the progressive pipeline is failed terminally on
      // a blip: nothing will ever retry it, and `failed` at least renders as
      // "no audio" rather than an eternal spinner. A pipeline lesson keeps its
      // status — the sweep owns its retries.
      if (!lesson?.generation) await this.markFailed(lessonId);
    }
  }

  private async run(
    lesson: UserLesson,
    prefetch?: UserLessonClipPrefetcher,
  ): Promise<void> {
    const lessonId = String(lesson._id);
    const lang = lesson.outputLocale;
    // The five app locales are the five the narrator catalogue covers. A lesson
    // outside them cannot be dubbed at all, so fail fast rather than let
    // `resolveVoiceName` throw halfway through synthesis.
    if (!this.ttsService.hasVoice(lang)) {
      this.logger.warn(
        `Dub skipped: user lesson ${lessonId} is in '${lang}', which has no narrator`,
      );
      await this.markFailed(lessonId);

      return;
    }

    const { scripts: rawScripts, groups } = buildKeypointNarrationScripts(
      lesson.keypoints ?? [],
    );
    const scripts = rawScripts.map(script => sanitizeForNarration(script));
    if (scripts.every(script => !script)) {
      this.logger.warn(
        `Dub skipped: user lesson ${lessonId} has no sayable text`,
      );
      await this.markFailed(lessonId);

      return;
    }

    const existing = lesson.audio?.keypoints ?? [];
    const done = new Set(existing.map(entry => entry.keypointIndex));
    const missing = groups
      .map((group, keypointIndex) => ({ group, keypointIndex }))
      .filter(({ keypointIndex }) => !done.has(keypointIndex))
      .filter(({ group }) =>
        scripts
          .slice(group.start, group.start + group.count)
          .some(script => script.length > 0),
      );

    if (missing.length === 0) return;

    // Only the very first dub of a lesson shows as `processing`: a top-up must
    // never downgrade a lesson the reader can already listen to.
    if (existing.length === 0) {
      await this.userLessonRepository.setAudioStatus(
        lessonId,
        UserLessonAudioStatus.PROCESSING,
      );
    }

    // The narrator is chosen ONCE per lesson and reused by every later top-up:
    // resolving fresh each phase could switch voices mid-lesson if Microsoft
    // retired a name between phases. The prefetcher's narrator wins the first
    // pick — its clips already exist in that voice.
    const voice =
      lesson.audio?.voice ||
      prefetch?.voice ||
      (await this.ttsService.resolveVoiceName(lang));
    // Clips made by a different narrator than this run's are unusable — one
    // keypoint alternating voices card to card is worse than a slow dub.
    const usablePrefetch =
      prefetch && prefetch.voice === voice ? prefetch : undefined;

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hddhistory-userlesson-'));
    try {
      await this.synthesizeAndCommit({
        lessonId,
        lang,
        voice,
        scripts,
        missing,
        tmpDir,
        prefetch: usablePrefetch,
      });
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  }

  /**
   * Synthesise the missing keypoints' cards, then merge, upload and COMMIT one
   * keypoint at a time.
   *
   * Synthesis is flat and the merge is grouped, on purpose: the worker pool
   * should not idle at a keypoint boundary waiting for a slow clip, but the
   * reader loads narration a keypoint at a time and the end of a file is how the
   * player knows a keypoint's narration ended.
   *
   * Each keypoint is written to the document the moment its file exists,
   * re-reading the audio field just before the write: the union-by-index merge
   * makes racing writers (the runner's phase-1 dub finishing late vs a sweep
   * top-up) converge on the same entries instead of clobbering each other --
   * same scripts, same voice, same hash, same R2 key, so a double write is a
   * no-op rather than a conflict.
   *
   * Unlike the catalogue dub, per-card clips are never uploaded: they exist only
   * as temp files on the way to the merged mp3s.
   */
  private async synthesizeAndCommit(params: {
    lessonId: string;
    lang: string;
    voice: string;
    scripts: string[];
    missing: { group: { start: number; count: number }; keypointIndex: number }[];
    tmpDir: string;
    prefetch?: UserLessonClipPrefetcher;
  }): Promise<void> {
    const { lessonId, lang, voice, scripts, missing, tmpDir, prefetch } =
      params;

    // Index-aligned with `scripts`, and stays that way: a card that produced no
    // audio keeps its slot with a null file, so cue `i` always addresses card
    // `i` of its keypoint.
    const files: (string | null)[] = new Array(scripts.length).fill(null);

    const wanted = missing.flatMap(({ group }) =>
      Array.from({ length: group.count }, (_, offset) => group.start + offset),
    );

    let cursor = 0;
    const workers = Array.from(
      { length: Math.min(SYNTH_CONCURRENCY, wanted.length) },
      async () => {
        while (cursor < wanted.length) {
          const index = wanted[cursor++];
          const script = scripts[index];
          if (!script) continue;

          // A prefetched clip (synthesized while the text was still
          // streaming) skips the synthesis entirely — this is what makes
          // "keypoint done" and "narration done" land together.
          const buffer =
            (await prefetch?.take(script)) ??
            (await this.ttsService.synthesizeMp3(
              script,
              lang,
              undefined,
              voice,
            ));
          const file = path.join(tmpDir, `${index}.mp3`);
          await fs.writeFile(file, buffer);
          files[index] = file;
        }
      },
    );
    await Promise.all(workers);

    let committed = 0;
    for (const { group, keypointIndex } of missing) {
      const own = files.slice(group.start, group.start + group.count);
      // Versioned per keypoint: a re-dub of one keypoint must change ONLY that
      // keypoint's url, and the R2 keys are deterministic and cached forever.
      const hash = computeNarrationHash(
        voice,
        scripts.slice(group.start, group.start + group.count),
      );
      const merged = await this.mergeKeypoint({
        lessonId,
        keypointIndex,
        hash,
        files: own,
        tmpDir,
      });
      if (!merged) continue;

      await this.commitKeypointAudio(lessonId, voice, merged);
      committed++;
      this.logger.log(
        `Dubbed user lesson ${lessonId} keypoint ${keypointIndex} (${lang}, ${merged.durationMs}ms)`,
      );
    }

    if (committed === 0) {
      throw new Error('every missing keypoint failed to synthesise');
    }
  }

  /**
   * Merge `entry` into the lesson's audio by keypoint index and let the status
   * follow: audio with at least one keypoint is READY — that is the app's
   * signal that the play button works — and coverage of the REST is the
   * completion sweep's business, not a status.
   */
  private async commitKeypointAudio(
    lessonId: string,
    voice: string,
    entry: IUserLessonKeypointAudio,
  ): Promise<void> {
    const current = await this.userLessonRepository.findAny(lessonId);
    if (!current) return;

    const others = (current.audio?.keypoints ?? []).filter(
      existing => existing.keypointIndex !== entry.keypointIndex,
    );
    const keypoints = [...others, entry].sort(
      (a, b) => a.keypointIndex - b.keypointIndex,
    );

    const audio: IUserLessonAudio = {
      voice,
      // The lesson-level hash is the identity of what is CURRENTLY dubbed.
      // Kept for compatibility (old readers may echo it); per-keypoint urls
      // carry their own version, which is the one that matters.
      hash: computeNarrationHash(
        voice,
        keypoints.map(keypoint => keypoint.url),
      ),
      keypoints,
    };

    await this.userLessonRepository.setAudio(
      lessonId,
      audio,
      UserLessonAudioStatus.READY,
    );
  }

  /**
   * Concatenate one keypoint's clips and upload the result.
   *
   * Returns null when the keypoint produced no audio at all — a keypoint of
   * image-only cards, or one whose every clip failed. Null rather than an empty
   * entry so the app sees a keypoint with no narration, which it already
   * handles, instead of a player pointed at a zero-length file.
   */
  private async mergeKeypoint(params: {
    lessonId: string;
    keypointIndex: number;
    hash: string;
    files: (string | null)[];
    tmpDir: string;
  }): Promise<IUserLessonKeypointAudio | null> {
    const { lessonId, keypointIndex, hash, files, tmpDir } = params;

    const durationsMs: number[] = [];
    const localFiles: string[] = [];
    for (const file of files) {
      if (!file) {
        durationsMs.push(0);
        continue;
      }
      durationsMs.push(await this.probeDurationMs(file));
      localFiles.push(file);
    }

    if (localFiles.length === 0) return null;

    const listFile = path.join(tmpDir, `list-${keypointIndex}.txt`);
    await fs.writeFile(listFile, localFiles.map(f => `file '${f}'`).join('\n'));

    const outFile = path.join(tmpDir, `merged-${keypointIndex}.mp3`);
    // Stream copy, no re-encode: every clip came from the same synthesiser at
    // the same bitrate, so the cue offsets are exactly the probed durations.
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

    const { cues, durationMs } = buildSectionCues(durationsMs);

    const actualMs = await this.probeDurationMs(outFile);
    if (Math.abs(actualMs - durationMs) > 250) {
      // Not fatal, but it means the card would drift out of step with the voice
      // near the end of the keypoint -- worth seeing in the logs if it starts
      // happening.
      this.logger.warn(
        `Merged duration drift for user lesson ${lessonId} keypoint ${keypointIndex}: cues=${durationMs}ms file=${actualMs}ms`,
      );
    }

    const { size } = await fs.stat(outFile);
    const { url } = await this.cloudflareService.uploadExternalFile({
      originalName: `${lessonId}-kp${keypointIndex}.mp3`,
      // Streamed rather than buffered: these are the biggest objects of the run.
      body: createReadStream(outFile),
      mimeType: 'audio/mpeg',
      size,
      key: `voiceover/user-lesson/${lessonId}/kp-${keypointIndex}.mp3`,
      cacheControl: VOICEOVER_CACHE_CONTROL,
    });

    return {
      keypointIndex,
      // Versioned by the content hash: the R2 keys are deterministic and cached
      // forever, so a re-dub must be served under urls no cache has seen.
      url: appendVersion(url, hash),
      durationMs,
      cues,
    };
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

  private async markFailed(lessonId: string): Promise<void> {
    try {
      await this.userLessonRepository.setAudioStatus(
        lessonId,
        UserLessonAudioStatus.FAILED,
      );
    } catch (error: any) {
      this.logger.error(
        `Could not mark dub failed for user lesson ${lessonId}: ${error?.message}`,
      );
    }
  }
}
