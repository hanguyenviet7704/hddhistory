import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { UserProgressExportStatus } from '../enum/user-progress-export.enum';

@Schema({ collection: 'user_progress_exports' })
export class UserProgressExport extends AbstractDocument {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({
    enum: UserProgressExportStatus,
    default: UserProgressExportStatus.PENDING,
  })
  status: UserProgressExportStatus;

  @Prop({ required: false })
  fileKey?: string;

  @Prop({ required: false })
  fileUrl?: string;

  @Prop({ type: Date })
  requestedAt?: Date;

  @Prop({ type: Date })
  startedAt?: Date;

  @Prop({ type: Date })
  finishedAt?: Date;

  @Prop({ required: false })
  error?: string;
}

export const UserProgressExportSchema =
  SchemaFactory.createForClass(UserProgressExport);

UserProgressExportSchema.index({ name: 1 });
