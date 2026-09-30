import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { UserRole, UserStatus } from '../enum/user.enum';
import { IDevice } from '../interface/device.interface';
import { IOnboarding } from '../interface/onboarding.interface';
import { IUser, IUserLastAction } from '../interface/user.interface';

@Schema()
export class User extends AbstractDocument implements IUser {
  @Prop({ alowNull: false })
  name: string;

  @Prop({ alowNull: false })
  email: string;

  @Prop({ alowNull: false })
  password: string;

  @Prop()
  phone: string;

  @Prop()
  avatar: string;

  @Prop()
  age: string;

  @Prop()
  gender: string;

  @Prop({ enum: UserRole, default: UserRole.USER })
  role: UserRole;

  @Prop({ enum: UserStatus, default: UserStatus.ACTIVE })
  status: UserStatus;

  @Prop()
  language: string;

  /**
   * IANA zone reported by the app (e.g. `Asia/Ho_Chi_Minh`). Scheduled
   * notifications fire at a LOCAL hour (08:00 / 14:00 / 21:00), so without this
   * the server has no way to know when that is for a given user. Kept at user
   * level, not per device: the send cap is per user, and a person with devices in
   * two zones would otherwise be notified twice.
   */
  @Prop()
  timezone: string;

  /**
   * Giờ nhắc học user chọn ở onboarding (HH:mm, bước 15 phút, giờ ĐỊA PHƯƠNG theo
   * `timezone`). Null = không nhắc. Nằm trên users (không trong onboarding_answers)
   * để dispatcher lọc chung một query với push candidates.
   */
  @Prop({ type: String, default: null })
  studyReminderTime: string | null;

  @Prop()
  country: string;

  @Prop()
  enery: string;

  @Prop({ type: SchemaTypes.Mixed })
  lastAction: IUserLastAction;

  @Prop({ type: SchemaTypes.Array })
  devices: IDevice[];

  @Prop()
  provider?: string;

  @Prop()
  providerId?: string;

  @Prop({ type: SchemaTypes.Mixed })
  providerData?: any;

  @Prop({ type: Boolean, default: true })
  anonymous: boolean;

  /**
   * A Community bot persona rather than a person.
   *
   * The account is otherwise ordinary — it has a name and an avatar, and the
   * forum renders it exactly like anybody else, which is the whole point. This
   * flag exists so the places that COUNT people (dashboard, segments, push
   * dispatch) can leave it out; nothing reader-facing may branch on it.
   */
  @Prop({ type: Boolean, default: false })
  isBot: boolean;

  @Prop({ type: SchemaTypes.Mixed })
  onboarding?: IOnboarding;

  @Prop({ type: Boolean, default: false })
  isOnboarded: boolean;

  /**
   * When this reader finished (or skipped) the first-run Confession tour.
   *
   * Server-side rather than a flag on the device, for the reason onboarding
   * already learnt the hard way: a local flag is wiped by a reinstall and
   * unknown on a second device, so the tour would greet the same person again.
   * A DATE rather than a bool — it costs the same and answers "when did this
   * cohort meet the forum", which a bool never can.
   */
  @Prop({ type: Date, default: null })
  communityTourSeenAt?: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(User);
UserSchema.index({ email: 1, provider: 1 }, { unique: true });
UserSchema.index(
  { 'devices.deviceId': 1 },
  {
    unique: true,
    partialFilterExpression: {
      anonymous: true,
      'devices.deviceId': { $exists: true },
    },
  },
);
UserSchema.index({ studyReminderTime: 1 });
