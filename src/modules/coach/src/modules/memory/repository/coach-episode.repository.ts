import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachEpisode } from '../schema/coach-episode.schema';

@Injectable()
export class CoachEpisodeRepository extends AbstractRepository<CoachEpisode> {
  protected readonly logger = new Logger(CoachEpisodeRepository.name);

  constructor(
    @InjectModel(CoachEpisode.name) model: Model<CoachEpisode>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Newest first, for one reader. */
  async findRecentForUser(userId: string, limit: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean();
  }

  /**
   * Những cảnh có chứa chữ người ta vừa hỏi tới.
   *
   * Dò trên `situation`/`insight` — đó là nơi chủ đề của một chuyện nằm. Cùng
   * lý do với `searchRecentForUser`: cửa sổ + regex, không text index.
   */
  async searchForUser(userId: string, keywords: string[], limit: number) {
    if (!keywords.length) return [];

    const rows = (await this.model
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean()) as Array<{
      situation: string;
      emotion?: string | null;
      insight?: string | null;
    }>;

    const needles = keywords.map((word) => word.toLowerCase());

    return rows
      .filter((row) => {
        const hay = `${row.situation ?? ''} ${row.insight ?? ''}`.toLowerCase();

        return needles.some((needle) => hay.includes(needle));
      })
      .slice(0, limit);
  }
}
