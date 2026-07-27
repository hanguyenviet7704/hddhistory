import React from "react";
import { AdjustmentsHorizontalIcon, LockClosedIcon } from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import { ConfigDraft } from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

interface GeneralSectionProps {
  draft: ConfigDraft;
  onChange: (patch: Partial<ConfigDraft>) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

const GeneralSection: React.FC<GeneralSectionProps> = ({
  draft,
  onChange,
  disabled = false,
  fieldErrors,
}) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <SectionCard
        title="General"
        description="Schema version and lesson-lock rules."
        icon={LockClosedIcon}
      >
        <label className="flex flex-col gap-1 text-xs text-slate-600 max-w-[160px]">
          <span className="font-medium">Schema version</span>
          <input
            type="number"
            min={1}
            step={1}
            value={draft.schemaVersion}
            onChange={(e) => onChange({ schemaVersion: e.target.value })}
            disabled={disabled}
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors.schemaVersion ? "border-red-300" : "border-slate-200"
            }`}
          />
          {fieldErrors.schemaVersion && (
            <span className="text-[11px] text-red-600">{fieldErrors.schemaVersion}</span>
          )}
        </label>

        <ToggleSwitch
          checked={draft.enableLessonLock}
          onChange={(checked) => onChange({ enableLessonLock: checked })}
          label="Enable lesson lock"
          description="Gate lessons behind the paywall using the rules below."
          disabled={disabled}
        />

        <label className="flex flex-col gap-1 text-xs text-slate-600">
          <span className="font-medium">
            Lesson lock rules (raw JSON, optional)
            {!draft.enableLessonLock && (
              <span className="ml-1 font-normal text-slate-400">
                - only used when lesson lock is enabled
              </span>
            )}
          </span>
          <textarea
            value={draft.lessonLockText}
            onChange={(e) => onChange({ lessonLockText: e.target.value })}
            disabled={disabled}
            rows={6}
            placeholder='{ "lockedAfterLesson": 3 }'
            spellCheck={false}
            className={`rounded-lg border px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors.lessonLock ? "border-red-300" : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-400">
            Shape isn't fixed by this editor - passed through to Remote Config
            as-is. Leave blank for none.
          </span>
          {fieldErrors.lessonLock && (
            <span className="text-[11px] text-red-600">{fieldErrors.lessonLock}</span>
          )}
        </label>
      </SectionCard>

      <SectionCard
        title="Auto-open"
        description="Automatically pop the paywall for a rollout percentage of sessions."
        icon={AdjustmentsHorizontalIcon}
        headerRight={
          <ToggleSwitch
            checked={draft.autoOpenEnabled}
            onChange={(checked) => onChange({ autoOpenEnabled: checked })}
            label="Enabled"
            disabled={disabled}
          />
        }
      >
        <label className="flex flex-col gap-1 text-xs text-slate-600 max-w-xs">
          <span className="font-medium">Session rollout percent</span>
          <div className="flex items-center gap-3">
            <input
              type="range"
              min={0}
              max={100}
              step={1}
              value={draft.autoOpenPercent || "0"}
              onChange={(e) => onChange({ autoOpenPercent: e.target.value })}
              disabled={disabled}
              className="flex-1 accent-teal-600"
            />
            <div className="relative w-20">
              <input
                type="number"
                min={0}
                max={100}
                step={1}
                value={draft.autoOpenPercent}
                onChange={(e) => onChange({ autoOpenPercent: e.target.value })}
                disabled={disabled}
                className={`w-full rounded-lg border px-2 py-1.5 pr-6 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors["autoOpen.sessionRolloutPercent"]
                    ? "border-red-300"
                    : "border-slate-200"
                }`}
              />
              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 text-xs pointer-events-none">
                %
              </span>
            </div>
          </div>
          {fieldErrors["autoOpen.sessionRolloutPercent"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["autoOpen.sessionRolloutPercent"]}
            </span>
          )}
          <span className="text-[11px] text-slate-400">
            Percent of sessions (0-100) that see the paywall pop automatically.
          </span>
        </label>
      </SectionCard>
    </div>
  );
};

export default GeneralSection;
