import React from "react";
import { ExclamationTriangleIcon, RectangleStackIcon } from "@heroicons/react/24/outline";
import GiftTitleEditor from "../../../components/paywall-config/GiftTitleEditor";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { PAYWALL_ENTRY_POINTS } from "../../../types/interface/paywall-config.interface";
import {
  CompactPaywallDraft,
  EntryPointVariantsDraft,
  ProductRefDraft,
  ProductsByPlatform,
} from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface CompactPaywallSectionProps {
  entryPointVariants: EntryPointVariantsDraft;
  /** Same numbers `EntryPointVariantsSection` uses for its own warning — kept in sync by sharing one computation in the page. */
  compactCounts: Record<"defaultUser" | "saleEvent", number>;
  defaultUserCompactProducts: ProductRefDraft[];
  onChangeDefaultUserCompactProducts: (next: ProductRefDraft[]) => void;
  value: CompactPaywallDraft;
  onChange: (next: CompactPaywallDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

/**
 * Pure UI grouping — the data still lives per-strategy in the draft
 * (`saleStrategy.defaultUser.compactProducts`, `...saleEvent.compactProducts`,
 * and each new-user impression rule's own `compactProducts`; see
 * `paywallConfigDraft.ts`). Gathered into one section because an operator
 * configuring "which SKU does the one-plan compact paywall show" had to hunt
 * for a "danh sách rút gọn" editor buried inside three different sections.
 */
const CompactPaywallSection: React.FC<CompactPaywallSectionProps> = ({
  entryPointVariants,
  compactCounts,
  defaultUserCompactProducts,
  onChangeDefaultUserCompactProducts,
  value,
  onChange,
  disabled = false,
  fieldErrors,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  const compactChosen = PAYWALL_ENTRY_POINTS.filter(
    (entryPoint) => entryPointVariants[entryPoint] === "compact"
  );

  const strategiesWithoutCompact = (
    [
      ["defaultUser", "Người dùng mặc định"],
    ] as const
  ).filter(([key]) => compactCounts[key] === 0);

  return (
    <SectionCard
      title="Paywall rút gọn"
      description={
        'Bản một-gói kiểu "33% OFF" mở ra ở các điểm đặt "Rút gọn" và từ popup quà. Toàn bộ số má của sheet — % giảm, hạn đếm ngược, dòng cảnh báo — config ngay tại đây. Sự kiện sale KHÔNG ảnh hưởng bản này (chỉ dành cho paywall đầy đủ).'
      }
      icon={RectangleStackIcon}
    >
      {compactChosen.length > 0 && strategiesWithoutCompact.length > 0 && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-3.5 py-2.5 text-xs text-amber-800 leading-relaxed flex items-start gap-2">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0 mt-0.5" />
          <span>
            Đang có {compactChosen.length} điểm đặt "rút gọn", nhưng chưa khai báo
            danh sách rút gọn cho:{" "}
            <b>{strategiesWithoutCompact.map(([, label]) => label).join(", ")}</b>.
            Khi chiến lược đó thắng, các điểm này sẽ hiện danh sách đầy đủ.
          </span>
        </div>
      )}

      <ProductRefsEditor
        fieldPrefix="saleStrategy.defaultUser.compactProducts"
        title="Gói cho Người dùng mặc định"
        hint="Gói duy nhất sheet rút gọn hiển thị. Để trống thì dùng danh sách đầy đủ của chiến lược đang thắng."
        emptyHint="Để trống — dùng danh sách đầy đủ của Người dùng mặc định."
        value={defaultUserCompactProducts}
        onChange={onChangeDefaultUserCompactProducts}
        disabled={disabled}
        fieldErrors={fieldErrors}
        productsByPlatform={productsByPlatform}
        productsLoading={productsLoading}
        productsError={productsError}
        onRefreshProducts={onRefreshProducts}
      />

      <p className="text-[11px] text-slate-500">
        Người dùng mới: mỗi rule theo impression có danh sách rút gọn riêng —
        chỉnh trực tiếp trong từng rule ở section "Người dùng mới".
      </p>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Giảm giá (%)</span>
          <input
            value={value.discountPercent}
            onChange={(e) => onChange({ ...value, discountPercent: e.target.value })}
            placeholder="33"
            disabled={disabled}
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors["compactPaywall.discountPercent"] ? "border-red-300" : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-500">
            Chỉ là con số hiển thị "N% OFF" — giá thu thật là giá của gói bên trên.
          </span>
          {fieldErrors["compactPaywall.discountPercent"] && (
            <span className="text-[11px] text-red-600">{fieldErrors["compactPaywall.discountPercent"]}</span>
          )}
        </label>
      </div>

      <div className="flex flex-col gap-1">
        <span className="text-xs font-medium text-slate-700">Dòng cảnh báo (urgency)</span>
        <p className="text-[11px] text-slate-500">
          Hiện dưới headline "N% OFF" (cần điền % ở trên). Để trống dùng copy
          built-in: "You will never see this again if you exit".
        </p>
        <GiftTitleEditor
          value={value.urgencyLine}
          onChange={(urgencyLine) => onChange({ ...value, urgencyLine })}
          disabled={disabled}
          idPrefix="compact-urgency"
        />
        {fieldErrors["compactPaywall.urgencyLine.en"] ? (
          <p className="text-[11px] text-red-600">{fieldErrors["compactPaywall.urgencyLine.en"]}</p>
        ) : null}
      </div>
    </SectionCard>
  );
};

export default CompactPaywallSection;
