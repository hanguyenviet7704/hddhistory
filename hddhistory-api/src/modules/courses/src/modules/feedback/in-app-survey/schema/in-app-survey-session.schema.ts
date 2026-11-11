import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  IN_APP_SURVEY_CONFIG_KEY,
} from './in-app-survey-config.schema';
import {
  InAppSurveyUserSnapshot,
  InAppSurveyUserSnapshotSchema,
} from './in-app-survey-response.schema';
import { IInAppSurveySession } from '../interface/in-app-survey.interface';

@Schema({ collection: 'in_app_survey_sessions' })
export class InAppSurveySession
  extends AbstractDocument
  implements IInAppSurveySession
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: InAppSurveyUserSnapshotSchema })
  userSnapshot?: InAppSurveyUserSnapshot;

  @Prop({ required: true, default: IN_APP_SURVEY_CONFIG_KEY })
  configKey: string;

  @Prop({ type: Date, default: Date.now })
  startedAt: Date;

  @Prop({ type: Date })
  completedAt?: Date;

  @Prop()
  responseId?: string;

  @Prop()
  branchId?: string;

  @Prop({ type: Number })
  ratingScore?: number;
}

export const InAppSurveySessionSchema =
  SchemaFactory.createForClass(InAppSurveySession);

InAppSurveySessionSchema.index({ startedAt: -1 });
InAppSurveySessionSchema.index({ completedAt: -1 });
InAppSurveySessionSchema.index({ userId: 1, startedAt: -1 });
