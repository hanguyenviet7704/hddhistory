import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListLessonDto } from '../dto/get-list-lesson.dto';
import { LessonStatus } from '../enum/lesson.enum';
import { Lesson } from '../schema/lesson.schema';

@Injectable()
export class LessonRepository extends AbstractRepository<Lesson> {
  protected readonly logger = new Logger(LessonRepository.name);
  constructor(
    @InjectModel(Lesson.name) model: Model<Lesson>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListLessonDto: GetListLessonDto) {
    const where: FilterQuery<Lesson> = {};

    const { page, take, search, status, courseId, type } = getListLessonDto;
    let { orderBy, order } = getListLessonDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    if (status) {
      where.status = status;
    }

    if (type) {
      where.type = type;
    }

    if (courseId) {
      where.courseId = courseId;
      orderBy = 'index';
      order = OrderType.ASC;
    }

    return this.paginateQuery<Lesson>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findByIds(ids: string[]) {
    return this.model
      .find(
        { _id: { $in: ids } },
        {
          _id: 1,
          title: 1,
          type: 1,
          estimateCompleTime: 1,
          estimateCompleTimeNumber: 1,
          keypoints: 1,
          icon: 1,
          lightIcon: 1,
          learningItemId: 1,
          description: 1,
          'video.thumbnail': 1,
          image: 1,
        },
      )
      .lean();
  }

  /**
   * The lessons of one course, newest (highest index) first, with only what a
   * chip needs: title and keypoints. Used by the AI Coach's course recap.
   */
  /**
   * Whole lesson documents by id. Distinct from `findByIds`, which returns a
   * projection for list rendering: a content tag has to freeze every field.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findFullByIds(ids: string[]): Promise<Lesson[]> {
    if (!ids.length) return [];

    return this.model
      .find({ _id: { $in: ids } })
      .sort({ index: 1, _id: 1 })
      .lean<Lesson[]>();
  }

  async findBriefByCourse(courseId: string) {
    return this.model
      .find({ courseId })
      .select('title index keypoints courseId')
      .sort({ index: -1 })
      .lean();
  }

  /**
   * Bài ĐÃ PHÁT HÀNH chứa một trong các keypoint này, kèm tiêu đề — cho mục
   * "Bài học nhắc tới" trên hồ sơ thực thể. Bài nháp bị loại: người học bấm
   * vào sẽ gặp một bài chưa mở.
   */
  async findPublishedBriefByKeypointIds(keypointIds: string[]) {
    if (!keypointIds.length) return [];
    return this.model
      .find({
        keypoints: { $in: keypointIds },
        status: LessonStatus.PUBLISHED,
      })
      .select('title courseId keypoints index')
      .lean();
  }

  async countByCourse(courseId: string): Promise<number> {
    return this.model.countDocuments({ courseId });
  }

  // Flattened, de-duplicated keypoint ids of a course (in lesson → keypoint
  // order), used to drive per-course voiceover generation.
  /**
   * The lessons holding ANY of these keypoints — the one-query reverse map
   * from a habit's `keypointIds` to the courses that teach it ("Read more on
   * this"). Projected to the two fields that mapping needs.
   */
  async findByKeypointIds(keypointIds: string[]) {
    if (!keypointIds.length) return [];
    return this.model
      .find({ keypoints: { $in: keypointIds } })
      .select('courseId keypoints')
      .lean();
  }

  /**
   * The FIRST lesson of each course, with its keypoints.
   *
   * For the Coach's card rule: "khoá gợi ra phải có BÀI ĐẦU TIÊN chứa habit
   * đó". A course whose habit only turns up in lesson nine is not a door into
   * that habit — the reader would have to walk past eight other things first.
   * One aggregate rather than a query per course: the candidate list is the
   * whole point of the rule, so it is never one id.
   */
  async findFirstByCourseIds(courseIds: string[]) {
    if (!courseIds.length) return [];

    return this.model.aggregate([
      { $match: { courseId: { $in: courseIds.map((id) => new Types.ObjectId(id)) } } },
      { $sort: { courseId: 1, index: 1 } },
      {
        $group: {
          _id: '$courseId',
          keypoints: { $first: '$keypoints' },
        },
      },
    ]);
  }

  async findKeypointIdsByCourse(courseId: string): Promise<string[]> {
    const lessons = await this.model
      .find({ courseId }, { keypoints: 1 })
      .sort({ index: 1 })
      .lean();
    const ids: string[] = [];
    for (const lesson of lessons as any[]) {
      for (const kp of lesson.keypoints ?? []) ids.push(kp.toString());
    }
    return [...new Set(ids)];
  }

  /**
   * The course a keypoint belongs to, or null when no lesson references it.
   *
   * The link only exists in this direction — a keypoint document has no
   * `courseId` — so anything that needs a keypoint's course has to come through
   * here. Used by the single-keypoint dub button to find out which speech
   * provider the course is on; batch runs already know the course and must not
   * pay for this per keypoint.
   */
  async findCourseIdByKeypoint(keypointId: string): Promise<string | null> {
    const lesson: any = await this.model
      .findOne({ keypoints: keypointId }, { courseId: 1 })
      .lean();
    return lesson?.courseId ? lesson.courseId.toString() : null;
  }

  /**
   * How many distinct keypoints each course has, for every course, in ONE
   * aggregation — `{ [courseId]: count }`.
   *
   * Exists so a catalogue-wide dub run can state its total keypoint count before
   * it starts. It used to accumulate the total course by course as it went,
   * which left the progress bar's denominator growing under it and made an ETA
   * impossible to compute honestly.
   *
   * De-duplicates the same way `findKeypointIdsByCourse` does (two lessons of a
   * course may share a keypoint), so the total matches what the run will
   * actually walk.
   */
  async countKeypointsByCourse(): Promise<Record<string, number>> {
    const rows = await this.model.aggregate<{ _id: any; count: number }>([
      { $unwind: '$keypoints' },
      { $group: { _id: { courseId: '$courseId', keypointId: '$keypoints' } } },
      { $group: { _id: '$_id.courseId', count: { $sum: 1 } } },
    ]);

    const counts: Record<string, number> = {};
    for (const row of rows) {
      if (row._id === null || row._id === undefined) continue;
      counts[row._id.toString()] = row.count;
    }

    return counts;
  }

  /**
   * Every lesson in the catalog, projected to `_id` + `keypoints` only.
   * Sorted by `_id` so the daily warm-up auto-tagging scan iterates lessons
   * in a stable order (keeps the run deterministic/idempotent even when two
   * lessons happen to share a keypoint).
   */
  async findAllWithKeypoints(): Promise<Lesson[]> {
    const lessons = await this.model
      .find({}, { _id: 1, keypoints: 1 })
      .sort({ _id: 1 })
      .lean();

    return lessons as unknown as Lesson[];
  }

  async findAllForExport(courseId?: string): Promise<Lesson[]> {
    const lessons = await this.model
      .find(courseId ? { courseId } : {})
      .sort({ courseId: 1, index: 1 })
      .lean();

    return lessons as unknown as Lesson[];
  }

  async checkExitsTitle(title: string, courseId: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const Lesson = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
      courseId,
    });
    return Lesson;
  }

  async getNextIndex(courseId: string): Promise<number> {
    const lastLesson = await this.model
      .findOne({ courseId })
      .sort({ index: -1 })
      .select('index')
      .lean();

    const maxIndex = lastLesson?.index ?? 0;
    return maxIndex + 1;
  }
}
