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
          <span className="font-medium">
            Bắt đầu (UTC)
            {value.enabled && <span className="text-red-500 ml-0.5">*</span>}
          </span>
          <input
            type="datetime-local"
            value={value.startAtUtc}
            onChange={(e) => onChange({ ...value, startAtUtc: e.target.value })}
            disabled={disabled}
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors["saleStrategy.saleEvent.startAtUtc"]
                ? "border-red-300"
                : "border-slate-200"
            }`}
          />
          {fieldErrors["saleStrategy.saleEvent.startAtUtc"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["saleStrategy.saleEvent.startAtUtc"]}
            </span>
          )}
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">
            Kết thúc (UTC)
            {value.enabled && <span className="text-red-500 ml-0.5">*</span>}
          </span>
          <input
            type="datetime-local"
            value={value.endAtUtc}
            onChange={(e) => onChange({ ...value, endAtUtc: e.target.value })}
            disabled={disabled}
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors["saleStrategy.saleEvent.endAtUtc"]
                ? "border-red-300"
                : "border-slate-200"
            }`}
          />
          {fieldErrors["saleStrategy.saleEvent.endAtUtc"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["saleStrategy.saleEvent.endAtUtc"]}
            </span>
          )}
        </label>
      </div>

      {/* Was a free-text field whose placeholder was `all` -- a value the app
          always dropped, so the campaign silently targeted nobody. The wire
          shape is a list of these two names and nothing else. */}
      <fieldset className="flex flex-col gap-1 text-xs text-slate-700">
        <legend className="font-medium">
          Áp dụng cho
          {value.enabled && <span className="text-red-500 ml-0.5">*</span>}
        </legend>
        <div className="flex flex-wrap gap-4 pt-1">
          <label className="inline-flex items-center gap-2">
            <input
              type="checkbox"
              checked={value.appliesToDefaultUser}
              onChange={(e) =>
                onChange({ ...value, appliesToDefaultUser: e.target.checked })
              }
              disabled={disabled}
              className="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
            />
            <span>Người dùng mặc định</span>
          </label>
          <label className="inline-flex items-center gap-2">
            <input
              type="checkbox"
              checked={value.appliesToNewUser}
              onChange={(e) =>
                onChange({ ...value, appliesToNewUser: e.target.checked })
              }
              disabled={disabled}
              className="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
            />
            <span>Người dùng mới</span>
          </label>
        </div>
        <span className="text-[11px] text-slate-500">
          Không chọn đối tượng nào thì chiến dịch không hiện với ai cả.
        </span>
        {fieldErrors["saleStrategy.saleEvent.appliesTo"] && (
          <span className="text-[11px] text-red-600">
            {fieldErrors["saleStrategy.saleEvent.appliesTo"]}
          </span>
        )}
      </fieldset>

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
        title="Sản phẩm — danh sách đầy đủ"
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

      <p className="text-[11px] text-slate-500">
        Danh sách rút gọn của sự kiện sale đã chuyển sang section "Paywall rút
        gọn".
      </p>
    </SectionCard>
  );
};

export default SaleEventSection;
