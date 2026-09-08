import React, { useCallback, useEffect, useState } from "react";
import {
  CheckCircle2Icon,
  DownloadIcon,
  RefreshCwIcon,
  TagIcon,
  Trash2Icon,
  TriangleAlertIcon,
  XIcon,
} from "lucide-react";

import { useNotification } from "../../utils/hooks/useNotification";
import { courseService } from "../../services/courseService";
import {
  courseVersionService,
  CourseVersionList,
} from "../../services/courseVersionService";
import { downloadBlob } from "../../utils/downloadBlob";

interface Props {
  open: boolean;
  onClose: () => void;
  courseId: string;
  courseTitle: string;
}

const ENTITY_LABEL: Record<string, string> = {
  course: "Khoá học",
  roadmap: "Lộ trình",
  lesson: "Bài học",
  keypoint: "Keypoint",
  learningItem: "Nội dung học",
};

/**
 * Phiên bản nội dung của một khoá. Mô hình như đánh tag trong git: sửa nội dung
 * bao nhiêu cũng được, user vẫn đọc tag đang phát hành cho tới khi đánh tag
 * mới; rollback = trỏ current về tag cũ (một lần ghi, không viết lại nội dung).
 *
 * Banner "chưa phát hành" không phải trang trí: một tag chụp CẢ CÂY nội dung,
 * nên nếu không thấy danh sách này thì đánh tag để lấy audio mới sẽ phát hành
 * luôn mấy chỗ sửa chữ còn dở.
 *
 * Xem `meup-api/plans/260907-course-content-versions/README.md`.
 */
const CourseVersionsModal: React.FC<Props> = ({
  open,
  onClose,
  courseId,
  courseTitle,
}) => {
  const { showSuccess, showError } = useNotification();
  const [data, setData] = useState<CourseVersionList | null>(null);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [tag, setTag] = useState("");
  const [note, setNote] = useState("");
  const [setCurrent, setSetCurrent] = useState(true);

  const load = useCallback(async () => {
    if (!courseId) return;
    setLoading(true);
    try {
      const result = await courseVersionService.list(courseId);
      setData(result);
      // `?? ""` không phải trang trí: `tag` undefined làm `tag.trim()` dưới
      // đây nổ ngay trong render, React unmount cả cây và TRẮNG toàn bộ trang
      // admin. Xem test "survives a payload with no nextTag".
      setTag(result?.nextTag ?? "");
    } catch (error: any) {
      showError(error?.response?.data?.message || "Không tải được danh sách phiên bản");
    } finally {
      setLoading(false);
    }
  }, [courseId, showError]);

  useEffect(() => {
    if (open) load();
  }, [open, load]);

  const runBusy = async (job: () => Promise<void>) => {
    setBusy(true);
    try {
      await job();
      await load();
    } catch (error: any) {
      showError(error?.response?.data?.message || "Thao tác thất bại");
    } finally {
      setBusy(false);
    }
  };

  const createTag = () =>
    runBusy(async () => {
      const wanted = (tag ?? "").trim();
      await courseVersionService.create(courseId, {
        tag: wanted,
        note: note.trim() || undefined,
        setCurrent,
      });
      setNote("");
      showSuccess(
        setCurrent
          ? `Đã phát hành ${wanted}`
          : `Đã đóng gói ${wanted} (chưa phát hành)`
      );
    });

  const publish = (target: string) =>
    runBusy(async () => {
      await courseVersionService.setCurrent(courseId, target);
      showSuccess(`Đang phát hành ${target}`);
    });

  const remove = (target: string) =>
    runBusy(async () => {
      await courseVersionService.remove(courseId, target);
      showSuccess(`Đã xoá ${target}`);
    });

  const exportTag = async (target: string) => {
    try {
      const res = await courseService.exportCourseFull(courseId, target);
      downloadBlob(res.data, `course-${courseId}-${target}.xlsx`);
    } catch {
      showError("Xuất workbook của tag thất bại");
    }
  };

  if (!open) return null;

  const pending = data?.pending;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 p-4">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between border-b px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold flex items-center gap-2">
              <TagIcon className="h-5 w-5 text-indigo-600" />
              Phiên bản nội dung
            </h2>
            <p className="text-sm text-gray-500 truncate max-w-lg">{courseTitle}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={load}
              disabled={loading || busy}
              className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50 disabled:opacity-60"
            >
              <RefreshCwIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
              Tải lại
            </button>
            <button
              onClick={onClose}
              className="rounded-lg p-2 text-gray-500 transition hover:bg-gray-100"
            >
              <XIcon className="h-5 w-5" />
            </button>
          </div>
        </div>

        <div className="px-6 py-5 space-y-5">
          {/* Chưa phát hành */}
          {pending &&
            (pending.total > 0 ? (
              <div className="rounded-lg border border-amber-300 bg-amber-50 p-4">
                <div className="flex items-center gap-2 font-medium text-amber-800">
                  <TriangleAlertIcon className="h-4 w-4" />
                  {pending.total} thay đổi chưa phát hành
                </div>
                <p className="mt-1 text-sm text-amber-700">
                  User vẫn đang đọc {data?.currentTag ?? "bản đang sửa"}. Một tag
                  chụp cả cây nội dung — kiểm danh sách dưới đây trước khi đánh
                  tag, kẻo phát hành luôn phần còn dở.
                </p>
                <ul className="mt-2 space-y-0.5 text-sm text-amber-900">
                  {[
                    ...(pending.changed ?? []).map((ref) => ({ ref, kind: "sửa" })),
                    ...(pending.added ?? []).map((ref) => ({ ref, kind: "thêm" })),
                    ...(pending.removed ?? []).map((ref) => ({ ref, kind: "xoá" })),
                  ]
                    .slice(0, 12)
                    .map(({ ref, kind }) => (
                      <li key={`${ref.entityType}:${ref.entityId}:${kind}`}>
                        <span className="font-medium">{kind}</span>{" "}
                        {ENTITY_LABEL[ref.entityType] ?? ref.entityType}{" "}
                        <code className="text-xs">{ref.entityId}</code>
                      </li>
                    ))}
                  {pending.total > 12 && <li>… và {pending.total - 12} thay đổi nữa</li>}
                </ul>
              </div>
            ) : (
              <div className="flex items-center gap-2 rounded-lg border border-green-300 bg-green-50 p-4 text-sm text-green-800">
                <CheckCircle2Icon className="h-4 w-4" />
                Bản đang sửa trùng khớp với {data?.currentTag ?? "—"} — không có gì
                chờ phát hành.
              </div>
            ))}

          {/* Đánh tag mới */}
          <div className="rounded-lg border border-gray-200 p-4">
            <div className="mb-3 font-medium">Đánh tag mới</div>
            <div className="flex flex-wrap items-end gap-3">
              <label className="flex flex-col text-sm">
                <span className="mb-1 text-gray-600">Tag</span>
                <input
                  value={tag}
                  onChange={(event) => setTag(event.target.value)}
                  placeholder="v1.0.1"
                  className="w-32 rounded-lg border border-gray-300 px-3 py-2"
                />
              </label>
              <label className="flex flex-1 flex-col text-sm">
                <span className="mb-1 text-gray-600">Ghi chú</span>
                <input
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                  placeholder="Sửa lại phần ghi chú bài 2"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2"
                />
              </label>
              <label className="flex items-center gap-2 pb-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  checked={setCurrent}
                  onChange={(event) => setSetCurrent(event.target.checked)}
                />
                Phát hành ngay
              </label>
              <button
                onClick={createTag}
                disabled={busy || !(tag ?? "").trim()}
                className="rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:from-blue-700 hover:to-indigo-700 disabled:opacity-60"
              >
                Đánh tag
              </button>
            </div>
          </div>

          {/* Lịch sử */}
          <div className="overflow-x-auto rounded-lg border border-gray-200">
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50 text-left text-gray-600">
                <tr>
                  <th className="px-4 py-2">Tag</th>
                  <th className="px-4 py-2">Ghi chú</th>
                  <th className="px-4 py-2">Nội dung</th>
                  <th className="px-4 py-2">Người đánh</th>
                  <th className="px-4 py-2" />
                </tr>
              </thead>
              <tbody>
                {(data?.versions ?? []).map((version) => (
                  <tr key={version._id} className="border-t">
                    <td className="whitespace-nowrap px-4 py-2 font-medium">
                      {version.tag}
                      {version.isCurrent && (
                        <span className="ml-2 rounded bg-green-100 px-2 py-0.5 text-xs text-green-700">
                          đang phát hành
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-2 text-gray-600">{version.note || "—"}</td>
                    <td className="whitespace-nowrap px-4 py-2 text-gray-600">
                      {version.entityCounts?.lessons ?? 0} bài ·{" "}
                      {version.entityCounts?.keypoints ?? 0} kp ·{" "}
                      {version.entityCounts?.learningItems ?? 0} nội dung
                    </td>
                    <td className="whitespace-nowrap px-4 py-2 text-gray-600">
                      {version.createdBy?.email ?? "hệ thống"}
                      {version.createdAt && (
                        <span className="block text-xs text-gray-400">
                          {new Date(version.createdAt).toLocaleString()}
                        </span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-4 py-2">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => exportTag(version.tag)}
                          title="Xuất workbook của tag này (import lại = khôi phục)"
                          className="rounded-lg border border-gray-300 p-2 text-gray-600 transition hover:bg-gray-50"
                        >
                          <DownloadIcon className="h-4 w-4" />
                        </button>
                        {!version.isCurrent && (
                          <>
                            <button
                              onClick={() => publish(version.tag)}
                              disabled={busy}
                              className="rounded-lg border border-indigo-500 px-3 py-2 text-xs font-medium text-indigo-600 transition hover:bg-indigo-50 disabled:opacity-60"
                            >
                              Đặt làm current
                            </button>
                            <button
                              onClick={() => remove(version.tag)}
                              disabled={busy}
                              title="Xoá tag và nội dung đã đóng băng của nó"
                              className="rounded-lg border border-red-300 p-2 text-red-600 transition hover:bg-red-50 disabled:opacity-60"
                            >
                              <Trash2Icon className="h-4 w-4" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {!loading && !(data?.versions ?? []).length && (
                  <tr>
                    <td colSpan={5} className="px-4 py-6 text-center text-gray-500">
                      Khoá này chưa có tag nào — user đang đọc bản đang sửa, y như
                      trước khi có tính năng phiên bản.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CourseVersionsModal;
