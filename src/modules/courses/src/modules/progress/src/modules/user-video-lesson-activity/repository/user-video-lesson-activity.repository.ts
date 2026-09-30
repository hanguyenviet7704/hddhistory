import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListUserVideoLessonActivityDto } from '../dto/user-video-lesson-activity.dto';
import { UserVideoLessonActivity } from '../schema/user-video-lesson-activity.schema';

@Injectable()
export class UserVideoLessonActivityRepository extends AbstractRepository<UserVideoLessonActivity> {
  protected readonly logger = new Logger(UserVideoLessonActivityRepository.name);

  constructor(
    @InjectModel(UserVideoLessonActivity.name)
    model: Model<UserVideoLessonActivity>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findOption(dto: GetListUserVideoLessonActivityDto & { userId: string }) {
    const { page, take, search, order, orderBy, userId, courseId, nodeId, lessonId } = dto;
    const effectiveOrderBy = orderBy || 'atSecond';
    const effectiveOrder = order || OrderType.ASC;
    const where: FilterQuery<UserVideoLessonActivity> = { userId };

    if (courseId) where.courseId = courseId;
    if (nodeId) where.nodeId = nodeId;
    if (lessonId) where.lessonId = lessonId;

    if (search) {
      where.content = { $regex: search, $options: 'i' };
    }

    return this.paginateQuery<UserVideoLessonActivity>({
      where,
      page,
      take,
      orderBy: effectiveOrderBy,
      order: effectiveOrder,
    });
  }

  findOneByComposite(where: FilterQuery<UserVideoLessonActivity>) {
    return this.model.findOne(where).lean();
  }
}
