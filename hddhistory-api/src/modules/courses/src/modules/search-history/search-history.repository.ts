import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { SearchHistory } from './schema/search-history.schema';

@Injectable()
export class SearchHistoryRepository extends AbstractRepository<SearchHistory> {
  protected readonly logger = new Logger(SearchHistoryRepository.name);

  constructor(
    @InjectModel(SearchHistory.name) model: Model<SearchHistory>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async upsertQuery(userId: string, query: string): Promise<void> {
    const result = await this.model.findOneAndUpdate(
      { userId, query },
      { $set: { userId, query, updatedAt: new Date() } },
      { upsert: true, new: true, rawResult: true },
    );

    // Re-saving an already-stored query only bumps its updatedAt — the
    // per-user count is unchanged, so the cap can't have been breached and
    // the fetch+trim below can be skipped for this (common, repeat-search)
    // case.
    const isNewQuery = Boolean(result.lastErrorObject?.upserted);
    if (!isNewQuery) return;

    // The cap only needs to be enforced eventually, not before this write's
    // response — run the fetch+trim in the background instead of blocking
    // every new-query write on 2 extra round trips.
    this.trimOldQueries(userId).catch(err =>
      this.logger.error('Failed to trim search history', err),
    );
  }

  private async trimOldQueries(userId: string): Promise<void> {
    const all = await this.model
      .find({ userId })
      .sort({ updatedAt: -1 })
      .select('_id')
      .lean();

    if (all.length > 10) {
      const toDelete = all.slice(10).map(d => d._id);
      await this.model.deleteMany({ _id: { $in: toDelete } });
    }
  }

  async getRecentQueries(userId: string): Promise<SearchHistory[]> {
    return this.model
      .find({ userId })
      .sort({ updatedAt: -1 })
      .limit(10)
      .lean() as unknown as SearchHistory[];
  }

  async clearAll(userId: string): Promise<void> {
    await this.model.deleteMany({ userId });
  }
}
