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
