import { createHash } from 'crypto';

import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { runWithConcurrency } from '@utils/concurrency';
import { CloudflareService } from 'src/modules/file/cloudflare/cloudflare.service';

import { clipFileToken, clipObjectKey } from './audio-clip.util';
import {
  VBEE_LANG,
  VoiceoverProvider,
} from './enum/voiceover-provider.enum';
import {
  buildNarrationSegments,
  buildNarrationText,
  nextUpNarrationText,
} from './narration-text.util';
import { KeypointAudioClipRepository } from './repository/keypoint-audio-clip.repository';
import { KeypointAudioClip } from './schema/keypoint-audio-clip.schema';
import { TtsService, VOICEOVER_LANGS } from './tts.service';
import { toVbeeVoiceName, VbeeTtsService } from './vbee-tts.service';
import { VoiceoverMergeService } from './voiceover-merge.service';
import {
  appendVersion,
  VOICEOVER_CACHE_CONTROL,
} from './voiceover-merge.util';
import { VoiceoverSettingsService } from './voiceover-settings.service';
import { CourseRepository } from '../course/repository/course.repository';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';

export interface KeypointVoiceoverResult {
  keypointId: string;
  generated: string[]; // langs freshly synthesised
  skipped: string[]; // langs unchanged (hash match) — no re-synth
  empty: string[]; // langs with no narratable text to read
  failed: Array<{ lang: string; message: string }>;
  error?: string;
}

export interface CourseVoiceoverResult {
  courseId: string;
  keypoints: number;
  generated: number;
  skipped: number;
  failed: number;
  details: KeypointVoiceoverResult[];
}

// Per (keypoint × language) coverage state — no synthesis, read-only:
//  done    = audio exists and matches the current keypoint text
//  stale   = audio exists but the content changed since (needs re-generate)
//  missing = there is text to narrate but no audio yet
//  failed  = last generation attempt errored for this language
//  none    = no narratable text for this language (nothing to voice)
export type VoiceoverCellStatus =
  | 'done'
  | 'stale'
  | 'missing'
  | 'failed'
  | 'none';

export interface KeypointVoiceoverStatus {
  keypointId: string;
  title: Record<string, string>;
  statuses: Record<string, VoiceoverCellStatus>;
  errors?: Record<string, string>;
}

export interface CourseVoiceoverStatus {
  courseId: string;
  langs: string[];
  summary: Record<VoiceoverCellStatus, number>;
  keypoints: KeypointVoiceoverStatus[];
}

// One row of the global (all-courses) coverage report.
export interface GlobalCourseVoiceoverStatus {
  courseId: string;
  title: Record<string, string>;
  keypointCount: number;
  summary: Record<VoiceoverCellStatus, number>;
  /** Which engine dubs this row's Vietnamese — what the admin toggle reads. */
  viProvider: VoiceoverProvider;
}

/** What a Vbee dub of one course would cost, counted rather than guessed. */
export interface CourseVoiceoverEstimate {
  courseId: string;
  provider: VoiceoverProvider;
  keypoints: number;
  /** Characters the NEXT run would synthesise, after per-card reuse. */
  chars: number;
  /** Every Vietnamese character in the course, i.e. the cost of a forced re-dub. */
  charsIfForced: number;
  voiceCode: string;
  creditFactor: number;
  /** `chars × creditFactor` — the number to compare against the balance. */
  estimatedCredits: number;
  /** 0 when uncapped. */
  maxCharsPerRun: number;
}

// One distinct failure message plus how many (keypoint × language) cells carry
// it — enough for the admin to tell "the endpoint is refusing us right now" from
// "these are leftovers from a provider we no longer use", which a bare count of
// failed cells cannot.
export interface VoiceoverErrorTally {
  message: string;
  count: number;
}

export interface GlobalVoiceoverStatus {
  langs: string[];
  summary: Record<VoiceoverCellStatus, number> & { total: number };
  courses: GlobalCourseVoiceoverStatus[];
  topErrors: VoiceoverErrorTally[];
}

// How many synthesis+upload calls one keypoint runs at once, when
// VOICEOVER_CONCURRENCY says nothing. Measured against the Edge endpoint: five
// concurrent calls finish in the time ONE of them takes sequentially, and 16
// concurrent still all succeed but stretch the slowest call from ~1.5s to ~15s.
// Six keeps the median low, leaves the endpoint unprovoked, and leaves the API
// process with room to keep serving the app while a catalogue-wide dub runs.
const DEFAULT_CONCURRENCY = 6;

// How many distinct failure messages `getGlobalStatus` reports.
const TOP_ERROR_LIMIT = 5;

// Courses scanned at once by the read-only coverage report. Lower than the dub
// concurrency on purpose: this is pure Mongo work that can run while a dub job
// holds the same event loop, so it stays modest.
const STATUS_SCAN_CONCURRENCY = 4;

/**
 * The synthesis work planned for ONE language of a keypoint, and where its
 * results land. Built before anything hits the network (see
 * `generateForKeypoint`) so the concurrency pool can be handed one flat list of
 * calls, and mutated by the pooled tasks as they finish.
 */
interface LangDubPlan {
  lang: string;
  /** The whole keypoint's narration text, hashed into `hash`. */
  text: string;
  hash: string;
  voice: string;
  /** Per-card clip urls / text hashes, indexed BY CARD — never appended to. */
  segmentUrls: string[];
  segmentHashes: string[];
  /** The whole-keypoint file kept at `audio.url` for older app builds. */
  wholeUrl: string;
  /** Câu "Tiếp theo: <tên>" đã TTS — đoạn chuyển tiếp của chain nghe nền. */
  nextUpUrl: string;
  nextUpHash: string;
  /** Whether anything was actually synthesised (vs entirely reused). */
  generatedAny: boolean;
  /** Last failure for this language, recorded for the coverage report. */
  failure?: string;
  /**
   * True when this language is dubbed by the PAID provider, which changes two
   * things: the whole-keypoint file is concatenated from the cards instead of
   * synthesised a second time, and every synthesised character is drawn from
   * the run's budget.
   */
  viaVbee: boolean;
  /**
   * The run's shared allowance, present only when [viaVbee]. Held here rather
   * than threaded through every dub method so the charge happens at the one
   * place that knows the exact text about to be billed.
   */
  budget?: VbeeBudget;
  /**
   * Set when PASS 2b must build `wholeUrl` by concatenating this language's
   * cards. An explicit flag rather than something re-derived after the fact:
   * the planning pass is the only place that knows whether the existing whole
   * file was still reusable.
   */
  needsWholeConcat: boolean;
  /**
   * Whether this run resolved a DIFFERENT narrator than the one the stored
   * clips were made with. Needed at commit time: see the rollback in PASS 3.
   */
  voiceChanged: boolean;
}

/**
 * A character allowance shared by every keypoint of ONE dub run.
 *
 * Deliberately a mutable object passed down rather than a counter on the
 * service: a run is not a singleton (a per-course dub and the global one can
 * overlap), and the point of the cap is that a single mis-click cannot drain a
 * prepaid balance — which is a property of the run, not of the process.
 */
export interface VbeeBudget {
  remaining: number;
}

@Injectable()
export class VoiceoverService {
  private readonly logger = new Logger(VoiceoverService.name);

  constructor(
    private readonly tts: TtsService,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly courseRepository: CourseRepository,
    private readonly cloudflareService: CloudflareService,
    private readonly configService: ConfigService,
    private readonly voiceoverMergeService: VoiceoverMergeService,
    private readonly voiceoverSettingsService: VoiceoverSettingsService,
    private readonly vbee: VbeeTtsService,
    private readonly audioClipRepository: KeypointAudioClipRepository,
  ) {}

  private get concurrency(): number {
    const configured = Number(
      this.configService.get<string>('VOICEOVER_CONCURRENCY'),
    );

    return Number.isFinite(configured) && configured > 0
      ? Math.floor(configured)
      : DEFAULT_CONCURRENCY;
  }

  private hash(text: string): string {
    return createHash('sha256').update(text).digest('hex');
  }

  /**
   * (Re)build a keypoint's voiceover purely from its own content. The
   * previous manual audio is NOT carried over — the resulting `audio` contains
   * ONLY languages that have narratable text and synthesised successfully, so this
   * wipes hand-entered url/text as the product now drives listening entirely
   * from TTS. Idempotent + resumable: a language whose text is
   * unchanged (matches a stored TTS hash) reuses the existing file instead of
   * re-synthesising, so a course run that times out can just be re-run. A
   * transient synth failure keeps that language's prior TTS file if there was
   * one (so we never lose good audio to a blip).
   */
  async generateForKeypoint(
    keypointId: string,
    opts?: {
      force?: boolean;
      /**
       * Which engine dubs Vietnamese. Passed in by the course/global job,
       * which already knows the course and resolves it ONCE per course rather
       * than per keypoint. Left out (the single-keypoint admin button), this
       * looks the course up from the keypoint — one indexed query.
       */
      viProvider?: VoiceoverProvider;
      /** Shared character allowance for the run; see [VbeeBudget]. */
      budget?: VbeeBudget;
    },
  ): Promise<KeypointVoiceoverResult> {
    const keypoint: any = await this.keypointRepository.findById(keypointId);
    if (!keypoint) {
      throw new NotFoundException(`Keypoint ${keypointId} not found`);
    }

    const items = await this.learningItemRepository.findNarratableByKeypoint(
      keypointId,
    );

    // Previous audio is only consulted to RESUME prior TTS (matched by hash);
    // it's never blanket-copied, so manual/stale entries get dropped.
    const prev = keypoint.audio ?? {};

    // The narrator is the locale's single female voice — this keypoint's own
    // history is deliberately NOT consulted. It used to be
    // (`opts.voices[lang] ?? prevVoices[lang] ?? prev.voice`), which is how a
    // keypoint dubbed once under the old two-narrator scheme kept its male
    // narrator through every later run: nothing ever moved it back.
    //
    // Because `sameVoice` below compares against what was stored, those
    // keypoints now read as a narrator change and get re-synthesised, while the
    // ones already on this voice still skip on an unchanged hash. Switching the
    // catalogue to one voice costs exactly the re-dubs it has to.
    // Vietnamese may be dubbed by the paid provider; the other four never are.
    const viProvider =
      opts?.viProvider ?? (await this.resolveKeypointViProvider(keypointId));
    const viaVbee = viProvider === VoiceoverProvider.VBEE;

    const prevVoices: Record<string, string> = prev.voices ?? {};
    const voices: Record<string, string> = {};
    // Resolved together rather than one after another: `TtsService` holds the
    // voice catalogue as an in-flight promise precisely so concurrent callers
    // share one fetch, so five languages cost one round trip instead of five.
    await Promise.all(
      VOICEOVER_LANGS.map(async (lang) => {
        try {
          // Vbee's narrator is picked in admin, not resolved from a locale
          // catalogue, and is stored PREFIXED (`vbee:<code>`) — which is what
          // makes a provider switch read as a narrator change to `sameVoice`
          // below, re-dubbing the whole language rather than leaving clips of
          // two bitrates side by side in one merged file.
          if (viaVbee && lang === VBEE_LANG) {
            voices[lang] = toVbeeVoiceName(
              await this.voiceoverSettingsService.resolveVbeeVoiceCode(),
            );
            return;
          }
          voices[lang] = await this.tts.resolveVoiceName(lang);
        } catch (err: any) {
          // Catalogue unreachable (no key, quota, network). Leave the language
          // unresolved; its synth attempts below fail and get recorded per-lang
          // exactly like any other failure.
          this.logger.error(
            `Could not resolve a voice for lang=${lang}: ${err?.message}`,
          );
        }
      }),
    );

    const next: Record<string, any> = {
      url: {},
      text: {},
      hash: {},
      // Per-card clips (index N = card N) and their per-card text hashes, which
      // is what lets a single edited card be re-dubbed on its own.
      segments: {},
      segmentHash: {},
      nextUp: {},
      nextUpHash: {},
      error: {}, // per-lang last-failure message, so status can report it
      // Per-language resolved voice names — now a RECORD of what was used, not
      // an input: nothing reads them back to choose a narrator any more, only to
      // tell whether this run's voice differs from the stored one. The legacy
      // scalar `voice` on older documents is left alone for the same comparison.
      voices,
    };

    const result: KeypointVoiceoverResult = {
      keypointId,
      generated: [],
      skipped: [],
      empty: [],
      failed: [],
    };

    // PASS 1 — PLAN. Work out what actually has to be synthesised: build the
    // text, compare hashes, keep the clips that can be reused. Nothing here
    // touches the network, so the pool below gets one flat list of real calls
    // instead of discovering them as it walks.
    const plans: LangDubPlan[] = [];
    const tasks: Array<() => Promise<void>> = [];
    // Vbee's calls are pooled SEPARATELY from Edge's. The two endpoints have
    // very different ceilings — Edge is happy at six concurrent calls, Vbee
    // answers 429 (TTS_CCR_MAX_LIMIT_REACHED) past an undocumented and much
    // lower one — and putting them in one pool would mean either throttling the
    // four free languages to Vbee's pace or provoking Vbee at Edge's.
    const vbeeTasks: Array<() => Promise<void>> = [];

    for (const lang of VOICEOVER_LANGS) {
      const segmentTexts = buildNarrationSegments(items, lang);
      const text = segmentTexts.filter(Boolean).join('\n\n');
      if (!text) {
        result.empty.push(lang); // nothing to read → language dropped (wiped)
        continue;
      }
      const h = this.hash(text);
      const voice = voices[lang];
      // Reuse is per language: an unchanged narrator for THIS language, not for
      // the keypoint as a whole. Switching only Chinese must not force a
      // re-dub of the other four.
      const sameVoice = (prevVoices[lang] ?? prev.voice) === voice;

      const prevSegments: string[] = prev.segments?.[lang] ?? [];
      const prevSegmentHashes: string[] = prev.segmentHash?.[lang] ?? [];

      // Pre-sized, and written BY INDEX from here on. This used to push onto
      // empty arrays while walking the cards in order — correct only because the
      // walk was sequential. With the cards synthesised concurrently, pushing
      // would order the clips by whichever request happened to finish first and
      // hand every card a neighbour's audio.
      const langViaVbee = viaVbee && lang === VBEE_LANG;
      const plan: LangDubPlan = {
        lang,
        text,
        hash: h,
        voice,
        segmentUrls: new Array(segmentTexts.length).fill(''),
        segmentHashes: new Array(segmentTexts.length).fill(''),
        wholeUrl: '',
        nextUpUrl: '',
        nextUpHash: '',
        generatedAny: false,
        viaVbee: langViaVbee,
        needsWholeConcat: false,
        voiceChanged: !sameVoice,
        ...(langViaVbee && opts?.budget ? { budget: opts.budget } : {}),
      };
      plans.push(plan);

      // One clip per card. An empty card (image only) keeps its slot as '' so a
      // segment index always lines up with the card at that index in the app.
      for (let index = 0; index < segmentTexts.length; index++) {
        const segmentText = segmentTexts[index];
        if (!segmentText) continue;

        const segmentHash = this.hash(segmentText);
        // Resume: reuse this card's existing clip when its own text is
        // unchanged AND the narrator is the same, so a re-run after a timeout
        // (or a text edit on one card) doesn't re-dub the whole keypoint.
        const reusable =
          !opts?.force &&
          sameVoice &&
          prevSegmentHashes[index] === segmentHash &&
          Boolean(prevSegments[index]);
        if (reusable) {
          plan.segmentUrls[index] = prevSegments[index];
          plan.segmentHashes[index] = segmentHash;
          continue;
        }

        (plan.viaVbee ? vbeeTasks : tasks).push(() =>
          this.dubCard(keypointId, plan, index, segmentText, segmentHash, {
            url: prevSegments[index] ?? '',
            hash: prevSegmentHashes[index] ?? '',
          }),
        );
      }

      // ALSO dub the keypoint as one whole file, kept at `url`.
      //
      // Both shapes ship on purpose: app builds released before per-card
      // narration read `url` and played it as the entire keypoint. Pointing it
      // at the first card's clip (as this did at first) left those builds
      // playing a few seconds and stopping — the "nghe được 9 giây" report. Old
      // builds get the full narration from `url`, new builds use `segments`, and
      // neither needs to know about the other. Once no released build reads
      // `url` any more this second synthesis can be dropped — it is the single
      // most expensive call of the keypoint, roughly the cost of all its cards
      // put together.
      const prevWholeUrl: string = prev.url?.[lang] ?? '';
      const reusableWhole =
        !opts?.force &&
        sameVoice &&
        prev.hash?.[lang] === h &&
        Boolean(prevWholeUrl);
      if (reusableWhole) {
        plan.wholeUrl = prevWholeUrl;
      } else if (plan.viaVbee) {
        // Not a task: PASS 2b builds this by concatenating the cards once they
        // exist, which costs no characters at all. Kept out of the pool for
        // that reason — it has to run AFTER the cards, not alongside them.
        plan.wholeUrl = prevWholeUrl;
        plan.needsWholeConcat = true;
      } else {
        tasks.push(() => this.dubWholeKeypoint(keypointId, plan, prevWholeUrl));
      }

      // The "Tiếp theo: <tên>" transition clip — a few dozen characters, so it
      // rides the same run at ~2% of the keypoint's own cost. Skipped when the
      // title has nothing to say in this language (announcing an empty name is
      // worse than silence), and hash-guarded like everything else so reruns
      // cost nothing until the title or narrator changes.
      const nextUpText = nextUpNarrationText(
        lang,
        keypoint.title?.[lang] ?? keypoint.title?.en ?? '',
      );
      if (nextUpText) {
        const nextUpHash = this.hash(nextUpText);
        const prevNextUpUrl: string = prev.nextUp?.[lang] ?? '';
        const reusableNextUp =
          !opts?.force &&
          sameVoice &&
          prev.nextUpHash?.[lang] === nextUpHash &&
          Boolean(prevNextUpUrl);
        if (reusableNextUp) {
          plan.nextUpUrl = prevNextUpUrl;
          plan.nextUpHash = nextUpHash;
        } else {
          plan.nextUpHash = nextUpHash;
          (plan.viaVbee ? vbeeTasks : tasks).push(() =>
            this.dubNextUp(keypointId, plan, nextUpText, prevNextUpUrl),
          );
        }
      }
    }

    // PASS 2 — SYNTHESISE, several calls at a time. Every task above is a
    // network round trip that spends nearly all of its wall clock waiting, and
    // they are independent: each writes to its own card slot of its own
    // language. Sequentially, five languages of one card measured 26.5s; the
    // same five concurrently, 1.1s.
    //
    // Failures are handled inside each task (previous clip kept, message
    // recorded per language), so the pool's settled results have nothing left
    // to report and are deliberately ignored.
    await Promise.all([
      runWithConcurrency(tasks, this.concurrency),
      runWithConcurrency(vbeeTasks, this.vbee.concurrency),
    ]);

    // PASS 2b — BUILD THE WHOLE-KEYPOINT FILE FOR THE PAID LANGUAGES, for free.
    //
    // Edge synthesises `audio.url` a second time (above); at a per-character
    // price that is roughly a second full bill for the same words, so here the
    // cards that PASS 2 just produced are concatenated instead. Runs after the
    // pool, not inside it, because it consumes the pool's output.
    //
    // The `failure` guard is load-bearing: a card that failed keeps its
    // PREVIOUS clip, which may have come from Edge at a different bitrate, and
    // `-c copy` cannot splice those together into a playable file. Better to
    // leave the old whole-keypoint file in place for one more run.
    const wholeConcats = plans
      .filter(
        (plan) =>
          plan.needsWholeConcat && !plan.failure && plan.segmentUrls.some(Boolean),
      )
      .map((plan) => async () => {
        try {
          plan.wholeUrl = await this.voiceoverMergeService.concatSegmentsToWhole(
            keypointId,
            plan.lang,
            plan.segmentUrls,
            plan.hash,
            plan.voice,
          );
          plan.generatedAny = true;
        } catch (err: any) {
          // Not recorded as a language failure: the narration itself succeeded
          // and `segments` (what current builds read) is complete. Only the
          // legacy whole-file is stale, and it keeps its previous value.
          this.logger.error(
            `Whole-keypoint concat failed (keypoint=${keypointId}, lang=${plan.lang}): ${err?.message}`,
            err?.stack,
          );
        }
      });
    if (wholeConcats.length) {
      await runWithConcurrency(wholeConcats, this.concurrency);
    }

    // PASS 3 — COMMIT. Walked in VOICEOVER_LANGS order, not completion order, so
    // the returned per-language lists stay deterministic.
    for (const plan of plans) {
      next.segments[plan.lang] = plan.segmentUrls;
      next.segmentHash[plan.lang] = plan.segmentHashes;
      next.text[plan.lang] = plan.text;
      next.hash[plan.lang] = plan.hash;
      // Falls back to the first card's clip only if the whole-keypoint synthesis
      // failed and there was nothing to keep — better a short clip than a
      // keypoint that reports having no narration at all.
      next.url[plan.lang] =
        plan.wholeUrl || (plan.segmentUrls.find(Boolean) ?? '');
      if (plan.nextUpUrl) {
        next.nextUp[plan.lang] = plan.nextUpUrl;
        next.nextUpHash[plan.lang] = plan.nextUpHash;
      }

      if (plan.failure) {
        next.error[plan.lang] = plan.failure;
        result.failed.push({ lang: plan.lang, message: plan.failure });

        // A FAILED NARRATOR SWITCH MUST NOT BE RECORDED AS IF IT HAPPENED.
        //
        // Each failed card keeps its previous clip — made by the previous
        // narrator — so writing the new name into `voices` would describe audio
        // that does not exist. The next run would then find `sameVoice` true
        // and every card's hash unchanged, skip the whole language, clear this
        // error, and turn the cell green over the OLD narrator's audio: a retry
        // that reports success and does nothing.
        //
        // Rolling the name back makes the next run see a narrator change and
        // re-dub the language whole. That is also the right repair for a
        // PARTIAL switch, where some cards did move: a language holding two
        // narrators (and, across providers, two bitrates) is exactly what
        // `-c copy` cannot merge, so redoing all of it is the only clean state.
        if (plan.voiceChanged) {
          next.voices[plan.lang] = prevVoices[plan.lang] ?? prev.voice ?? '';
        }
      } else if (plan.generatedAny) {
        result.generated.push(plan.lang);
      } else {
        result.skipped.push(plan.lang);
      }
    }

    // Always persist: this is what wipes old manual audio (dropped languages)
    // and commits freshly generated/kept ones.
    await this.keypointRepository.findOneAndUpdate(
      { _id: keypointId },
      { $set: { audio: next } },
    );

    // Record the same recordings in the content-addressed store, which is what
    // the version-aware read path resolves against. Written from `next` rather
    // than from what this run synthesised, so clips CARRIED OVER from an older
    // run (hash unchanged, nothing re-dubbed) get a row too — otherwise a
    // keypoint nobody has touched since the store landed would read as missing
    // audio forever.
    await this.recordClips(keypointId, plans, next);

    // `$set { audio: next }` above replaced the whole audio object, wiping any
    // previous `merged`. Hand that previous map in so unchanged languages are
    // carried over instead of re-concatenated; a merge failure only logs —
    // segments are the app's fallback and the dub itself succeeded.
    try {
      await this.voiceoverMergeService.mergeAndPersist(keypointId, {
        previous: prev.merged,
        // `force` HAS to reach the merge, or a forced re-dub leaves the app
        // playing the old file. The merge hash is built from the narrator name
        // plus the per-card TEXT hashes — none of which a re-dub changes when
        // the text is the same and the narrator name was already recorded. So
        // the merged clip would match its stored hash and be reused, and
        // `audio.merged` is exactly what the listening screen plays: every card
        // freshly synthesised, and the audible file still the previous one.
        force: opts?.force,
      });
    } catch (err: any) {
      this.logger.error(
        `Post-dub merge failed (keypoint=${keypointId}): ${err?.message}`,
        err?.stack,
      );
    }

    return result;
  }

  /**
   * Synthesise and store ONE card's clip, writing the result into `plan` at
   * `index`. Runs inside the concurrency pool, so it swallows its own failure:
   * one refused request must not abandon the other cards, and the coverage
   * report reads the recorded message later.
   */
  /**
   * Draw `text`'s characters from the run's allowance before they are spent.
   *
   * Throws when there is not enough left, and the caller's existing catch then
   * treats it exactly like a synthesis failure: the card keeps its previous
   * clip and the language is reported as failed with this message. That reuse
   * is the whole point — a budget stop must degrade the same way a refused
   * request does, never by silently writing an empty clip.
   *
   * A no-op for Edge languages and when no cap is configured.
   */
  private chargeVbeeBudget(plan: LangDubPlan, text: string): void {
    if (!plan.viaVbee || !plan.budget) return;

    const cost = text.trim().length;
    if (cost > plan.budget.remaining) {
      throw new Error(
        `Vbee character budget exhausted for this run (needs ${cost}, ${plan.budget.remaining} left) — raise VBEE_MAX_CHARS_PER_RUN or dub fewer courses at once`,
      );
    }
    plan.budget.remaining -= cost;
  }

  private async dubCard(
    keypointId: string,
    plan: LangDubPlan,
    index: number,
    segmentText: string,
    segmentHash: string,
    previous: { url: string; hash: string },
  ): Promise<void> {
    try {
      this.chargeVbeeBudget(plan, segmentText);
      const mp3 = await this.tts.synthesizeMp3(
        segmentText,
        plan.lang,
        undefined,
        plan.voice,
      );
      const { url } = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${plan.lang}-${index}.mp3`,
        mimeType: 'audio/mpeg',
        body: mp3,
        size: mp3.length,
        // The text's own token is IN the key, so this upload cannot land on
        // the bytes an older tag is still pointing at. The un-hashed key this
        // used to write is what let a re-dub silently rewrite every published
        // version's narration.
        key: clipObjectKey(
          keypointId,
          plan.lang,
          'card',
          clipFileToken(segmentHash, plan.voice),
          index,
        ),
        cacheControl: VOICEOVER_CACHE_CONTROL,
      });
      // Versioned by this card's segment hash — the R2 key is reused on every
      // re-dub, so only the url can tell a cache the audio changed.
      plan.segmentUrls[index] = appendVersion(url, segmentHash);
      plan.segmentHashes[index] = segmentHash;
      plan.generatedAny = true;
    } catch (err: any) {
      this.logger.error(
        `Voiceover failed (keypoint=${keypointId}, lang=${plan.lang}, card=${index}): ${err?.message}`,
        err?.stack,
      );
      plan.failure = err?.message ?? 'error';
      // Keep this card's previous clip if there was one, so one bad request
      // doesn't blank out audio for the rest of the keypoint. The hash comes
      // along only with a url — a hash without a clip would make the next run
      // think this card is already done.
      plan.segmentUrls[index] = previous.url;
      plan.segmentHashes[index] = previous.url ? previous.hash : '';
    }
  }

  /**
   * Synthesise and store the whole-keypoint file for one language (`audio.url`,
   * read by app builds released before per-card narration). Same
   * failure-tolerant contract as `dubCard`.
   */
  private async dubWholeKeypoint(
    keypointId: string,
    plan: LangDubPlan,
    prevWholeUrl: string,
  ): Promise<void> {
    try {
      const mp3 = await this.tts.synthesizeMp3(
        plan.text,
        plan.lang,
        undefined,
        plan.voice,
      );
      const uploaded = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${plan.lang}.mp3`,
        mimeType: 'audio/mpeg',
        body: mp3,
        size: mp3.length,
        key: clipObjectKey(
          keypointId,
          plan.lang,
          'whole',
          clipFileToken(plan.hash, plan.voice),
        ),
        cacheControl: VOICEOVER_CACHE_CONTROL,
      });
      plan.wholeUrl = appendVersion(uploaded.url, plan.hash);
      plan.generatedAny = true;
    } catch (err: any) {
      this.logger.error(
        `Voiceover failed (keypoint=${keypointId}, lang=${plan.lang}, whole-keypoint file): ${err?.message}`,
        err?.stack,
      );
      plan.failure = err?.message ?? 'error';
      // Keep the previous whole-keypoint file so a blip doesn't silence
      // older app builds entirely.
      plan.wholeUrl = prevWholeUrl;
    }
  }

  /**
   * Synthesise the "Tiếp theo: <tên>" transition clip for one language. Same
   * failure contract as [dubWholeKeypoint]: keep the previous clip on a blip,
   * record nothing fatal — a chain missing its announcement still chains.
   */
  private async dubNextUp(
    keypointId: string,
    plan: LangDubPlan,
    text: string,
    prevUrl: string,
  ): Promise<void> {
    try {
      this.chargeVbeeBudget(plan, text);
      const mp3 = await this.tts.synthesizeMp3(
        text,
        plan.lang,
        undefined,
        plan.voice,
      );
      const uploaded = await this.cloudflareService.uploadExternalFile({
        originalName: `${keypointId}-${plan.lang}-nextup.mp3`,
        mimeType: 'audio/mpeg',
        body: mp3,
        size: mp3.length,
        key: clipObjectKey(
          keypointId,
          plan.lang,
          'nextup',
          clipFileToken(plan.nextUpHash, plan.voice),
        ),
        cacheControl: VOICEOVER_CACHE_CONTROL,
      });
      plan.nextUpUrl = appendVersion(uploaded.url, plan.nextUpHash);
      plan.generatedAny = true;
    } catch (err: any) {
      this.logger.error(
        `Voiceover failed (keypoint=${keypointId}, lang=${plan.lang}, next-up clip): ${err?.message}`,
        err?.stack,
      );
      // KHÔNG ghi plan.failure: thiếu lời giới thiệu không được phép làm cả
      // ngôn ngữ báo failed — narration chính đã thành công.
      plan.nextUpUrl = prevUrl;
    }
  }

  /**
   * Mirror a keypoint's freshly committed audio into `keypoint_audio_clips` —
   * the store the version-aware read path resolves against.
   *
   * Built from the committed `next` rather than from what this run actually
   * synthesised, on purpose: a card whose hash was unchanged keeps its previous
   * url and is never re-uploaded, so recording only fresh work would leave every
   * untouched keypoint looking like it has no audio at all. `insertMissing`
   * makes the repeat writes free.
   *
   * Never fatal. A dub that reached R2 and Mongo has done its job; failing it
   * here would make a completed run report failure and invite a re-dub that
   * pays for the same audio twice.
   */
  private async recordClips(
    keypointId: string,
    plans: LangDubPlan[],
    next: Record<string, any>,
  ): Promise<void> {
    const clips: Partial<KeypointAudioClip>[] = [];

    for (const plan of plans) {
      const { lang } = plan;
      // The voice as COMMITTED: a failed narrator switch rolls `next.voices`
      // back to the old name, and the kept clips really were read by it.
      const voice = next.voices?.[lang] ?? plan.voice ?? '';

      const segments: string[] = next.segments?.[lang] ?? [];
      const segmentHashes: string[] = next.segmentHash?.[lang] ?? [];
      segments.forEach((url, index) => {
        const textHash = segmentHashes[index];
        // An image-only card has neither, and a card whose dub failed with no
        // previous clip has a hash of '' — both are "nothing to record".
        if (!url || !textHash) return;
        clips.push({
          keypointId,
          lang,
          kind: 'card',
          textHash,
          url,
          voice,
          index,
        });
      });

      const wholeUrl = next.url?.[lang];
      const wholeHash = next.hash?.[lang];
      if (wholeUrl && wholeHash) {
        clips.push({
          keypointId,
          lang,
          kind: 'whole',
          textHash: wholeHash,
          url: wholeUrl,
          voice,
          index: -1,
        });
      }

      const nextUpUrl = next.nextUp?.[lang];
      const nextUpHash = next.nextUpHash?.[lang];
      if (nextUpUrl && nextUpHash) {
        clips.push({
          keypointId,
          lang,
          kind: 'nextup',
          textHash: nextUpHash,
          url: nextUpUrl,
          voice,
          index: -1,
        });
      }
    }

    if (!clips.length) return;

    try {
      await this.audioClipRepository.insertMissing(clips);
    } catch (err: any) {
      this.logger.error(
        `Audio clip store write failed (keypoint=${keypointId}): ${err?.message}`,
        err?.stack,
      );
    }
  }

  /** The engine that dubs a course's Vietnamese; `edge` unless opted in. */
  async resolveCourseViProvider(courseId: string): Promise<VoiceoverProvider> {
    const stored = await this.courseRepository.findVoiceoverViProvider(courseId);
    return stored === VoiceoverProvider.VBEE
      ? VoiceoverProvider.VBEE
      : VoiceoverProvider.EDGE;
  }

  /**
   * Same, for a lone keypoint. Costs one extra indexed query, which is why
   * every batch path resolves per COURSE and passes the answer down instead.
   */
  private async resolveKeypointViProvider(
    keypointId: string,
  ): Promise<VoiceoverProvider> {
    const courseId = await this.lessonRepository.findCourseIdByKeypoint(
      keypointId,
    );
    // An orphan keypoint (no lesson references it) has no course to opt in, so
    // it can only be free.
    if (!courseId) return VoiceoverProvider.EDGE;
    return this.resolveCourseViProvider(courseId);
  }

  /**
   * A fresh allowance for one run, or `undefined` when no cap is configured.
   *
   * Created per run rather than per keypoint: the cap exists so that ONE
   * mis-click cannot drain a prepaid balance, and a per-keypoint cap would
   * happily let a thousand keypoints through.
   */
  newVbeeBudget(): VbeeBudget | undefined {
    const max = this.vbee.maxCharsPerRun;
    return max > 0 ? { remaining: max } : undefined;
  }

  /**
   * Switch which engine dubs a course's Vietnamese.
   *
   * Refuses to select Vbee when no credentials are configured — otherwise the
   * toggle would look like it worked and then fail once per keypoint, hundreds
   * of times, at dub time.
   *
   * Changing this does NOT re-dub anything on its own. The next run sees a
   * different narrator in `audio.voices.vi` and re-synthesises Vietnamese; the
   * other four locales are untouched either way.
   */
  async setCourseViProvider(
    courseId: string,
    provider: VoiceoverProvider,
  ): Promise<{ courseId: string; provider: VoiceoverProvider }> {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException(`Course ${courseId} not found`);

    if (provider === VoiceoverProvider.VBEE && !this.vbee.isConfigured) {
      throw new BadRequestException(
        'Vbee is not configured on this environment (VBEE_APP_ID / VBEE_TOKEN)',
      );
    }

    await this.courseRepository.findOneAndUpdate(
      { _id: courseId },
      { $set: { voiceoverViProvider: provider } },
    );
    return { courseId, provider };
  }

  /**
   * What dubbing this course's Vietnamese would COST, in characters, before
   * anything is spent.
   *
   * Read-only and deliberately exact rather than estimated from an average: it
   * replays the same reuse rules `generateForKeypoint` uses (per-card hash plus
   * narrator match), so `chars` is what the next run would actually synthesise
   * — usually far less than the whole course, and exactly the whole course the
   * first time a course moves onto a new provider.
   *
   * The whole-keypoint file is not counted: on Vbee it is concatenated from the
   * cards (PASS 2b) and costs nothing.
   */
  async estimateCourseVbee(
    courseId: string,
  ): Promise<CourseVoiceoverEstimate> {
    const keypointIds = await this.lessonRepository.findKeypointIdsByCourse(
      courseId,
    );
    const provider = await this.resolveCourseViProvider(courseId);
    const voiceCode = await this.voiceoverSettingsService.resolveVbeeVoiceCode();
    const targetVoice = toVbeeVoiceName(voiceCode);

    let chars = 0;
    let charsIfForced = 0;

    for (const id of keypointIds) {
      const keypoint: any = await this.keypointRepository.findById(id);
      if (!keypoint) continue;

      const items = await this.learningItemRepository.findNarratableByKeypoint(
        id,
      );
      const segmentTexts = buildNarrationSegments(items, VBEE_LANG);
      const prev = keypoint.audio ?? {};
      const prevVoice = prev.voices?.[VBEE_LANG] ?? prev.voice;
      const sameVoice = prevVoice === targetVoice;
      const prevSegments: string[] = prev.segments?.[VBEE_LANG] ?? [];
      const prevHashes: string[] = prev.segmentHash?.[VBEE_LANG] ?? [];

      for (let index = 0; index < segmentTexts.length; index++) {
        const text = segmentTexts[index];
        if (!text) continue;
        charsIfForced += text.length;
        const reusable =
          sameVoice &&
          prevHashes[index] === this.hash(text) &&
          Boolean(prevSegments[index]);
        if (!reusable) chars += text.length;
      }

      // The "Tiếp theo: <tên>" clip rides the same run and is billed the same.
      const nextUpText = nextUpNarrationText(
        VBEE_LANG,
        keypoint.title?.[VBEE_LANG] ?? keypoint.title?.en ?? '',
      );
      if (nextUpText) {
        charsIfForced += nextUpText.length;
        const reusableNextUp =
          sameVoice &&
          prev.nextUpHash?.[VBEE_LANG] === this.hash(nextUpText) &&
          Boolean(prev.nextUp?.[VBEE_LANG]);
        if (!reusableNextUp) chars += nextUpText.length;
      }
    }

    // `credit_factor` is the difference between a run costing X and 3X, so the
    // estimate has to carry it. Unreachable catalogue (or no credentials) falls
    // back to 1 rather than refusing to answer — the character counts above are
    // the part that matters and they are already exact.
    let creditFactor = 1;
    try {
      // Looked up across every ownership, not just Vbee's own catalogue: the
      // narrator may be a pasted COMMUNITY or PERSONAL code, and quoting factor
      // 1 for a voice that actually bills 3x would understate the run by 200%.
      creditFactor = (await this.vbee.findVoice(voiceCode))?.creditFactor ?? 1;
    } catch (err: any) {
      this.logger.warn(
        `Could not read Vbee credit factor for ${voiceCode}: ${err?.message}`,
      );
    }

    return {
      courseId,
      provider,
      keypoints: keypointIds.length,
      chars,
      charsIfForced,
      voiceCode,
      creditFactor,
      estimatedCredits: chars * creditFactor,
      maxCharsPerRun: this.vbee.maxCharsPerRun,
    };
  }

  /**
   * Generate voiceover for every keypoint of a course (from its own
   * content). Processes sequentially; idempotent + resumable via the
   * per-keypoint hash skip, so re-running after a timeout continues where it
   * left off.
   */
  async generateForCourse(courseId: string): Promise<CourseVoiceoverResult> {
    const keypointIds = await this.lessonRepository.findKeypointIdsByCourse(
      courseId,
    );
    // Resolved ONCE for the course, then handed to every keypoint: the flag
    // lives on the course, and looking it up per keypoint would add a query per
    // keypoint to answer the same question.
    const viProvider = await this.resolveCourseViProvider(courseId);
    const budget = this.newVbeeBudget();

    const details: KeypointVoiceoverResult[] = [];
    let generated = 0;
    let skipped = 0;
    let failed = 0;

    for (const id of keypointIds) {
      try {
        const r = await this.generateForKeypoint(id, { viProvider, budget });
        details.push(r);
        generated += r.generated.length;
        skipped += r.skipped.length;
        failed += r.failed.length;
      } catch (err: any) {
        details.push({
          keypointId: id,
          generated: [],
          skipped: [],
          empty: [],
          failed: [],
          error: err?.message ?? 'error',
        });
        failed += 1;
      }
    }

    return {
      courseId,
      keypoints: keypointIds.length,
      generated,
      skipped,
      failed,
      details,
    };
  }

  /**
   * Read-only coverage report for a course: for every keypoint × language,
   * classify the voiceover state (done / stale / missing / failed / none) by
   * comparing the stored audio hash + presence + last error against the
   * current keypoint text. No synthesis — safe to call anytime to see what is
   * still missing or errored.
   */
  async getCourseStatus(courseId: string): Promise<CourseVoiceoverStatus> {
    const keypointIds = await this.lessonRepository.findKeypointIdsByCourse(
      courseId,
    );

    // Two queries for the whole course, not two per keypoint. The loop below
    // used to call findById + findNarratableByKeypoint per keypoint, so a scan
    // of the catalogue cost ~1000 round trips — and the admin batch page polled
    // that scan every 3 seconds while a dub job was running, on the same event
    // loop as the dubbing.
    const [keypointDocs, narratableItems] = await Promise.all([
      this.keypointRepository.findVoiceoverStatusByIds(keypointIds),
      this.learningItemRepository.findNarratableByKeypoints(keypointIds),
    ]);

    const keypointById = new Map<string, any>(
      (keypointDocs as any[]).map((doc) => [doc._id.toString(), doc]),
    );
    // Sorted by (keypointId, index) in the query, so each bucket comes out in
    // the display order the narration walk depends on — the same order
    // `generateForKeypoint` hashes, which is what keeps "done" honest.
    const itemsByKeypoint = new Map<string, any[]>();
    for (const item of narratableItems as any[]) {
      const key = item.keypointId?.toString();
      if (!key) continue;
      const bucket = itemsByKeypoint.get(key);
      if (bucket) bucket.push(item);
      else itemsByKeypoint.set(key, [item]);
    }

    const summary: Record<VoiceoverCellStatus, number> = {
      done: 0,
      stale: 0,
      missing: 0,
      failed: 0,
      none: 0,
    };
    const keypoints: KeypointVoiceoverStatus[] = [];

    for (const id of keypointIds) {
      const kp: any = keypointById.get(id);
      if (!kp) continue;
      const items = itemsByKeypoint.get(id) ?? [];
      const audio = kp.audio ?? {};
      const statuses: Record<string, VoiceoverCellStatus> = {};
      const errors: Record<string, string> = {};

      for (const lang of VOICEOVER_LANGS) {
        const text = buildNarrationText(items, lang);
        if (!text) {
          statuses[lang] = 'none';
        } else {
          const h = this.hash(text);
          const url = audio.url?.[lang];
          const err = audio.error?.[lang];
          if (url && audio.hash?.[lang] === h) {
            statuses[lang] = 'done';
          } else if (err) {
            statuses[lang] = 'failed';
            errors[lang] = err;
          } else if (url) {
            statuses[lang] = 'stale';
          } else {
            statuses[lang] = 'missing';
          }
        }
        summary[statuses[lang]] += 1;
      }

      keypoints.push({
        keypointId: id,
        title: kp.title ?? {},
        statuses,
        ...(Object.keys(errors).length ? { errors } : {}),
      });
    }

    return { courseId, langs: VOICEOVER_LANGS, summary, keypoints };
  }

  /**
   * Read-only, GLOBAL coverage report: every course's coverage, aggregated,
   * plus a tally of the distinct failure messages behind the `failed` count.
   * Reuses `getCourseStatus` as-is (one call per course) — no new status logic.
   *
   * This is the explicit admin "Scan", NOT something to poll: it is a few
   * queries per course across the whole catalogue. The batch page's 3-second
   * progress poll deliberately hits the job endpoint instead, which reads one
   * document.
   *
   * `topErrors` exists because a bare "1190 failed" can't distinguish an
   * endpoint refusing calls right now from stale errors left by a TTS provider
   * that has since been swapped out — the two want opposite responses, and the
   * messages were already stored per language, just never surfaced.
   */
  async getGlobalStatus(): Promise<GlobalVoiceoverStatus> {
    const courses = await this.courseRepository.findAllBriefTitles();

    // A few courses in flight at once: each one's scan is dominated by waiting
    // on Mongo, and the scan is what the admin waits on after pressing Quét.
    const scans = await runWithConcurrency(
      (courses as any[]).map((course) => async () => ({
        course,
        status: await this.getCourseStatus(course._id.toString()),
      })),
      STATUS_SCAN_CONCURRENCY,
    );

    const summary: Record<VoiceoverCellStatus, number> & { total: number } = {
      done: 0,
      stale: 0,
      missing: 0,
      failed: 0,
      none: 0,
      total: 0,
    };
    const courseStatuses: GlobalCourseVoiceoverStatus[] = [];
    const errorTally = new Map<string, number>();

    // Index-aligned with `courses`, so the report keeps catalogue order however
    // the scans interleaved.
    for (const scan of scans) {
      if (scan.status === 'rejected') {
        // One unreadable course must not blank the whole report; it simply
        // contributes nothing to the totals.
        this.logger.error(
          `Voiceover scan failed for a course: ${scan.reason?.message}`,
          scan.reason?.stack,
        );
        continue;
      }

      const { course, status } = scan.value;

      for (const key of Object.keys(status.summary) as VoiceoverCellStatus[]) {
        summary[key] += status.summary[key];
        summary.total += status.summary[key];
      }

      for (const keypoint of status.keypoints) {
        for (const message of Object.values(keypoint.errors ?? {})) {
          errorTally.set(message, (errorTally.get(message) ?? 0) + 1);
        }
      }

      courseStatuses.push({
        courseId: course._id.toString(),
        title: course.title ?? {},
        keypointCount: status.keypoints.length,
        summary: status.summary,
        // Projected by `findAllBriefTitles`, so the toggle state costs no extra
        // query — courses written before the field exists read as `edge`.
        viProvider:
          course.voiceoverViProvider === VoiceoverProvider.VBEE
            ? VoiceoverProvider.VBEE
            : VoiceoverProvider.EDGE,
      });
    }

    const topErrors: VoiceoverErrorTally[] = [...errorTally.entries()]
      .map(([message, count]) => ({ message, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, TOP_ERROR_LIMIT);

    return {
      langs: VOICEOVER_LANGS,
      summary,
      courses: courseStatuses,
      topErrors,
    };
  }
}
