export interface IDevice {
  deviceId: string;
  deviceName: string;
  refreshToken: string;
  loginAt: Date;

  /**
   * FCM registration token for THIS device, so scheduled notifications can be
   * sent to a specific user instead of a broadcast topic. Optional: it only
   * arrives once the app calls `POST users/push-registration` (a device that
   * never granted notification permission never reports one), and Firebase can
   * invalidate it at any time — the sender is what prunes dead tokens.
   */
  pushToken?: string;

  /**
   * The app's OWN notification toggle, not the OS permission. The server cannot
   * see either, so it must be told: sending to a device whose in-app switch is
   * off would show a notification the user already opted out of.
   */
  pushEnabled?: boolean;

  /** 'ios' | 'android' — kept free-form; only used for reporting. */
  pushPlatform?: string;

  /** When the three fields above were last reported. */
  pushUpdatedAt?: Date;
}
