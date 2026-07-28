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
      title="Sale event"
      description="A time-boxed campaign (e.g. Black Friday) that overrides the other strategies while active."
      icon={MegaphoneIcon}
      headerRight={
        <ToggleSwitch
          checked={value.enabled}
          onChange={(enabled) => onChange({ ...value, enabled })}
          label="Enabled"
          disabled={disabled}
        />
      }
    >
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          <span className="font-medium">Campaign ID</span>
          <input
            value={value.campaignId}
            onChange={(e) => onChange({ ...value, campaignId: e.target.value })}
            placeholder="black-friday-2026"
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-600">
          <span className="font-medium">Start (UTC)</span>
          <input
            type="datetime-local"
            value={value.startAtUtc}
            onChange={(e) => onChange({ ...value, startAtUtc: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-600">
          <span className="font-medium">End (UTC)</span>
          <input
            type="datetime-local"
            value={value.endAtUtc}
            onChange={(e) => onChange({ ...value, endAtUtc: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>
      </div>

      <label className="flex flex-col gap-1 text-xs text-slate-600">
        <span className="font-medium">Applies to</span>
        <input
          value={value.appliesTo}
          onChange={(e) => onChange({ ...value, appliesTo: e.target.value })}
          placeholder="all"
          disabled={disabled}
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
        />
        <span className="text-[11px] text-slate-400">
          Target audience selector - shape not fixed by the backend. Plain
          text (e.g. "all") is stored as-is; valid JSON (an object or array)
          is parsed and stored as that shape.
        </span>
      </label>

      <div>
        <p className="text-xs font-medium text-slate-600 mb-1.5">
          Content for this campaign (optional)
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
