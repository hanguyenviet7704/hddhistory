import { TranslationDto } from './dto/common.dto';

export type TranslationInput =
  | Record<string, string | undefined>
  | TranslationDto
  | string
  | null
  | undefined;

export const normalizeTranslation = (
  input: string,
  lang: string,
  tran: TranslationDto = {},
): TranslationDto => {
  if (input && typeof input === 'string') {
    return { ...tran, [lang]: input };
  }
  return tran;
};

export const getTranslationValue = (
  input: TranslationInput,
  lang: string,
): string => {
  if (typeof input === 'string') return input.trim();

  const value = (input as Record<string, string | undefined>)?.[lang];
  return typeof value === 'string' ? value.trim() : '';
};

export const hasAnyTranslationValue = (input: TranslationInput): boolean => {
  if (typeof input === 'string') return input.trim().length > 0;
  if (!input || typeof input !== 'object') return false;

  return Object.values(input).some(
    value => typeof value === 'string' && value.trim().length > 0,
  );
};
