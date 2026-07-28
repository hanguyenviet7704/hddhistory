// Shared parsing/formatting helpers for the voucher create/edit and bulk
// import forms - kept out of the components so both can stay in sync.

export const numberOrUndefined = (value: string): number | undefined => {
  if (!value.trim()) return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

// `datetime-local` inputs work in unzoned "YYYY-MM-DDTHH:mm" strings; the API
// expects/returns full ISO 8601. Convert only at the edges.
export const toInputDateTime = (value?: string): string => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate()
  )}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

export const fromInputDateTime = (value: string): string | undefined => {
  if (!value) return undefined;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString();
};

export const countriesToInput = (countries?: string[]): string =>
  countries && countries.length ? countries.join(", ") : "";

export const parseCountries = (value: string): string[] | undefined => {
  const codes = value
    .split(",")
    .map((code) => code.trim().toUpperCase())
    .filter(Boolean);
  return codes.length ? codes : undefined;
};

export const parseCodes = (value: string): string[] => {
  const codes = value
    .split(/[\n,]/)
    .map((code) => code.trim())
    .filter(Boolean);
  return Array.from(new Set(codes));
};
