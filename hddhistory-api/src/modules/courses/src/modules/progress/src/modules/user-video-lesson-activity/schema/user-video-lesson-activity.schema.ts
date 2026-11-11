import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IUserVideoLessonNote } from '../interface/user-video-lesson-activity.interface';

@Schema({ collection: 'user_video_lesson_activity' })
export class UserVideoLessonActivity
  extends AbstractDocument
  implements IUserVideoLessonNote
{
  @Prop({ required: true })
  id: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  courseId: string;

  @Prop({ required: true })
  nodeId: string;

  @Prop({ required: true })
  lessonId: string;

  @Prop({ required: true })
  content: string;

  @Prop({ type: Number, min: 0 })
  atSecond?: number;
}
export const UserVideoLessonActivitySchema = SchemaFactory.createForClass(
  UserVideoLessonActivity,
);

UserVideoLessonActivitySchema.index({ id: 1 }, { unique: true });
UserVideoLessonActivitySchema.index(
  { userId: 1, lessonId: 1, nodeId: 1, createdAt: -1 },
  { name: 'user_lesson_node_created_at_idx' },
);
UserVideoLessonActivitySchema.index({ courseId: 1, lessonId: 1 });
