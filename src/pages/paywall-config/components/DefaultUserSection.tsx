import React from "react";
import { UserIcon } from "@heroicons/react/24/outline";
import LocaleContentEditor from "../../../components/paywall-config/LocaleContentEditor";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { DefaultUserDraft, ProductsByPlatform } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface DefaultUserSectionProps {
  value: DefaultUserDraft;
  onChange: (next: DefaultUserDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

const DefaultUserSection: React.FC<DefaultUserSectionProps> = ({
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
      title="Người dùng mặc định"
      description="Hiển thị cho mọi user không nằm trong cửa sổ người dùng mới và không có sự kiện sale nào đang chạy. Luôn bắt buộc."
      icon={UserIcon}
    >
      <LocaleContentEditor
        idPrefix="default-user"
        value={value.content}
        onChange={(content) => onChange({ ...value, content })}
        disabled={disabled}
        requiredError={fieldErrors["saleStrategy.defaultUser.content"]}
      />

      <ProductRefsEditor
        fieldPrefix="saleStrategy.defaultUser.products"
        title="Sản phẩm — danh sách đầy đủ"
        hint="Hiện ở các điểm mở paywall được đặt là 'đầy đủ'."
        value={value.products}
        onChange={(products) => onChange({ ...value, products })}
        disabled={disabled}
        required
        fieldErrors={fieldErrors}
        productsByPlatform={productsByPlatform}
        productsLoading={productsLoading}
        productsError={productsError}
        onRefreshProducts={onRefreshProducts}
      />

      <p className="text-[11px] text-slate-500">
        Danh sách rút gọn của người dùng mặc định đã chuyển sang section
        "Paywall rút gọn".
      </p>
    </SectionCard>
  );
};

export default DefaultUserSection;
