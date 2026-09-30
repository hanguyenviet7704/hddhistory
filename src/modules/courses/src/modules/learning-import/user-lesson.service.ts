import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { IResponseListPage } from '@utils/interface/paging/page.interface';

import {
  ListUserLessonDto,
  UpdateUserLessonProgressDto,
} from './dto/list-learning-import.dto';
import {
  UserLessonAudioStatus,
  UserLessonContentStatus,
} from './enum/learning-import.enum';
import {
  ILessonKeypoint,
  IUserLessonAudio,
} from './interface/learning-import.interface';
import { UserLessonRepository } from './repository/user-lesson.repository';
import { UserLesson } from './schema/user-lesson.schema';

// The list card. Deliberately without the body: see LIST_PROJECTION.
export interface UserLessonSummary {
  id: string;
  title: string;
  description: string;
  outputLocale: string;
  sourceType: string;
  sourceLabel: string;
  wordCount: number;
  estimatedMinutes: number;
  stopAtKeypointIndex: number;
  stopAtSectionIndex: number;
  /**
   * The cover dealt from the admin pool at creation. Empty for lessons that
   * predate the pool (or an empty pool) — the app falls back to its bundled
   * placeholder art.
   */
  coverUrl: string;
  /** Null until the reader reaches the last card of the last keypoint. */
  completedAt: Date | null;
  /**
   * Null until the reader asked for more content on this lesson. Sent so the
   * panel at the end of the roadmap can come back already answered instead of
   * inviting the same wish twice.
   */
  additionalContentRequestedAt: Date | null;
  createdAt: Date;
  // Whether narration exists yet. `processing` right after an import, `failed`
  // when the TTS provider let us down -- both are ordinary states the card
  // renders without complaint.
  audioStatus: UserLessonAudioStatus;
  // `partial` while the background phase is still writing keypoints — the
  // roadmap keeps polling while it sees this, and the card may say "đang tạo
  // tiếp". Old lessons read as `complete`.
  contentStatus: UserLessonContentStatus;
}

@Injectable()
export class UserLessonService {
  constructor(
    private readonly userLessonRepository: UserLessonRepository,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString?.();
  }

  async list(
    dto: ListUserLessonDto,
  ): Promise<IResponseListPage<UserLessonSummary>> {
    const page = await this.userLessonRepository.findPaginatedByUser(
      this.userId,
      dto.page ?? 1,
      dto.take ?? 10,
    );

    return { ...page, items: page.items.map(item => this.toSummary(item)) };
  }

  async findOne(id: string) {
    const lesson = await this.userLessonRepository.findOwned(id, this.userId);
    if (!lesson) throw new NotFoundException('Lesson not found');

    return {
      ...this.toSummary(lesson),
      keypoints: resolveKeypoints(lesson),
      // The committed outline, first title included. What lets the roadmap
      // draw nodes for keypoints the background phase has not written yet.
      plannedKeypointTitles: lesson.plannedKeypointTitles ?? [],
      // Node art for the same outline, so a not-yet-written keypoint draws the
      // picture it will keep instead of a placeholder that swaps under the
      // reader. Empty on lessons dealt before the field existed.
      plannedKeypointCoverUrls: lesson.plannedKeypointCoverUrls ?? [],
      // Null until the dubbing phase finishes, and null forever when it fails.
      // The reader treats a lesson with no audio as ordinary, not broken.
      audio: resolveAudio(lesson),
      // Whether the background still OWES this lesson narration.
      //
      // The app used to infer this from `contentStatus`, and that inference is
      // wrong for the streamed pipeline: text lands in seconds and narration in
      // minutes (measured on dev: content complete at +13s, first keypoint dubbed
      // at +218s, all four at ~9min). The moment content went `complete` the app
      // stopped polling and stopped treating missing audio as pending, so a
      // reader who opened their new lesson met four keypoints marked ready with
      // no sound anywhere and nothing ever corrected it.
      //
      // `audioStatus` cannot answer it either: it goes `ready` at the FIRST
      // playable keypoint by design, so it says yes while three quarters of the
      // lesson is still silent.
      //
      // `generation` is the honest discriminator. It is the completion sweep's
      // own scope filter and it stays non-null for the lesson's life (release
      // only clears `heartbeatAt`), so `generation != null` means "born in the
      // progressive pipeline, and the sweep will keep trying" — the sweep has no
      // give-up ceiling. A lesson from BEFORE that pipeline has no `generation`
      // and reports false, which is what keeps its permanent narration holes
      // from being dressed as work in progress.
      audioPending: this.isAudioPending(lesson),
    };
  }

  /** See the `audioPending` note in [findOne]. */
  private isAudioPending(lesson: UserLesson): boolean {
    if (!lesson.generation) return false;

    const dubbed = lesson.audio?.keypoints?.length ?? 0;
    const written = lesson.keypoints?.length ?? 0;

    // Still writing keypoints ⇒ still owes narration for the ones to come, even
    // when every keypoint written SO FAR happens to be dubbed.
    if (lesson.contentStatus === UserLessonContentStatus.PARTIAL) return true;

    return dubbed < written;
  }

  /**
   * Remember where the reader stopped: which keypoint, and which card in it.
   *
   * Silently clamped rather than validated against the lesson's real shape: the
   * app can legitimately report a stale index after a lesson is re-read on
   * another device, and refusing the write would cost the user their place to
   * enforce a bound that only affects where the reader lands.
   */
  async updateProgress(
    id: string,
    dto: UpdateUserLessonProgressDto,
  ): Promise<{ stopAtKeypointIndex: number; stopAtSectionIndex: number }> {
    const lesson = await this.userLessonRepository.findOwned(id, this.userId);
    if (!lesson) throw new NotFoundException('Lesson not found');

    const keypoints = resolveKeypoints(lesson);
    const keypointIndex = clamp(
      dto.stopAtKeypointIndex ?? 0,
      Math.max(0, keypoints.length - 1),
    );
    const cardIndex = clamp(
      dto.stopAtSectionIndex,
      Math.max(0, (keypoints[keypointIndex]?.sections?.length ?? 1) - 1),
    );

    // Finished = the last card of the last keypoint. Worked out here because
    // this is the only side that has the body: the list response omits the
    // keypoints, so the card the app draws has no way to know how many there
    // were, let alone how many cards the final one held.
    const lastKeypoint = Math.max(0, keypoints.length - 1);
    const lastCard = Math.max(
      0,
      (keypoints[lastKeypoint]?.sections?.length ?? 1) - 1,
    );
    // A PARTIAL lesson can never finish: its "last keypoint" is only the last
    // one written so far, and stamping completedAt off it would declare a
    // lesson read before most of it existed.
    const finished =
      (lesson.contentStatus ?? UserLessonContentStatus.COMPLETE) ===
        UserLessonContentStatus.COMPLETE &&
      keypointIndex >= lastKeypoint &&
      cardIndex >= lastCard;

    await this.userLessonRepository.updateProgress(
      id,
      this.userId,
      keypointIndex,
      cardIndex,
      // Stamped once. A reread walks back through the same last card and would
      // otherwise keep moving the completion date forward.
      finished && !lesson.completedAt ? new Date() : undefined,
    );

    return {
      stopAtKeypointIndex: keypointIndex,
      stopAtSectionIndex: cardIndex,
    };
  }

  /**
   * "I finished this and I want more of it."
   *
   * Records the wish and nothing else -- no generation, no quota spent. The app
   * only offers the panel once the lesson is read out, but the check is repeated
   * here because the app's copy of "finished" is a number it was handed, and a
   * request stamped on a lesson nobody read tells us the opposite of what this
   * signal exists to measure.
   *
   * Idempotent by design: asking twice answers `alreadyRequested` and keeps the
   * first date, so the reader gets the same confirmation either way.
   */
  async requestAdditionalContent(
    id: string,
  ): Promise<{ requested: boolean; requestedAt: Date | null }> {
    const lesson = await this.userLessonRepository.findOwned(id, this.userId);
    if (!lesson) throw new NotFoundException('Lesson not found');

    if (!lesson.completedAt) {
      throw new BadRequestException('Finish the lesson before asking for more');
    }

    if (lesson.additionalContentRequestedAt) {
      return {
        requested: true,
        requestedAt: lesson.additionalContentRequestedAt,
      };
    }

    const requestedAt = new Date();
    await this.userLessonRepository.markAdditionalContentRequested(
      id,
      this.userId,
      requestedAt,
    );

    return { requested: true, requestedAt };
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    const deleted = await this.userLessonRepository.deleteOwned(id, this.userId);
    if (!deleted) throw new NotFoundException('Lesson not found');

    return { deleted: true };
  }

  private toSummary(lesson: UserLesson): UserLessonSummary {
    return {
      id: String(lesson._id),
      title: lesson.title,
      description: lesson.description,
      outputLocale: lesson.outputLocale,
      sourceType: lesson.source?.type ?? '',
      // What the card shows under the title: the video's own title when we have
      // it, otherwise the filename the user uploaded.
      sourceLabel:
        lesson.source?.videoTitle ||
        lesson.source?.fileName ||
        lesson.source?.url ||
        '',
      coverUrl: lesson.coverUrl ?? '',
      wordCount: lesson.wordCount ?? 0,
      estimatedMinutes: lesson.estimatedMinutes ?? 0,
      stopAtKeypointIndex: lesson.stopAtKeypointIndex ?? 0,
      stopAtSectionIndex: lesson.stopAtSectionIndex ?? 0,
      completedAt: lesson.completedAt ?? null,
      additionalContentRequestedAt: lesson.additionalContentRequestedAt ?? null,
      createdAt: lesson.createdAt,
      audioStatus: lesson.audioStatus ?? UserLessonAudioStatus.NONE,
      contentStatus: lesson.contentStatus ?? UserLessonContentStatus.COMPLETE,
    };
  }
}

function clamp(value: number, max: number): number {
  return Math.min(Math.max(0, value ?? 0), max);
}

/**
 * The lesson body, whichever era it was written in.
 *
 * Lessons generated before the keypoint split stored one flat card list. Wrapping
 * that into a single keypoint here is the whole of the back-compat story: it
 * costs one allocation on read and means the app never learns that two shapes
 * ever existed. Nothing writes `sections` any more.
 */
function resolveKeypoints(lesson: UserLesson): ILessonKeypoint[] {
  const keypoints = lesson.keypoints ?? [];
  if (keypoints.length > 0) return keypoints;

  const sections = lesson.sections ?? [];
  if (sections.length === 0) return [];

  return [{ title: lesson.title || '', sections }];
}

/**
 * Narration, from either era.
 *
 * A pre-split lesson's `audio` is one file for the whole lesson with cues
 * numbered across it — which is exactly what a SINGLE keypoint looks like, and a
 * single keypoint is what [resolveKeypoints] folds such a lesson into. So the
 * old shape converts with nothing lost: same file, same cue order, now addressed
 * as keypoint 0. Those lessons keep their voice.
 */
function resolveAudio(lesson: UserLesson): IUserLessonAudio | null {
  const audio = lesson.audio as (IUserLessonAudio & ILegacyAudio) | null;
  if (!audio) return null;
  if (Array.isArray(audio.keypoints)) return audio;
  if (!audio.url) return null;

  return {
    voice: audio.voice ?? '',
    hash: audio.hash ?? '',
    keypoints: [
      {
        keypointIndex: 0,
        url: audio.url,
        durationMs: audio.durationMs ?? 0,
        cues: (audio.cues ?? []).map(cue => ({
          cardIndex: cue.cardIndex ?? cue.sectionIndex ?? 0,
          startMs: cue.startMs,
          durMs: cue.durMs,
        })),
      },
    ],
  };
}

/**
 * The pre-split narration shape, declared only so [resolveAudio] can read it
 * without casting to `any`. Nothing writes it.
 */
interface ILegacyAudio {
  url?: string;
  durationMs?: number;
  cues?: Array<{
    cardIndex?: number;
    sectionIndex?: number;
    startMs: number;
    durMs: number;
  }>;
}
