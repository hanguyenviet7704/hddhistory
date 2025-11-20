import { LangCode } from "../types/enum/common.enum";
import { ITranslation } from "./translate";

export type { ITranslation } from "./translate";

/**
 * Lấy giá trị dịch theo thứ tự ưu tiên:
 * 1. Ngôn ngữ hiện tại
 * 2. Tiếng Anh (en)
 * 3. Ngôn ngữ đầu tiên có giá trị
 */
export function getTranslationValue(
  translation: ITranslation | undefined,
  currentLang: LangCode
): string {
  if (!translation) return "";

  // Ưu tiên ngôn ngữ hiện tại
  if (translation[currentLang]) {
    return translation[currentLang]!;
  }

  // Ưu tiên tiếng Anh
  if (translation[LangCode.EN]) {
    return translation[LangCode.EN]!;
  }

  // Lấy ngôn ngữ đầu tiên có giá trị
  const firstValue = Object.values(translation).find(
    (value) => value && value.trim() !== ""
  );
  return firstValue || "";
}

/**
 * Chỉ lấy giá trị của ngôn ngữ hiện tại, không lấy các ngôn ngữ khác
 * Dùng cho input field để người dùng có thể xóa hết text
 */
export function getCurrentTranslationValue(
  translation: ITranslation | undefined,
  currentLang: LangCode
): string {
  if (!translation) return "";
  return translation[currentLang] || "";
}

/**
 * Cập nhật giá trị dịch cho ngôn ngữ hiện tại
 */
export function updateTranslationValue(
  translation: ITranslation | undefined,
  lang: LangCode,
  value: string
): ITranslation {
  if (!translation) {
    return { [lang]: value };
  }

  return {
    ...translation,
    [lang]: value,
  };
}

/**
 * Lọc bỏ các giá trị rỗng trong ITranslation
 * Chỉ giữ lại các ngôn ngữ có giá trị không rỗng
 */
export function cleanTranslation(
  translation: ITranslation | undefined
): ITranslation | undefined {
  if (!translation) return undefined;

  const cleaned: ITranslation = {};

  // Lọc qua từng key-value pair
  Object.entries(translation).forEach(([key, value]) => {
    if (value && value.trim() !== "") {
      cleaned[key as LangCode] = value;
    }
  });

  // Nếu không có giá trị nào, trả về undefined
  return Object.keys(cleaned).length > 0 ? cleaned : undefined;
}

/**
 * Giống cleanTranslation nhưng luôn trả về ITranslation không undefined
 * Dùng cho API yêu cầu object không rỗng
 */
export function ensureTranslationObject(
  translation: ITranslation | undefined,
  fallbackLang: LangCode = LangCode.EN
): ITranslation {
  const cleaned = cleanTranslation(translation);

  if (cleaned) {
    return cleaned;
  }

  // Nếu không có giá trị nào, trả về object với fallbackLang có giá trị mặc định
  return { [fallbackLang]: "" };
}
