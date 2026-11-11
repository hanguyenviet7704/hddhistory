import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

import { toPushSafeUrl } from '@utils/url.utils';

import {
  createNoopFirebaseApp,
  shouldStubFirebase,
} from './firebase-credential';

@Injectable()
export class FirebaseService {
  private readonly logger = new Logger(FirebaseService.name);
  private readonly firebaseApp: admin.app.App;
  constructor() {
    const serviceAccount = require('../../../google-service.json');

    if (shouldStubFirebase(serviceAccount, process.env.NODE_ENV)) {
      this.logger.warn(
        'google-service.json là placeholder — Firebase chạy ở chế độ no-op. ' +
          'Push notification và Remote Config sẽ không hoạt động. ' +
          'Chỉ dành cho máy dev; ở production thiếu credential vẫn là lỗi.',
      );
      this.firebaseApp = createNoopFirebaseApp();
      return;
    }

    this.firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  async verifyToken(idToken: string) {
    return this.firebaseApp.auth().verifyIdToken(idToken);
  }

  /**
   * Exposes the Remote Config service off the already-initialised app so
   * callers (see `modules/paywall-config`) never touch `admin.initializeApp`
   * themselves -- this class stays the single place that does.
   */
  remoteConfig(): admin.remoteConfig.RemoteConfig {
    return this.firebaseApp.remoteConfig();
  }

  /**
   * Sends one notification to a list of device tokens and reports which of them
   * Firebase rejected as permanently dead, so the caller can drop them from the
   * user document. A token outlives nothing gracefully: reinstalls, restores and
   * long-idle apps all leave stale ones behind, and without pruning every send
   * grows a longer tail of guaranteed failures.
   *
   * Batched at 500 — the `sendEachForMulticast` ceiling.
   */
  async sendToTokens(
    tokens: string[],
    title: string,
    body: string,
    payload: Record<string, unknown> = {},
    imageUrl?: string | null,
  ): Promise<{
    successCount: number;
    failureCount: number;
    deadTokens: string[];
    // Why FCM rejected each failed token, most-frequent code first. Carried out
    // of here because a bare `failureCount: 1` is unactionable: the admin's test
    // send reported "not delivered" with no way to tell an expired token from an
    // APNs key that was never configured for this bundle.
    failures: string[];
  }> {
    const unique = [...new Set(tokens.filter(token => !!token))];
    if (unique.length === 0) {
      return { successCount: 0, failureCount: 0, deadTokens: [], failures: [] };
    }

    // FCM data values must be strings; a number or bool silently breaks the send.
    const data: Record<string, string> = {};
    for (const key of Object.keys(payload)) {
      data[key] = String(payload[key]);
    }

    // Encoded, not just trimmed: `firebase-admin` validates this URL itself and
    // throws INVALID_PAYLOAD for a character as ordinary as a space -- inside
    // `sendEach`'s per-message map, so it surfaces as every token failing with
    // `messaging/invalid-payload` and nothing naming the image. An artwork URL
    // that no encoding can save is dropped rather than allowed to sink the send:
    // a text-only push beats a push nobody receives.
    const image = toPushSafeUrl(imageUrl);
    if (!image && (imageUrl ?? '').trim()) {
      this.logger.warn(
        `Notification image URL is not sendable, sending without it: ${imageUrl}`,
      );
    }
    // The app reads `imageUrl` off the DATA map, not off the notification block:
    // that is the path a foreground push takes (the OS shows nothing while the
    // app is open, so the app renders its own notification and needs the URL
    // itself). Sent on both platforms because that path is shared.
    if (image) data.imageUrl = image;

    let successCount = 0;
    let failureCount = 0;
    const deadTokens: string[] = [];
    const failures: string[] = [];

    for (let index = 0; index < unique.length; index += 500) {
      const batch = unique.slice(index, index + 500);
      const response = await this.firebaseApp.messaging().sendEachForMulticast({
        tokens: batch,
        data,
        notification: image ? { title, body, imageUrl: image } : { title, body },
        // Both platforms are configured explicitly rather than left to the
        // top-level `notification.imageUrl` alone: that field is documented to
        // fan out, but each platform needs something extra that only its own
        // block carries -- and a silently image-less push looks identical to a
        // working one from the server's side.
        ...(image
          ? {
              // Android renders it as BigPictureStyle itself, with no app-side
              // work, whenever the app is NOT in the foreground.
              android: { notification: { imageUrl: image } },
              apns: {
                payload: {
                  aps: {
                    // What wakes the NotificationService extension. Without it
                    // APNs delivers the push as-is and drops the attachment --
                    // this flag is the whole reason an iOS image works.
                    mutableContent: true,
                    // Set explicitly alongside `mutable-content` so the banner
                    // still carries wording if FCM's own merge of the top-level
                    // notification into `aps` ever stops covering this case.
                    alert: { title, body },
                  },
                },
                fcmOptions: { imageUrl: image },
              },
            }
          : {}),
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((result, position) => {
        if (result.success) return;
        const code = result.error?.code ?? 'unknown';
        failures.push(code);
        // Logged at error level with the message too: the code alone does not
        // say WHICH bundle or key is misconfigured, and this is the only place
        // Firebase's own explanation exists.
        this.logger.error(
          `FCM send failed (${code}): ${result.error?.message ?? 'no message'}`,
        );
        // Only these two mean "this token will never work again". Everything
        // else (quota, unavailable, internal) is transient and must NOT cost the
        // user their registration.
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          deadTokens.push(batch[position]);
        }
      });
    }

    return { successCount, failureCount, deadTokens, failures };
  }

  async sendMessageToTopic(
    topic: string,
    title: string,
    message: string,
    payload: any,
  ) {
    const stringifiedPayload = { key: '' } as any;
    for (const key in payload) {
      if (payload.hasOwnProperty(key)) {
        stringifiedPayload[key] = String(payload[key]);
      }
    }

    const messageNoti = {
      data: stringifiedPayload,
      notification: {
        title: title,
        body: message,
      },
      topic: topic,
    };

    await this.firebaseApp
      .messaging()
      .send(messageNoti)
      .then(response => {
        console.log(`Successfully sent message to ${topic}:`, response);
      })
      .catch(error => {
        console.log(`Error sending message to ${topic}:`, error);
      });
  }

  async subscribeTopicByToken(token: string, topic: string) {
    const registrationTokens = [token];

    try {
      const response = await this.firebaseApp
        .messaging()
        .subscribeToTopic(registrationTokens, topic);

      if (!response || response.failureCount > 0) {
        const error =
          response?.errors?.[0]?.error ||
          new Error('Unknown error subscribing to topic');
        console.log('Error subscribing to topic:', error);
        throw error;
      }

      console.log('Successfully subscribed to topic:', response);
      return response;
    } catch (error) {
      console.log('Error subscribing to topic:', error);
      throw error;
    }
  }

  async unsubscribeTopicByToken(token: string, topic: string) {
    const registrationTokens = [token];

    try {
      const response = await this.firebaseApp
        .messaging()
        .unsubscribeFromTopic(registrationTokens, topic);

      if (!response || response.failureCount > 0) {
        const error =
          response?.errors?.[0]?.error ||
          new Error('Unknown error unsubscribing from topic');
        console.log('Error unsubscribing to topic:', error);
        throw error;
      }

      console.log('Successfully unsubscribed to topic:', response);
      return response;
    } catch (error) {
      console.log('Error unsubscribing to topic:', error);
      throw error;
    }
  }
}
