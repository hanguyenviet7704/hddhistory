import React from "react";
import { GiftIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import GiftTitleEditor from "../../../components/paywall-config/GiftTitleEditor";
import { GiftCampaignDraft } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface GiftCampaignSectionProps {
  value: GiftCampaignDraft;
  onChange: (next: GiftCampaignDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

/**
 * Gift popup: its job is to open the compact paywall (see the "Paywall rút gọn"
 * section), so everything the reader sees after the tap belongs there. What is
 * configured here is the popup's title line and its schedule — the two triggers
 * and how long the daily one runs.
 *
 * The schedule used to be constants in the app, which made "run it for five
 * days this month" a code change, a release and a store review for a purely
 * marketing number. Still hardcoded: premium accounts are always skipped, the
 * popup shows at most once a day, and the "Open" CTA label.
 */
const GiftCampaignSection: React.FC<GiftCampaignSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
}) => {
  return (
    <SectionCard
      title="Gift campaign (popup quà tặng)"
      description={
        'Popup quà dẫn tới Paywall rút gọn. Hai thời điểm hiện: khi thêm habit đầu tiên (D0), và lần mở app đầu tiên của mỗi ngày trong cửa sổ D1–D<số ngày>. Luôn bỏ qua user đã premium, và tối đa 1 lần/ngày. CTA "Open" là chữ cứng.'
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
            label="D1–D7 — lần mở app đầu mỗi ngày"
            disabled={disabled}
          />
        </div>

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
            disabled={disabled || !value.triggerOnDailyOpen}
            placeholder="7"
            className="w-32 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition disabled:bg-slate-100 disabled:text-slate-400"
          />
          <p className="text-[11px] text-slate-500 mt-1.5">
            Đếm từ ngày user thêm habit đầu tiên. Để trống thì app dùng mặc định
            7 ngày. Chỉ áp dụng cho lịch D1–D7.
          </p>
          {fieldErrors["giftCampaign.windowDays"] && (
            <p className="text-[11px] text-red-600 mt-1">
              {fieldErrors["giftCampaign.windowDays"]}
            </p>
          )}
        </div>
      </div>
    </SectionCard>
  );
};

export default GiftCampaignSection;
