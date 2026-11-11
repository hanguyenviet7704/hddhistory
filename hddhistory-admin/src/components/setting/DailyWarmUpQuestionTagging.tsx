import { useState } from "react";
import { dailyWarmUpTaggingService } from "../../services/dailyWarmUpTaggingService";
import { DailyWarmUpTaggingResult } from "../../types/interface/learning-item/daily-warm-up-tagging.interface";
import { useNotification } from "../../utils/hooks/useNotification";

const DailyWarmUpQuestionTagging = () => {
  const { showSuccess, showError } = useNotification();

  const [previewing, setPreviewing] = useState(false);
  const [applying, setApplying] = useState(false);
  const [preview, setPreview] = useState<DailyWarmUpTaggingResult | null>(null);

  const hasChanges =
    !!preview &&
    (preview.questionsToTickOn > 0 || preview.questionsToTickOff > 0);

  const handlePreview = async () => {
    try {
      setPreviewing(true);
      const res = await dailyWarmUpTaggingService.preview();
      setPreview(res);
    } catch (err) {
      console.error("Failed to preview daily warm-up tagging", err);
      showError("Xem trước gắn cờ warm-up thất bại");
    } finally {
      setPreviewing(false);
    }
  };

  const handleApply = async () => {
    try {
      setApplying(true);
      const res = await dailyWarmUpTaggingService.apply();
      showSuccess(
        `Áp dụng thành công: tick thêm ${res.questionsToTickOn} câu, bỏ tick ${res.questionsToTickOff} câu, trên ${res.foldersChanged} folder (${res.lessonsScanned} lesson đã quét).`,
      );
      // Reset so a stale preview can't be re-confirmed without previewing again.
      setPreview(null);
    } catch (err) {
      console.error("Failed to apply daily warm-up tagging", err);
      showError("Áp dụng gắn cờ warm-up thất bại");
    } finally {
      setApplying(false);
    }
  };

  return (
    <div className="max-w-2xl">
      <div className="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <div>
          <h2 className="mb-1 text-lg font-medium text-gray-900">
            Gắn cờ câu hỏi Daily Warm-up
          </h2>
          <p className="text-sm text-gray-500">
            Tự động đồng bộ cờ <code>isDailyWarmUp</code> cho câu hỏi bài tập
            trên toàn bộ hệ thống. Với mỗi lesson: chọn folder bài tập cuối cùng
            (theo thứ tự keypoint rồi index) và tick toàn bộ câu hỏi trong đó,
            bỏ tick các folder còn lại. Chạy được nhiều lần, an toàn bất cứ lúc
            nào.
          </p>
        </div>

        {preview && (
          <div
            role="status"
            aria-live="polite"
            className="rounded-md border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700"
          >
            {hasChanges ? (
              <>
                Sẽ tick thêm{" "}
                <span className="font-semibold text-gray-900">
                  {preview.questionsToTickOn}
                </span>{" "}
                câu, bỏ tick{" "}
                <span className="font-semibold text-gray-900">
                  {preview.questionsToTickOff}
                </span>{" "}
                câu, trên{" "}
                <span className="font-semibold text-gray-900">
                  {preview.foldersChanged}
                </span>{" "}
                folder ({preview.lessonsScanned} lesson đã quét).
              </>
            ) : (
              <>
                Không có thay đổi nào — dữ liệu đã khớp quy tắc (
                {preview.lessonsScanned} lesson đã quét).
              </>
            )}
          </div>
        )}

        <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={handlePreview}
            disabled={previewing || applying}
            className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-5 py-2.5 text-sm font-semibold text-gray-700 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {previewing ? (
              <>
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-gray-400 border-t-transparent" />
                Đang xem trước...
              </>
            ) : (
              "Xem trước"
            )}
          </button>

          <button
            type="button"
            onClick={handleApply}
            disabled={!hasChanges || applying || previewing}
            className="inline-flex items-center gap-2 rounded-lg bg-bronze-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-bronze-700 disabled:cursor-not-allowed disabled:bg-bronze-300"
          >
            {applying ? (
              <>
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                Đang áp dụng...
              </>
            ) : (
              "Xác nhận áp dụng"
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default DailyWarmUpQuestionTagging;
