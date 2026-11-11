import { Types } from 'mongoose';

export interface IUserMeta {
  _id: Types.ObjectId;
  name: string;
  email?: string;
  phone?: string;
}
