import { Injectable } from '@nestjs/common';

import { SaveSearchHistoryDto } from './dto/search-history.dto';
import { SearchHistoryRepository } from './search-history.repository';

@Injectable()
export class SearchHistoryService {
  constructor(
    private readonly searchHistoryRepository: SearchHistoryRepository,
  ) {}

  async saveQuery(userId: string, dto: SaveSearchHistoryDto): Promise<void> {
    await this.searchHistoryRepository.upsertQuery(userId, dto.query);
  }

  async getRecent(
    userId: string,
  ): Promise<{ query: string; updatedAt: Date }[]> {
    const results =
      await this.searchHistoryRepository.getRecentQueries(userId);
    return results.map(r => ({ query: r.query, updatedAt: r.updatedAt }));
  }

  async clearAll(userId: string): Promise<void> {
    await this.searchHistoryRepository.clearAll(userId);
  }
}
