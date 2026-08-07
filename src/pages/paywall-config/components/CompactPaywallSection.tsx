import React from "react";
import { ExclamationTriangleIcon, RectangleStackIcon } from "@heroicons/react/24/outline";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { PAYWALL_ENTRY_POINTS } from "../../../types/interface/paywall-config.interface";
import {
  EntryPointVariantsDraft,
  ProductRefDraft,
  ProductsByPlatform,
} from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface CompactPaywallSectionProps {
  entryPointVariants: EntryPointVariantsDraft;
  /** Same numbers `EntryPointVariantsSection` uses for its own warning — kept in sync by sharing one computation in the page. */
  compactCounts: Record<"defaultUser" | "newUser" | "saleEvent", number>;
  defaultUserCompactProducts: ProductRefDraft[];
  onChangeDefaultUserCompactProducts: (next: ProductRefDraft[]) => void;
  saleEventCompactProducts: ProductRefDraft[];
  onChangeSaleEventCompactProducts: (next: ProductRefDraft[]) => void;
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
  saleEventCompactProducts,
  onChangeSaleEventCompactProducts,
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
      ["newUser", "Người dùng mới"],
      ["saleEvent", "Sự kiện sale"],
    ] as const
  ).filter(([key]) => compactCounts[key] === 0);

  return (
    <SectionCard
      title="Paywall rút gọn"
      description={
        'Bản một-gói kiểu "33% OFF" mở ra ở các điểm đặt "Rút gọn" và từ popup quà. Gói hiển thị lấy từ danh sách rút gọn của chiến lược đang thắng; % giảm và đồng hồ đếm ngược lấy từ Sự kiện sale đang chạy.'
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
        hint="Hiện ở các điểm mở paywall đặt 'rút gọn' khi không có sự kiện sale nào đang thắng. Để trống thì dùng danh sách đầy đủ của Người dùng mặc định."
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

      <ProductRefsEditor
        fieldPrefix="saleStrategy.saleEvent.compactProducts"
        title="Gói khi có Sự kiện sale"
        hint="Hiện ở các điểm 'rút gọn' trong lúc Sự kiện sale đang chạy. Để trống thì dùng danh sách đầy đủ của Sự kiện sale."
        emptyHint="Để trống — dùng danh sách đầy đủ của Sự kiện sale."
        value={saleEventCompactProducts}
        onChange={onChangeSaleEventCompactProducts}
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
    </SectionCard>
  );
};

export default CompactPaywallSection;
