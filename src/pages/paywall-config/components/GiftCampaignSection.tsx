import React from "react";
import { GiftIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import GiftTitleEditor from "../../../components/paywall-config/GiftTitleEditor";
import { PaywallGiftOpenFrequency } from "../../../types/interface/paywall-config.interface";
import { GiftCampaignDraft } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface GiftCampaignSectionProps {
  value: GiftCampaignDraft;
  onChange: (next: GiftCampaignDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

const OPEN_FREQUENCY_OPTIONS: {
  value: PaywallGiftOpenFrequency;
  label: string;
  hint: string;
}[] = [
  {
    value: "oncePerDay",
    label: "1 lần/ngày, trong cửa sổ D1–D<số ngày>",
    hint: "Lịch gốc: chỉ lần mở app đầu tiên của mỗi ngày, và chỉ với user đã thêm habit đầu tiên (D0).",
  },
  {
    value: "everyOpen",
    label: "Mỗi lần mở app",
    hint: "Mọi user chưa premium, không cần đã thêm habit. Đếm từ NGÀY TẠO TÀI KHOẢN và tính cả ngày đó (D0–D<số ngày>), nên user cũ hơn cửa sổ sẽ không thấy nữa. Còn bị chặn bởi giãn cách bên dưới.",
  },
];

/**
 * Gift popup: its job is to open the compact paywall (see the "Paywall rút gọn"
 * section), so everything the reader sees after the tap belongs there. What is
 * configured here is the popup's title line and its schedule — the two triggers,
 * how often the app-open one may fire, and how long the daily one runs.
 *
 * The schedule used to be constants in the app, which made "run it for five
 * days this month" a code change, a release and a store review for a purely
 * marketing number. Still hardcoded: premium accounts are always skipped, the
 * popup never covers a sheet the reader is already dealing with, and the "Open"
 * CTA label.
 */
const GiftCampaignSection: React.FC<GiftCampaignSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
}) => {
  const everyOpen = value.openFrequency === "everyOpen";
  // The whole frequency group hangs off the app-open trigger: with that toggle
  // off, none of these numbers is read by anything.
  const scheduleDisabled = disabled || !value.triggerOnDailyOpen;

  return (
    <SectionCard
      title="Gift campaign (popup quà tặng)"
      description={
        'Popup quà dẫn tới Paywall rút gọn. Hai thời điểm hiện: khi thêm habit đầu tiên (D0), và khi mở app — tần suất của lịch mở app chọn ngay bên dưới. Luôn bỏ qua user đã premium, và không bao giờ đè lên popup/sheet đang mở. Trong lúc có sự kiện sale chạy thì popup này NGƯNG hẳn (không đốt lượt — hết đợt sale là lịch tiếp tục từ đúng chỗ đang dở). CTA "Open" là chữ cứng.'
      }
      icon={GiftIcon}
      headerRight={
        <ToggleSwitch
          checked={value.enabled}
          onChange={(enabled) => onChange({ ...value, enabled })}
          label="Bật"
          disabled={disabled}
        />
      }
    >
      <div>
        <p className="text-xs font-medium text-slate-700 mb-1.5">
          Tiêu đề popup theo ngôn ngữ (không bắt buộc)
        </p>
        <GiftTitleEditor
          idPrefix="gift-title"
          value={value.title}
          onChange={(title) => onChange({ ...value, title })}
          disabled={disabled}
        />
        <p className="text-[11px] text-slate-500 mt-1.5">
          Để trống toàn bộ thì app dùng chữ mặc định "A special gift for you!".
        </p>
        {fieldErrors["giftCampaign.title.en"] && (
          <p className="text-[11px] text-red-600 mt-1">
            {fieldErrors["giftCampaign.title.en"]}
          </p>
        )}
      </div>

      <div className="mt-5 pt-5 border-t border-slate-200 space-y-4">
        <p className="text-xs font-semibold text-slate-700">Lịch hiển thị</p>

        <div className="flex flex-wrap items-start gap-6">
          <ToggleSwitch
            checked={value.triggerOnFirstHabit}
            onChange={(triggerOnFirstHabit) =>
              onChange({ ...value, triggerOnFirstHabit })
            }
            label="D0 — khi thêm habit đầu tiên"
            disabled={disabled}
          />
          <ToggleSwitch
            checked={value.triggerOnDailyOpen}
            onChange={(triggerOnDailyOpen) =>
              onChange({ ...value, triggerOnDailyOpen })
            }
            label="Khi mở app"
            disabled={disabled}
          />
        </div>

        <fieldset className="space-y-2" disabled={scheduleDisabled}>
          <legend className="text-xs font-medium text-slate-700 mb-1">
            Tần suất của lịch mở app
          </legend>
          {OPEN_FREQUENCY_OPTIONS.map((option) => (
            <label
              key={option.value}
              htmlFor={`gift-open-frequency-${option.value}`}
              className={`flex items-start gap-2.5 rounded-xl border px-3.5 py-2.5 transition ${
                scheduleDisabled
                  ? "cursor-not-allowed border-slate-200 bg-slate-50"
                  : "cursor-pointer border-slate-200 hover:border-slate-300"
              } ${
                value.openFrequency === option.value && !scheduleDisabled
                  ? "border-blue-400 bg-blue-50/60"
                  : ""
              }`}
            >
              <input
                id={`gift-open-frequency-${option.value}`}
                type="radio"
                name="gift-open-frequency"
                value={option.value}
                checked={value.openFrequency === option.value}
                onChange={() =>
                  onChange({ ...value, openFrequency: option.value })
                }
                disabled={scheduleDisabled}
                className="mt-0.5 h-4 w-4 flex-shrink-0 accent-blue-600"
              />
              <span className="flex flex-col gap-0.5">
                <span
                  className={`text-sm ${
                    scheduleDisabled ? "text-slate-400" : "text-slate-800"
                  }`}
                >
                  {option.label}
                </span>
                <span className="text-[11px] leading-relaxed text-slate-500">
                  {option.hint}
                </span>
              </span>
            </label>
          ))}
        </fieldset>

        <div>
          <label
            htmlFor="gift-window-days"
            className="block text-xs font-medium text-slate-700 mb-1.5"
          >
            Số ngày của cửa sổ (không bắt buộc)
          </label>
          <input
            id="gift-window-days"
            type="number"
            min={1}
            max={30}
            value={value.windowDays}
            onChange={(e) => onChange({ ...value, windowDays: e.target.value })}
            disabled={scheduleDisabled}
            placeholder="7"
            className="w-32 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition disabled:bg-slate-100 disabled:text-slate-400"
          />
          <p className="text-[11px] text-slate-500 mt-1.5">
            {everyOpen
              ? "Đếm từ ngày tạo tài khoản, TÍNH CẢ ngày đó (D0–D<số ngày>). Ngày kết thúc giống chế độ kia, chỉ thêm một ngày ở đầu — vì hôm user mới vào không có popup nào khác bắn, và đó là lúc lời mời đáng giá nhất. Để trống thì app dùng mặc định 7 ngày."
              : "Đếm từ ngày user thêm habit đầu tiên, KHÔNG tính ngày đó (D1–D<số ngày>) — hôm ấy popup habit đã bắn rồi. Để trống thì app dùng mặc định 7 ngày."}
          </p>
          {fieldErrors["giftCampaign.windowDays"] && (
            <p className="text-[11px] text-red-600 mt-1">
              {fieldErrors["giftCampaign.windowDays"]}
            </p>
          )}
        </div>

        {everyOpen && (
          <div>
            <label
              htmlFor="gift-min-gap-minutes"
              className="block text-xs font-medium text-slate-700 mb-1.5"
            >
              Giãn cách tối thiểu giữa 2 lần hiện (phút)
            </label>
            <input
              id="gift-min-gap-minutes"
              type="number"
              min={0}
              max={1440}
              value={value.minGapMinutes}
              onChange={(e) =>
                onChange({ ...value, minGapMinutes: e.target.value })
              }
              disabled={scheduleDisabled}
              placeholder="30"
              className="w-32 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition disabled:bg-slate-100 disabled:text-slate-400"
            />
            <p className="text-[11px] text-slate-500 mt-1.5">
              App kiểm tra mỗi lần user quay lại app, không chỉ lúc mở nguội —
              nên để 0 là user rời app 10 giây rồi vào lại cũng ăn popup. Để
              trống thì app dùng mặc định 30 phút.
            </p>
            {fieldErrors["giftCampaign.minGapMinutes"] && (
              <p className="text-[11px] text-red-600 mt-1">
                {fieldErrors["giftCampaign.minGapMinutes"]}
              </p>
            )}
          </div>
        )}
      </div>
    </SectionCard>
  );
};

export default GiftCampaignSection;
