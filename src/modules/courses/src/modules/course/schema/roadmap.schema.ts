import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IRoadmap, IRoadmapLevel } from '../interface/roadmap.interface';

@Schema()
export class Roadmap extends AbstractDocument implements IRoadmap {
  @Prop()
  courseId: string;

  @Prop({ type: SchemaTypes.Array })
  levels: IRoadmapLevel[];
}

export const RoadmapSchema = SchemaFactory.createForClass(Roadmap);

RoadmapSchema.index({ courseId: 1 });
