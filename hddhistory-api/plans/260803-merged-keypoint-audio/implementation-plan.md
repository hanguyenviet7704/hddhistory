# Merged Keypoint Audio — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One merged narration file per keypoint × language (ffmpeg concat of the existing per-card clips) with an identity-based cue map, played as a single continuous track in the app, with exact card+second resume after app kill.

**Architecture:** hddhistory-api gains a `VoiceoverMergeService` that concats theory-document clips into `keypoint.audio.merged[lang] = {url, durationMs, hash, cues[]}` (cue = `{learningItemId, documentIndex, startMs, durMs}`), wired into the dub pipeline + a backfill endpoint. hddhistory-flutter plays `merged.url` as ONE source; the deck follows the player via cue boundaries (no per-card reloads), gates are enforced by an `allowedThroughCue` bound pushed from the deck, and a small HydratedCubit persists `{keypointId, positionMs}` for resume. Keypoints without `merged` keep the existing per-card path untouched.

**Tech Stack:** NestJS 9 + Mongoose (Mixed schema — no migration), ffmpeg/ffprobe via child_process, Cloudflare R2; Flutter + just_audio 0.10 + audio_service + freezed/json_serializable + hydrated_bloc.

**Spec:** `hddhistory-api/plans/260803-merged-keypoint-audio/README.md` (committed on branch `feature/merged-keypoint-audio`).

## Global Constraints

- **Never run full test suites** (`npm test` bare, `flutter test` bare) — RAM. Run ONE targeted file only. Correctness gates: `npx tsc --noEmit` (hddhistory-api), `flutter analyze` (hddhistory-flutter). A PostToolUse hook already type-checks after every edit — read its output.
- **Never `git add -A` / `git add .`** — both repos hold unrelated uncommitted WIP files. Add ONLY the files named in the task. **Never `git checkout --`** on anything.
- Branches: `feature/merged-keypoint-audio` in BOTH repos (already exists in hddhistory-api). Integration branch is `develop`.
- Commits: `type: subject` (imperative, lowercase, EN or VI), trailer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- hddhistory-api style: 2-space, 80 cols, single quotes, trailing commas; layering: controller → service → repository (only repositories touch the DB — `findOneAndUpdate` etc. must live in/behind a repository).
- hddhistory-flutter: never edit `*.g.dart`/`*.freezed.dart`/`*.config.dart`; rerun `dart run build_runner build --delete-conflicting-outputs` after model/DI changes (a "l10n.g.dart already exists" message from slang assets is expected noise — check for "wrote N outputs"); `dart format` ONLY the files you edited (180 cols).
- Legacy per-card playback path must keep working byte-for-byte for keypoints without `merged` — every new behaviour branches on merged mode.
- The `merged` Mongo field is additive inside the existing `SchemaTypes.Mixed` `audio` prop — NO schema migration, and old app builds ignore it.

---

# Phase 1 — hddhistory-api

### Task 1: Pure merge utilities + types + spec

**Files:**
- Modify: `src/modules/courses/src/modules/keypoint/interface/keypoint.interface.ts`
- Create: `src/modules/courses/src/modules/voiceover/voiceover-merge.util.ts`
- Test: `src/modules/courses/src/modules/voiceover/voiceover-merge.util.spec.ts`

**Interfaces (produced, used by Tasks 2–4):**
- `IMergedAudioCue { learningItemId: string; documentIndex: number; startMs: number; durMs: number }`
- `IMergedKeypointAudio { url: string; durationMs: number; hash: string; cues: IMergedAudioCue[] }`
- `IKeypointAudio.merged?: Record<string, IMergedKeypointAudio>`
- `TheoryCueSlot { segmentIndex: number; learningItemId: string; documentIndex: number }`
- `computeTheoryCueSlots(items: any[]): TheoryCueSlot[]`
- `buildCues(slots, durationsMs: Map<number, number>): { cues: IMergedAudioCue[]; durationMs: number }`
- `computeMergeHash(voice: string, slots: TheoryCueSlot[], segmentHashes: string[]): string`

- [ ] **Step 1: Add the interfaces** to `keypoint.interface.ts` (below `IKeypointAudio`'s existing members, `merged` as a new optional member of `IKeypointAudio`):

```ts
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
```
and on `IKeypointAudio`:
```ts
  /// One merged theory-narration file per language — see IMergedKeypointAudio.
  merged?: Record<string, IMergedKeypointAudio>;
```

- [ ] **Step 2: Write the failing spec** `voiceover-merge.util.spec.ts`:

```ts
import {
  buildCues,
  computeMergeHash,
  computeTheoryCueSlots,
} from './voiceover-merge.util';

const theory = (id: string, docs: number) => ({
  _id: id,
  type: 'theory',
  documents: Array.from({ length: docs }, () => ({})),
});
const exercise = (id: string, questions: number) => ({
  _id: id,
  type: 'exercise',
  questions: Array.from({ length: questions }, () => ({})),
});
const video = (id: string, docs: number) => ({
  _id: id,
  type: 'video',
  documents: Array.from({ length: docs }, () => ({})),
});

describe('computeTheoryCueSlots', () => {
  it('numbers theory docs the way buildSegments does, skipping exercise questions', () => {
    // exercise first — the exact shape behind "first cards break"
    const items = [exercise('e1', 3), theory('t1', 2)];
    expect(computeTheoryCueSlots(items)).toEqual([
      { segmentIndex: 3, learningItemId: 't1', documentIndex: 0 },
      { segmentIndex: 4, learningItemId: 't1', documentIndex: 1 },
    ]);
  });

  it('video documents occupy segment indexes but produce no slots', () => {
    const items = [theory('t1', 1), video('v1', 2), theory('t2', 1)];
    expect(computeTheoryCueSlots(items)).toEqual([
      { segmentIndex: 0, learningItemId: 't1', documentIndex: 0 },
      { segmentIndex: 3, learningItemId: 't2', documentIndex: 0 },
    ]);
  });
});

describe('buildCues', () => {
  it('accumulates offsets and gives silent cards durMs 0', () => {
    const slots = computeTheoryCueSlots([theory('t1', 3)]);
    const durations = new Map([
      [0, 4000],
      [2, 6000],
    ]); // slot 1 has no clip
    expect(buildCues(slots, durations)).toEqual({
      durationMs: 10000,
      cues: [
        { learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 4000 },
        { learningItemId: 't1', documentIndex: 1, startMs: 4000, durMs: 0 },
        { learningItemId: 't1', documentIndex: 2, startMs: 4000, durMs: 6000 },
      ],
    });
  });
});

describe('computeMergeHash', () => {
  const slots = computeTheoryCueSlots([theory('t1', 2)]);
  it('is stable for identical inputs', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).toEqual(
      computeMergeHash('voiceA', slots, ['h0', 'h1']),
    );
  });
  it('changes when the voice changes (same text)', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).not.toEqual(
      computeMergeHash('voiceB', slots, ['h0', 'h1']),
    );
  });
  it('changes when a card hash changes', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).not.toEqual(
      computeMergeHash('voiceA', slots, ['h0', 'CHANGED']),
    );
  });
});
```

- [ ] **Step 3: Run it to verify it fails** (module missing):
`cd hddhistory-api && npm test -- src/modules/courses/src/modules/voiceover/voiceover-merge.util.spec.ts`
Expected: FAIL — cannot find `./voiceover-merge.util`.

- [ ] **Step 4: Implement** `voiceover-merge.util.ts`:

```ts
import { createHash } from 'crypto';

import { LearningItemType } from '../learning-item/enum/learning-item.enum';
import { IMergedAudioCue } from '../keypoint/interface/keypoint.interface';

/**
 * A theory document's place in `VoiceoverService.buildSegments`' numbering,
 * plus the card identity the app will look it up by. This walk MUST stay in
 * lockstep with buildSegments (exercise → one segment per question, every
 * other item → one segment per document); it lives here so the numbering has
 * exactly one home on the backend and none in the app.
 */
export interface TheoryCueSlot {
  segmentIndex: number;
  learningItemId: string;
  documentIndex: number;
}

export function computeTheoryCueSlots(items: any[]): TheoryCueSlot[] {
  const slots: TheoryCueSlot[] = [];
  let segmentIndex = 0;
  for (const item of items) {
    if (item.type === LearningItemType.EXERCISE) {
      segmentIndex += (item.questions ?? []).length;
      continue;
    }
    const documents = item.documents ?? [];
    for (let documentIndex = 0; documentIndex < documents.length; documentIndex++) {
      if (item.type === LearningItemType.THEORY) {
        slots.push({
          segmentIndex,
          learningItemId: String(item._id ?? item.id ?? ''),
          documentIndex,
        });
      }
      segmentIndex++;
    }
  }
  return slots;
}

export function buildCues(
  slots: TheoryCueSlot[],
  durationsMs: Map<number, number>,
): { cues: IMergedAudioCue[]; durationMs: number } {
  const cues: IMergedAudioCue[] = [];
  let cursor = 0;
  for (const slot of slots) {
    const durMs = durationsMs.get(slot.segmentIndex) ?? 0;
    cues.push({
      learningItemId: slot.learningItemId,
      documentIndex: slot.documentIndex,
      startMs: cursor,
      durMs,
    });
    cursor += durMs;
  }
  return { cues, durationMs: cursor };
}

/**
 * Content identity of a merged file. Includes the VOICE because a narrator
 * change re-synthesises clips under the SAME deterministic R2 keys — urls
 * alone cannot reveal that the audio behind them changed.
 */
export function computeMergeHash(
  voice: string,
  slots: TheoryCueSlot[],
  segmentHashes: string[],
): string {
  const parts = [
    voice ?? '',
    ...slots.map((s) => `${s.segmentIndex}:${segmentHashes[s.segmentIndex] ?? ''}`),
  ];
  return createHash('sha256').update(parts.join('|')).digest('hex');
}
```

- [ ] **Step 5: Run the spec to verify it passes** (same command). Expected: PASS (3 describes, 6 tests).
- [ ] **Step 6: `npx tsc --noEmit`** — clean.
- [ ] **Step 7: Commit** (only these three files):
```bash
git add src/modules/courses/src/modules/keypoint/interface/keypoint.interface.ts \
        src/modules/courses/src/modules/voiceover/voiceover-merge.util.ts \
        src/modules/courses/src/modules/voiceover/voiceover-merge.util.spec.ts
git commit -m "feat: cue-slot walk + merged-audio types for keypoint audio merge

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: VoiceoverMergeService (download → ffprobe → concat → upload → persist)

**Files:**
- Create: `src/modules/courses/src/modules/voiceover/voiceover-merge.service.ts`
- Modify: `src/modules/courses/src/modules/voiceover/voiceover.module.ts` (add provider)

**Interfaces:**
- Consumes: Task 1 utils/types; `CloudflareService.uploadExternalFile({originalName, mimeType, body, size, key}) → {url}` (same call `dubCard` makes); `KeypointRepository.findById` / `findOneAndUpdate`; `LearningItemRepository.findNarratableByKeypoint(keypointId)`.
- Produces: `mergeAndPersist(keypointId: string, opts?: { previous?: Record<string, IMergedKeypointAudio>; force?: boolean }): Promise<KeypointMergeResult>` where `KeypointMergeResult = { keypointId: string; merged: string[]; reused: string[]; skipped: string[]; failed: Array<{ lang: string; message: string }> }`.

- [ ] **Step 1: Check ffmpeg availability locally**: `which ffmpeg ffprobe` — if missing, `brew install ffmpeg`. (Container gets it in Task 5.)

- [ ] **Step 2: Implement the service.** Notes that matter: use `execFile` (no shell interpolation); write downloads into `fs.mkdtemp(path.join(os.tmpdir(), 'hddhistory-merge-'))` and always clean up in `finally`; Node 18 has global `fetch`. Skeleton (complete — fill nothing in later):

```ts
import { execFile } from 'child_process';
import { promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { promisify } from 'util';

import { Injectable, Logger } from '@nestjs/common';

import { CloudflareService } from 'src/modules/file/cloudflare/cloudflare.service';

import {
  buildCues,
  computeMergeHash,
  computeTheoryCueSlots,
  TheoryCueSlot,
} from './voiceover-merge.util';
import {
  IMergedKeypointAudio,
} from '../keypoint/interface/keypoint.interface';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';

const execFileAsync = promisify(execFile);

export interface KeypointMergeResult {
  keypointId: string;
  merged: string[]; // langs freshly concatenated
  reused: string[]; // langs whose hash matched `previous`
  skipped: string[]; // langs with no audible theory clip at all
  failed: Array<{ lang: string; message: string }>;
}

@Injectable()
export class VoiceoverMergeService {
  private readonly logger = new Logger(VoiceoverMergeService.name);

  constructor(
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly cloudflareService: CloudflareService,
  ) {}

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
      const prior = previous[lang];
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
        );
        result.merged.push(lang);
      } catch (err: any) {
        // One bad language must not sink the others; segments stay the
        // app's fallback for this lang until the next run.
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
    return result;
  }

  /** Download audible clips → ffprobe each → concat (-c copy) → upload. */
  private async mergeLang(
    keypointId: string,
    lang: string,
    allSlots: TheoryCueSlot[],
    audibleSlots: TheoryCueSlot[],
    segmentUrls: string[],
    hash: string,
  ): Promise<IMergedKeypointAudio> {
    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hddhistory-merge-'));
    try {
      const durationsMs = new Map<number, number>();
      const localFiles: string[] = [];
      for (const slot of audibleSlots) {
        const url = segmentUrls[slot.segmentIndex];
        const local = path.join(tmpDir, `${slot.segmentIndex}.mp3`);
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`clip ${slot.segmentIndex} HTTP ${res.status}`);
        }
        await fs.writeFile(local, Buffer.from(await res.arrayBuffer()));
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
      // re-encode, offsets = the exact per-clip frame durations probed above.
      await execFileAsync('ffmpeg', [
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

      const body = await fs.readFile(outFile);
      const { url } = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${lang}-merged.mp3`,
        mimeType: 'audio/mpeg',
        body,
        size: body.length,
        key: `voiceover/${keypointId}/${lang}/merged.mp3`,
      });

      return { url, durationMs, hash, cues };
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  }

  private async probeDurationMs(file: string): Promise<number> {
    const { stdout } = await execFileAsync('ffprobe', [
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
```
NOTE for the implementer: `keypointRepository.findOneAndUpdate` is exactly how `generateForKeypoint` persists today (`voiceover.service.ts:440-443`) — if the repository exposes a differently-named update, mirror whatever that call site uses.

- [ ] **Step 3: Register the provider** — in `voiceover.module.ts` add `VoiceoverMergeService` to `providers` (import from `./voiceover-merge.service`).
- [ ] **Step 4: `npx tsc --noEmit`** — clean.
- [ ] **Step 5: Commit:**
```bash
git add src/modules/courses/src/modules/voiceover/voiceover-merge.service.ts \
        src/modules/courses/src/modules/voiceover/voiceover.module.ts
git commit -m "feat: merge per-card voiceover clips into one file per keypoint x lang

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Wire merge into the dub pipeline

**Files:**
- Modify: `src/modules/courses/src/modules/voiceover/voiceover.service.ts`

**Interfaces:**
- Consumes: `VoiceoverMergeService.mergeAndPersist(keypointId, { previous })` from Task 2.

- [ ] **Step 1: Inject** `VoiceoverMergeService` into `VoiceoverService`'s constructor (module already provides it; no import cycle — MergeService does not depend on VoiceoverService).
- [ ] **Step 2: Call it at the end of `generateForKeypoint`**, right AFTER the existing `findOneAndUpdate` (`voiceover.service.ts:440-443`) and before `return result;`:

```ts
    // `$set { audio: next }` above replaced the whole audio object, wiping any
    // previous `merged`. Hand that previous map in so unchanged languages are
    // carried over instead of re-concatenated; a merge failure only logs —
    // segments are the app's fallback and the dub itself succeeded.
    try {
      await this.voiceoverMergeService.mergeAndPersist(keypointId, {
        previous: prev.merged,
      });
    } catch (err: any) {
      this.logger.error(
        `Post-dub merge failed (keypoint=${keypointId}): ${err?.message}`,
        err?.stack,
      );
    }
```
- [ ] **Step 3: `npx tsc --noEmit`** — clean.
- [ ] **Step 4: Smoke-check on dev data** (optional but cheap if a local API + Mongo is running): trigger a single-keypoint dub via the existing `POST /api/v1/voiceover/keypoint/:id` and confirm the keypoint document now has `audio.merged.<lang>.url` + `cues` (use the db-query agent, read-only).
- [ ] **Step 5: Commit:**
```bash
git add src/modules/courses/src/modules/voiceover/voiceover.service.ts
git commit -m "feat: merge theory clips after every keypoint dub

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Backfill endpoint (merge-all) + status

**Files:**
- Modify: `src/modules/courses/src/modules/voiceover/voiceover-merge.service.ts` (add the run-all job)
- Modify: `src/modules/courses/src/modules/voiceover/voiceover.controller.ts`

**Interfaces:**
- Produces: `POST /api/v1/voiceover/merge-all` → snapshot; `GET /api/v1/voiceover/merge-all/status` → snapshot. `MergeAllSnapshot = { state: 'idle' | 'running' | 'done'; total: number; done: number; failed: number; startedAt?: string; finishedAt?: string; lastErrors: string[] }`.

- [ ] **Step 1: Add the job to `VoiceoverMergeService`:**

```ts
export interface MergeAllSnapshot {
  state: 'idle' | 'running' | 'done';
  total: number;
  done: number;
  failed: number;
  startedAt?: string;
  finishedAt?: string;
  lastErrors: string[];
}
```
```ts
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

  /** Fire-and-forget backfill over every keypoint that has per-card segments. */
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
          const r = await this.mergeAndPersist(String(id), {
            force: opts?.force,
          });
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
    this.mergeAll.lastErrors = [message, ...this.mergeAll.lastErrors].slice(0, 5);
  }
```
Sequential on purpose (one keypoint at a time): each merge already fans out per-lang downloads, and this shares the event loop with live traffic.

- [ ] **Step 2: Add `findIdsWithSegments` to `KeypointRepository`** (`src/modules/courses/src/modules/keypoint/repository/keypoint.repository.ts`) — repositories are the only DB layer, so the query lives here, following the repository's existing method style. Shape:

```ts
  async findIdsWithSegments(): Promise<string[]> {
    const docs = await this.model
      .find({ 'audio.segments': { $exists: true, $ne: {} } }, { _id: 1 })
      .lean();
    return docs.map((d: any) => String(d._id));
  }
```
(If the abstract Mongo repository names its model handle differently — check a sibling method in the same file and copy its access pattern.)

- [ ] **Step 3: Controller routes** — mirror the decorators/guards of the existing `@Post('generate-all')` route EXACTLY (same auth/roles), adding:

```ts
  @Post('merge-all')
  async mergeAll(@Query('force') force?: string) {
    return this.voiceoverMergeService.startMergeAll({ force: force === 'true' });
  }

  @Get('merge-all/status')
  getMergeAllStatus() {
    return this.voiceoverMergeService.snapshot();
  }
```
(inject `VoiceoverMergeService` into the controller constructor).

- [ ] **Step 4: `npx tsc --noEmit`** — clean. Run the util spec once more (regression): `npm test -- src/modules/courses/src/modules/voiceover/voiceover-merge.util.spec.ts` → PASS.
- [ ] **Step 5: Commit:**
```bash
git add src/modules/courses/src/modules/voiceover/voiceover-merge.service.ts \
        src/modules/courses/src/modules/voiceover/voiceover.controller.ts \
        src/modules/courses/src/modules/keypoint/repository/keypoint.repository.ts
git commit -m "feat: merge-all backfill endpoint for existing dubbed keypoints

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: ffmpeg in the container + rollout notes

**Files:**
- Modify: `Dockerfile`
- Modify: `plans/260803-merged-keypoint-audio/README.md` (rollout checklist appendix)

- [ ] **Step 1: Dockerfile** — in the **production** stage, BEFORE `USER appuser` (apk needs root), add:

```dockerfile
# ffmpeg + ffprobe for VoiceoverMergeService (keypoint audio concat)
RUN apk add --no-cache ffmpeg
```

- [ ] **Step 2: Append a rollout checklist** to the spec README:

```markdown
## Rollout checklist (API)

1. Merge branch → develop → deploy dev qua Jenkins (`/deploy-api`).
2. `POST /api/v1/voiceover/merge-all` (bearer admin) trên dev.
3. Poll `GET /api/v1/voiceover/merge-all/status` đến `state: done`;
   `failed` phải ≈ 0, xem `lastErrors` nếu không.
4. Spot-check 2-3 keypoint (db-query, read-only): `audio.merged.vi.url`
   tồn tại, `cues` phủ đúng số theory documents, `durationMs` ≈ tổng durMs.
5. Chỉ sau đó mới ship app (Phase 2) — app tự fallback khi thiếu `merged`.
```

- [ ] **Step 3: Commit:**
```bash
git add Dockerfile plans/260803-merged-keypoint-audio/README.md
git commit -m "chore: ffmpeg in api image + merge rollout checklist

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

# Phase 2 — hddhistory-flutter

All paths below are relative to `hddhistory-flutter/`. First step of this phase: `git switch -c feature/merged-keypoint-audio` (from `develop`).

### Task 6: Merged-audio model + entity + codegen

**Files:**
- Modify: `lib/src/course/data/models/keypoint_audio_model.dart`
- Modify: `lib/src/course/domain/entities/keypoint_audio_entity.dart`
- Modify: `lib/src/course/domain/entities/keypoint_entity.dart`

**Interfaces (produced):**
- `MergedAudioCueEntity { learningItemId, documentIndex, startMs, durMs }`
- `MergedKeypointAudioEntity { url, durationMs, cues }` + `bool get isUsable`
- `KeypointAudioEntity.merged: Map<String, MergedKeypointAudioEntity>?` + `MergedKeypointAudioEntity? get resolvedMerged`
- `KeypointEntity.resolvedMergedAudio → MergedKeypointAudioEntity?`

- [ ] **Step 1: Models** — in `keypoint_audio_model.dart` add (same file, `part of course.dart` style):

```dart
@freezed
abstract class MergedAudioCueModel with _$MergedAudioCueModel {
  const factory MergedAudioCueModel({
    @Default('') String learningItemId,
    @Default(0) int documentIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _MergedAudioCueModel;

  factory MergedAudioCueModel.fromJson(Map<String, dynamic> json) => _$MergedAudioCueModelFromJson(json);
}

@freezed
abstract class MergedKeypointAudioModel with _$MergedKeypointAudioModel {
  const factory MergedKeypointAudioModel({
    @Default('') String url,
    @Default(0) int durationMs,
    @Default([]) List<MergedAudioCueModel> cues,
  }) = _MergedKeypointAudioModel;

  factory MergedKeypointAudioModel.fromJson(Map<String, dynamic> json) => _$MergedKeypointAudioModelFromJson(json);
}
```
add to `KeypointAudioModel`: `Map<String, MergedKeypointAudioModel>? merged,` and extend `toEntity()`:
```dart
  KeypointAudioEntity toEntity() => KeypointAudioEntity(
    url: url,
    text: text,
    segments: segments,
    merged: merged?.map((lang, m) => MapEntry(lang, m.toEntity())),
  );
```
plus per-model `toEntity()` extensions mirroring the fields 1:1.

- [ ] **Step 2: Entities** — in `keypoint_audio_entity.dart` add `MergedAudioCueEntity` and `MergedKeypointAudioEntity` (freezed, same defaults as models) with:

```dart
extension MergedKeypointAudioEntityX on MergedKeypointAudioEntity {
  /// A merged file is only worth switching modes for when it can drive the
  /// deck: a url to play and at least one audible cue to map cards with.
  bool get isUsable => url.isNotEmpty && cues.any((c) => c.durMs > 0);
}
```
add `Map<String, MergedKeypointAudioEntity>? merged,` to `KeypointAudioEntity`, and a resolver next to `resolvedSegments` **reusing its exact fallback chain**:
```dart
  /// The merged whole-keypoint narration for the active locale, or null when
  /// this keypoint has not been merged yet (then callers stay on the per-card
  /// path). Same locale fallback order as [resolvedSegments].
  MergedKeypointAudioEntity? get resolvedMerged {
    final byLanguage = merged;
    if (byLanguage == null || byLanguage.isEmpty) return null;

    final locale = AppDI.injector.get<LocaleCubit>().state;
    final preferred = switch (locale) {
      AppLocale.en => 'en',
      AppLocale.vi => 'vi',
      AppLocale.zh => 'zh',
      AppLocale.ja => 'ja',
      AppLocale.ko => 'ko',
    };

    for (final code in [preferred, 'en', 'vi', 'zh', 'ja', 'ko']) {
      final candidate = byLanguage[code];
      if (candidate != null && candidate.isUsable) return candidate;
    }
    return null;
  }
```
In `keypoint_entity.dart` extension add:
```dart
  MergedKeypointAudioEntity? get resolvedMergedAudio => audio?.resolvedMerged;
```

- [ ] **Step 3: Codegen:** `dart run build_runner build --delete-conflicting-outputs` — expect "wrote N outputs" (slang asset warning is noise).
- [ ] **Step 4:** `flutter analyze` (hook output) — clean. `dart format` the three edited .dart files only.
- [ ] **Step 5: Commit** (the three source files + their regenerated `*.freezed.dart`/`*.g.dart` siblings ONLY):
```bash
git add lib/src/course/data/models/keypoint_audio_model.dart \
        lib/src/course/domain/entities/keypoint_audio_entity.dart \
        lib/src/course/domain/entities/keypoint_entity.dart \
        lib/src/course/data/models/keypoint_audio_model.freezed.dart \
        lib/src/course/data/models/keypoint_audio_model.g.dart \
        lib/src/course/domain/entities/keypoint_audio_entity.freezed.dart \
        lib/src/course/domain/entities/keypoint_audio_entity.g.dart \
        lib/src/course/domain/entities/keypoint_entity.freezed.dart \
        lib/src/course/domain/entities/keypoint_entity.g.dart
git commit -m "feat: merged keypoint audio model + entity with cue map

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
(If generated siblings live under different names, `git status` and add exactly the generated files belonging to these three sources.)

---

### Task 7: MergedNarrationTimeline (pure cue math) + unit test

**Files:**
- Create: `lib/src/lesson/presentation/cubits/lesson_audio/merged_narration_timeline.dart` (add `part` entry in `lib/src/lesson/lesson.dart` next to the other lesson_audio parts)
- Test: `test/unit/lesson/presentation/cubits/merged_narration_timeline_test.dart`

**Interfaces (produced):**
- `MergedNarrationTimeline(MergedKeypointAudioEntity merged)`
- `int cueIndexAtMs(int positionMs)` — audible cue containing the position; positions past the end → last audible cue; positions inside a zero-length gap → the next audible cue.
- `int? cueIndexForCard({required String learningItemId, required int documentIndex})` — null for cards absent from the cue list (video) OR with `durMs == 0`.
- `MergedAudioCueEntity? cueAt(int index)`; `int get lastAudibleCueIndex`; `int endMsOf(int index)`; `int nextAudibleCueAfter(int index)` — smallest audible cue index > `index`, or `index` itself when nothing audible follows (the gate then simply cannot extend).

- [ ] **Step 1: Write the failing test:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  const cues = [
    MergedAudioCueEntity(learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 4000),
    MergedAudioCueEntity(learningItemId: 't1', documentIndex: 1, startMs: 4000, durMs: 0),
    MergedAudioCueEntity(learningItemId: 't2', documentIndex: 0, startMs: 4000, durMs: 6000),
  ];
  const merged = MergedKeypointAudioEntity(url: 'https://x/m.mp3', durationMs: 10000, cues: cues);
  const timeline = MergedNarrationTimeline(merged);

  group('cueIndexAtMs', () {
    test('start of file is the first cue', () => expect(timeline.cueIndexAtMs(0), 0));
    test('inside the first cue', () => expect(timeline.cueIndexAtMs(3999), 0));
    test('a boundary belongs to the NEXT audible cue, skipping durMs 0', () => expect(timeline.cueIndexAtMs(4000), 2));
    test('past the end clamps to the last audible cue', () => expect(timeline.cueIndexAtMs(999999), 2));
  });

  group('cueIndexForCard', () {
    test('finds an audible card', () {
      expect(timeline.cueIndexForCard(learningItemId: 't2', documentIndex: 0), 2);
    });
    test('a silent card has no cue to point the player at', () {
      expect(timeline.cueIndexForCard(learningItemId: 't1', documentIndex: 1), isNull);
    });
    test('a card that was never dubbed has no cue', () {
      expect(timeline.cueIndexForCard(learningItemId: 'video', documentIndex: 0), isNull);
    });
  });

  test('endMsOf / lastAudibleCueIndex', () {
    expect(timeline.endMsOf(0), 4000);
    expect(timeline.lastAudibleCueIndex, 2);
  });

  test('nextAudibleCueAfter skips silent cues and saturates at the end', () {
    expect(timeline.nextAudibleCueAfter(0), 2); // cue 1 is silent
    expect(timeline.nextAudibleCueAfter(2), 2); // nothing audible after
  });
}
```

- [ ] **Step 2: Run it to verify it fails:** `flutter test test/unit/lesson/presentation/cubits/merged_narration_timeline_test.dart` → FAIL (class undefined). (Single file — allowed.)
- [ ] **Step 3: Implement:**

```dart
part of '../../../lesson.dart';

/// Pure cue math for one merged keypoint narration file. Card identity in,
/// file time out — the ONLY place the app converts between the two, so the
/// deck never mirrors backend numbering again.
class MergedNarrationTimeline {
  const MergedNarrationTimeline(this.merged);

  final MergedKeypointAudioEntity merged;

  List<MergedAudioCueEntity> get _cues => merged.cues;

  MergedAudioCueEntity? cueAt(int index) => (index < 0 || index >= _cues.length) ? null : _cues[index];

  int endMsOf(int index) {
    final cue = cueAt(index);
    return cue == null ? 0 : cue.startMs + cue.durMs;
  }

  int get lastAudibleCueIndex {
    for (var i = _cues.length - 1; i >= 0; i--) {
      if (_cues[i].durMs > 0) return i;
    }
    return -1;
  }

  /// The audible cue [positionMs] falls in. A boundary (or a zero-length gap)
  /// belongs to the NEXT audible cue — the voice is about to read it; past the
  /// last audible cue's end, clamps to that cue.
  int cueIndexAtMs(int positionMs) {
    var lastAudible = -1;
    for (var i = 0; i < _cues.length; i++) {
      final cue = _cues[i];
      if (cue.durMs <= 0) continue;
      if (positionMs < cue.startMs + cue.durMs) return i;
      lastAudible = i;
    }
    return lastAudible;
  }

  /// Smallest AUDIBLE cue index after [index], or [index] when nothing
  /// audible follows — the gate bound then stays where it is.
  int nextAudibleCueAfter(int index) {
    for (var i = index + 1; i < _cues.length; i++) {
      if (_cues[i].durMs > 0) return i;
    }
    return index;
  }

  /// File-time home of one CARD, or null when the card has nothing audible —
  /// the caller leaves narration alone exactly as the per-card path does for
  /// a missing clip.
  int? cueIndexForCard({required String learningItemId, required int documentIndex}) {
    for (var i = 0; i < _cues.length; i++) {
      final cue = _cues[i];
      if (cue.learningItemId == learningItemId && cue.documentIndex == documentIndex) {
        return cue.durMs > 0 ? i : null;
      }
    }
    return null;
  }
}
```
Add `part 'src/lesson/presentation/cubits/lesson_audio/merged_narration_timeline.dart';` — matching the exact relative-path style of the neighbouring `lesson_audio_*.dart` part entries in `lib/src/lesson/lesson.dart`.

- [ ] **Step 4: Run the test again** → PASS. `flutter analyze` clean.
- [ ] **Step 5: Commit:**
```bash
git add lib/src/lesson/lesson.dart \
        lib/src/lesson/presentation/cubits/lesson_audio/merged_narration_timeline.dart \
        test/unit/lesson/presentation/cubits/merged_narration_timeline_test.dart
git commit -m "feat: cue timeline math for merged keypoint narration

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: LessonAudioCubit merged mode

**Files:**
- Modify: `lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_state.dart`
- Modify: `lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_cubit.dart`

**Interfaces (produced, consumed by Task 9/10):**
- `LessonAudioState`: `+ @Default(false) bool isMergedMode`, `+ @Default(-1) int activeCueIndex`. In merged mode `positionSeconds`/`durationSeconds` are **card-relative** (position inside / duration of the active cue) so `progressForCard` and `NarrationAutoScroll` keep working unchanged; the lock screen gets true file position straight from the player.
- `MergedNarrationTimeline? get timeline`
- `int? cueForCard({required String learningItemId, required int documentIndex})` (wraps timeline)
- `void setAllowedThroughCue(int cueIndex)` — highest cue the voice may play INTO without stopping; the deck owns the value (gates + lifecycle), the cubit only enforces it.
- `Future<void> playCue(int cueIndex, {bool autoplay = false, Duration? offset})`
- `enterAudioMode({bool autoplay = true, Duration? startAt})` — startAt = absolute file position (resume path; merged mode only, ignored on legacy).
- Emits `hasCompletedPlayback: true` when pausing at a gated boundary AND at true end-of-file — the deck's existing completion semantics.

- [ ] **Step 1: State fields** — add to `LessonAudioState`:
```dart
    @Default(false) bool isMergedMode,
    @Default(-1) int activeCueIndex,
```
- [ ] **Step 2: Cubit fields + configure()** — add:
```dart
  MergedNarrationTimeline? _timeline;
  MergedNarrationTimeline? get timeline => _timeline;
  bool get isMergedMode => _timeline != null;
  static const int unboundedCue = 1 << 30;
  int _allowedThroughCue = unboundedCue;
```
In `configure(keypoint)` FIRST resolve merged:
```dart
    final mergedAudio = keypoint.resolvedMergedAudio;
    _timeline = mergedAudio == null ? null : MergedNarrationTimeline(mergedAudio);
    _allowedThroughCue = unboundedCue;
```
then when `_timeline != null` use `nextSourceUrl = mergedAudio.url` (skip the segments/first-clip pick, keep `_cardClips` populated anyway for safety) and include `isMergedMode: true, activeCueIndex: -1` in the emitted state. The early-return identity check must ALSO match on the new source url (it already compares `sourceUrl`, so no change needed).
- [ ] **Step 3: `cueForCard` + `setAllowedThroughCue`:**
```dart
  int? cueForCard({required String learningItemId, required int documentIndex}) =>
      _timeline?.cueIndexForCard(learningItemId: learningItemId, documentIndex: documentIndex);

  /// The deck's gate bound. RAISING it while the voice sits paused at that very
  /// boundary does not auto-play — the deck decides that (it knows why it rose).
  void setAllowedThroughCue(int cueIndex) => _allowedThroughCue = cueIndex;
```
- [ ] **Step 4: `playCue`:**
```dart
  /// Points the merged file at [cueIndex] (+[offset] inside it). The deck's
  /// merged-mode replacement for [loadCard] — a seek, never a source reload.
  Future<void> playCue(int cueIndex, {bool autoplay = false, Duration? offset}) async {
    final timeline = _timeline;
    final cue = timeline?.cueAt(cueIndex);
    if (timeline == null || cue == null || cue.durMs <= 0) return;

    final targetMs = cue.startMs + (offset?.inMilliseconds ?? 0);
    if (!state.hasStartedSession) {
      _playWhenReady = autoplay;
      await _initializePlayer(startAt: Duration(milliseconds: targetMs));
      return;
    }
    try {
      await _handler.seek(Duration(milliseconds: targetMs));
      emit(state.copyWith(activeCueIndex: cueIndex, hasCompletedPlayback: false));
      if (autoplay) await play();
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.playCue');
    }
  }
```
- [ ] **Step 5: `enterAudioMode` startAt** — change signature to `enterAudioMode({bool autoplay = true, Duration? startAt})`; when `state.hasStartedSession` is false call `_initializePlayer(startAt: isMergedMode ? startAt : null)`. (`startAt` reaches `loadItem`'s `initialPosition`, which already exists.)
- [ ] **Step 6: Merged position pipeline** — in `_initializePlayer`, branch the subscriptions when `isMergedMode`:
  - Skip the `durationStream` subscription (card duration comes from cues).
  - Replace the position subscription body:
```dart
      _positionSubscription = _handler.positionStream.listen((position) {
        if (isClosed) return;
        if (!isMergedMode) { /* existing whole-second mirror */ return; }
        _onMergedTick(position.inMilliseconds);
      });
```
```dart
  void _onMergedTick(int positionMs) {
    final timeline = _timeline;
    if (timeline == null || state.status != LessonAudioLoadStatus.ready) return;

    final cueIndex = timeline.cueIndexAtMs(positionMs);
    if (cueIndex < 0) return;

    // The deck said "no further": hold EXACTLY at the allowed cue's end, in a
    // completed-looking state — the same shape a finished per-card clip leaves,
    // so every existing deck reaction applies unchanged.
    if (cueIndex > _allowedThroughCue) {
      final holdMs = timeline.endMsOf(_allowedThroughCue.clamp(0, timeline.merged.cues.length - 1));
      unawaited(_handler.pause());
      unawaited(_handler.seek(Duration(milliseconds: holdMs)));
      final heldCue = timeline.cueIndexAtMs(holdMs - 1);
      final held = timeline.cueAt(heldCue);
      emit(state.copyWith(
        isPlaying: false,
        hasCompletedPlayback: true,
        activeCueIndex: heldCue,
        positionSeconds: held == null ? 0 : (held.durMs / 1000).round(),
        durationSeconds: held == null ? 0 : (held.durMs / 1000).round(),
      ));
      return;
    }

    final cue = timeline.cueAt(cueIndex)!;
    final cardPositionSeconds = ((positionMs - cue.startMs) / 1000).floor().clamp(0, 359999);
    final cardDurationSeconds = (cue.durMs / 1000).round().clamp(0, 359999);
    if (cueIndex != state.activeCueIndex || cardPositionSeconds != state.positionSeconds || cardDurationSeconds != state.durationSeconds) {
      emit(state.copyWith(
        activeCueIndex: cueIndex,
        positionSeconds: cardPositionSeconds,
        durationSeconds: cardDurationSeconds,
        hasCompletedPlayback: false,
      ));
    }
  }
```
  - `processingStateStream` completed handler: keep as is (pause + `hasCompletedPlayback: true`) — in merged mode that fires once, at true end of file. The `duration` returned by `loadItem` must NOT overwrite card-relative `durationSeconds` in merged mode — guard the `emit(durationSeconds: duration.inSeconds)` with `if (!isMergedMode)`.
  - (Resume persistence deliberately does NOT appear in this task — Task 10 adds `_maybePersistResume` and its call at the end of `_onMergedTick`, so this task compiles and ships standalone.)
- [ ] **Step 7:** `flutter analyze` clean; `dart format` edited files. Commit:
```bash
git add lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_cubit.dart \
        lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_state.dart \
        lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_state.freezed.dart \
        lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_state.g.dart
git commit -m "feat: merged-file playback mode in LessonAudioCubit with cue ticks and gate bound

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
(run `dart run build_runner build --delete-conflicting-outputs` first for the state file's freezed output.)

---

### Task 9: Deck ↔ merged-player sync (KeypointCardCubit + builder reveal-by-identity)

**Files:**
- Modify: `lib/src/lesson/presentation/cubits/keypoint_card/keypoint_cards_builder.dart`
- Modify: `lib/src/lesson/presentation/cubits/keypoint_card/keypoint_card_cubit.dart`
- Test: extend `test/unit/lesson/presentation/cubits/keypoint_cards_builder_test.dart`

**Interfaces:**
- Consumes: Task 8's `isMergedMode`, `activeCueIndex`, `timeline`, `cueForCard`, `playCue`, `setAllowedThroughCue`, `LessonAudioCubit.unboundedCue`.
- Produces: `KeypointCardsBuilder.build(..., ({String learningItemId, int documentIndex})? revealToCard)`; `KeypointCardCubit.jumpToCard({required String learningItemId, required int documentIndex, Duration? startAt})` (consumed by Task 10's resume entry).

- [ ] **Step 1: Builder — reveal by identity.** Add the optional named param `({String learningItemId, int documentIndex})? revealToCard` to `build`. Change `stillSeekingReveal` and `emitCard`:
```dart
    bool stillSeekingReveal() => (revealToClipIndex >= 0 || revealToCard != null) && revealCardIndex < 0;

    void emitCard(KeypointCardDescriptor descriptor, int? clipIndex) {
      cards.add(descriptor);
      if (revealToCard != null &&
          descriptor.learningItemId == revealToCard.learningItemId &&
          descriptor.documentIndex == revealToCard.documentIndex) {
        revealCardIndex = cards.length - 1;
      }
      if (clipIndex == null) return;
      cardToClip[cards.length - 1] = clipIndex;
      if (clipIndex == revealToClipIndex) revealCardIndex = cards.length - 1;
    }
```
- [ ] **Step 2: Builder test (failing first):** add to the existing builder test file a case: items `[theory A(2 docs), theory B(2 docs)]`, `currentLearningItemIndex: 0`, `liveIndexInCurrentItem: 0`, `revealToCard: (learningItemId: 'B', documentIndex: 1)` → expect 4 theory cards emitted (reveal reaches B/1), `revealCardIndex == 3`, `liveCardIndex == 0`. Run ONLY this file: `flutter test test/unit/lesson/presentation/cubits/keypoint_cards_builder_test.dart` — write test → FAIL → (builder change from Step 1 makes it) PASS.
- [ ] **Step 3: KeypointCardCubit — merged plumbing.** Add fields:
```dart
  ({String learningItemId, int documentIndex})? _revealToCardTarget;
  int _lastSeenCueIndex = -1;
  StreamSubscription<TheoryState>? _theorySubscription;
```
  - constructor: `_theorySubscription = _theoryCubit.stream.listen((_) => _pushAllowedThroughCue());` and call `_pushAllowedThroughCue()` once after the initial `_rebuildCards`. Cancel in `close()`.
  - `_rebuildCards`: pass `revealToCard: _revealToCardTarget` into the builder; clear `_revealToCardTarget` under the same condition `_revealToClipIndex` is cleared (`built.liveCardIndex >= built.revealCardIndex`); after the emit, call `_pushAllowedThroughCue()`.
- [ ] **Step 4: `_pushAllowedThroughCue`** — the single place gate rules become a number:
```dart
  /// Highest cue the voice may play INTO without stopping, from the deck's
  /// gates. Backgrounded, everything up to the paywall is allowed (the OS
  /// controls promise an ordinary player — same rule playRestOfKeypoint
  /// encodes for the legacy path; the paywall wall wins over everything,
  /// background included). Foregrounded: through the deck's reachable region
  /// — `revealBound`, NOT `furthestCardIndex`, because after a background
  /// read-ahead the voice legitimately sits on revealed cards and a tighter
  /// bound would yank it backwards — plus one audible cue more when the live
  /// card owes nothing (canContinue): crossing it is what advances the live
  /// edge, and this recomputes for the next boundary. The extension is
  /// computed in CUE space (nextAudibleCueAfter): at the live edge the next
  /// card does not exist yet, so a card-space walk could never reach it.
  void _pushAllowedThroughCue() {
    if (!_audioCubit.isMergedMode) return;
    final timeline = _audioCubit.timeline;
    if (timeline == null) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isBackground = !(lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive);
    final cap = _paywallCardCap;

    if (isBackground && cap == null) {
      _audioCubit.setAllowedThroughCue(LessonAudioCubit.unboundedCue);
      return;
    }

    var allowedCardBound = isBackground ? cap! : state.revealBound;
    if (cap != null && allowedCardBound > cap) allowedCardBound = cap;

    // Last audible cue among the reachable (built) cards.
    var allowedCue = -1;
    for (var index = 0; index <= allowedCardBound && index < state.cards.length; index++) {
      final descriptor = state.cards[index];
      if (!descriptor.isTheory) continue;
      final cue = _audioCubit.cueForCard(
        learningItemId: descriptor.learningItemId,
        documentIndex: descriptor.documentIndex,
      );
      if (cue != null) allowedCue = cue;
    }
    // Cards not built yet (entry burst) — leave the voice unrestrained rather
    // than pausing narration on a transient empty deck.
    if (allowedCue < 0) {
      _audioCubit.setAllowedThroughCue(LessonAudioCubit.unboundedCue);
      return;
    }

    // One boundary further ONLY at the true live edge with an open gate —
    // never while the deck sits in revealed (read-only) territory.
    final atTrueLiveEdge = state.revealBound == state.furthestCardIndex;
    final underCap = cap == null || state.furthestCardIndex < cap;
    if (!isBackground && atTrueLiveEdge && underCap && _theoryCubit.state.canContinue) {
      allowedCue = timeline.nextAudibleCueAfter(allowedCue);
    }
    _audioCubit.setAllowedThroughCue(allowedCue);
  }
```
- [ ] **Step 5: `_loadCardNarration` merged branch** — at the top, before the legacy `hasCardClips` guard:
```dart
    if (_audioCubit.isMergedMode) {
      if (index < 0 || index >= state.cards.length) return;
      final descriptor = state.cards[index];
      if (!descriptor.isTheory) return;
      final cueIndex = _audioCubit.cueForCard(
        learningItemId: descriptor.learningItemId,
        documentIndex: descriptor.documentIndex,
      );
      if (cueIndex == null) return;
      _loadedClipCardIndex = index;
      // The voice is already reading this very cue (deck following player):
      // do NOT seek — that restarts the sentence.
      if (cueIndex == _audioCubit.state.activeCueIndex && startAt == null) return;
      final audioState = _audioCubit.state;
      final autoplay = startAt != null || audioState.isPlaying || audioState.hasCompletedPlayback;
      unawaited(_audioCubit.playCue(cueIndex, autoplay: autoplay, offset: startAt));
      return;
    }
```
- [ ] **Step 6: `_onAudioStateChanged` merged branch** — insert BEFORE the `hasCompletedPlayback` block:
```dart
    if (_audioCubit.isMergedMode && audioState.activeCueIndex >= 0 && audioState.activeCueIndex != _lastSeenCueIndex) {
      _lastSeenCueIndex = audioState.activeCueIndex;
      _onMergedCueChanged(audioState.activeCueIndex);
    }
```
```dart
  /// The player crossed into a new cue: bring the deck along. Mirrors the
  /// per-clip completion branches — same gates, same order — but as a FOLLOW
  /// (the audio kept playing through the boundary; nothing reloads).
  void _onMergedCueChanged(int cueIndex) {
    final timeline = _audioCubit.timeline;
    final cue = timeline?.cueAt(cueIndex);
    if (cue == null) return;

    int cardIndexForCue() {
      for (var i = 0; i < state.cards.length; i++) {
        final d = state.cards[i];
        if (d.isTheory && d.learningItemId == cue.learningItemId && d.documentIndex == cue.documentIndex) {
          return i;
        }
      }
      return -1;
    }

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isBackground = !(lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive);

    var cardIndex = cardIndexForCue();

    // Cue past the built deck (true live edge). Foreground with an open gate:
    // advance for real — this is where lesson progress moves (the per-clip
    // path's nextDocument call, relocated). One cue can be several documents
    // ahead when silent cards sit between audible ones, so advance until the
    // cue's card exists; nextDocument emits synchronously but the deck's own
    // stream listener runs a microtask later, hence the direct _rebuildCards.
    // Backgrounded: leave the deck alone; the return path reveals to wherever
    // the voice got (didChangeAppLifecycleState → jumpToCard).
    if (cardIndex < 0 && !isBackground) {
      var guard = 0;
      while (cardIndex < 0 && guard++ < 50) {
        if (isAtPaywallWall || !_theoryCubit.state.canContinue) break;
        final before = (_lessonCubit.state.currentLearningItemIndex, _theoryCubit.state.currentDocumentIndex);
        _theoryCubit.nextDocument();
        _rebuildCards(_lessonCubit.state);
        final after = (_lessonCubit.state.currentLearningItemIndex, _theoryCubit.state.currentDocumentIndex);
        if (after == before) break; // refused (gate/end) — stop pushing
        cardIndex = cardIndexForCue();
      }
    }

    if (cardIndex >= 0) {
      if (cardIndex != state.viewedCardIndex && !isBackground) viewCard(cardIndex);
      if (cardIndex == state.viewedCardIndex) _loadedClipCardIndex = cardIndex;
    }
    _pushAllowedThroughCue();
  }
```
- [ ] **Step 7: Lifecycle, merged branch** — extend `didChangeAppLifecycleState`:
```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (_audioCubit.isMergedMode) {
      _pushAllowedThroughCue();
      if (lifecycleState != AppLifecycleState.resumed) {
        // Going away mid-hold: the voice paused at a gate the reader can't
        // answer from the lock screen — read on, like the legacy queue does.
        final audioState = _audioCubit.state;
        if (audioState.hasCompletedPlayback && !audioState.isPlaying && audioState.activeCueIndex >= 0 && audioState.activeCueIndex < (_audioCubit.timeline?.lastAudibleCueIndex ?? -1)) {
          unawaited(_audioCubit.play());
        }
        return;
      }
      // Back on screen: land the deck on the card being read, at full flight.
      final cueIndex = _audioCubit.state.activeCueIndex;
      final cue = _audioCubit.timeline?.cueAt(cueIndex);
      if (cue != null) {
        jumpToCard(learningItemId: cue.learningItemId, documentIndex: cue.documentIndex);
      }
      return;
    }
    // ... existing legacy body unchanged ...
  }
```
- [ ] **Step 8: `jumpToCard`** (also Task 10's resume entry point):
```dart
  /// Moves the view onto the card with this identity, revealing it first when
  /// it sits past the live edge (revealed cards are NOT progress — they render
  /// read-only past the edge exactly like the legacy narration reveal).
  void jumpToCard({required String learningItemId, required int documentIndex, Duration? startAt}) {
    _revealToCardTarget = (learningItemId: learningItemId, documentIndex: documentIndex);
    _rebuildCards(_lessonCubit.state);

    for (var i = 0; i < state.cards.length; i++) {
      final d = state.cards[i];
      if (d.isTheory && d.learningItemId == learningItemId && d.documentIndex == documentIndex) {
        viewCard(i, startAt: startAt);
        return;
      }
    }
  }
```
- [ ] **Step 9: `_listenOnWhileAway`** — first line add: `if (_audioCubit.isMergedMode) return;` (merged background continuation is automatic; the queue path is legacy-only). Same guard at the top of the legacy-only `didChangeAppLifecycleState` body is already covered by Step 7's early branch.
- [ ] **Step 10:** `flutter analyze` clean; run the builder test file once → PASS; `dart format` edited files. Commit:
```bash
git add lib/src/lesson/presentation/cubits/keypoint_card/keypoint_cards_builder.dart \
        lib/src/lesson/presentation/cubits/keypoint_card/keypoint_card_cubit.dart \
        test/unit/lesson/presentation/cubits/keypoint_cards_builder_test.dart
git commit -m "feat: deck follows the merged narration file across cue boundaries

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 10: Resume record (HydratedCubit) + entry resume

**Files:**
- Create: `lib/src/lesson/presentation/cubits/listen_resume/listen_resume_cubit.dart`
- Create: `lib/src/lesson/presentation/cubits/listen_resume/listen_resume_state.dart` (+ `part` entries in `lib/src/lesson/lesson.dart`)
- Modify: `lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_cubit.dart` (the three `_maybePersistResume`/pause/close call sites from Task 8 Step 7)
- Modify: `lib/src/lesson/presentation/cubits/lesson/lesson_cubit.dart` (`jumpToItem`, clear-on-complete)
- Modify: `lib/src/lesson/presentation/cubits/theory/theory_cubit.dart` (`jumpToDocument`)
- Modify: `lib/src/lesson/presentation/pages/lesson_page.dart` (entry resume)
- Test: `test/unit/lesson/presentation/cubits/listen_resume_cubit_test.dart`

**Interfaces:**
- `ListenResumeCubit extends HydratedCubit<ListenResumeState>` `@lazySingleton`, with `static ListenResumeCubit? get instanceOrNull` (null before DI init — keeps LessonAudioCubit testable), `void record({required String keypointId, required int positionMs})`, `ListenResumeState? recordFor(String keypointId)` (null when keypoint differs or older than 7 days), `void clear(String keypointId)`.
- `LessonCubit.jumpToItem(int index)`; `TheoryCubit.jumpToDocument(int index)`.
- Consumes: `KeypointCardCubit.jumpToCard` (Task 9), `LessonAudioCubit.enterAudioMode(startAt:)` + `timeline` (Task 8).

- [ ] **Step 1: State:**
```dart
part of '../../../lesson.dart';

@freezed
abstract class ListenResumeState with _$ListenResumeState {
  const factory ListenResumeState({
    @Default('') String keypointId,
    @Default(0) int positionMs,
    @Default(0) int updatedAtMillis,
  }) = _ListenResumeState;

  factory ListenResumeState.initial() => const ListenResumeState();

  factory ListenResumeState.fromJson(Map<String, dynamic> json) => _$ListenResumeStateFromJson(json);
}
```
- [ ] **Step 2: Cubit (failing test first).** Test:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

// Mock HydratedBloc storage the way test/unit/config/services/device/
// hydrated_service_test.dart does (setUpAll + a mocked Storage assigned to
// HydratedBloc.storage) — copy that file's storage setup verbatim.
void main() {
  // <hydrated storage setup from the pattern file goes here>


  test('recordFor returns the stored position for the same keypoint', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 42000);
    expect(cubit.recordFor('kp1')?.positionMs, 42000);
    expect(cubit.recordFor('kp2'), isNull);
  });

  test('clear wipes only a matching keypoint', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 42000);
    cubit.clear('other'); // no-op
    expect(cubit.recordFor('kp1'), isNotNull);
    cubit.clear('kp1');
    expect(cubit.recordFor('kp1'), isNull);
  });

  test('a record older than 7 days is not offered', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 1000);
    cubit.emitForTest(cubit.state.copyWith(updatedAtMillis: DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch));
    expect(cubit.recordFor('kp1'), isNull);
  });
}
```
Run just this file → FAIL. Implement:
```dart
part of '../../../lesson.dart';

/// One "đang nghe dở" bookmark — the LAST keypoint the reader was listening
/// to and the exact millisecond of its merged file. Survives app kill
/// (hydrated); consumed once on lesson entry, wiped on keypoint completion.
/// Deliberately a single record, not a map: resume is "continue what I was
/// doing", not a library of positions.
@lazySingleton
class ListenResumeCubit extends HydratedCubit<ListenResumeState> {
  ListenResumeCubit() : super(ListenResumeState.initial());

  static const Duration maxAge = Duration(days: 7);

  static ListenResumeCubit? get instanceOrNull =>
      AppDI.injector.isRegistered<ListenResumeCubit>() ? AppDI.injector.get<ListenResumeCubit>() : null;

  void record({required String keypointId, required int positionMs}) {
    if (keypointId.isEmpty) return;
    emit(ListenResumeState(keypointId: keypointId, positionMs: positionMs, updatedAtMillis: DateTime.now().millisecondsSinceEpoch));
  }

  ListenResumeState? recordFor(String keypointId) {
    if (state.keypointId.isEmpty || state.keypointId != keypointId) return null;
    final age = DateTime.now().millisecondsSinceEpoch - state.updatedAtMillis;
    if (age > maxAge.inMilliseconds) return null;
    return state;
  }

  void clear(String keypointId) {
    if (state.keypointId != keypointId) return;
    emit(ListenResumeState.initial());
  }

  @visibleForTesting
  void emitForTest(ListenResumeState next) => emit(next);

  @override
  ListenResumeState? fromJson(Map<String, dynamic> json) => ListenResumeState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ListenResumeState state) => state.toJson();
}
```
Add both `part` entries to `lib/src/lesson/lesson.dart`; run `dart run build_runner build --delete-conflicting-outputs` (freezed + injectable config). Re-run the test file → PASS.
- [ ] **Step 3: Writer call sites in `LessonAudioCubit`** — add the field + method:
```dart
  int _lastResumePersistMs = -1;

  /// Bookmarks the merged position every ~5s of playback so an app kill loses
  /// at most a few seconds. pause()/close() write the exact position on top.
  void _maybePersistResume(int positionMs) {
    if (!isMergedMode || !state.isPlaying || state.keypointId.isEmpty) return;
    if (_lastResumePersistMs >= 0 && (positionMs - _lastResumePersistMs).abs() < 5000) return;
    _lastResumePersistMs = positionMs;
    ListenResumeCubit.instanceOrNull?.record(keypointId: state.keypointId, positionMs: positionMs);
  }
```
call `_maybePersistResume(positionMs);` as the LAST line of `_onMergedTick`, and in `pause()` + `close()` (before `_handler.stop()`) add, guarded `if (isMergedMode && state.hasStartedSession && state.keypointId.isNotEmpty)`:
```dart
      ListenResumeCubit.instanceOrNull?.record(keypointId: state.keypointId, positionMs: _handler.position.inMilliseconds);
```
- [ ] **Step 4: Clear on completion** — in `LessonCubit`, inside `completeCurrentKeypoint()` right where `_updateUserProgressKeypoint()` fires (it knows the keypoint id it reports — use the same id variable):
```dart
    ListenResumeCubit.instanceOrNull?.clear(keypointId);
```
- [ ] **Step 5: Jump APIs.** `LessonCubit`:
```dart
  /// Resume-entry only: place the live edge on [index] without walking
  /// nextLearningItem's gates — the listener genuinely heard their way here.
  void jumpToItem(int index) {
    if (index < 0 || index >= state.pageData.items.length) return;
    emit(state.copyWith(currentLearningItemIndex: index));
  }
```
`TheoryCubit` (mirrors `nextDocument`'s emit + `setTheoryData` pattern, minus the `canContinue` gate — resume is not a forward walk):
```dart
  void jumpToDocument(int index) {
    final documents = state.currentLearningItem.documents;
    if (index <= 0 || index >= documents.length) return;
    emit(state.copyWith(currentDocumentIndex: index, selectedExplanationOptionKeys: const {}));
    setTheoryData(state.currentDocument);
  }
```
- [ ] **Step 6: Entry resume in `LessonPage`.** Two halves:
  (a) in `_syncAudioKeypoint` (`lesson_page.dart:180-198`), replace the plain `enterAudioMode()` call with:
```dart
    final resume = ListenResumeCubit.instanceOrNull?.recordFor(keypoint.id);
    unawaited(audioCubit.enterAudioMode(
      autoplay: autoplayOnEntry || resume != null,
      startAt: resume == null ? null : Duration(milliseconds: resume.positionMs),
    ));
```
  (audio is correct within ~a second of entry, before items even land).
  (b) deck jump once items land: in the page's existing `BlocListener`/listener on `LessonCubit` (the same place that reacts to `LessonStatus.success` — follow `lesson_page.dart`'s current listener structure), add a once-per-keypoint guard field `String _resumeAppliedForKeypoint = '';` and:
```dart
    if (lessonState.status == LessonStatus.success && _resumeAppliedForKeypoint != keypoint.id) {
      _resumeAppliedForKeypoint = keypoint.id;
      final resume = ListenResumeCubit.instanceOrNull?.recordFor(keypoint.id);
      final timeline = audioCubit.timeline;
      if (resume != null && timeline != null) {
        final cueIndex = timeline.cueIndexAtMs(resume.positionMs);
        final cue = timeline.cueAt(cueIndex);
        if (cue != null) {
          final items = lessonState.pageData.items;
          final itemIndex = items.indexWhere((item) => item.id == cue.learningItemId);
          if (itemIndex >= 0) {
            lessonCubit.jumpToItem(itemIndex);
            theoryCubit.setCurrentLearningItem(items[itemIndex]);
            theoryCubit.jumpToDocument(cue.documentIndex);
            keypointCardCubit.jumpToCard(
              learningItemId: cue.learningItemId,
              documentIndex: cue.documentIndex,
            );
          }
        }
      }
    }
```
  No `startAt` on `jumpToCard`: the player is ALREADY at the right millisecond from (a); `_loadCardNarration`'s "already on this cue → don't seek" guard (Task 9 Step 5) is what makes the two halves meet without a restart. Resolve the exact cubit variable names from the page's existing code (`context.read<...>` / DI getters already used there).
- [ ] **Step 7:** `flutter analyze` clean; run the listen-resume test file → PASS; `dart format` edited files. Commit:
```bash
git add lib/src/lesson/lesson.dart \
        lib/src/lesson/presentation/cubits/listen_resume/ \
        lib/src/lesson/presentation/cubits/lesson_audio/lesson_audio_cubit.dart \
        lib/src/lesson/presentation/cubits/lesson/lesson_cubit.dart \
        lib/src/lesson/presentation/cubits/theory/theory_cubit.dart \
        lib/src/lesson/presentation/pages/lesson_page.dart \
        test/unit/lesson/presentation/cubits/listen_resume_cubit_test.dart \
        lib/config/di/injection.config.dart
git commit -m "feat: resume merged narration to exact card and second after app kill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
(add whichever regenerated freezed/config files `git status` shows for the new cubit — generated files belonging to OUR new/edited sources only.)

---

### Task 11: End-to-end verification

**Files:** none created — verification only. Prereq: Phase 1 deployed to dev AND `merge-all` backfill completed (Task 5 checklist), or at minimum one dev keypoint dubbed post-deploy so it has `merged`.

- [ ] **Step 1: Static gates, both repos:** `cd hddhistory-api && npx tsc --noEmit` ; `cd hddhistory-flutter && flutter analyze` — both clean.
- [ ] **Step 2: Targeted tests only** (one file at a time): the three files created/extended by this plan (`voiceover-merge.util.spec.ts`, `merged_narration_timeline_test.dart`, `keypoint_cards_builder_test.dart`, `listen_resume_cubit_test.dart`) → all PASS.
- [ ] **Step 3: Simulator pass** (use the `sim-test` skill; full re-run after changes per project convention, not hot-reload):
  1. Open a merged dev keypoint → voice reads card 1, deck turns pages by itself at each cue boundary, pip fill creeps.
  2. Swipe back two cards → narration restarts that card (seek, no reload spinner).
  3. Card with explanation choice: voice stops exactly at the card's end, does not advance; choose → swipe → narration continues.
  4. Background the app mid-card (sim: Home) → audio keeps playing continuously past several boundaries (no per-card gaps); return → deck sits on the card being read, mid-sentence, still playing.
  5. Kill the app while listening; relaunch; re-enter the keypoint from the roadmap → audio starts at the same card + second, deck on that card.
  6. A NON-merged keypoint (legacy) → per-card behaviour identical to before (regression).
- [ ] **Step 4: Physical device (iOS)** — lock-screen check (simulator cannot show it): one long track with the keypoint title, real total duration, working scrubber and ±10s, no track resets at card boundaries. Android device/emulator: media notification equivalent.
- [ ] **Step 5:** Report results (per verification-before-completion: paste actual command output/screenshots, no claims without evidence). Then `superpowers:finishing-a-development-branch` for both repos.
