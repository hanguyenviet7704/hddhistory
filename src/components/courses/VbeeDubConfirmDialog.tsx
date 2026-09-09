import React, { useEffect, useState } from "react";
import { AlertTriangleIcon, Loader2Icon, Volume2Icon } from "lucide-react";

import {
  CourseVoiceoverEstimate,
  voiceoverService,
} from "../../services/voiceoverService";

/**
 * Shown before dubbing a course that is on Vbee, because that dub spends real
 * credit and the amount is knowable in advance.
 *
 * The number is COUNTED by the API from the same per-card reuse rules the dub
 * itself applies, not averaged from a keypoint count — so "0 ký tự" genuinely
 * means the run would synthesise nothing, and the first run after switching a
 * course over genuinely costs the whole course.
 */

interface Props {
  courseId: string;
  courseTitle: string;
  onCancel: () => void;
  onConfirm: () => void;
}

const formatNumber = (value: number): string =>
  new Intl.NumberFormat("vi-VN").format(value);

export default function VbeeDubConfirmDialog({
  courseId,
  courseTitle,
  onCancel,
  onConfirm,
}: Props) {
  const [estimate, setEstimate] = useState<CourseVoiceoverEstimate | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    voiceoverService
      .estimateCourse(courseId)
      .then((res) => !cancelled && setEstimate(res))
      .catch(
        (err: any) =>
          !cancelled &&
          setError(
            err?.response?.data?.message ||
              err?.message ||
              "Không ước tính được chi phí"
          )
      );
    return () => {
      cancelled = true;
    };
  }, [courseId]);

  // The API refuses a run past this ceiling, so say so here rather than letting
  // the run start and fail card by card.
  const overCap = Boolean(
    estimate?.maxCharsPerRun && estimate.chars > estimate.maxCharsPerRun
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-lg bg-white shadow-xl">
        <header className="border-b border-slate-100 px-5 py-4">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-slate-900">
            <Volume2Icon className="h-4 w-4 text-indigo-600" />
            Dub bằng Vbee — tốn điểm
          </h2>
          <p className="mt-1 truncate text-xs text-slate-500" title={courseTitle}>
            {courseTitle}
          </p>
        </header>

        <div className="px-5 py-4">
          {error ? (
            <p className="text-sm text-red-600">{error}</p>
          ) : !estimate ? (
            <p className="flex items-center gap-2 text-sm text-slate-500">
              <Loader2Icon className="h-4 w-4 animate-spin" /> Đang đếm ký tự…
            </p>
          ) : (
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between">
                <dt className="text-slate-500">Ký tự sẽ tổng hợp</dt>
                <dd className="font-semibold text-slate-900">
                  {formatNumber(estimate.chars)}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-slate-500">Hệ số giọng</dt>
                <dd className="text-slate-700">×{estimate.creditFactor}</dd>
              </div>
              <div className="flex justify-between border-t border-slate-100 pt-2">
                <dt className="font-medium text-slate-700">Điểm dự kiến</dt>
                <dd className="text-base font-bold text-indigo-700">
                  {formatNumber(estimate.estimatedCredits)}
                </dd>
              </div>
              <p className="pt-1 text-xs text-slate-400">
                {estimate.keypoints} keypoint · toàn bộ tiếng Việt của khoá là{" "}
                {formatNumber(estimate.charsIfForced)} ký tự · giọng{" "}
                <span className="font-mono">{estimate.voiceCode}</span>
              </p>

              {estimate.chars === 0 && (
                <p className="rounded-md bg-green-50 px-3 py-2 text-xs text-green-700">
                  Không có gì phải tổng hợp lại — chạy cũng không tốn điểm.
                </p>
              )}

              {overCap && (
                <p className="flex items-start gap-1.5 rounded-md bg-red-50 px-3 py-2 text-xs text-red-700">
                  <AlertTriangleIcon className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                  Vượt hạn mức mỗi lần chạy ({formatNumber(estimate.maxCharsPerRun)}{" "}
                  ký tự). Run sẽ dừng giữa chừng và những thẻ chưa kịp làm vẫn giữ
                  audio cũ. Nâng <span className="font-mono">VBEE_MAX_CHARS_PER_RUN</span>{" "}
                  hoặc dub ít khoá hơn một lượt.
                </p>
              )}
            </dl>
          )}
        </div>

        <footer className="flex justify-end gap-2 border-t border-slate-100 px-5 py-3">
          <button
            type="button"
            onClick={onCancel}
            className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50"
          >
            Huỷ
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={!estimate && !error}
            className="rounded-md bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
          >
            Dub ngay
          </button>
        </footer>
      </div>
    </div>
  );
}
