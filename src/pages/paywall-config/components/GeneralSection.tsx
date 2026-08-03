import React from "react";
import {
  AdjustmentsHorizontalIcon,
  BookOpenIcon,
  ExclamationTriangleIcon,
  LockClosedIcon,
} from "@heroicons/react/24/outline";
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

        <label className="flex flex-col gap-1 text-xs text-slate-700 max-w-[200px]">
          <span className="font-medium">
            Số bài học miễn phí
            {draft.enableLessonLock && <span className="text-red-500 ml-0.5">*</span>}
            {!draft.enableLessonLock && (
              <span className="ml-1 font-normal text-slate-500">
                - chỉ dùng khi bật khóa bài học
              </span>
            )}
          </span>
          <input
            type="number"
            min={0}
            step={1}
            value={draft.lessonLockCount}
            onChange={(e) => onChange({ lessonLockCount: e.target.value })}
            disabled={disabled}
            placeholder="3"
            className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
              fieldErrors.lessonLock ? "border-red-300" : "border-slate-200"
            }`}
          />
          <span className="text-[11px] text-slate-500">
            Số bài đầu khóa học vẫn mở; từ bài kế tiếp trở đi sẽ hiện paywall.
            Tính theo thứ tự bài trong toàn khóa.
          </span>
          {fieldErrors.lessonLock && (
            <span className="text-[11px] text-red-600">{fieldErrors.lessonLock}</span>
          )}
          {/* 0 is a legitimate value (a course sold in full) but it is far more
              often a slip, and the consequence is severe: the first lesson is
              locked while still `notStarted`, so tapping it does nothing at all
              rather than opening the paywall. */}
          {draft.enableLessonLock && draft.lessonLockCount.trim() === "0" && (
            <span className="text-[11px] text-amber-700 flex items-start gap-1">
              <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0 mt-px" />
              0 nghĩa là khóa toàn bộ khóa học ngay từ bài đầu — user sẽ không mở
              được bài nào. Chỉ dùng nếu đó đúng là ý bạn.
            </span>
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

      <SectionCard
        title="Mở paywall trong bài học"
        description="Mở paywall ngay khi user cuộn qua thẻ đầu tiên của một keypoint."
        icon={BookOpenIcon}
        headerRight={
          <ToggleSwitch
            checked={draft.inLessonEnabled}
            onChange={(checked) => onChange({ inLessonEnabled: checked })}
            label="Bật"
            disabled={disabled}
          />
        }
      >
        <div className="flex flex-wrap gap-4">
          <label className="flex flex-col gap-1 text-xs text-slate-700 w-40">
            <span className="font-medium">Keypoint thứ</span>
            {/* Counts keypoints, in roadmap order — NOT the same ordering the
                lesson-lock count above uses. The client used to count lessons
                here despite the field name; see
                meup-api/plans/260803-paywall-entry-point-variants/design.md. */}
            <input
              type="number"
              min={0}
              step={1}
              value={draft.inLessonKeypointOrdinal}
              onChange={(e) =>
                onChange({ inLessonKeypointOrdinal: e.target.value })
              }
              disabled={disabled || !draft.inLessonEnabled}
              className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                fieldErrors["inLessonPaywall.keypointOrdinal"]
                  ? "border-red-300"
                  : "border-slate-200"
              }`}
            />
            {fieldErrors["inLessonPaywall.keypointOrdinal"] && (
              <span className="text-[11px] text-red-600">
                {fieldErrors["inLessonPaywall.keypointOrdinal"]}
              </span>
            )}
            <span className="text-[11px] text-slate-500">
              Đếm theo thứ tự <b>keypoint</b> trong toàn khóa (khác cách "số bài
              học miễn phí" đếm). Để 0 nếu muốn áp cho mọi keypoint.
            </span>
          </label>

          <label className="flex flex-col gap-1 text-xs text-slate-700 w-40">
            <span className="font-medium">Mở sau khi qua mấy thẻ</span>
            <input
              type="number"
              min={1}
              step={1}
              value={draft.inLessonAfterCards}
              onChange={(e) => onChange({ inLessonAfterCards: e.target.value })}
              disabled={disabled || !draft.inLessonEnabled}
              className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                fieldErrors["inLessonPaywall.afterCards"]
                  ? "border-red-300"
                  : "border-slate-200"
              }`}
            />
            {fieldErrors["inLessonPaywall.afterCards"] && (
              <span className="text-[11px] text-red-600">
                {fieldErrors["inLessonPaywall.afterCards"]}
              </span>
            )}
            <span className="text-[11px] text-slate-500">
              1 = mở đúng lúc user cuộn từ thẻ 1 sang thẻ 2.
            </span>
          </label>
        </div>
      </SectionCard>
    </div>
  );
};

export default GeneralSection;
