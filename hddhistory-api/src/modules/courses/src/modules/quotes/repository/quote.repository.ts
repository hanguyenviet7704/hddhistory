import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListQuoteDto } from '../dto/get-list-quote.dto';
import { Quote } from '../schema/quote.schema';

@Injectable()
export class QuoteRepository extends AbstractRepository<Quote> {
  protected readonly logger = new Logger(QuoteRepository.name);

  // Quotes rarely change, so cache the pool and sample in-memory instead of
  // running an aggregate $sample on every request.
  private static readonly POOL_TTL_MS = 5 * 60 * 1000;
  private quotePoolCache: { data: Quote[]; expiresAt: number } | null = null;

  constructor(
    @InjectModel(Quote.name) model: Model<Quote>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListQuoteDto: GetListQuoteDto) {
    const where: FilterQuery<Quote> = {};

    const { page, take, search, order, orderBy } = getListQuoteDto;

    if (search) {
      where.$or = [
        { [`content.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Quote>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findRandom(): Promise<Quote | null> {
    const pool = await this.getQuotePool();
    if (!pool.length) return null;

    const index = Math.floor(Math.random() * pool.length);
    return pool[index] ?? null;
  }

  private async getQuotePool(): Promise<Quote[]> {
    const now = Date.now();
    if (this.quotePoolCache && this.quotePoolCache.expiresAt > now) {
      return this.quotePoolCache.data;
    }

    const data = (await this.model.find({}).lean()) as unknown as Quote[];
    this.quotePoolCache = {
      data,
      expiresAt: now + QuoteRepository.POOL_TTL_MS,
    };

    return data;
  }

  clearCache(): void {
    this.quotePoolCache = null;
  }
}
