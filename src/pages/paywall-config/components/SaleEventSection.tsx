import React from "react";
import { MegaphoneIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import LocaleContentEditor from "../../../components/paywall-config/LocaleContentEditor";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { ProductsByPlatform, SaleEventDraft } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface SaleEventSectionProps {
  value: SaleEventDraft;
  onChange: (next: SaleEventDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

const SaleEventSection: React.FC<SaleEventSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  return (
    <SectionCard
      title="Sự kiện sale"
      description="Một chiến dịch có thời hạn (vd: Black Friday) sẽ ghi đè các chiến lược khác trong lúc đang chạy."
      icon={MegaphoneIcon}
      headerRight={
        <ToggleSwitch
          checked={value.enabled}
          onChange={(enabled) => onChange({ ...value, enabled })}
          label="Bật"
          disabled={disabled}
        />
      }
    >
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Mã chiến dịch</span>
          <input
            value={value.campaignId}
            onChange={(e) => onChange({ ...value, campaignId: e.target.value })}
            placeholder="black-friday-2026"
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Bắt đầu (UTC)</span>
          <input
            type="datetime-local"
            value={value.startAtUtc}
            onChange={(e) => onChange({ ...value, startAtUtc: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Kết thúc (UTC)</span>
          <input
            type="datetime-local"
            value={value.endAtUtc}
            onChange={(e) => onChange({ ...value, endAtUtc: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>
      </div>

      <label className="flex flex-col gap-1 text-xs text-slate-700">
        <span className="font-medium">Áp dụng cho</span>
        <input
          value={value.appliesTo}
          onChange={(e) => onChange({ ...value, appliesTo: e.target.value })}
          placeholder="all"
          disabled={disabled}
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-mono bg-slate-50/70 focus:bg-white transition-colors focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
        />
        <span className="text-[11px] text-slate-500">
          Bộ lọc đối tượng áp dụng - định dạng không cố định phía backend.
          Text thường (vd "all") được lưu nguyên văn; JSON hợp lệ (object
          hoặc array) sẽ được lưu đúng theo cấu trúc đó.
        </span>
      </label>

      <div>
        <p className="text-xs font-medium text-slate-700 mb-1.5">
          Nội dung cho chiến dịch này (không bắt buộc)
        </p>
        <LocaleContentEditor
          idPrefix="sale-event"
          value={value.content}
          onChange={(content) => onChange({ ...value, content })}
          disabled={disabled}
        />
      </div>

      <ProductRefsEditor
        fieldPrefix="saleStrategy.saleEvent.products"
        value={value.products}
        onChange={(products) => onChange({ ...value, products })}
        disabled={disabled}
        required={value.enabled}
        fieldErrors={fieldErrors}
        productsByPlatform={productsByPlatform}
        productsLoading={productsLoading}
        productsError={productsError}
        onRefreshProducts={onRefreshProducts}
      />
    </SectionCard>
  );
};

export default SaleEventSection;
