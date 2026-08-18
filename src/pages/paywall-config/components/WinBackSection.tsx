import React from "react";
import { ArrowUturnLeftIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import SectionCard from "./SectionCard";

interface WinBackSectionProps {
  enabled: boolean;
  delaySeconds: string;
  maxPerSession: string;
  onChange: (next: {
    enabled: boolean;
    delaySeconds: string;
    maxPerSession: string;
  }) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

/**
 * Win-back: the reader opened the FULL paywall, closed it without buying, and
 * gets the compact discount sheet a few seconds later.
 *
 * The sheet itself is configured in "Paywall rút gọn" — this section only owns
 * WHEN it appears. Two things stay hardcoded in the app on purpose: it never
 * follows the compact sheet (that would be the same sheet twice), and a delay
 * that elapses while the app is in the background is dropped rather than queued,
 * so nobody comes back to MeUp and is met by a sales sheet.
 */
const WinBackSection: React.FC<WinBackSectionProps> = ({
  enabled,
  delaySeconds,
  maxPerSession,
  onChange,
  disabled = false,
  fieldErrors,
}) => {
  const numberField = (
    id: string,
    label: string,
    hint: string,
    value: string,
    errorKey: string,
    onValue: (next: string) => void,
  ) => (
    <div>
      <label
        htmlFor={id}
        className="block text-xs font-medium text-slate-700 mb-1.5"
      >
        {label}
      </label>
      <input
        id={id}
        type="number"
        value={value}
        onChange={(event) => onValue(event.target.value)}
        disabled={disabled || !enabled}
        className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm disabled:bg-slate-50 disabled:text-slate-400"
      />
      <p className="mt-1 text-xs text-slate-500">{hint}</p>
      {fieldErrors[errorKey] && (
        <p className="mt-1 text-xs text-rose-600">{fieldErrors[errorKey]}</p>
      )}
    </div>
  );

  return (
    <SectionCard
      title="Win-back (đã xem paywall nhưng chưa mua)"
      description="Đóng paywall đầy đủ mà không mua ⇒ sau N giây hiện Paywall rút gọn. Nội dung sheet lấy từ mục 'Paywall rút gọn'. Không áp dụng khi vừa đóng chính sheet rút gọn, và bỏ qua nếu app đang ở nền lúc hết giờ."
      icon={ArrowUturnLeftIcon}
      headerRight={
        <ToggleSwitch
          checked={enabled}
          onChange={(next) =>
            onChange({ enabled: next, delaySeconds, maxPerSession })
          }
          label="Bật"
          disabled={disabled}
        />
      }
    >
      {fieldErrors["winBack.enabled"] && (
        <p className="text-xs text-rose-600">{fieldErrors["winBack.enabled"]}</p>
      )}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {numberField(
          "win-back-delay",
          "Số giây chờ",
          "0–60. Spec là 3.",
          delaySeconds,
          "winBack.delaySeconds",
          (next) =>
            onChange({ enabled, delaySeconds: next, maxPerSession }),
        )}
        {numberField(
          "win-back-cap",
          "Tối đa mỗi phiên",
          "1–5. Một phiên = một lần mở app.",
          maxPerSession,
          "winBack.maxPerSession",
          (next) =>
            onChange({ enabled, delaySeconds, maxPerSession: next }),
        )}
      </div>
    </SectionCard>
  );
};

export default WinBackSection;
