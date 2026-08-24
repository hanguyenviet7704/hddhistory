import React from "react";

import { LangCode } from "../../types/enum/common.enum";
import { ITranslation, updateTranslationValue } from "../../utils/translation";

/**
 * Every locale the app ships, English FIRST because it is the fallback.
 *
 * The API resolves `value[readerLocale] || value.en || firstFilled`, so a topic
 * missing Japanese still renders for a Japanese reader — but one missing
 * everything renders as a blank row.
 */
export const COMMUNITY_LANGS: { code: LangCode; label: string }[] = [
  { code: LangCode.EN, label: "EN" },
  { code: LangCode.VI, label: "VI" },
  { code: LangCode.ZH, label: "ZH" },
  { code: LangCode.JA, label: "JA" },
  { code: LangCode.KO, label: "KO" },
];

interface Props {
  label: string;
  value?: ITranslation;
  onChange: (next: ITranslation) => void;
  rows?: number;
  /** Shown under the fields; defaults to the fallback explanation. */
  hint?: string;
  disabled?: boolean;
}

/**
 * One field per locale, all visible at once.
 *
 * Deliberately not a tab strip: with tabs there is no way to see which
 * languages are still blank without clicking through all five, which is how
 * half-translated content ships.
 */
const TranslationFields: React.FC<Props> = ({
  label,
  value,
  onChange,
  rows = 2,
  hint,
  disabled,
}) => (
  <div className="space-y-2">
    <label className="block text-sm font-medium text-gray-700">{label}</label>
    {COMMUNITY_LANGS.map(({ code, label: langLabel }) => {
      const isFallback = code === LangCode.EN;
      return (
        <div key={code} className="flex gap-2">
          <span
            className={`mt-2 w-10 shrink-0 text-xs font-semibold ${
              isFallback ? "text-indigo-600" : "text-gray-400"
            }`}
            title={
              isFallback
                ? "Bắt buộc — bản fallback khi user dùng ngôn ngữ chưa dịch"
                : undefined
            }
          >
            {langLabel}
            {isFallback ? " *" : ""}
          </span>
          <textarea
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100"
            rows={rows}
            disabled={disabled}
            value={value?.[code] || ""}
            placeholder={isFallback ? "Bắt buộc" : "Để trống sẽ dùng bản EN"}
            onChange={(event) =>
              onChange(
                updateTranslationValue(value || {}, code, event.target.value)
              )
            }
          />
        </div>
      );
    })}
    <p className="text-xs text-gray-500">
      {hint ??
        "Chỉ EN là bắt buộc: user ở ngôn ngữ chưa dịch sẽ đọc bản EN."}
    </p>
  </div>
);

export default TranslationFields;
