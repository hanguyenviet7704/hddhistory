import React from "react";
import { ExclamationTriangleIcon, PlusIcon, SparklesIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import LocaleContentEditor from "../../../components/paywall-config/LocaleContentEditor";
import {
  NewUserDraft,
  ProductsByPlatform,
  emptyImpressionRule,
} from "../paywallConfigDraft";
import ImpressionRuleCard from "./ImpressionRuleCard";
import SectionCard from "./SectionCard";

interface NewUserSectionProps {
  value: NewUserDraft;
  onChange: (next: NewUserDraft) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

const NewUserSection: React.FC<NewUserSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  const updateRule = (index: number, rule: NewUserDraft["impressionRules"][number]) => {
    onChange({
      ...value,
      impressionRules: value.impressionRules.map((r, i) => (i === index ? rule : r)),
    });
  };

  const removeRule = (index: number) => {
    onChange({
      ...value,
      impressionRules: value.impressionRules.filter((_, i) => i !== index),
    });
  };

  const addRule = () => {
    onChange({ ...value, impressionRules: [...value.impressionRules, emptyImpressionRule()] });
  };

  return (
    <SectionCard
      title="Người dùng mới"
      description="Hiển thị cho user còn trong cửa sổ 'người dùng mới', với nội dung/sản phẩm tăng dần theo số lần hiển thị (impression)."
      icon={SparklesIcon}
      headerRight={
        <ToggleSwitch
          checked={value.enabled}
          onChange={(enabled) => onChange({ ...value, enabled })}
          label="Bật"
          disabled={disabled}
        />
      }
    >
      <label className="flex flex-col gap-1 text-xs text-slate-700 max-w-[180px]">
        <span className="font-medium">Cửa sổ (số ngày)</span>
        <input
          type="number"
          min={0}
          step={1}
          value={value.windowDays}
          onChange={(e) => onChange({ ...value, windowDays: e.target.value })}
          disabled={disabled}
          placeholder="7"
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
        />
        <span className="text-[11px] text-slate-500">
          Số ngày sau khi đăng ký mà user vẫn được tính là "mới". Để trống nếu
          không giới hạn thời gian.
        </span>
      </label>

      <div>
        <p className="text-xs font-medium text-slate-700 mb-1.5">
          Nội dung mặc định cho nhóm này (không bắt buộc)
        </p>
        <LocaleContentEditor
          idPrefix="new-user"
          value={value.content}
          onChange={(content) => onChange({ ...value, content })}
          disabled={disabled}
        />
      </div>

      <div className="space-y-3 rounded-xl border border-slate-100 bg-slate-50/40 p-3.5">
        <div className="flex items-center justify-between">
          <p className="text-xs font-medium text-slate-700">
            Quy tắc theo impression
            {value.enabled && <span className="text-red-500 ml-0.5">*</span>}
          </p>
        </div>

        {fieldErrors["saleStrategy.newUser.impressionRules"] && (
          <p className="text-xs text-red-600 flex items-center gap-1.5">
            <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
            {fieldErrors["saleStrategy.newUser.impressionRules"]}
          </p>
        )}

        {value.impressionRules.length === 0 ? (
          <p className="text-xs text-slate-500">
            Chưa có rule nào - bắt buộc nếu bật "Người dùng mới".
          </p>
        ) : (
          <div className="space-y-2">
            {value.impressionRules.map((rule, index) => (
              <ImpressionRuleCard
                key={rule._localId}
                index={index}
                value={rule}
                onChange={(next) => updateRule(index, next)}
                onRemove={() => removeRule(index)}
                disabled={disabled}
                fieldErrors={fieldErrors}
                productsByPlatform={productsByPlatform}
                productsLoading={productsLoading}
                productsError={productsError}
                onRefreshProducts={onRefreshProducts}
              />
            ))}
          </div>
        )}

        <button
          type="button"
          onClick={addRule}
          disabled={disabled}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-dashed border-slate-300 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
        >
          <PlusIcon className="h-4 w-4" />
          Thêm rule
        </button>
      </div>
    </SectionCard>
  );
};

export default NewUserSection;
