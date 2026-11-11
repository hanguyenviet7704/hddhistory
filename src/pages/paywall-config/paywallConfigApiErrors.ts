// Best-effort extraction of field-level errors from a failed API call.
//
// KNOWN GAP (hddhistory-api, not fixed here): `PaywallConfigService` throws
// `BadRequestException({ message, errors: [{ field, message }] })` for both
// shape and product-existence failures, but the shared
// `AllExceptionsFilter` (src/base/filters/all-exceptions.filter.ts) only
// forwards `message` to the HTTP response -- the `errors` array never
// reaches the client today. `validateDraft` (paywallConfigDraft.ts) mirrors
// the same rules client-side so inline errors still work without relying on
// this; this helper reads `errors` defensively so a future backend fix
// (forwarding `res.errors` when present) lights up automatically with no
// frontend change.
export const extractFieldErrors = (err: any): Record<string, string> => {
  const errors =
    err?.response?.data?.errors ?? err?.response?.data?.data?.errors;
  if (!Array.isArray(errors)) return {};

  const map: Record<string, string> = {};
  errors.forEach((entry: any) => {
    if (entry?.field) map[entry.field] = entry.message ?? "Invalid value";
  });
  return map;
};

export const extractErrorMessage = (err: any, fallback: string): string =>
  err?.response?.data?.message || fallback;

export const isNotFound = (err: any): boolean => err?.response?.status === 404;
