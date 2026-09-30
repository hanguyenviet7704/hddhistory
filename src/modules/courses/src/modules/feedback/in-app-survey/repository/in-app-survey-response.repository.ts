import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetInAppSurveyResponsesDto } from '../dto/get-in-app-survey-responses.dto';
import { InAppSurveyResponse } from '../schema/in-app-survey-response.schema';

@Injectable()
export class InAppSurveyResponseRepository extends AbstractRepository<InAppSurveyResponse> {
  protected readonly logger = new Logger(InAppSurveyResponseRepository.name);

  constructor(
    @InjectModel(InAppSurveyResponse.name) model: Model<InAppSurveyResponse>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findByUserId(userId: string) {
    return this.model.find({ userId }).sort({ submittedAt: -1 }).lean();
  }

  async findAll(dto: GetInAppSurveyResponsesDto) {
    const page = Math.max(Number(dto.page) || 1, 1);
    const take = Math.max(Number(dto.take) || 20, 1);
    const filter = dto.userId?.trim() ? { userId: dto.userId.trim() } : {};
    const skip = (page - 1) * take;

    const [items, total] = await Promise.all([
      this.model
        .find(filter)
        .sort({ submittedAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(take)
        .lean(),
      this.model.countDocuments(filter),
    ]);

    return {
      items,
      total,
      totalPages: Math.ceil(total / take) || 1,
      currentPage: page,
      itemsPerPage: take,
    };
  }
}
