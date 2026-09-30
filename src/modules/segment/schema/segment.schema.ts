import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { SegmentCriteriaShape } from '../segment-match.util';

/**
 * The criteria block, embedded — a segment IS its criteria plus a name, and
 * they are always read and written together. Every field optional; unset
 * filters nothing. See `segment-match.util.ts` for the semantics of each.
 */
@Schema({ _id: false })
export class SegmentCriteria implements SegmentCriteriaShape {
  @Prop({ type: Date, default: null })
  firstSessionFrom: Date | null;

  @Prop({ type: Date, default: null })
  firstSessionTo: Date | null;

  @Prop({ type: Date, default: null })
  lastSessionFrom: Date | null;

  @Prop({ type: Date, default: null })
  lastSessionTo: Date | null;

  @Prop({ type: [String], default: [], comment: 'lowercase (vi, en, …)' })
  languages: string[];

  @Prop({ type: [String], default: [], comment: 'ISO-3166 alpha-2, uppercase' })
  countries: string[];

  @Prop({ type: [String], default: [], comment: 'ios | android' })
  deviceTypes: string[];

  @Prop({ type: Number, default: null, comment: 'D-day lower bound, inclusive' })
  lifecycleFrom: number | null;

  @Prop({ type: Number, default: null, comment: 'D-day upper bound, inclusive' })
  lifecycleTo: number | null;

  @Prop({ type: [String], default: [] })
  userIds: string[];

  @Prop({ type: [Number], default: [], comment: 'onboarding.learningGoal ids' })
  userGoals: number[];

  @Prop({
    type: [Number],
    default: [],
    comment: 'onboarding.skillsetWantToMaster ids, ANY match',
  })
  topicIds: number[];

  @Prop({
    type: [String],
    default: [],
    comment: 'pro_lifetime | pro_subscription | free_logged_in | free_guest',
  })
  userTypes: string[];
}

export const SegmentCriteriaSchema =
  SchemaFactory.createForClass(SegmentCriteria);

/**
 * A named audience. Referenced by id from banner slides and popup campaigns
 * (`segmentIds`), so deleting one only widens targeting — a dangling id simply
 * never matches, it does not break the surface that held it.
 */
@Schema({ collection: 'segments' })
export class Segment extends AbstractDocument {
  @Prop({ type: String, required: true })
  name: string;

  @Prop({ type: SegmentCriteriaSchema, default: () => ({}) })
  criteria: SegmentCriteria;
}

export const SegmentSchema = SchemaFactory.createForClass(Segment);
