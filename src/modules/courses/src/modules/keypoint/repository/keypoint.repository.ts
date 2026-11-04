import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { ITranslation } from '@utils/interface/common.interface';

import { GetListKeypointDto } from '../dto/get-list-keypoint.dto';
import { IKeypointEntityContext } from '../interface/keypoint.interface';
import { Keypoint } from '../schema/keypoint.schema';

@Injectable()
export class KeypointRepository extends AbstractRepository<Keypoint> {
  protected readonly logger = new Logger(KeypointRepository.name);
  constructor(
    @InjectModel(Keypoint.name) model: Model<Keypoint>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListKeypointDto: GetListKeypointDto) {
    const where: FilterQuery<Keypoint> = {};

    const { page, take, search, order, orderBy } = getListKeypointDto;

    if (search) {
      const regex = new RegExp(search, 'i');
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
        { tag: { $in: [regex] } },
      ];
    }

    return this.paginateQuery<Keypoint>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findAllBrief() {
    const where: FilterQuery<Keypoint> = {};

    const list = await this.model
      .find(where)
      .select(
        'title _id description estimateCompleTime estimateCompleTimeNumber',
      )
      .lean();

    return { list };
  }

  /**
   * Brief projections for a known id set.
   *
   * Ids that are not castable ObjectIds are DROPPED rather than passed to
   * Mongo. Not defensive noise: these id lists come from rows the client wrote
   * (saved cards, recently viewed), and a generated "Bài học của tôi" keypoint
   * carries a synthesised `<lessonId>::user-lesson::<n>` id that this
   * collection can never hold. Handed to `$in`, Mongoose throws a CastError and
   * the WHOLE list request 500s — one such row took down all of Saved cards.
   *
   * Returning fewer rows than ids asked for is already this method's contract
   * (unpublished and deleted keypoints don't come back either), so callers
   * handle the gap; a throw is the only outcome none of them handle.
   */
  async findBriefByIds(ids: string[]) {
    const objectIds = ids.filter(id => Types.ObjectId.isValid(id));
    if (!objectIds.length) return [];

    return this.model
      .find(
        { _id: { $in: objectIds } },
        {
          _id: 1,
          title: 1,
          description: 1,
          estimateCompleTime: 1,
          estimateCompleTimeNumber: 1,
          image: 1,
          // Only the audio URL is needed by "brief" consumers (roadmap's
          // hasUsableAudio indicator; learning-item's keypoint tag). The full
          // `audio` object also carries `audio.text` — a 5-language TTS
          // transcript ~8KB per keypoint that no client reads here and that
          // dominated the roadmap payload (~95% of each lesson's bytes). The
          // full transcript is still served via findKeypointsByIds when a
          // keypoint is actually opened.
          'audio.url': 1,
        },
      )
      .lean();
  }

  async checkExitsTitle(title: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const Keypoint = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return Keypoint;
  }

  async findKeypointsByIds(ids: string[]) {
    return this.model.find({ _id: { $in: ids } }).lean();
  }

  /**
   * Tiêu đề và `entityIds` của một keypoint — đủ cho coach lịch sử mở cuộc trò
   * chuyện "hỏi về bài này". Id không phải ObjectId hợp lệ trả null (để nơi
   * gọi ra 404) thay vì ném CastError thành 500.
   */
  async findEntityContextById(
    id: string,
  ): Promise<IKeypointEntityContext | null> {
    if (!Types.ObjectId.isValid(id)) return null;

    const row = await this.model
      .findById(id, { title: 1, entityIds: 1 })
      .lean<{ _id: unknown; title: ITranslation; entityIds?: string[] }>();
    if (!row) return null;

    return {
      _id: String(row._id),
      title: row.title,
      entityIds: row.entityIds ?? [],
    };
  }

  /**
   * Keypoint nhắc tới một thực thể đồ thị tri thức — chiều ngược của
   * `entityIds`, cho mục "Bài học nhắc tới" trên hồ sơ thực thể. Có chỉ mục
   * `{ entityIds: 1 }` nên không quét cả collection.
   */
  async findBriefByEntityId(
    entityId: string,
  ): Promise<{ _id: string; title: ITranslation }[]> {
    const rows = await this.model
      .find({ entityIds: entityId }, { title: 1 })
      .lean<{ _id: unknown; title: ITranslation }[]>();
    return rows.map(row => ({ _id: String(row._id), title: row.title }));
  }

  async findAllForExport(keypointIds?: string[]) {
    return this.model
      .find(keypointIds ? { _id: { $in: keypointIds } } : {})
      .sort({ index: 1, _id: 1 })
      .lean();
  }

  /**
   * Every keypoint that has per-card voiceover segments — the population the
   * merged-audio backfill walks. Ids only: the merge re-reads each document
   * one at a time anyway, and this scan covers the whole catalogue.
   */
  /**
   * Keypoints that carry any audio, a page at a time, projected down to what
   * the clip-store backfill reads.
   *
   * Paged rather than all at once: `audio.text` alone is a five-language
   * transcript per keypoint, and loading the catalogue's worth in one array is
   * how a backfill pushes a pod over its memory limit. `audio.text` is excluded
   * for the same reason — nothing here reads it.
   */
  async findAudioPage(skip: number, limit: number) {
    return this.model
      .find(
        { audio: { $exists: true } },
        {
          _id: 1,
          'audio.url': 1,
          'audio.hash': 1,
          'audio.segments': 1,
          'audio.segmentHash': 1,
          'audio.nextUp': 1,
          'audio.nextUpHash': 1,
          'audio.merged': 1,
          'audio.voices': 1,
          'audio.voice': 1,
        },
      )
      .sort({ _id: 1 })
      .skip(skip)
      .limit(limit)
      .lean();
  }

  async findIdsWithSegments(): Promise<string[]> {
    const docs = await this.model
      .find({ 'audio.segments': { $exists: true, $ne: {} } }, { _id: 1 })
      .lean();
    return docs.map((doc: any) => String(doc._id));
  }

  /**
   * Exactly what the voiceover coverage report needs, for many keypoints at
   * once: the title plus the three `audio` sub-fields it compares against the
   * current text (`url` present?, `hash` matching?, `error` recorded?).
   *
   * The projection is the point. `audio.text` holds the whole 5-language
   * transcript — several KB per keypoint that the report never reads — and the
   * scan covers the entire catalogue, so pulling the full document (what
   * `findKeypointsByIds` does) made a scan far heavier than the comparison it
   * feeds.
   */
  async findVoiceoverStatusByIds(ids: string[]) {
    if (!ids.length) return [];

    return this.model
      .find(
        { _id: { $in: ids } },
        {
          _id: 1,
          title: 1,
          'audio.url': 1,
          'audio.hash': 1,
          'audio.error': 1,
        },
      )
      .lean();
  }
}
