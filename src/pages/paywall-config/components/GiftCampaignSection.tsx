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
 * Gift popup: its only job is to open the compact paywall (see the "Paywall
 * rút gọn" section) — everything the reader sees after the tap belongs there,
 * so the only thing left to configure here is the popup's title line. The
 * schedule (first habit on day 0, then the first app open each of days 1-7,
 * premium users skipped) and the "Open" CTA are both hardcoded in the app.
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
        'Popup quà dẫn tới Paywall rút gọn. Lịch hiển thị code cứng trong app: khi thêm habit đầu tiên (D0) và lần mở app đầu mỗi ngày D1–D7, chỉ user chưa premium. CTA "Open" là chữ cứng.'
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
    </SectionCard>
  );
};

export default GiftCampaignSection;
