import React from "react";
import { ArrowsRightLeftIcon } from "@heroicons/react/24/outline";
import {
  PAYWALL_ENTRY_POINTS,
  PAYWALL_ENTRY_POINT_LABELS,
  PaywallEntryPoint,
  PaywallProductVariant,
} from "../../../types/interface/paywall-config.interface";
import { EntryPointVariantsDraft } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface EntryPointVariantsSectionProps {
  value: EntryPointVariantsDraft;
  onChange: (next: EntryPointVariantsDraft) => void;
  disabled?: boolean;
  /** Which strategies actually have a reduced list to show. */
  compactCounts: Record<"defaultUser" | "newUser" | "saleEvent", number>;
}

const VARIANT_LABELS: Record<PaywallProductVariant, string> = {
  full: "Đầy đủ",
  compact: "Rút gọn",
};

/**
 * Which SKU list each entry point renders.
 *
 * The strategy (default user / new user / sale event) still decides the copy and
 * owns both lists; this only picks which of its two lists an entry point sees.
 * An entry point left on "đầy đủ" behaves exactly as it did before this feature
 * existed.
 */
const EntryPointVariantsSection: React.FC<EntryPointVariantsSectionProps> = ({
  value,
  onChange,
  disabled = false,
  compactCounts,
}) => {
  const compactChosen = PAYWALL_ENTRY_POINTS.filter(
    (entryPoint) => value[entryPoint] === "compact"
  );

  // A `compact` entry point with no strategy defining a reduced list falls back
  // to the full list. That is safe by design, but it also means the toggle
  // silently does nothing — worth saying out loud rather than letting someone
  // conclude the feature is broken.
  const strategiesWithoutCompact = (
    [
      ["defaultUser", "Người dùng mặc định"],
      ["newUser", "Người dùng mới"],
      ["saleEvent", "Sự kiện sale"],
    ] as const
  ).filter(([key]) => compactCounts[key] === 0);

  const setVariant = (
    entryPoint: PaywallEntryPoint,
    variant: PaywallProductVariant
  ) => onChange({ ...value, [entryPoint]: variant });

  return (
    <SectionCard
      title="Bộ gói theo điểm mở paywall"
      description="Cùng một nội dung, nhưng số gói hiển thị có thể khác nhau tùy user tới paywall từ đâu."
      icon={ArrowsRightLeftIcon}
    >
      {compactChosen.length > 0 && strategiesWithoutCompact.length > 0 && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-3.5 py-2.5 text-xs text-amber-800 leading-relaxed">
          Đang có {compactChosen.length} điểm đặt "rút gọn", nhưng chưa khai báo
          danh sách rút gọn cho:{" "}
          <b>{strategiesWithoutCompact.map(([, label]) => label).join(", ")}</b>.
          Khi chiến lược đó thắng, các điểm này sẽ hiện danh sách đầy đủ.
        </div>
      )}

      <div className="overflow-hidden rounded-xl border border-slate-200">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50/80 text-left text-xs text-slate-600">
              <th className="px-3.5 py-2.5 font-medium">Điểm mở paywall</th>
              <th className="w-56 px-3.5 py-2.5 font-medium">Bộ gói</th>
            </tr>
          </thead>
          <tbody>
            {PAYWALL_ENTRY_POINTS.map((entryPoint) => (
              <tr
                key={entryPoint}
                className="border-t border-slate-100 hover:bg-slate-50/50"
              >
                <td className="px-3.5 py-2.5">
                  <span className="text-slate-800">
                    {PAYWALL_ENTRY_POINT_LABELS[entryPoint]}
                  </span>
                  <code className="ml-2 font-mono text-[11px] text-slate-400">
                    {entryPoint}
                  </code>
                </td>
                <td className="px-3.5 py-2.5">
                  <div
                    className="inline-flex rounded-lg border border-slate-200 p-0.5"
                    role="radiogroup"
                    aria-label={`Bộ gói cho ${PAYWALL_ENTRY_POINT_LABELS[entryPoint]}`}
                  >
                    {(["full", "compact"] as PaywallProductVariant[]).map(
                      (variant) => {
                        const selected = value[entryPoint] === variant;
                        return (
                          <button
                            key={variant}
                            type="button"
                            role="radio"
                            aria-checked={selected}
                            onClick={() => setVariant(entryPoint, variant)}
                            disabled={disabled}
                            className={`rounded-md px-3 py-1 text-xs transition-colors disabled:opacity-50 ${
                              selected
                                ? "bg-teal-600 text-white font-medium"
                                : "text-slate-600 hover:bg-slate-100"
                            }`}
                          >
                            {VARIANT_LABELS[variant]}
                          </button>
                        );
                      }
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </SectionCard>
  );
};

export default EntryPointVariantsSection;
