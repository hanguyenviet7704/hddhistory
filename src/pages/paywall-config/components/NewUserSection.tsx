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
      title="New user"
      description="Shown to users still inside their new-user window, with copy/products that escalate by impression count."
      icon={SparklesIcon}
      headerRight={
        <ToggleSwitch
          checked={value.enabled}
          onChange={(enabled) => onChange({ ...value, enabled })}
          label="Enabled"
          disabled={disabled}
        />
      }
    >
      <label className="flex flex-col gap-1 text-xs text-slate-600 max-w-[180px]">
        <span className="font-medium">Window (days)</span>
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
        <span className="text-[11px] text-slate-400">
          How many days after signup a user still counts as "new". Leave blank
          for no time limit.
        </span>
      </label>

      <div>
        <p className="text-xs font-medium text-slate-600 mb-1.5">
          Default content for this strategy (optional)
        </p>
        <LocaleContentEditor
          idPrefix="new-user"
          value={value.content}
          onChange={(content) => onChange({ ...value, content })}
          disabled={disabled}
        />
      </div>

      <div className="space-y-2 pt-1 border-t border-slate-100">
        <div className="flex items-center justify-between pt-3">
          <p className="text-xs font-medium text-slate-600">
            Impression rules
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
          <p className="text-xs text-slate-400">
            No impression rules yet - required if "New user" is enabled.
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
