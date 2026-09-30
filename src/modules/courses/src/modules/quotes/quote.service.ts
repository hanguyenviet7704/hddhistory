import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { CreateQuoteDto } from './dto/create-quote.dto';
import { GetListQuoteDto } from './dto/get-list-quote.dto';
import { UpdateQuoteDto } from './dto/update-quote.dto';
import { IQuote } from './interface/quote.interface';
import { QuoteRepository } from './repository/quote.repository';
import { Quote } from './schema/quote.schema';

@Injectable()
export class QuoteService {
  constructor(
    private readonly quoteRepository: QuoteRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createQuoteDto: CreateQuoteDto): Promise<Quote> {
    createQuoteDto._id = undefined;

    const quote = await this.quoteRepository.create(
      { ...createQuoteDto } as IQuote,
      this.user,
    );

    this.quoteRepository.clearCache();

    return quote;
  }

  async findAll(getListQuoteDto: GetListQuoteDto) {
    const result = await this.quoteRepository.findOption(getListQuoteDto);

    return result;
  }

  async findOne(id: string): Promise<Quote> {
    const quote = await this.quoteRepository.findOne({ _id: id });
    if (!quote)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_QUOTE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return quote;
  }

  async findRandom(): Promise<Quote> {
    const quote = await this.quoteRepository.findRandom();
    if (!quote)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_QUOTE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return quote;
  }

  async update(id: string, updateQuoteDto: UpdateQuoteDto) {
    const quote = await this.quoteRepository.findOne({ _id: id });
    if (!quote)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_QUOTE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    updateQuoteDto._id = undefined;
    const update = await this.quoteRepository.updateOne(
      { _id: id },
      {
        ...updateQuoteDto,
        content: updateQuoteDto.content
          ? { ...(quote.content ?? {}), ...updateQuoteDto.content }
          : quote.content,
      } as IQuote,
      this.user,
    );

    this.quoteRepository.clearCache();

    return update;
  }

  async remove(id: string) {
    const quote = await this.quoteRepository.findOne({ _id: id });
    if (!quote)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_QUOTE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const res = await this.quoteRepository.deleteOne({ _id: id });

    this.quoteRepository.clearCache();

    return res;
  }
}
