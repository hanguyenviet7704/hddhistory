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
        title="Chung"
        description="Phiên bản schema và quy tắc khóa bài học."
        icon={LockClosedIcon}
      >
        <label className="flex flex-col gap-1 text-xs text-slate-700 max-w-[160px]">
          <span className="font-medium">Phiên bản schema</span>
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

        <div className="rounded-xl border border-slate-100 bg-slate-50/60 px-3.5 py-3">
          <ToggleSwitch
            checked={draft.enableLessonLock}
            onChange={(checked) => onChange({ enableLessonLock: checked })}
            label="Bật khóa bài học"
            description="Chặn bài học sau paywall theo các quy tắc bên dưới."
            disabled={disabled}
            fullWidth
          />
        </div>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">
            Quy tắc khóa bài học (JSON thô, không bắt buộc)
            {!draft.enableLessonLock && (
              <span className="ml-1 font-normal text-slate-500">
                - chỉ dùng khi bật khóa bài học
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
            className={`rounded-lg border px-3 py-2.5 text-[13px] leading-relaxed font-mono bg-slate-50/70 focus:bg-white transition-colors focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors.lessonLock ? "border-red-300" : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-500">
            Định dạng không cố định trong trình chỉnh này - được lưu nguyên
            trạng. Để trống nếu không cần.
          </span>
          {fieldErrors.lessonLock && (
            <span className="text-[11px] text-red-600">{fieldErrors.lessonLock}</span>
          )}
        </label>
      </SectionCard>

      <SectionCard
        title="Tự động mở paywall"
        description="Tự động bật paywall cho một phần trăm phiên (session) được chọn."
        icon={AdjustmentsHorizontalIcon}
        headerRight={
          <ToggleSwitch
            checked={draft.autoOpenEnabled}
            onChange={(checked) => onChange({ autoOpenEnabled: checked })}
            label="Bật"
            disabled={disabled}
          />
        }
      >
        <label className="flex flex-col gap-1 text-xs text-slate-700 max-w-xs">
          <span className="font-medium">Tỷ lệ phiên áp dụng (rollout)</span>
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
              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-500 text-xs pointer-events-none">
                %
              </span>
            </div>
          </div>
          {fieldErrors["autoOpen.sessionRolloutPercent"] && (
            <span className="text-[11px] text-red-600">
              {fieldErrors["autoOpen.sessionRolloutPercent"]}
            </span>
          )}
          <span className="text-[11px] text-slate-500">
            Phần trăm phiên (0-100) sẽ tự động thấy paywall bật lên.
          </span>
        </label>
      </SectionCard>
    </div>
  );
};

export default GeneralSection;
