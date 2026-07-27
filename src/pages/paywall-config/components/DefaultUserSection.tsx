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
      title="Default user"
      description="Shown to everyone who doesn't match the new-user window or an active sale event. Always required."
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
    </SectionCard>
  );
};

export default DefaultUserSection;
