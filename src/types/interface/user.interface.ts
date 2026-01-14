import { UserRole, UserStatus } from "../enum/user.enum";
import { BaseQuery } from "./common.interface";
import { IOnboarding } from "./onboarding.interface";

export interface IUserLastAction {
  time: Date;
  action: string;
}

export interface IDevice {
  deviceId: string;
  deviceName: string;
  refreshToken: string;
  loginAt: Date;
}
export interface IUser {
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
  anonymous: boolean;
  createdAt?: Date;
}

export interface DevicePayload {
  deviceId: string;
  deviceName: string;
}

export interface LoginPayload {
  email: string;
  password: string;
  device: DevicePayload;
}

export interface LogoutPayload {
  device: DevicePayload;
}

export interface RefreshTokenPayload {
  refreshToken: string;
  device: DevicePayload;
}

export interface TopinPayload {
  token: string;
  topic: string;
}

export class UserListQuery extends BaseQuery {
  role?: UserRole;
  status?: UserStatus;
  anonymous?: boolean;

  constructor(init?: Partial<UserListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.role) params.set("type", this.role);
    if (this.status) params.set("status", this.status);
    if (this.anonymous) params.set("courseId", this.anonymous.toString());

    return params.toString();
  }
}
