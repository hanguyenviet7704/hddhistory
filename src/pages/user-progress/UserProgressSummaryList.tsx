import React, { useCallback, useEffect, useState } from "react";
import { Pagination, Tooltip } from "@mui/material";
import {
  ArrowPathIcon,
  DocumentDuplicateIcon,
  EyeIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { LangCode } from "../../types/enum/common.enum";
import { LessonType } from "../../types/enum/lesson.enum";
import { GradeResultType } from "../../types/enum/user-progress.enum";
import { userProgressService } from "../../services/userProgressService";
import { userFeedbackService } from "../../services/userFeedbackService";
import {
  ICompletedLevel,
  ICourseProgressSummary,
  IStopAtDetail,
} from "../../types/interface/user-progress.interface";
import {
  IUserFeedback,
  IUserFeedbackComplete,
  IUserFeedbackIncomplete,
} from "../../types/interface/user-feedback.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const DEFAULT_PAGE_SIZE = 20;

const formatDate = (value?: string | Date) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

const normalizeList = (payload: any): ICourseProgressSummary[] => {
  const parsed = payload?.data?.data ?? payload?.data ?? payload ?? {};
  if (Array.isArray(parsed)) return parsed;

  const list =
    parsed.items ??
    parsed.list ??
    parsed.data?.items ??
    parsed.data?.list ??
    parsed.data ??
    [];
  return Array.isArray(list) ? list : [];
};

const resolvePagination = (
  payload: any,
  fallbackLength: number,
  pageNumber: number,
  take: number
) => {
  const parsed = payload?.data?.data ?? payload?.data ?? payload ?? {};
  const totalPages =
    parsed.totalPages ??
    parsed.pagination?.totalPages ??
    parsed.pagination?.total ??
    parsed.data?.totalPages;
  const totalItems =
    parsed.total ??
    parsed.pagination?.totalItems ??
    parsed.data?.total ??
    parsed.data?.totalItems;
  const itemsPerPage =
    parsed.itemsPerPage ??
    parsed.take ??
    parsed.pagination?.take ??
    parsed.data?.take ??
    take;
  const computedTotal =
    totalPages ||
    (totalItems ? Math.ceil(totalItems / itemsPerPage) : undefined) ||
    (itemsPerPage ? Math.ceil(fallbackLength / itemsPerPage) : 1);
  const currentPage =
    parsed.currentPage ??
    parsed.page ??
    parsed.pagination?.page ??
    parsed.data?.page ??
    pageNumber;
  return {
    totalPages: Number(computedTotal) || 1,
    currentPage: Number(currentPage) || pageNumber,
  };
};

const getCourseId = (summary: ICourseProgressSummary | any) =>
  summary?.courseId || summary?.id || summary?._id || "";

const lessonTypeStyles: Record<string, string> = {
  [LessonType.LESSON]: "bg-blue-100 text-blue-700",
  [LessonType.ROLEPLAY]: "bg-amber-100 text-amber-700",
  [LessonType.OUTPUT]: "bg-emerald-100 text-emerald-700",
};

const getStopAtLabel = (stopAt: IStopAtDetail | undefined, lang: LangCode) => {
  if (!stopAt) return "-";
  const lessonTitle = getTranslationValue(stopAt.lessonTitle, lang);
  const keypointTitle = getTranslationValue(stopAt.keypointTitle, lang);
  const parts = [
    stopAt.lessonType,
    lessonTitle || undefined,
    keypointTitle || undefined,
  ].filter(Boolean);
  return parts.length ? parts.join(" - ") : "-";
};

const renderStars = (value?: number) => {
  if (value === undefined || value === null) return "-";
  const safe = Math.max(0, Math.min(5, Math.round(value)));
  return "★".repeat(safe) + "☆".repeat(5 - safe);
};

const CompletedLevelsCell = ({ levels }: { levels?: ICompletedLevel[] }) => {
  const completedLevels = Array.isArray(levels) ? levels : [];
  if (completedLevels.length === 0) {
    return <span className="text-gray-400">-</span>;
  }

  return (
    <div className="flex min-w-[280px] flex-col gap-2">
      {completedLevels.map((completedLevel, index) => {
        const request = completedLevel.additionalContentRequest;
        return (
          <div
            key={`${completedLevel.level}-${index}`}
            className="rounded-lg border border-gray-100 bg-gray-50 p-2"
          >
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold uppercase text-emerald-700">
                {completedLevel.level}
              </span>
              {request ? (
                <span
                  className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase ${
                    request.requested
                      ? "bg-blue-100 text-blue-700"
                      : "bg-gray-100 text-gray-600"
                  }`}
                >
                  {request.requested ? "Requested" : "Not requested"}
                </span>
              ) : (
                <span className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-semibold uppercase text-gray-500">
                  No request
                </span>
              )}
            </div>
            <div className="mt-2 text-xs text-gray-600">
              {request ? (
                <div className="space-y-1">
                  {request.requestText ? (
                    <Tooltip
                      title={
                        <span className="whitespace-pre-wrap">
                          {request.requestText}
                        </span>
                      }
                      arrow
                      placement="top"
                    >
                      <div
                        className="max-w-[300px] cursor-help truncate text-gray-700"
                        tabIndex={0}
                      >
                        {request.requestText}
                      </div>
                    </Tooltip>
                  ) : null}
                  <div className="text-gray-500">
                    Submitted: {formatDate(request.submittedAt)}
                  </div>
                </div>
              ) : (
                <span className="text-gray-400">-</span>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
};

const renderFeedbackDetail = (
  label: string,
  lang: LangCode,
  feedback?: IUserFeedbackComplete | IUserFeedbackIncomplete,
  type: "complete" | "incomplete" = "complete"
) => {
  if (!feedback) return null;
  const lessonTitle = getTranslationValue(feedback.lessonTitle, lang);
  const keypointTitle = getTranslationValue(feedback.keypointTitle, lang);
  const isComplete = type === "complete";
  const complete = feedback as IUserFeedbackComplete;
  const incomplete = feedback as IUserFeedbackIncomplete;

  return (
    <div className="border border-gray-100 rounded-lg p-3 bg-gray-50/60">
      <div className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-2">
        {label}
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 text-xs text-gray-700">
        <div className="flex items-start gap-2">
          <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
            Course
          </span>
          <span className="font-medium text-gray-900">
            {getTranslationValue(feedback.courseTitle, lang) ||
              feedback.courseId ||
              "-"}
          </span>
        </div>
        <div className="flex items-start gap-2">
          <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
            Lesson
          </span>
          <span className="font-medium text-gray-900">
            {lessonTitle || feedback.lessonId || "-"}
          </span>
        </div>
        <div className="flex items-start gap-2">
          <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
            Keypoint
          </span>
          <span className="font-medium text-gray-900">
            {keypointTitle || feedback.keypointId || "-"}
          </span>
        </div>
        <div className="flex items-start gap-2">
          <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
            Submitted
          </span>
          <span className="font-medium text-gray-900">
            {formatDate(feedback.submittedAt)}
          </span>
        </div>
        {isComplete ? (
          <>
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-700 text-[10px] font-semibold uppercase tracking-wide">
                Overall
              </span>
              <span className="font-medium text-gray-900">
                {renderStars(complete.overallRating)}
              </span>
              <span className="text-gray-400">
                ({complete.overallRating ?? "-"})
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-700 text-[10px] font-semibold uppercase tracking-wide">
                Content
              </span>
              <span className="font-medium text-gray-900">
                {renderStars(complete.contentRating)}
              </span>
              <span className="text-gray-400">
                ({complete.contentRating ?? "-"})
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-700 text-[10px] font-semibold uppercase tracking-wide">
                Experience
              </span>
              <span className="font-medium text-gray-900">
                {renderStars(complete.experienceRating)}
              </span>
              <span className="text-gray-400">
                ({complete.experienceRating ?? "-"})
              </span>
            </div>
            <div className="flex items-start gap-2 md:col-span-2">
              <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
                Comment
              </span>
              <span className="font-medium text-gray-900">
                {complete.comment || "-"}
              </span>
            </div>
          </>
        ) : (
          <>
            <div className="flex items-start gap-2 md:col-span-2">
              <span className="px-2 py-0.5 rounded-full bg-rose-100 text-rose-700 text-[10px] font-semibold uppercase tracking-wide">
                Reasons
              </span>
              <span className="font-medium text-gray-900">
                {incomplete.reasons?.length
                  ? incomplete.reasons.join(", ")
                  : "-"}
              </span>
            </div>
            <div className="flex items-start gap-2 md:col-span-2">
              <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wide">
                Comment
              </span>
              <span className="font-medium text-gray-900">
                {incomplete.comment || "-"}
              </span>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default function UserProgressSummaryList() {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError, showSuccess } = useNotification();
  const stateUserLabel =
    (location.state as { userLabel?: string } | null)?.userLabel ?? "";

  const [items, setItems] = useState<ICourseProgressSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [feedbackLoading, setFeedbackLoading] = useState(false);
  const [feedbackList, setFeedbackList] = useState<IUserFeedback[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [confirmCourseId, setConfirmCourseId] = useState<string | null>(null);
  const [removing, setRemoving] = useState(false);
  const [confirmFeedbackRemove, setConfirmFeedbackRemove] = useState(false);
  const [removingFeedback, setRemovingFeedback] = useState(false);
  const userLabel = stateUserLabel;

  const fetchProgress = useCallback(
    async (pageNumber: number) => {
      if (!userId) {
        setItems([]);
        setTotalPages(1);
        return;
      }
      setLoading(true);
      try {
        const res = await userProgressService.getProgressOfUser(userId, {
          page: pageNumber,
          take: DEFAULT_PAGE_SIZE,
        });
        const list = normalizeList(res);
        const pagination = resolvePagination(
          res,
          list.length,
          pageNumber,
          DEFAULT_PAGE_SIZE
        );
        setItems(list);
        setPage(pagination.currentPage);
        setTotalPages(pagination.totalPages);
      } catch (error) {
        console.error("Failed to fetch progress summary", error);
        showError("Không tải được tiến độ học tập");
      } finally {
        setLoading(false);
      }
    },
    [showError, userId]
  );

  const fetchFeedback = useCallback(async () => {
    if (!userId) {
      setFeedbackList([]);
      return;
    }
    setFeedbackLoading(true);
    try {
      const res = await userFeedbackService.getByUserId(userId);
      const payload = (res as any)?.data ?? res;
      const list = Array.isArray(payload) ? payload : payload ? [payload] : [];
      setFeedbackList(list);
    } catch (error) {
      console.error("Failed to fetch user feedback", error);
      showError("Không tải được feedback");
      setFeedbackList([]);
    } finally {
      setFeedbackLoading(false);
    }
  }, [showError, userId]);

  const feedbackByCourse = React.useMemo(() => {
    const map = new Map<string, IUserFeedback>();
    const upsert = (
      courseId: string | undefined,
      userIdValue: string | undefined,
      patch: Partial<IUserFeedback>
    ) => {
      if (!courseId) return;
      const current = map.get(courseId) || { userId: userIdValue || "" };
      map.set(courseId, { ...current, ...patch });
    };

    feedbackList.forEach((fb) => {
      upsert(fb.roleplayComplete?.courseId, fb.userId, {
        roleplayComplete: fb.roleplayComplete,
      });
      upsert(fb.roleplayIncomplete?.courseId, fb.userId, {
        roleplayIncomplete: fb.roleplayIncomplete,
      });
      upsert(fb.keypointComplete?.courseId, fb.userId, {
        keypointComplete: fb.keypointComplete,
      });
      upsert(fb.keypointIncomplete?.courseId, fb.userId, {
        keypointIncomplete: fb.keypointIncomplete,
      });
    });

    return map;
  }, [feedbackList]);

  useEffect(() => {
    fetchProgress(page);
  }, [fetchProgress, page]);

  useEffect(() => {
    fetchFeedback();
  }, [fetchFeedback]);

  const handleRemoveCourse = async () => {
    if (!confirmCourseId) return;
    if (!userId) {
      showError("Thiếu thông tin user để xoá");
      return;
    }

    try {
      setRemoving(true);
      await userProgressService.remove({
        userId,
        courseId: confirmCourseId,
        grade: GradeResultType.COURSE,
      });
      showSuccess("Xoá tiến độ khoá học thành công");
      setConfirmCourseId(null);
      fetchProgress(page);
    } catch (error) {
      console.error("Failed to remove course progress", error);
      showError("Xoá tiến độ khoá học thất bại");
    } finally {
      setRemoving(false);
    }
  };

  const handleRemoveFeedback = async () => {
    if (!userId) {
      showError("Thiếu thông tin user để xoá feedback");
      return;
    }

    try {
      setRemovingFeedback(true);
      await userFeedbackService.remove(userId);
      showSuccess("Xoá feedback thành công");
      setConfirmFeedbackRemove(false);
      fetchFeedback();
    } catch (error) {
      console.error("Failed to remove user feedback", error);
      showError("Xoá feedback thất bại");
    } finally {
      setRemovingFeedback(false);
    }
  };

  const handleCopyUserId = async () => {
    if (!userId) {
      showError("Không có userId để copy");
      return;
    }

    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(userId);
      } else {
        const textArea = document.createElement("textarea");
        textArea.value = userId;
        textArea.style.position = "fixed";
        textArea.style.opacity = "0";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand("copy");
        document.body.removeChild(textArea);
      }
      showSuccess("Đã copy userId");
    } catch (error) {
      console.error("Failed to copy userId", error);
      showError("Copy userId thất bại");
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">
              User learn progress
            </h1>
            <div className="flex flex-wrap items-center gap-2 text-sm text-gray-500">
              <span>{userLabel || "-"}</span>
              {userId ? (
                <span className="inline-flex items-center gap-1 rounded-md bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-600">
                  <span className="text-[10px] uppercase tracking-wide text-gray-400">
                    ID
                  </span>
                  <span className="font-mono">{userId}</span>
                  <button
                    type="button"
                    onClick={handleCopyUserId}
                    className="text-gray-500 hover:text-gray-800"
                    title="Copy userId"
                    aria-label="Copy userId"
                  >
                    <DocumentDuplicateIcon className="h-3.5 w-3.5" />
                  </button>
                </span>
              ) : null}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchProgress(page)}
              disabled={loading}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50 text-sm shadow-sm disabled:opacity-70"
              title="Làm mới"
            >
              <ArrowPathIcon
                className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
              />
              Làm mới
            </button>
            <button
              onClick={() => navigate(-1)}
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 text-sm shadow-sm"
            >
              Quay lại
            </button>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          {loading ? (
            <div className="p-10 text-center text-gray-500">
              Đang tải dữ liệu...
            </div>
          ) : items.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              Chưa có tiến độ học tập.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Course
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Start time
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Last time
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Stop at
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Completed levels
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Action
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {items.map((item) => {
                    const courseId = getCourseId(item);
                    const courseTitle =
                      getTranslationValue(item.title, lang) || "";
                    const title = courseTitle || courseId || "-";
                    const stopAtLabel = getStopAtLabel(item.stopAt, lang);
                    const lessonTitle = getTranslationValue(
                      item.stopAt?.lessonTitle,
                      lang
                    );
                    const keypointTitle = getTranslationValue(
                      item.stopAt?.keypointTitle,
                      lang
                    );
                    const type = item.stopAt?.lessonType;
                    const typeClass = type
                      ? lessonTypeStyles[type] || "bg-slate-100 text-slate-600"
                      : "";
                    const canNavigate = Boolean(courseId);
                    return (
                      <tr
                        key={courseId || title}
                        className="hover:bg-slate-50 transition-colors"
                      >
                        <td className="px-6 py-4 text-sm text-gray-800">
                          <div
                            className="max-w-[260px] truncate font-semibold text-gray-900"
                            title={title}
                          >
                            {title}
                          </div>
                          <div className="text-xs text-gray-400">
                            {courseId}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {formatDate(item.createdAt)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {formatDate(item.lastTime)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <div className="flex flex-col gap-1">
                            <div className="flex items-center gap-2">
                              {type ? (
                                <span
                                  className={`px-2 py-0.5 rounded-full text-xs font-semibold uppercase ${typeClass}`}
                                >
                                  {type}
                                </span>
                              ) : null}
                              <span
                                className="max-w-[220px] truncate text-sm text-gray-700"
                                title={lessonTitle || stopAtLabel}
                              >
                                {lessonTitle || stopAtLabel || "-"}
                              </span>
                            </div>
                            <span
                              className="max-w-[260px] truncate text-xs text-gray-500"
                              title={keypointTitle || stopAtLabel}
                            >
                              {keypointTitle
                                ? `Keypoint: ${keypointTitle}`
                                : stopAtLabel}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600 align-top">
                          <CompletedLevelsCell
                            levels={item.completedLevels}
                          />
                        </td>
                        <td className="px-6 py-4 text-right text-sm">
                          <div className="inline-flex items-center gap-3">
                            <button
                              onClick={() => {
                                if (!canNavigate) return;
                                navigate(
                                  `/progress/user/${userId}/course/${courseId}`,
                                  { state: { userLabel, courseTitle } }
                                );
                              }}
                              disabled={!canNavigate}
                              className={`inline-flex items-center gap-1 ${
                                canNavigate
                                  ? "text-blue-600 hover:text-blue-800"
                                  : "text-gray-400 cursor-not-allowed"
                              }`}
                            >
                              <EyeIcon className="h-4 w-4" />
                              <span className="underline">see detail</span>
                            </button>
                            <button
                              onClick={() => setConfirmCourseId(courseId)}
                              disabled={!courseId}
                              className={`inline-flex items-center ${
                                courseId
                                  ? "text-rose-600 hover:text-rose-700"
                                  : "text-gray-300 cursor-not-allowed"
                              }`}
                              title="Xoá tiến độ khoá học"
                            >
                              <TrashIcon className="h-4 w-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          <div className="p-4 flex justify-end">
            <Pagination
              count={totalPages}
              page={page}
              onChange={(_, value) => setPage(value)}
              color="primary"
              shape="rounded"
            />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between mb-3">
            <h2 className="text-lg font-semibold text-gray-900">Feedback</h2>
            <button
              onClick={() => setConfirmFeedbackRemove(true)}
              disabled={feedbackByCourse.size === 0 || feedbackLoading}
              className={`inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm border ${
                feedbackByCourse.size > 0 && !feedbackLoading
                  ? "text-rose-600 border-rose-200 hover:bg-rose-50"
                  : "text-gray-300 border-gray-200 cursor-not-allowed"
              }`}
              title="Xoá feedback của user"
            >
              <TrashIcon className="h-4 w-4" />
              Xoá feedback
            </button>
          </div>
          {feedbackLoading ? (
            <div className="py-6 text-center text-gray-500">
              Đang tải feedback...
            </div>
          ) : feedbackByCourse.size === 0 ? (
            <div className="py-6 text-center text-gray-500">
              Chưa có feedback.
            </div>
          ) : (
            <div className="space-y-3">
              {Array.from(feedbackByCourse.entries()).map(
                ([courseId, feedback]) => {
                  const courseTitle =
                    feedback.roleplayComplete?.courseTitle ||
                    feedback.roleplayIncomplete?.courseTitle ||
                    feedback.keypointComplete?.courseTitle ||
                    feedback.keypointIncomplete?.courseTitle;
                  const title =
                    getTranslationValue(courseTitle, lang) ||
                    courseId ||
                    "-";
                  return (
                    <div
                      key={courseId}
                      className="border border-gray-200 rounded-lg p-4"
                    >
                      <div className="flex flex-col gap-1 mb-2">
                        <div
                          className="font-semibold text-gray-900 truncate"
                          title={title}
                        >
                          {title}
                        </div>
                        <div className="text-xs text-gray-400">{courseId}</div>
                      </div>
                      <div className="space-y-1">
                        {renderFeedbackDetail(
                          "Roleplay hoàn thành",
                          lang,
                          feedback.roleplayComplete,
                          "complete"
                        )}
                        {renderFeedbackDetail(
                          "Roleplay bỏ dở",
                          lang,
                          feedback.roleplayIncomplete,
                          "incomplete"
                        )}
                        {renderFeedbackDetail(
                          "Keypoint hoàn thành",
                          lang,
                          feedback.keypointComplete,
                          "complete"
                        )}
                        {renderFeedbackDetail(
                          "Keypoint bỏ dở",
                          lang,
                          feedback.keypointIncomplete,
                          "incomplete"
                        )}
                      </div>
                    </div>
                  );
                }
              )}
            </div>
          )}
        </div>

        {confirmCourseId && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
            <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6 space-y-4">
              <h3 className="text-lg font-semibold text-gray-900">
                Xoá tiến độ khoá học?
              </h3>
              <p className="text-sm text-gray-600">
                Hành động này sẽ xoá toàn bộ tiến độ của khoá học này.
              </p>
              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setConfirmCourseId(null)}
                  disabled={removing}
                  className="px-4 py-2 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50"
                >
                  Huỷ
                </button>
                <button
                  onClick={handleRemoveCourse}
                  disabled={removing}
                  className="px-4 py-2 rounded-lg bg-rose-600 text-white hover:bg-rose-700 disabled:opacity-70"
                >
                  {removing ? "Đang xoá..." : "Xoá"}
                </button>
              </div>
            </div>
          </div>
        )}

        {confirmFeedbackRemove && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
            <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6 space-y-4">
              <h3 className="text-lg font-semibold text-gray-900">
                Xoá feedback của user?
              </h3>
              <p className="text-sm text-gray-600">
                Hành động này sẽ xoá toàn bộ feedback của user này.
              </p>
              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setConfirmFeedbackRemove(false)}
                  disabled={removingFeedback}
                  className="px-4 py-2 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50"
                >
                  Huỷ
                </button>
                <button
                  onClick={handleRemoveFeedback}
                  disabled={removingFeedback}
                  className="px-4 py-2 rounded-lg bg-rose-600 text-white hover:bg-rose-700 disabled:opacity-70"
                >
                  {removingFeedback ? "Đang xoá..." : "Xoá"}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
