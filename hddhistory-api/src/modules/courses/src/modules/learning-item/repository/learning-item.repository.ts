import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { OrderType } from '@utils/type/orderByType';

import { GetListLearningItemDto } from '../dto/get-learning-item.dto';
import { LearningItemType } from '../enum/learning-item.enum';
import { ExerciseInput } from '../interface/learning-item.interface';
import { LearningItem } from '../schema/learning-item.schema';

@Injectable()
export class LearningItemRepository extends AbstractRepository<LearningItem> {
  protected readonly logger = new Logger(LearningItemRepository.name);
  constructor(
    @InjectModel(LearningItem.name) model: Model<LearningItem>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(
    getListLearningItemDto: GetListLearningItemDto,
  ): Promise<IResponseListPage<LearningItem>> {
    const where: FilterQuery<LearningItem> = {};

    const { page, take, search, type, order, orderBy, keypointId } =
      getListLearningItemDto;

    if (search) {
      const regex = new RegExp(search, 'i');
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
        { tag: { $in: [regex] } },
      ];
    }

    if (type) {
      where.type = type;
    }

    if (keypointId) {
      where.keypointId = keypointId;
    }

    return this.paginateQuery<LearningItem>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findAllBrief(keypointId: string, order: OrderType, orderBy: string) {
    const where: FilterQuery<LearningItem> = { keypointId };

    const list = await this.model
      .find(where)
      .sort({ [orderBy]: order })
      .select('title index _id type keypointId image isSub');

    return { list };
  }

  async checkExitsTitle(title: string, keypointId: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const Exercise = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
      keypointId,
    });
    return Exercise;
  }

  async getNextIndex(keypointId: string): Promise<number> {
    const lastLearningItem = await this.model
      .findOne({ keypointId })
      .sort({ index: -1 })
      .select('index')
      .lean();

    const maxIndex = lastLearningItem?.index ?? 0;
    return maxIndex + 1;
  }

  // Every learning-item of a keypoint that gets narrated, in display order —
  // the source text for keypoint voiceover generation.
  //
  // Theory (read out in full) and exercise (only the question is read, so the
  // reader hears what is being asked without the answer being handed to them).
  // Video and roleplay items are excluded: they carry their own audio. The
  // ORDER and the type filter here are load-bearing — the app numbers the clips
  // it plays by walking the same items the same way, so a type added or dropped
  // here shifts every clip after it (see `KeypointCardCubit._buildCardList`).
  async findNarratableByKeypoint(keypointId: string) {
    return this.model
      .find({
        keypointId,
        type: { $in: [LearningItemType.THEORY, LearningItemType.EXERCISE] },
      })
      .sort({ index: 1 })
      .lean();
  }

  // The same narratable items, for MANY keypoints in one round trip — the
  // coverage report reads a whole course at a time and used to call the
  // single-keypoint version above in a loop. At ~480 keypoints in the catalogue
  // that was ~480 queries per scan, and the admin batch page polled the scan
  // every 3 seconds while a dub job ran, so the monitoring competed with the
  // work it was monitoring.
  //
  // Sorted by keypoint then index so a caller can group by `keypointId` and
  // still get each keypoint's items in the display order the clip numbering
  // depends on.
  async findNarratableByKeypoints(keypointIds: string[]) {
    if (!keypointIds.length) return [];

    return this.model
      .find({
        keypointId: { $in: keypointIds },
        type: { $in: [LearningItemType.THEORY, LearningItemType.EXERCISE] },
      })
      .sort({ keypointId: 1, index: 1 })
      .lean();
  }

  /**
   * The exercises belonging to any of these keypoints, in display order.
   *
   * Backs habit practice, which is derived from the keypoint rather than stored:
   * a habit hangs off `habits.keypointIds`, and practising it means doing that
   * keypoint's own exercises.
   *
   * `questions.0` must exist. An exercise folder with no questions authored yet
   * is a real state in the catalogue, and offering it as practice would open a
   * deck with nothing in it — a dead end with nothing to report.
   *
   * Only EXERCISE. Video and roleplay items on a keypoint are its teaching
   * material, not its practice, so those stay an explicit admin choice through
   * `habit_practices`.
   */
  async findExercisesByKeypoints(keypointIds: string[]) {
    if (!keypointIds.length) return [];

    return this.model
      .find({
        keypointId: { $in: keypointIds },
        type: LearningItemType.EXERCISE,
        'questions.0': { $exists: true },
      })
      .sort({ keypointId: 1, index: 1 })
      .lean();
  }

  async findDailyWarmUpQuestions(
    keypointId: string,
    exerciseIds: string[],
  ): Promise<ExerciseInput[]> {
    if (!exerciseIds.length) return [];

    const exerciseIdSet = new Set(exerciseIds);
    const learningItems = await this.model
      .find({
        keypointId,
        type: LearningItemType.EXERCISE,
        'questions.exerciseId': { $in: exerciseIds },
        'questions.isDailyWarmUp': true,
      })
      .select('_id keypointId questions')
      .lean();

    return learningItems.flatMap(item =>
      ((item.questions ?? []) as ExerciseInput[]).filter(
        question =>
          question.isDailyWarmUp &&
          question.exerciseId &&
          exerciseIdSet.has(question.exerciseId),
      ),
    );
  }

  /**
   * Every EXERCISE-type LearningItem in the catalog, projected to only the
   * fields the daily warm-up auto-tagging rule needs. Used to scan the whole
   * system in one query (the rule spans all lessons, not a single lesson's
   * keypoints).
   */
  /**
   * Hydrate a set of learning items by id, in no particular order — the caller
   * owns the ordering (habit practices sort by their own `order`). Used by the
   * habit-practice read, which stores only pointers.
   */
  async findByIds(ids: string[]): Promise<LearningItem[]> {
    if (!ids.length) return [];
    const items = await this.model.find({ _id: { $in: ids } }).lean();
    return items as unknown as LearningItem[];
  }

  /**
   * Every learning item of these keypoints, whatever its type -- what a content
   * tag has to freeze. The existing per-type helpers each filter to one kind.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findAllByKeypointIds(keypointIds: string[]): Promise<LearningItem[]> {
    if (!keypointIds.length) return [];

    const items = await this.model
      .find({ keypointId: { $in: keypointIds } })
      .sort({ keypointId: 1, index: 1 })
      .lean();

    return items as unknown as LearningItem[];
  }

  async findAllByTypeForExport(
    type: LearningItemType,
    keypointIds?: string[],
  ): Promise<LearningItem[]> {
    const items = await this.model
      .find(keypointIds ? { type, keypointId: { $in: keypointIds } } : { type })
      .sort({ keypointId: 1, index: 1 })
      .lean();

    return items as unknown as LearningItem[];
  }

  async findAllExerciseFolders(): Promise<LearningItem[]> {
    const items = await this.model
      .find({ type: LearningItemType.EXERCISE })
      .select('_id keypointId index questions')
      .lean();

    return items as unknown as LearningItem[];
  }

  /**
   * Exercise questions belonging to any of the given keypoints that are
   * flagged `isDailyWarmUp` in admin, in the same `ExerciseInput` shape the
   * app already consumes for exercise UI. Used by the lesson warm-up
   * feature to replay only the admin-curated questions from the user's
   * furthest-studied lesson in the course.
   */
  async findWarmUpEligibleExercisesByKeypointIds(
    keypointIds: string[],
  ): Promise<ExerciseInput[]> {
    if (!keypointIds.length) return [];

    const learningItems = await this.model
      .find({
        keypointId: { $in: keypointIds },
        type: LearningItemType.EXERCISE,
        'questions.isDailyWarmUp': true,
      })
      .sort({ index: 1 })
      .select('_id keypointId questions')
      .lean();

    return learningItems.flatMap(item =>
      ((item.questions ?? []) as ExerciseInput[]).filter(
        question => question.isDailyWarmUp,
      ),
    );
  }
}
