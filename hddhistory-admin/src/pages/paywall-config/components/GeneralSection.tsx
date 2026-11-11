import React from "react";
import {
  AdjustmentsHorizontalIcon,
  BookOpenIcon,
  ExclamationTriangleIcon,
  LockClosedIcon,
} from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import { PaywallBodyVariant } from "../../../types/interface/paywall-config.interface";
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

        <div className="rounded-xl border border-slate-100 bg-slate-50/60 px-3.5 py-3">
          <ToggleSwitch
            checked={draft.showCredibilityBlock}
            onChange={(checked) => onChange({ showCredibilityBlock: checked })}
            label="Khối uy tín trên paywall"
            description="Dải nguyệt quế “Built on brain science” + đánh giá 5/5 dưới bảng giá. Tắt nếu tuyên bố này không phù hợp thị trường."
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

        <label className="flex flex-col gap-1">
          <span className="text-xs font-medium text-slate-700">Thân paywall</span>
          <select
            value={draft.bodyVariant}
            onChange={(e) =>
              onChange({ bodyVariant: e.target.value as PaywallBodyVariant })
            }
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          >
            <option value="benefits">Danh sách lợi ích</option>
            <option value="comparison">Bảng so sánh (Miễn phí vs Premium)</option>
          </select>
          <span className="text-[11px] text-slate-500">
            Chọn khối nằm giữa tiêu đề và các thẻ gói. Hai kiểu loại trừ nhau, không
            hiện cùng lúc. Nội dung của mỗi kiểu nhập trong khối ngôn ngữ bên dưới
            (Lợi ích / Bảng so sánh).
          </span>
          {/* Bật layout mà locale chưa có dòng nào thì app rơi về danh sách lợi
              ích — nói ra ở đây để người ta không đi tìm cái bảng không xuất hiện. */}
          {draft.bodyVariant === "comparison" && (
            <span className="text-[11px] text-amber-700 flex items-start gap-1">
              <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0 mt-px" />
              Ngôn ngữ nào chưa nhập dòng so sánh nào thì app vẫn hiện danh sách lợi
              ích của ngôn ngữ đó, không hiện bảng rỗng.
            </span>
          )}
        </label>

        {/* Nằm ngay dưới ô chọn thân paywall vì khi đợt test đang bật, chính nó
            là thứ quyết định người dùng thấy gì — ô ở trên chỉ còn áp dụng cho
            những người bị loại khỏi test. */}
        <div className="mt-4 rounded-lg border border-slate-200 bg-slate-50/60 p-3 flex flex-col gap-2">
          <div className="flex items-center justify-between gap-2">
            <span className="text-xs font-medium text-slate-700">
              A/B test thân paywall
            </span>
            <ToggleSwitch
              checked={draft.bodyExperiment.enabled}
              onChange={(checked) =>
                onChange({
                  bodyExperiment: { ...draft.bodyExperiment, enabled: checked },
                })
              }
              label="Bật"
              disabled={disabled}
            />
          </div>

          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Mã đợt test (key)</span>
            <input
              type="text"
              value={draft.bodyExperiment.key}
              onChange={(e) =>
                onChange({
                  bodyExperiment: {
                    ...draft.bodyExperiment,
                    key: e.target.value,
                  },
                })
              }
              placeholder="paywall_body_2026_08"
              disabled={disabled}
              className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                fieldErrors["bodyExperiment.key"]
                  ? "border-red-300"
                  : "border-slate-200"
              }`}
            />
            {fieldErrors["bodyExperiment.key"] && (
              <span className="text-[11px] text-red-600">
                {fieldErrors["bodyExperiment.key"]}
              </span>
            )}
            <span className="text-[11px] text-slate-500">
              Đợt mới phải đổi key. Dùng lại key cũ là trả mọi người về đúng nhánh
              họ từng ở, và đơn hàng cũ sẽ lẫn vào kết quả đợt mới.
            </span>
          </label>

          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Tỷ lệ vào nhánh Bảng so sánh</span>
            <div className="flex items-center gap-3">
              <input
                type="range"
                min={0}
                max={100}
                step={1}
                value={draft.bodyExperiment.comparisonPercent || "0"}
                onChange={(e) =>
                  onChange({
                    bodyExperiment: {
                      ...draft.bodyExperiment,
                      comparisonPercent: e.target.value,
                    },
                  })
                }
                disabled={disabled}
                className="flex-1 accent-teal-600"
              />
              <div className="relative w-20">
                <input
                  type="number"
                  min={0}
                  max={100}
                  step={1}
                  value={draft.bodyExperiment.comparisonPercent}
                  onChange={(e) =>
                    onChange({
                      bodyExperiment: {
                        ...draft.bodyExperiment,
                        comparisonPercent: e.target.value,
                      },
                    })
                  }
                  disabled={disabled}
                  className={`w-full rounded-lg border px-2 py-1.5 pr-6 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                    fieldErrors["bodyExperiment.comparisonPercent"]
                      ? "border-red-300"
                      : "border-slate-200"
                  }`}
                />
                <span className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-500 text-xs pointer-events-none">
                  %
                </span>
              </div>
            </div>
            <span className="text-[11px] text-slate-500">
              Phần còn lại vào nhánh Danh sách lợi ích. Server chia theo hash của
              user id nên một người luôn ở nguyên một nhánh.
            </span>
          </label>

          {draft.bodyExperiment.enabled && (
            <span className="text-[11px] text-amber-700 flex items-start gap-1">
              <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0 mt-px" />
              Đang chạy test: đừng đổi giá, đừng bật LogicSale/gift campaign và đừng
              sửa nội dung paywall — mỗi lần đăng bản mới là một lần dữ liệu bị cắt.
              Ngôn ngữ chưa có dòng so sánh sẽ bị loại khỏi test (không tính vào
              nhánh nào) thay vì bị cho xem bảng tiếng Anh.
            </span>
          )}
        </div>
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
        title="Khoá theo lượt ngày"
        description="Mỗi user chưa premium học xong miễn phí 1 keypoint mỗi ngày; học hết keypoint đó mới tính 1 lượt, sau đó các keypoint khác trong ngày khoá từ thẻ 3. Hôm sau lại có lượt mới."
        icon={BookOpenIcon}
        headerRight={
          <ToggleSwitch
            checked={draft.dailyQuotaEnabled}
            onChange={(checked) => onChange({ dailyQuotaEnabled: checked })}
            label="Bật"
            disabled={disabled}
          />
        }
      >
        <div className="flex flex-wrap gap-4">
          <label className="flex flex-col gap-1 text-xs text-slate-700 w-44">
            <span className="font-medium">Số keypoint free mỗi ngày</span>
            <input
              type="number"
              min={0}
              step={1}
              value={draft.dailyQuotaFreeKeypointsPerDay}
              onChange={(e) =>
                onChange({ dailyQuotaFreeKeypointsPerDay: e.target.value })
              }
              disabled={disabled || !draft.dailyQuotaEnabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
            <span className="text-[11px] text-slate-500">
              Số keypoint <b>học hết</b> mỗi ngày. Lượt chỉ bị tiêu khi user{" "}
              <b>hoàn thành</b> keypoint — đọc dở rồi thoát không mất gì, và đọc lại
              bài đã hoàn thành trước đó cũng không tính. Khi còn lượt thì mọi
              keypoint đều mở trọn vẹn, hết lượt mới dựng khoá.
            </span>
          </label>
          <label className="flex flex-col gap-1 text-xs text-slate-700 w-44">
            <span className="font-medium">Khoá từ thẻ thứ</span>
            <input
              type="number"
              min={1}
              step={1}
              value={draft.dailyQuotaAfterCards}
              onChange={(e) => onChange({ dailyQuotaAfterCards: e.target.value })}
              disabled={disabled || !draft.dailyQuotaEnabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
            <span className="text-[11px] text-slate-500">
              3 = đọc được 2 thẻ đầu rồi gặp paywall ở thẻ 3. Chỉ áp dụng sau khi
              user đã dùng hết lượt của ngày.
            </span>
          </label>
        </div>
        <p className="mt-3 rounded bg-amber-50 px-3 py-2 text-[11px] leading-relaxed text-amber-800">
          Luật này <b>thay</b> "Mở paywall trong bài học" bên dưới — bật cả hai thì
          cái nào chặn trước sẽ thắng, và user gặp một cái khoá khó đoán (cùng là bài
          đầu tiên trong ngày mà bài này đọc hết được, bài kia chỉ 2 thẻ vì nó nằm
          thứ 5 trong khoá). Bật cái này thì tắt cái kia.
        </p>
        <p className="mt-2 text-[11px] leading-relaxed text-slate-500">
          Khác mọi mục khác ở trang này: luật này do <b>server</b> cưỡng chế, vì nó
          phụ thuộc vào việc user đã <b>học xong</b> gì hôm nay — app chỉ được cho
          biết kết quả. "Ngày" tính theo múi giờ của chính user.
        </p>
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
            <span className="font-medium">Từ keypoint thứ</span>
            {/* Counts keypoints, in roadmap order — NOT the same ordering the
                lesson-lock count above uses. The client used to count lessons
                here despite the field name; see
                hddhistory-api/plans/260803-paywall-entry-point-variants/design.md. */}
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
              Áp cho keypoint thứ N <b>trở đi</b>, đếm theo thứ tự{" "}
              <b>keypoint</b> trong toàn khóa (khác cách "số bài học miễn phí"
              đếm) — user đã học quá mốc này (vd premium hết hạn) vẫn gặp
              paywall. Để 0 nếu muốn áp cho mọi keypoint.
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
