import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { NotificationType } from '../notification.enum';
import { NotificationTemplate } from '../schema/notification-template.schema';

@Injectable()
export class NotificationTemplateRepository extends AbstractRepository<NotificationTemplate> {
  protected readonly logger = new Logger(NotificationTemplateRepository.name);

  constructor(
    @InjectModel(NotificationTemplate.name) model: Model<NotificationTemplate>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findAllTemplates() {
    return this.model.find().sort({ localHour: 1 }).lean();
  }

  async findByType(type: NotificationType) {
    return this.model.findOne({ type }).lean();
  }

  /** Only the types that are switched on, for the scheduler to walk. */
  async findEnabled() {
    return this.model.find({ enabled: true }).lean();
  }

  async upsertByType(
    type: NotificationType,
    update: UpdateQuery<NotificationTemplate>,
  ) {
    return this.model
      .findOneAndUpdate({ type }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }
}
