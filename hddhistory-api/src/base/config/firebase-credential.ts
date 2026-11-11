import * as admin from 'firebase-admin';

/**
 * `google-service.json` trong repo là file mẫu với mọi trường để rỗng. Nếu đưa
 * thẳng vào `admin.credential.cert()` thì nó ném lỗi ngay trong constructor của
 * FirebaseService, kéo sập mọi module chạm tới AuthModule — tức là gần như cả
 * app, trước khi Nest kịp wire xong. Đó là lý do API không boot được trên máy
 * cá nhân nếu không có credential thật.
 *
 * Hai hàm dưới đây tách riêng phần quyết định để test được mà không cần đụng
 * tới firebase-admin.
 */

/** Các trường mà thiếu một cái là `credential.cert()` chắc chắn ném lỗi. */
const REQUIRED_FIELDS = ['project_id', 'private_key', 'client_email'] as const;

export function isPlaceholderServiceAccount(sa: unknown): boolean {
  if (!sa || typeof sa !== 'object') return true;
  const record = sa as Record<string, unknown>;
  return REQUIRED_FIELDS.some((field) => {
    const value = record[field];
    return typeof value !== 'string' || value.trim() === '';
  });
}

/**
 * Hai điều kiện chứ không phải một: placeholder là dấu hiệu máy dev, còn chặn
 * `production` đảm bảo môi trường thật không bao giờ im lặng chạy với Firebase
 * giả — ở đó thiếu credential phải là lỗi ồn ào, không phải tính năng tắt lặng lẽ.
 */
export function shouldStubFirebase(
  sa: unknown,
  nodeEnv: string | undefined,
): boolean {
  if (nodeEnv === 'production') return false;
  return isPlaceholderServiceAccount(sa);
}

/**
 * Chỉ cần *dựng được* và trả về các service rỗng — không có lời gọi Firebase
 * nào chạy qua đây ở máy dev. Mỗi method ném lỗi có tên rõ ràng, để nếu sau này
 * một luồng nào đó thật sự cần Firebase thì lỗi chỉ thẳng vào chỗ gọi thay vì
 * im lặng trả undefined. Ép kiểu vì đây cố ý không phải app thật.
 */
export function createNoopFirebaseApp(): admin.app.App {
  const reject = (method: string) => async () => {
    throw new Error(`Firebase đang ở chế độ no-op, không gọi được ${method}`);
  };
  return {
    name: 'noop',
    auth: () => ({ verifyIdToken: reject('auth().verifyIdToken') }),
    messaging: () => ({
      sendEachForMulticast: reject('messaging().sendEachForMulticast'),
      send: reject('messaging().send'),
      subscribeToTopic: reject('messaging().subscribeToTopic'),
      unsubscribeFromTopic: reject('messaging().unsubscribeFromTopic'),
    }),
    remoteConfig: () => ({
      getTemplate: reject('remoteConfig().getTemplate'),
      publishTemplate: reject('remoteConfig().publishTemplate'),
    }),
  } as unknown as admin.app.App;
}
