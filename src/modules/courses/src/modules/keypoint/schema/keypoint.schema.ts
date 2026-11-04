import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IKeypoint, IKeypointAudio } from '../interface/keypoint.interface';

@Schema()
export class Keypoint extends AbstractDocument implements IKeypoint {
  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  audio?: IKeypointAudio;

  @Prop({ type: SchemaTypes.Mixed })
  estimateCompleTime?: ITranslation;

  // Numeric estimate in minutes for backend calculations.
  // Keep text estimateCompleTime for display only.
  @Prop({ type: Number, default: 0, min: 0 })
  estimateCompleTimeNumber?: number;

  @Prop({ type: SchemaTypes.Array })
  tag: string[];

  /**
   * Id thực thể đồ thị tri thức (Neo4j `Entity.id`) mà bài nói tới — hợp các
   * `entityIds` của các thẻ trong bài, theo thứ tự xuất hiện. Coach lịch sử
   * dùng nó làm ngữ cảnh khi người học hỏi "về bài này". Ghi bởi seed
   * (`curriculum.builder.ts`) và `npm run backfill:keypoint-entities`.
   */
  @Prop({ type: [String], default: [] })
  entityIds?: string[];

  @Prop()
  image: string;

  @Prop()
  index: number;

  @Prop({ type: SchemaTypes.Mixed })
  learningItems?: any;

  progess?: string;
}

export const KeypointSchema = SchemaFactory.createForClass(Keypoint);

KeypointSchema.index({ index: 1 });
KeypointSchema.index({ entityIds: 1 });

// Per-language indexes backing KeypointRepository.findOption()'s
// `title.${lang}` / `description.${lang}` regex search and
// checkExitsTitle()'s `title.${lang}` exact-match uniqueness check (see
// course.schema.ts for why per-locale indexes are needed on a Mixed
// ITranslation field instead of a single compound one).
KeypointSchema.index({ 'title.en': 1 });
KeypointSchema.index({ 'title.vi': 1 });
KeypointSchema.index({ 'title.zh': 1 });
KeypointSchema.index({ 'title.ja': 1 });
KeypointSchema.index({ 'title.ko': 1 });
KeypointSchema.index({ 'description.en': 1 });
KeypointSchema.index({ 'description.vi': 1 });
KeypointSchema.index({ 'description.zh': 1 });
KeypointSchema.index({ 'description.ja': 1 });
KeypointSchema.index({ 'description.ko': 1 });
