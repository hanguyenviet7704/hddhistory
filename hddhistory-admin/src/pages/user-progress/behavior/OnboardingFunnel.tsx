import React, { useMemo } from "react";
import { CheckIcon } from "@heroicons/react/24/outline";
import { ONBOARDING_FUNNEL_STEPS } from "../../../config/analyticsFunnel";
import { IUserBehaviorSummary } from "../../../types/interface/analytics.interface";
import { formatDateTime } from "./behaviorFormat";

export default function OnboardingFunnel({
  summary,
}: {
  summary: IUserBehaviorSummary;
}) {
  const seen = useMemo(() => {
    const map = new Map<string, string>();
    (summary.funnelFirstSeen ?? []).forEach((step) => {
      map.set(step.name, step.at);
    });
    return map;
  }, [summary.funnelFirstSeen]);

  // Last step the user actually reached — everything after it is where they
  // dropped off.
  const lastReachedIndex = useMemo(() => {
    let last = -1;
    ONBOARDING_FUNNEL_STEPS.forEach((step, index) => {
      if (seen.has(step.name)) last = index;
    });
    return last;
  }, [seen]);

  if (seen.size === 0) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <h3 className="text-sm font-semibold text-gray-900 mb-1">
          Funnel onboarding
        </h3>
        <p className="text-sm text-gray-500">
          Không có event onboarding trong khoảng thời gian này.
        </p>
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-semibold text-gray-900">
          Funnel onboarding
        </h3>
        <span className="text-xs text-gray-500">
          {lastReachedIndex + 1}/{ONBOARDING_FUNNEL_STEPS.length} bước
        </span>
      </div>
      <ol className="space-y-1">
        {ONBOARDING_FUNNEL_STEPS.map((step, index) => {
          const at = seen.get(step.name);
          const isDropOff = index === lastReachedIndex;
          return (
            <li
              key={step.name}
              className={`flex items-center gap-2 rounded-md px-2 py-1 text-sm ${
                isDropOff
                  ? "bg-amber-50 border border-amber-200"
                  : at
                  ? "bg-white"
                  : "bg-gray-50 text-gray-400"
              }`}
            >
              <span
                className={`flex h-4 w-4 items-center justify-center rounded-full text-[10px] ${
                  at ? "bg-emerald-100 text-emerald-700" : "bg-gray-200 text-gray-400"
                }`}
              >
                {at ? <CheckIcon className="h-3 w-3" /> : index + 1}
              </span>
              <span className="flex-1 truncate" title={step.name}>
                {step.label}
              </span>
              <span className="font-mono text-[11px] text-gray-400 hidden lg:inline">
                {step.name}
              </span>
              <span className="text-xs text-gray-500 w-40 text-right">
                {at ? formatDateTime(at) : "chưa tới"}
              </span>
            </li>
          );
        })}
      </ol>
      {lastReachedIndex >= 0 &&
      lastReachedIndex < ONBOARDING_FUNNEL_STEPS.length - 1 ? (
        <p className="mt-2 text-xs text-amber-700">
          Dừng ở bước "{ONBOARDING_FUNNEL_STEPS[lastReachedIndex].label}".
        </p>
      ) : null}
    </div>
  );
}
