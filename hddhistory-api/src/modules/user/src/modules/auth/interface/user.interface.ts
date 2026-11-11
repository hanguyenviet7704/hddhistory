import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { IDevice } from './device.interface';
import { IOnboarding } from './onboarding.interface';
import { UserRole, UserStatus } from '../enum/user.enum';

export interface IUserLastAction {
  time: Date;
  action: string;
}

export interface IUser extends IUserMeta {
  id?: string;
  name: string;
  email: string;
  phone: string;
  age: string;
  gender: string;
  status: UserStatus;
  language: string;
  country: string;
  lastAction: IUserLastAction;
  avatar: string;
  role: UserRole;
  devices: IDevice[];
  provider?: string;
  enery?: string;
  onboarding?: IOnboarding;
  isOnboarded: boolean;
  /** When the first-run Confession tour was finished or skipped. Null = never. */
  communityTourSeenAt?: Date | null;
  anonymous: boolean;
  /** A Community bot persona, not a person. See the prop on the schema. */
  isBot?: boolean;
}
