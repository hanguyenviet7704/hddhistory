/**
 * Che những field không bao giờ được nằm trong một dòng log.
 *
 * Tách ra khỏi `request-context.middleware.ts` khi nhật ký thao tác admin cần
 * đúng danh sách này. Một bản sao của danh sách secret là thứ chắc chắn sẽ lệch
 * nhau — và nó lệch về phía ghi ra thứ đáng lẽ phải che, im lặng, ở cả hai chỗ
 * cùng lúc.
 */
export const REDACTED_TEXT = '[REDACTED]';
const CIRCULAR_TEXT = '[Circular]';
export const UNSERIALIZABLE_TEXT = '[Unserializable]';
const SENSITIVE_BODY_FIELDS = new Set([
  'password',
  'newpassword',
  'oldpassword',
  'confirmpassword',
  'token',
  'accesstoken',
  'refreshtoken',
  'idtoken',
  'secret',
  'clientsecret',
  'apikey',
  'authorization',
  'cookie',
]);

export function isSensitiveField(fieldName: string): boolean {
  const normalized = fieldName.toLowerCase().replace(/[^a-z0-9]/g, '');
  return (
    SENSITIVE_BODY_FIELDS.has(normalized) ||
    normalized.endsWith('token') ||
    normalized.endsWith('secret')
  );
}

export function redactBody(
  value: unknown,
  visited: WeakSet<object> = new WeakSet(),
): unknown {
  if (Array.isArray(value)) {
    return value.map(item => redactBody(item, visited));
  }

  if (value && typeof value === 'object') {
    if (visited.has(value as object)) {
      return CIRCULAR_TEXT;
    }

    visited.add(value as object);
    const redactedObject: Record<string, unknown> = {};

    for (const [key, nestedValue] of Object.entries(
      value as Record<string, unknown>,
    )) {
      redactedObject[key] = isSensitiveField(key)
        ? REDACTED_TEXT
        : redactBody(nestedValue, visited);
    }

    return redactedObject;
  }

  return value;
}

/**
 * JSON hoá mà không bao giờ ném.
 *
 * Một dòng log không được phép làm gãy thứ nó đang ghi lại — và body có vòng
 * lặp tham chiếu là chuyện có thật.
 */
export function safeStringify(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch {
    return UNSERIALIZABLE_TEXT;
  }
}
