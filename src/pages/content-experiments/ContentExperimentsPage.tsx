import React, { useCallback, useEffect, useState } from "react";
import {
  BeakerIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";

import {
  contentExperimentService,
  ContentExperiment,
  ContentExperimentStats,
  ExperimentArm,
} from "../../services/contentExperimentService";
import { courseService } from "../../services/courseService";
import { courseVersionService } from "../../services/courseVersionService";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";
import { RootState } from "../../store";

interface CourseOption {
  _id: string;
  title: string;
}

const ARM_LABEL: Record<"A" | "B", string> = { A: "Nhánh A", B: "Nhánh B" };

/**
 * Cần bao nhiêu người mỗi nhánh. Xấp xỉ tiêu chuẩn n ≈ 16·p(1-p)/δ² (80% power,
 * 95% tin cậy) — KHÔNG phải con số 5.000 của paywall: phễu ở đây là hoàn thành
 * keypoint với tỉ lệ hàng chục %, không phải chuyển đổi mua 3%.
 */
const sampleNeeded = (baseRate: number, lift: number) =>
  Math.ceil((16 * baseRate * (1 - baseRate)) / (lift * lift));

const ContentExperimentsPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [runs, setRuns] = useState<ContentExperiment[]>([]);
  const [courses, setCourses] = useState<CourseOption[]>([]);
  const [tagsByCourse, setTagsByCourse] = useState<Record<string, string[]>>({});
  const [busy, setBusy] = useState(false);

  const [key, setKey] = useState("");
  const [percentB, setPercentB] = useState(50);
  const [note, setNote] = useState("");
  const [arms, setArms] = useState<ExperimentArm[]>([
    { courseId: "", tagA: "", tagB: "" },
  ]);

  const [statsKey, setStatsKey] = useState<string | null>(null);
  const [env, setEnv] = useState("dev");
  const [stats, setStats] = useState<ContentExperimentStats | null>(null);
  const [statsLoading, setStatsLoading] = useState(false);

  const load = useCallback(async () => {
    try {
      const [list, courseRes] = await Promise.all([
        contentExperimentService.list(),
        courseService.getList({ page: 1, take: 200, isAll: true } as any),
      ]);
      setRuns(list ?? []);
      setCourses(
        ((courseRes as any)?.data?.items ?? []).map((course: any) => ({
          _id: course._id,
          title: getTranslationValue(course.title, lang) || course._id,
        }))
      );
    } catch (error: any) {
      showError(error?.response?.data?.message || "Không tải được danh sách đợt");
    }
  }, [lang, showError]);

  useEffect(() => {
    load();
  }, [load]);

  /** Tag của một khoá, tải khi người dùng chọn khoá đó. */
  const loadTags = async (courseId: string) => {
    if (!courseId || tagsByCourse[courseId]) return;
    try {
      const res = await courseVersionService.list(courseId);
      setTagsByCourse(prev => ({
        ...prev,
        [courseId]: (res?.versions ?? []).map(version => version.tag),
      }));
    } catch {
      setTagsByCourse(prev => ({ ...prev, [courseId]: [] }));
    }
  };

  const setArm = (index: number, patch: Partial<ExperimentArm>) =>
    setArms(prev => prev.map((arm, i) => (i === index ? { ...arm, ...patch } : arm)));

  const create = async () => {
    setBusy(true);
    try {
      await contentExperimentService.create({
        key: key.trim(),
        percentB,
        startedAt: new Date().toISOString(),
        arms: arms.filter(arm => arm.courseId && arm.tagA && arm.tagB),
        note: note.trim() || undefined,
      });
      showSuccess(`Đã tạo đợt ${key.trim()} — đang TẮT, bật khi app đã lên`);
      setKey("");
      setNote("");
      setArms([{ courseId: "", tagA: "", tagB: "" }]);
      await load();
    } catch (error: any) {
      showError(error?.response?.data?.message || "Tạo đợt thất bại");
    } finally {
      setBusy(false);
    }
  };

  const toggle = async (run: ContentExperiment) => {
    setBusy(true);
    try {
      await contentExperimentService.setEnabled(run._id, !run.enabled);
      showSuccess(run.enabled ? `Đã tắt ${run.key}` : `Đã bật ${run.key}`);
      await load();
    } catch (error: any) {
      showError(error?.response?.data?.message || "Không đổi được trạng thái");
    } finally {
      setBusy(false);
    }
  };

  const loadStats = async (runKey: string) => {
    setStatsKey(runKey);
    setStatsLoading(true);
    try {
      setStats(await contentExperimentService.stats(runKey, env));
    } catch (error: any) {
      setStats(null);
      showError(error?.response?.data?.message || "Không tải được kết quả");
    } finally {
      setStatsLoading(false);
    }
  };

  const canCreate =
    !!key.trim() && arms.some(arm => arm.courseId && arm.tagA && arm.tagB);

  return (
    <div className="flex flex-col gap-5 p-6">
      <div>
        <h1 className="flex items-center gap-2 text-xl font-semibold">
          <BeakerIcon className="h-6 w-6 text-indigo-600" />
          A/B test nội dung khoá học
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Hai tag của cùng một khoá làm hai nhánh. Server chia theo hash của user
          id nên một người luôn ở nguyên một nhánh, và ở cùng nhánh đó xuyên mọi
          khoá trong đợt.
        </p>
      </div>

      {/* Điều kiện tiên quyết, không phải trang trí: bật đợt trước khi app biết
          đóng dấu nhánh là phục vụ hai bản khác nhau mà không đo được gì. */}
      <div className="flex gap-2 rounded-lg border border-amber-300 bg-amber-50 p-4 text-sm text-amber-800">
        <ExclamationTriangleIcon className="h-5 w-5 shrink-0" />
        <div>
          <div className="font-medium">
            Chỉ bật đợt sau khi bản app biết đóng dấu nhánh đã lên
          </div>
          Phễu đếm từ event của app. App chưa gửi{" "}
          <code className="text-xs">content_variant</code> thì bảng kết quả toàn
          số 0 — và trông y như "hai bản không khác gì nhau".
        </div>
      </div>

      {/* Tạo đợt */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <div className="mb-4 font-medium">Đợt mới</div>

        <div className="flex flex-wrap items-end gap-4">
          <label className="flex flex-col text-sm">
            <span className="mb-1 text-slate-600">Mã đợt test (key)</span>
            <input
              value={key}
              onChange={event => setKey(event.target.value)}
              placeholder="noidung_2026_09"
              className="w-56 rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="flex flex-1 flex-col text-sm">
            <span className="mb-1 text-slate-600">Tỷ lệ vào nhánh B</span>
            <div className="flex items-center gap-3">
              <input
                type="range"
                min={0}
                max={100}
                value={percentB}
                onChange={event => setPercentB(Number(event.target.value))}
                className="flex-1"
              />
              <span className="w-16 rounded-lg border border-slate-300 px-2 py-1 text-center">
                {percentB}%
              </span>
            </div>
          </label>

          <label className="flex flex-1 flex-col text-sm">
            <span className="mb-1 text-slate-600">Ghi chú</span>
            <input
              value={note}
              onChange={event => setNote(event.target.value)}
              placeholder="Thử lối viết ngắn hơn"
              className="w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>
        </div>

        <p className="mt-2 text-xs text-slate-500">
          Đợt mới phải đổi key. Dùng lại key cũ là trả mọi người về đúng nhánh họ
          từng ở, biến đợt mới thành phần tiếp của đợt cũ.
        </p>

        <div className="mt-4 flex flex-col gap-2">
          {arms.map((arm, index) => (
            <div key={index} className="flex flex-wrap items-center gap-2">
              <select
                value={arm.courseId}
                onChange={event => {
                  setArm(index, {
                    courseId: event.target.value,
                    tagA: "",
                    tagB: "",
                  });
                  loadTags(event.target.value);
                }}
                className="min-w-[16rem] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm"
              >
                <option value="">— chọn khoá —</option>
                {courses.map(course => (
                  <option key={course._id} value={course._id}>
                    {course.title}
                  </option>
                ))}
              </select>

              {(["tagA", "tagB"] as const).map(field => (
                <select
                  key={field}
                  value={arm[field]}
                  onChange={event => setArm(index, { [field]: event.target.value })}
                  disabled={!arm.courseId}
                  className="w-40 rounded-lg border border-slate-300 px-3 py-2 text-sm disabled:bg-slate-50"
                >
                  <option value="">
                    {field === "tagA" ? "— nhánh A —" : "— nhánh B —"}
                  </option>
                  {(tagsByCourse[arm.courseId] ?? []).map(tag => (
                    <option key={tag} value={tag}>
                      {tag}
                    </option>
                  ))}
                </select>
              ))}

              {arms.length > 1 && (
                <button
                  onClick={() => setArms(prev => prev.filter((_, i) => i !== index))}
                  className="rounded-lg border border-slate-300 p-2 text-slate-500 hover:bg-slate-50"
                >
                  <TrashIcon className="h-4 w-4" />
                </button>
              )}
            </div>
          ))}

          <button
            onClick={() =>
              setArms(prev => [...prev, { courseId: "", tagA: "", tagB: "" }])
            }
            className="inline-flex w-fit items-center gap-1 text-sm text-indigo-600 hover:underline"
          >
            <PlusIcon className="h-4 w-4" />
            Thêm khoá vào đợt
          </button>
        </div>

        <button
          onClick={create}
          disabled={busy || !canCreate}
          className="mt-4 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
        >
          Tạo đợt (đang tắt)
        </button>
      </div>

      {/* Danh sách đợt */}
      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-50 text-left text-slate-600">
            <tr>
              <th className="px-4 py-2">Đợt</th>
              <th className="px-4 py-2">Chia</th>
              <th className="px-4 py-2">Khoá</th>
              <th className="px-4 py-2">Mở từ</th>
              <th className="px-4 py-2" />
            </tr>
          </thead>
          <tbody>
            {runs.map(run => (
              <tr key={run._id} className="border-t border-slate-100">
                <td className="px-4 py-2">
                  <span className="font-medium">{run.key}</span>
                  <span
                    className={`ml-2 rounded px-2 py-0.5 text-xs ${
                      run.enabled
                        ? "bg-green-100 text-green-700"
                        : "bg-slate-100 text-slate-600"
                    }`}
                  >
                    {run.enabled ? "đang chạy" : "đang tắt"}
                  </span>
                  {run.note && (
                    <div className="text-xs text-slate-500">{run.note}</div>
                  )}
                </td>
                <td className="whitespace-nowrap px-4 py-2 text-slate-600">
                  {run.percentB}% vào B
                </td>
                <td className="px-4 py-2 text-slate-600">
                  {(run.arms ?? []).length} khoá
                  <div className="text-xs text-slate-400">
                    {(run.arms ?? [])
                      .map(arm => `${arm.tagA} ↔ ${arm.tagB}`)
                      .join(" · ")}
                  </div>
                </td>
                <td className="whitespace-nowrap px-4 py-2 text-slate-600">
                  {new Date(run.startedAt).toLocaleDateString("vi-VN")}
                </td>
                <td className="whitespace-nowrap px-4 py-2 text-right">
                  <button
                    onClick={() => toggle(run)}
                    disabled={busy}
                    className="rounded-lg border border-indigo-500 px-3 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50 disabled:opacity-60"
                  >
                    {run.enabled ? "Tắt" : "Bật"}
                  </button>
                  <button
                    onClick={() => loadStats(run.key)}
                    className="ml-2 rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-medium text-white"
                  >
                    Kết quả
                  </button>
                </td>
              </tr>
            ))}
            {!runs.length && (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-slate-500">
                  Chưa có đợt nào.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Kết quả */}
      {statsKey && (
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2 font-medium">
              <ChartBarIcon className="h-5 w-5 text-teal-600" />
              Kết quả đợt {statsKey}
            </div>
            <div className="flex items-center gap-2">
              <select
                value={env}
                onChange={event => setEnv(event.target.value)}
                className="rounded-lg border border-slate-200 px-2 py-1 text-xs"
              >
                <option value="dev">dev</option>
                <option value="stg">stg</option>
                <option value="prod">prod</option>
              </select>
              <button
                onClick={() => loadStats(statsKey)}
                disabled={statsLoading}
                className="rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-medium text-white disabled:bg-slate-300"
              >
                {statsLoading ? "Đang tải…" : "Tải kết quả"}
              </button>
            </div>
          </div>

          <p className="mb-2 text-xs text-slate-500">
            Phễu đếm theo NGƯỜI từ event của app, lọc theo mã đợt nên hai đợt
            trùng khoảng thời gian không bị trộn.
          </p>

          {stats && (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead className="text-left text-slate-500">
                    <tr>
                      <th className="py-1.5 pr-3 font-medium">Nhánh</th>
                      <th className="py-1.5 pr-3 font-medium">Người thấy khoá</th>
                      <th className="py-1.5 pr-3 font-medium">Mở keypoint</th>
                      <th className="py-1.5 pr-3 font-medium">Đọc nội dung</th>
                      <th className="py-1.5 pr-3 font-medium">Hoàn thành</th>
                      <th className="py-1.5 pr-3 font-medium">Tỉ lệ</th>
                      <th className="py-1.5 pr-3 font-medium">Bỏ qua</th>
                      <th className="py-1.5 pr-3 font-medium">Bỏ giữa</th>
                      <th className="py-1.5 pr-3 font-medium">Báo lỗi</th>
                    </tr>
                  </thead>
                  <tbody className="text-slate-700">
                    {stats.arms.map(arm => (
                      <tr key={arm.arm} className="border-t border-slate-100">
                        <td className="py-1.5 pr-3 font-medium">
                          {ARM_LABEL[arm.arm]}
                        </td>
                        <td className="py-1.5 pr-3">{arm.viewers}</td>
                        <td className="py-1.5 pr-3">{arm.keypointStarts}</td>
                        <td className="py-1.5 pr-3">{arm.keypointReads}</td>
                        <td className="py-1.5 pr-3">{arm.completes}</td>
                        <td className="py-1.5 pr-3">{arm.completionRate}%</td>
                        <td className="py-1.5 pr-3">{arm.skips}</td>
                        <td className="py-1.5 pr-3">{arm.exits}</td>
                        <td className="py-1.5 pr-3">{arm.reports}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <p className="mt-3 text-xs text-slate-500">
                Chênh lệch nhỏ phần lớn là nhiễu. Với tỉ lệ hoàn thành quanh 50%,
                cần cỡ <b>{sampleNeeded(0.5, 0.05).toLocaleString("vi-VN")}</b>{" "}
                người mỗi nhánh mới phân biệt được 50% với 55%, và cỡ{" "}
                <b>{sampleNeeded(0.5, 0.03).toLocaleString("vi-VN")}</b> nếu muốn
                thấy chênh 3 điểm. Ít hơn số đó thì đừng kết luận.
              </p>

              <p className="mt-1 text-xs text-slate-500">
                Ba cột cuối là tín hiệu âm. Một nhánh hoàn thành cao mà bỏ qua
                cũng cao thì nó đang dễ hơn, chứ chưa hẳn dạy tốt hơn.
              </p>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default ContentExperimentsPage;
