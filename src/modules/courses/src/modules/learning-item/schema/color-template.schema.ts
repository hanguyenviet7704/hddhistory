import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  IColorStyle,
  IConversationColor,
  IRoleplayColorTemplate,
} from '../interface/roleplays/color-template.interface';

@Schema({ collection: 'roleplay-color-templates' })
export class RoleplayColorTemplate
  extends AbstractDocument
  implements IRoleplayColorTemplate
{
  @Prop()
  title: string;

  @Prop({ type: SchemaTypes.Mixed })
  conversation: IConversationColor;

  @Prop({ type: SchemaTypes.Mixed })
  leadingText: IColorStyle;

  @Prop({ type: SchemaTypes.Mixed })
  transition: IColorStyle;

  @Prop({ type: SchemaTypes.Mixed })
  resultsOfAnsweringTheQuestion: IColorStyle;
}

export const RoleplayColorTemplateSchema = SchemaFactory.createForClass(
  RoleplayColorTemplate,
);
