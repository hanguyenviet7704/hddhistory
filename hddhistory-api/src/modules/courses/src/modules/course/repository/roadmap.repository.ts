import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { Roadmap } from '../schema/roadmap.schema';

@Injectable()
export class RoadmapRepository extends AbstractRepository<Roadmap> {
  protected readonly logger = new Logger(RoadmapRepository.name);
  constructor(
    @InjectModel(Roadmap.name) model: Model<Roadmap>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findByCourseIds(courseIds: string[]) {
    return this.model.find({ courseId: { $in: courseIds } }).lean();
  }

  async checkExitsTitle(title: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const roadmap = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return roadmap;
  }
}
