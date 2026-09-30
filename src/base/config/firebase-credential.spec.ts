import {
  createNoopFirebaseApp,
  isPlaceholderServiceAccount,
  shouldStubFirebase,
} from './firebase-credential';

const PLACEHOLDER = {
  type: 'service_account',
  project_id: '',
  private_key: '',
  client_email: '',
};

const REAL = {
  type: 'service_account',
  project_id: 'hddhistory-dev',
  private_key: '-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n',
  client_email: 'sa@meup-dev.iam.gserviceaccount.com',
};

describe('isPlaceholderServiceAccount', () => {
  it('nhận ra file mẫu trong repo là placeholder', () => {
    expect(isPlaceholderServiceAccount(PLACEHOLDER)).toBe(true);
  });

  it('nhận ra service account thật', () => {
    expect(isPlaceholderServiceAccount(REAL)).toBe(false);
  });

  it('coi project_id chỉ có khoảng trắng là placeholder', () => {
    expect(isPlaceholderServiceAccount({ ...REAL, project_id: '   ' })).toBe(true);
  });

  it('coi thiếu private_key là placeholder dù có project_id', () => {
    expect(isPlaceholderServiceAccount({ ...REAL, private_key: '' })).toBe(true);
  });

  it('không nổ khi nhận null hoặc thứ không phải object', () => {
    expect(isPlaceholderServiceAccount(null)).toBe(true);
    expect(isPlaceholderServiceAccount('nope')).toBe(true);
  });
});

describe('shouldStubFirebase', () => {
  it('stub khi placeholder và không phải production', () => {
    expect(shouldStubFirebase(PLACEHOLDER, 'development')).toBe(true);
  });

  it('KHÔNG stub ở production dù credential là placeholder', () => {
    expect(shouldStubFirebase(PLACEHOLDER, 'production')).toBe(false);
  });

  it('KHÔNG stub khi credential thật', () => {
    expect(shouldStubFirebase(REAL, 'development')).toBe(false);
  });

  it('stub khi NODE_ENV không được đặt và credential là placeholder', () => {
    expect(shouldStubFirebase(PLACEHOLDER, undefined)).toBe(true);
  });
});

/**
 * Mỗi dòng ứng với một lời gọi thật trên `this.firebaseApp` bên trong
 * `firebase.ts`, cộng một lời gọi gián tiếp qua `remoteConfig()` bên trong
 * `paywall-config.repository.ts`. Thiếu một dòng ở đây nghĩa là trên máy dev
 * nó sẽ ném `TypeError: ... is not a function` thay vì lỗi no-op có tên rõ
 * ràng.
 */
const FIREBASE_CALL_SITES: Array<{
  namespace: 'auth' | 'messaging' | 'remoteConfig';
  method: string;
}> = [
  { namespace: 'auth', method: 'verifyIdToken' }, // firebase.ts:34
  { namespace: 'messaging', method: 'sendEachForMulticast' }, // firebase.ts:107
  { namespace: 'messaging', method: 'send' }, // firebase.ts:190-192
  { namespace: 'messaging', method: 'subscribeToTopic' }, // firebase.ts:205-207 (auth.service.ts subscribeTopicByToken)
  { namespace: 'messaging', method: 'unsubscribeFromTopic' }, // firebase.ts:229-231 (auth.service.ts unsubscribeTopicByToken)
  { namespace: 'remoteConfig', method: 'getTemplate' }, // firebase.ts:43 -> paywall-config.repository.ts:107
  { namespace: 'remoteConfig', method: 'publishTemplate' }, // paywall-config.repository.ts:112
];

describe('createNoopFirebaseApp', () => {
  it.each(FIREBASE_CALL_SITES)(
    'expose $namespace().$method và từ chối kèm tên method khi gọi',
    async ({ namespace, method }) => {
      const app = createNoopFirebaseApp();
      const getNamespace = app[namespace] as unknown as () => Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      const service = getNamespace();
      const fn = service[method];

      expect(typeof fn).toBe('function');
      await expect(fn()).rejects.toThrow(`${namespace}().${method}`);
    },
  );
});
