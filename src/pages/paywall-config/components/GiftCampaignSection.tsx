import React from "react";
import { GiftIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import LocaleContentEditor from "../../../components/paywall-config/LocaleContentEditor";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { GiftCampaignDraft, ProductsByPlatform } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface GiftCampaignSectionProps {
  value: GiftCampaignDraft;
  onChange: (next: GiftCampaignDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

/**
 * Gift campaign: popup "quà tặng" mở ra bottom sheet "N% OFF" với nút Claim.
 * Tách khỏi Sự kiện sale — sale đổi giao diện paywall đang mở, còn gift chen
 * ngang bằng hai surface riêng, chạy theo lịch riêng.
 */
const GiftCampaignSection: React.FC<GiftCampaignSectionProps> = ({
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
      title="Gift campaign (popup quà tặng)"
      description="Popup “Một món quà đặc biệt” mở ra bottom sheet giảm giá có đếm ngược. App sẽ bỏ qua campaign bật mà không có sản phẩm — nút Nhận ưu đãi khi đó không mua được gì."
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
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Mã chiến dịch</span>
          <input
            value={value.campaignId}
            onChange={(e) => onChange({ ...value, campaignId: e.target.value })}
            placeholder="tet-2027-gift"
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
              fieldErrors["giftCampaign.startAtUtc"]
                ? "border-red-300"
                : "border-slate-200"
            }`}
          />
          {fieldErrors["giftCampaign.startAtUtc"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["giftCampaign.startAtUtc"]}
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
              fieldErrors["giftCampaign.endAtUtc"]
                ? "border-red-300"
                : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-500">
            Cũng chính là mốc mà đồng hồ đếm ngược trên sheet đếm về.
          </span>
          {fieldErrors["giftCampaign.endAtUtc"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["giftCampaign.endAtUtc"]}
            </span>
          )}
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Giảm giá (%)</span>
          <input
            type="number"
            min={1}
            max={99}
            value={value.discountPercent}
            onChange={(e) =>
              onChange({ ...value, discountPercent: e.target.value })
            }
            placeholder="33"
            disabled={disabled}
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors["giftCampaign.discountPercent"]
                ? "border-red-300"
                : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-500">
            Chỉ là con số hiển thị “N% OFF”. Giá thu thật là giá của sản phẩm
            bên dưới — hai bên lệch nhau là lỗi hiển thị, không thu sai tiền.
          </span>
          {fieldErrors["giftCampaign.discountPercent"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["giftCampaign.discountPercent"]}
            </span>
          )}
        </label>
      </div>

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
        {fieldErrors["giftCampaign.appliesTo"] && (
          <span className="text-[11px] text-red-600">
            {fieldErrors["giftCampaign.appliesTo"]}
          </span>
        )}
      </fieldset>

      <div>
        <p className="text-xs font-medium text-slate-700 mb-1.5">
          Nội dung popup (bước 1 — chỉ heading được dùng)
        </p>
        <LocaleContentEditor
          idPrefix="gift-popup"
          value={value.popupContent}
          onChange={(popupContent) => onChange({ ...value, popupContent })}
          disabled={disabled}
        />
      </div>

      <div>
        <p className="text-xs font-medium text-slate-700 mb-1.5">
          Nội dung bottom sheet (bước 2)
        </p>
        <LocaleContentEditor
          idPrefix="gift-sheet"
          value={value.sheetContent}
          onChange={(sheetContent) => onChange({ ...value, sheetContent })}
          disabled={disabled}
        />
      </div>

      <ProductRefsEditor
        fieldPrefix="giftCampaign.products"
        title="Sản phẩm nút Nhận ưu đãi mua"
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

export default GiftCampaignSection;
